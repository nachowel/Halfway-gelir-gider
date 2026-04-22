import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/features/transactions/presentation/transactions_screen.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:gider/shared/hi_fi/hi_fi_list_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(AppTheme.configure);

  String groupKey(DateTime date, TransactionType type) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final String month = normalized.month.toString().padLeft(2, '0');
    final String day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day-${type.name}';
  }

  List<TransactionData> sampleTransactions() {
    final DateTime now = DateTime.now();
    return <TransactionData>[
      TransactionData(
        id: 't1',
        type: TransactionType.income,
        occurredOn: DateTime(now.year, now.month, now.day),
        amountMinor: 18600,
        categoryId: 'c1',
        categoryName: 'Food sales',
        paymentMethod: PaymentMethodType.card,
        createdAt: DateTime(now.year, now.month, now.day, 10),
        sourcePlatform: SourcePlatformType.uber,
        vendor: 'Uber Eats payout',
        note: 'Lunch rush settlement',
      ),
      TransactionData(
        id: 't2',
        type: TransactionType.expense,
        occurredOn: DateTime(now.year, now.month, now.day - 1),
        amountMinor: 4200,
        categoryId: 'c2',
        categoryName: 'Fuel',
        paymentMethod: PaymentMethodType.cash,
        createdAt: DateTime(now.year, now.month, now.day - 1, 9),
        vendor: null,
        note: 'Van fuel top up',
      ),
      TransactionData(
        id: 't3',
        type: TransactionType.expense,
        occurredOn: DateTime(now.year, now.month, now.day - 45),
        amountMinor: 15000,
        categoryId: 'c3',
        categoryName: 'Rent',
        paymentMethod: PaymentMethodType.bankTransfer,
        createdAt: DateTime(now.year, now.month, now.day - 45, 8),
        sourcePlatform: SourcePlatformType.direct,
        vendor: 'Landlord',
        note: 'Old month rent',
      ),
    ];
  }

  List<TransactionData> groupedDayTransactions() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime previousDay = today.subtract(const Duration(days: 1));

    return <TransactionData>[
      TransactionData(
        id: 'g1',
        type: TransactionType.expense,
        occurredOn: today,
        amountMinor: 22200,
        categoryId: 'c1',
        categoryName: 'Rent',
        paymentMethod: PaymentMethodType.bankTransfer,
        createdAt: DateTime(today.year, today.month, today.day, 9, 30),
        vendor: 'Rent',
      ),
      TransactionData(
        id: 'g2',
        type: TransactionType.expense,
        occurredOn: today,
        amountMinor: 23200,
        categoryId: 'c2',
        categoryName: 'Stock Purchase',
        paymentMethod: PaymentMethodType.cash,
        createdAt: DateTime(today.year, today.month, today.day, 8, 30),
        vendor: 'Stock Purchase',
      ),
      TransactionData(
        id: 'g3',
        type: TransactionType.expense,
        occurredOn: today,
        amountMinor: 8900,
        categoryId: 'c3',
        categoryName: 'Groceries',
        paymentMethod: PaymentMethodType.card,
        createdAt: DateTime(today.year, today.month, today.day, 7, 30),
        vendor: 'Groceries',
      ),
      TransactionData(
        id: 'g4',
        type: TransactionType.income,
        occurredOn: today,
        amountMinor: 39000,
        categoryId: 'c4',
        categoryName: 'Card Sales',
        paymentMethod: PaymentMethodType.card,
        createdAt: DateTime(today.year, today.month, today.day, 13),
        sourcePlatform: SourcePlatformType.direct,
        vendor: 'Card Sales',
      ),
      TransactionData(
        id: 'g5',
        type: TransactionType.income,
        occurredOn: today,
        amountMinor: 20000,
        categoryId: 'c5',
        categoryName: 'Cash Sales',
        paymentMethod: PaymentMethodType.cash,
        createdAt: DateTime(today.year, today.month, today.day, 12),
        sourcePlatform: SourcePlatformType.direct,
        vendor: 'Cash Sales',
      ),
      TransactionData(
        id: 'g6',
        type: TransactionType.expense,
        occurredOn: previousDay,
        amountMinor: 5000,
        categoryId: 'c6',
        categoryName: 'Utilities',
        paymentMethod: PaymentMethodType.bankTransfer,
        createdAt: DateTime(
          previousDay.year,
          previousDay.month,
          previousDay.day,
          11,
        ),
        vendor: 'Utilities',
      ),
    ];
  }

  Widget buildTestApp({
    required List<TransactionData> data,
    bool simulateError = false,
    bool enableSearch = true,
    bool enableFilter = true,
  }) {
    return ProviderScope(
      overrides: <Override>[
        for (final TransactionsFilter filter in TransactionsFilter.values)
          transactionsProvider(filter).overrideWith((ref) async {
            if (simulateError) {
              throw Exception('network error');
            }
            return data;
          }),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransactionsScreen(
            enableSearch: enableSearch,
            enableFilter: enableFilter,
          ),
        ),
      ),
    );
  }

  testWidgets('renders provider data as grouped list rows', (
    WidgetTester tester,
  ) async {
    final List<TransactionData> data = sampleTransactions();
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(data: data));
    await tester.pumpAndSettle();

    expect(find.text('Uber Eats payout'), findsOneWidget);
    expect(find.text('Fuel'), findsWidgets);
    expect(find.byType(HiFiListRow), findsNWidgets(3));
    expect(find.text('£186.00'), findsWidgets);
    expect(find.text('£42.00'), findsWidgets);
  });

  testWidgets('renders expense and income groups within each day with totals', (
    WidgetTester tester,
  ) async {
    final List<TransactionData> data = groupedDayTransactions();
    final DateTime today = DateTime.now();
    final String expenseToggleKey = groupKey(today, TransactionType.expense);
    final String incomeToggleKey = groupKey(today, TransactionType.income);
    final String previousDayExpenseKey = groupKey(
      today.subtract(const Duration(days: 1)),
      TransactionType.expense,
    );

    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(data: data));
    await tester.pumpAndSettle();

    expect(find.byType(HiFiListRow), findsNWidgets(6));
    expect(
      find.byKey(
        ValueKey<String>('transaction-group-toggle-$expenseToggleKey'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('transaction-group-toggle-$incomeToggleKey')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('transaction-group-toggle-$previousDayExpenseKey'),
      ),
      findsOneWidget,
    );
    expect(find.text('Expenses'), findsNWidgets(2));
    expect(find.text('£543.00'), findsOneWidget);
    expect(find.text('£590.00'), findsOneWidget);
    expect(find.text('net +£47.00'), findsOneWidget);
    expect(find.text('Card Sales'), findsOneWidget);
    expect(find.text('Groceries · Card'), findsOneWidget);
    expect(find.text('Card Sales · Card · Direct'), findsOneWidget);
  });

  testWidgets(
    'collapsing a group hides only its rows and keeps the header visible',
    (WidgetTester tester) async {
      final List<TransactionData> data = groupedDayTransactions();
      final DateTime today = DateTime.now();
      final String expenseToggleKey = groupKey(today, TransactionType.expense);

      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(data: data));
      await tester.pumpAndSettle();

      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Stock Purchase'), findsOneWidget);
      expect(find.text('Card Sales'), findsOneWidget);

      await tester.tap(
        find.byKey(
          ValueKey<String>('transaction-group-toggle-$expenseToggleKey'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text('Expenses'), findsNWidgets(2));
      expect(find.text('£543.00'), findsOneWidget);
      expect(find.text('Rent'), findsNothing);
      expect(find.text('Stock Purchase'), findsNothing);
      expect(find.text('Groceries'), findsNothing);
      expect(find.text('Card Sales'), findsOneWidget);
      expect(find.byType(HiFiListRow), findsNWidgets(3));
    },
  );

  testWidgets('shows empty state when provider returns empty list', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(data: const <TransactionData>[]));
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Transactions you add will appear here.'), findsOneWidget);
    expect(find.byType(HiFiListRow), findsNothing);
  });

  testWidgets('shows error state when provider throws', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(data: const <TransactionData>[], simulateError: true),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn’t load transactions"), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.byType(HiFiListRow), findsNothing);
  });

  testWidgets('search filters by note, platform and payment method', (
    WidgetTester tester,
  ) async {
    final List<TransactionData> data = sampleTransactions();
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(data: data));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('transactions-search-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('transactions-search-field')),
      'lunch',
    );
    await tester.pumpAndSettle();
    expect(find.text('Uber Eats payout'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('transactions-search-field')),
      'cash',
    );
    await tester.pumpAndSettle();
    expect(find.text('Fuel'), findsWidgets);
    expect(find.text('Uber Eats payout'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('transactions-search-field')),
      'uber',
    );
    await tester.pumpAndSettle();
    expect(find.text('Uber Eats payout'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);
  });

  testWidgets(
    'search can be opened and closed repeatedly without lifecycle exceptions',
    (WidgetTester tester) async {
      final List<TransactionData> data = sampleTransactions();
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(data: data));
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(
          find.byKey(const ValueKey<String>('transactions-search-button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('transactions-search-field')),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const ValueKey<String>('transactions-search-field')),
          'uber',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('transactions-search-button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('transactions-search-field')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('shows empty search result state', (WidgetTester tester) async {
    final List<TransactionData> data = sampleTransactions();
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(data: data));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('transactions-search-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('transactions-search-field')),
      'no-match',
    );
    await tester.pumpAndSettle();

    expect(find.text('No matching transactions'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
    expect(find.byType(HiFiListRow), findsNothing);
  });

  testWidgets('filter sheet applies filters and reset clears them', (
    WidgetTester tester,
  ) async {
    final List<TransactionData> data = sampleTransactions();
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(data: data));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('transactions-filter-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('filter-period-thisMonth')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('filter-type-expense')));
    await tester.tap(find.byKey(const ValueKey<String>('filter-payment-cash')));
    await tester.tap(
      find.byKey(const ValueKey<String>('transactions-filter-apply')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fuel'), findsWidgets);
    expect(find.text('Uber Eats payout'), findsNothing);
    expect(find.text('Landlord'), findsNothing);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Expense'), findsWidgets);
    expect(find.text('Cash'), findsWidgets);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(find.text('Uber Eats payout'), findsOneWidget);
    expect(find.text('Landlord'), findsOneWidget);
  });

  testWidgets(
    'filter sheet can be dismissed, applied and reset repeatedly without exceptions',
    (WidgetTester tester) async {
      final List<TransactionData> data = sampleTransactions();
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(data: data));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('transactions-filter-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Refine transactions'), findsOneWidget);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.text('Refine transactions'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey<String>('transactions-filter-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('filter-type-expense')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('transactions-filter-apply')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Expense'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey<String>('transactions-filter-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('transactions-filter-reset')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('transactions-filter-apply')),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsNothing);
      expect(find.text('Uber Eats payout'), findsOneWidget);
      expect(find.text('Fuel'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search and advanced filters combine as an intersection', (
    WidgetTester tester,
  ) async {
    final List<TransactionData> data = sampleTransactions();
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(data: data));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('transactions-search-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('transactions-search-field')),
      'rent',
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('transactions-filter-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('filter-payment-bankTransfer')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('transactions-filter-apply')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Landlord'), findsOneWidget);
    expect(find.text('Uber Eats payout'), findsNothing);
    expect(find.text('Fuel'), findsNothing);
    expect(find.text('Search: rent'), findsOneWidget);
  });

  testWidgets('feature icons are hidden when feature flags are disabled', (
    WidgetTester tester,
  ) async {
    final List<TransactionData> data = sampleTransactions();
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(data: data, enableSearch: false, enableFilter: false),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('transactions-search-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('transactions-filter-button')),
      findsNothing,
    );
  });
}
