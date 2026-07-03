import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/features/reports/domain/payee_analytics_models.dart';
import 'package:gider/features/reports/presentation/payee_analytics_section.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:gider/shared/hi_fi/hi_fi_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppTheme.configure);

  TransactionData tx({
    required String id,
    required String vendor,
    required int amountMinor,
    required DateTime occurredOn,
    String categoryName = 'Stock Purchase',
  }) {
    return TransactionData(
      id: id,
      type: TransactionType.expense,
      occurredOn: occurredOn,
      amountMinor: amountMinor,
      categoryId: 'cat-$id',
      categoryName: categoryName,
      paymentMethod: PaymentMethodType.card,
      createdAt: occurredOn,
      vendor: vendor,
    );
  }

  DateTime currentDay() => DateTime.now();

  Widget buildApp({
    required PayeeAnalyticsDataset dataset,
    PayeeAnalyticsQuery? query,
  }) {
    final DateTime today = currentDay();
    return ProviderScope(
      overrides: <Override>[
        payeeAnalyticsDatasetProvider.overrideWith((_) async => dataset),
        payeeAnalyticsQueryProvider.overrideWith(
          (_) =>
              query ??
              PayeeAnalyticsQuery(
                preset: PayeeRangePreset.custom,
                customStart: DateTime(today.year - 1, 1, 1),
                customEnd: DateTime(today.year + 1, 12, 31),
              ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: PayeeAnalyticsSection()),
        ),
      ),
    );
  }

  testWidgets('renders payee section with empty state when no data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        dataset: const PayeeAnalyticsDataset(
          transactions: <TransactionData>[],
          expenseCategoryIcons: <String, IconData>{},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PAYEE ANALYTICS'), findsOneWidget);
    expect(find.byType(HiFiCard), findsWidgets);
  });

  testWidgets('renders payee rows when data is available', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    final List<TransactionData> txs = <TransactionData>[
      tx(
        id: 't1',
        vendor: 'Costco',
        amountMinor: 5000,
        occurredOn: now.subtract(const Duration(days: 5)),
      ),
      tx(
        id: 't2',
        vendor: 'Tesco',
        amountMinor: 3000,
        occurredOn: now.subtract(const Duration(days: 8)),
      ),
    ];
    await tester.pumpWidget(
      buildApp(
        dataset: PayeeAnalyticsDataset(
          transactions: txs,
          expenseCategoryIcons: const <String, IconData>{},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Costco'), findsNWidgets(2));
    expect(find.text('Tesco'), findsNWidgets(2));
    expect(find.text('£50.00'), findsNWidgets(2));
    expect(find.text('£30.00'), findsNWidgets(2));
  });

  testWidgets('search filters payee rows', (WidgetTester tester) async {
    final DateTime now = DateTime.now();
    final List<TransactionData> txs = <TransactionData>[
      tx(
        id: 't1',
        vendor: 'Costco',
        amountMinor: 5000,
        occurredOn: now.subtract(const Duration(days: 5)),
      ),
      tx(
        id: 't2',
        vendor: 'Tesco',
        amountMinor: 3000,
        occurredOn: now.subtract(const Duration(days: 8)),
      ),
    ];
    await tester.pumpWidget(
      buildApp(
        dataset: PayeeAnalyticsDataset(
          transactions: txs,
          expenseCategoryIcons: const <String, IconData>{},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Costco'), findsNWidgets(2));
    expect(find.text('Tesco'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey<String>('payee-analytics-search-field')),
      'cos',
    );
    await tester.pumpAndSettle();

    expect(find.text('Costco'), findsNWidgets(2));
    expect(find.text('Tesco'), findsNWidgets(1));
  });
}
