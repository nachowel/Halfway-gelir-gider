import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/features/recurring/presentation/recurring_screen.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:gider/shared/hi_fi/hi_fi_icon_tile.dart';
import 'package:gider/shared/hi_fi/hi_fi_recurring_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppTheme.configure);

  final RecurringUiItem rentItem = RecurringUiItem(
    record: RecurringExpenseData(
      id: 'rec-rent',
      name: 'Rent',
      categoryId: 'cat-1',
      categoryName: 'Housing',
      amountMinor: 85000,
      frequency: RecurringFrequencyType.monthly,
      nextDueOn: DateTime(2026, 5, 1),
      reminderDaysBefore: 3,
      reserveEnabled: false,
      isActive: true,
      defaultPaymentMethod: PaymentMethodType.bankTransfer,
    ),
    status: RecurringUiStatus.soon,
    statusLabel: 'In 2 days',
    frequencyMeta: 'Every month · Thu 1 May',
    icon: Icons.home_rounded,
  );

  Widget buildTestApp({
    required List<RecurringUiItem> items,
    bool simulateError = false,
  }) {
    return ProviderScope(
      overrides: <Override>[
        expenseCategoriesProvider.overrideWith(
          (ref) async => <CategoryData>[
            const CategoryData(
              id: 'cat-1',
              type: CategoryType.expense,
              name: 'Housing',
              icon: Icons.home_rounded,
              tone: HiFiIconTileTone.expense,
              sortOrder: 0,
              isArchived: false,
              entryCount: 0,
              monthlyTotalMinor: 0,
            ),
          ],
        ),
        recurringItemsProvider.overrideWith((ref) async {
          if (simulateError) throw Exception('network error');
          return items;
        }),
        recurringSummaryProvider.overrideWith(
          (ref) async =>
              const RecurringSummarySnapshot(totalMinor: 85000, paidMinor: 0),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RecurringScreen()),
      ),
    );
  }

  testWidgets('renders provider data as recurring rows', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(items: [rentItem]));
    await tester.pumpAndSettle();

    expect(find.text('Rent'), findsOneWidget);
    expect(find.byType(HiFiRecurringRow), findsOneWidget);
    expect(find.text('£850.00'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('recurring-back-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('recurring-add-button')),
      findsOneWidget,
    );
  });

  testWidgets('shows empty state when provider returns empty list', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(items: []));
    await tester.pumpAndSettle();

    expect(find.text('No recurring expenses'), findsOneWidget);
    expect(find.text('Tap + to add your first one.'), findsOneWidget);
    expect(find.byType(HiFiRecurringRow), findsNothing);
  });

  testWidgets('shows error state when provider throws', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(items: [], simulateError: true));
    await tester.pumpAndSettle();

    expect(find.text("Couldn’t load recurring expenses"), findsOneWidget);
    expect(find.byType(HiFiRecurringRow), findsNothing);
  });

  testWidgets('summary card shows paid and remaining amounts', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(items: []));
    await tester.pumpAndSettle();

    expect(find.text('£0.00 paid'), findsOneWidget);
    expect(find.text('£850.00 remaining'), findsOneWidget);
  });

  testWidgets(
    'opening recurring form on a small viewport with keyboard does not overflow',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(items: []));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('recurring-add-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('New recurring expense'), findsOneWidget);
      expect(find.text('Add recurring'), findsOneWidget);

      await tester.showKeyboard(find.byType(TextField).first);
      await tester.pumpAndSettle();

      expect(find.text('Add recurring'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      expect(find.text('Add recurring'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
