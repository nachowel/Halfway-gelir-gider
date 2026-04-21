import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gider/app/app.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/router/route_access.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/shared/hi_fi/hi_fi_icon_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const BusinessSettingsData settings = BusinessSettingsData(
    email: 'owner@example.com',
    businessName: 'Halfway Cafe',
    timezone: 'Europe/London',
    currency: 'GBP',
    weekStartsOn: 1,
    isBootstrapComplete: true,
  );

  const CategoryData expenseCategory = CategoryData(
    id: 'expense-rent',
    type: CategoryType.expense,
    name: 'Rent',
    icon: Icons.home_rounded,
    tone: HiFiIconTileTone.expense,
    sortOrder: 0,
    isArchived: false,
    entryCount: 2,
    monthlyTotalMinor: 540000,
  );

  const DashboardSnapshot dashboard = DashboardSnapshot(
    weekLabel: 'MON 1 -> SUN 7 APR',
    incomeMinor: 150000,
    expenseMinor: 90000,
    cashIncomeMinor: 50000,
    cardIncomeMinor: 100000,
    netDeltaMinor: 12000,
    reservePlanner: ReservePlannerSnapshot.empty(),
    recentTransactions: <TransactionData>[],
    upcomingRecurring: <RecurringUiItem>[],
  );

  const RecurringSummarySnapshot recurringSummary = RecurringSummarySnapshot(
    totalMinor: 4000,
    paidMinor: 0,
  );

  final List<RecurringUiItem> recurringItems = <RecurringUiItem>[
    RecurringUiItem(
      record: RecurringExpenseData(
        id: 'rec-1',
        name: 'Broadband',
        categoryId: 'expense-rent',
        categoryName: 'Utilities',
        amountMinor: 4000,
        frequency: RecurringFrequencyType.monthly,
        nextDueOn: DateTime(2026, 4, 25),
        reminderDaysBefore: 3,
        reserveEnabled: true,
        isActive: true,
      ),
      status: RecurringUiStatus.soon,
      statusLabel: 'In 4 days',
      frequencyMeta: 'Every month · Fri 25 Apr',
      icon: Icons.wifi_rounded,
    ),
  ];

  Widget buildApp() {
    return ProviderScope(
      overrides: <Override>[
        authRoutingStatusProvider.overrideWithValue(
          AppAuthRoutingStatus.authenticated,
        ),
        businessSettingsBootstrapStatusProvider.overrideWithValue(
          BusinessSettingsBootstrapStatus.complete,
        ),
        dashboardSnapshotProvider.overrideWith((ref) async => dashboard),
        businessSettingsProvider.overrideWith((ref) async => settings),
        expenseCategoriesProvider.overrideWith(
          (ref) async => <CategoryData>[expenseCategory],
        ),
        incomeCategoriesProvider.overrideWith((ref) async => <CategoryData>[]),
        recurringItemsProvider.overrideWith((ref) async => recurringItems),
        recurringSummaryProvider.overrideWith((ref) async => recurringSummary),
      ],
      child: const GiderApp(),
    );
  }

  testWidgets(
    'bottom nav switches shell routes without stacking while sub-routes still pop',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('NET PROFIT'), findsOneWidget);

      await tester.tap(find.byKey(const Key('bottom-nav-item-3')));
      await tester.pumpAndSettle();

      expect(find.text('Preferences & account'), findsOneWidget);
      expect(find.text('NET PROFIT'), findsNothing);

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Manage expense and income tags'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Preferences & account'), findsOneWidget);
      expect(find.text('Manage expense and income tags'), findsNothing);
    },
  );

  testWidgets(
    'income entry opens after quick actions sheet closes and still pops after keyboard hide',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('shell-fab-visible')));
      await tester.pumpAndSettle();

      expect(find.text('Gelir ekle'), findsOneWidget);

      await tester.tap(find.text('Gelir ekle'));
      await tester.pumpAndSettle();

      expect(find.text('ADD NEW'), findsNothing);
      expect(find.text('Geliri kaydet'), findsOneWidget);

      await tester.showKeyboard(find.byType(TextField).first);
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      expect(find.text('Geliri kaydet'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('NET PROFIT'), findsOneWidget);
      expect(find.text('Geliri kaydet'), findsNothing);
    },
  );

  testWidgets('authenticated app starts on the dashboard entry point', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('NET PROFIT'), findsOneWidget);
  });

  testWidgets('recurring screen shows back button and pops to settings', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bottom-nav-item-3')));
    await tester.pumpAndSettle();
    expect(find.text('Preferences & account'), findsOneWidget);

    await tester.tap(find.text('Recurring expenses'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('recurring-back-button')),
      findsOneWidget,
    );
    expect(find.text('Broadband'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-back-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preferences & account'), findsOneWidget);
    expect(find.text('Broadband'), findsNothing);
  });

  testWidgets('direct recurring route open stays stable and pops to settings', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.byKey(const Key('bottom-nav'))),
    ).go('/settings/recurring');
    await tester.pumpAndSettle();

    expect(find.text('Broadband'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('recurring-back-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('recurring-back-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preferences & account'), findsOneWidget);
  });
}
