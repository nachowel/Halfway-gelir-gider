import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gider/features/dashboard/widgets/reserve_planner_card.dart';
import 'package:gider/features/dashboard/widgets/summary_cards.dart';
import 'package:gider/features/dashboard/widgets/transaction_list_item.dart';
import 'package:gider/features/dashboard/widgets/upcoming_payment_item.dart';
import 'package:gider/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppTheme.configure);

  final TransactionData incomeTransaction = TransactionData(
    id: 'tx-1',
    type: TransactionType.income,
    occurredOn: DateTime(2026, 4, 14),
    amountMinor: 32000,
    categoryId: 'cat-sales',
    categoryName: 'Cash Sales',
    paymentMethod: PaymentMethodType.cash,
    createdAt: DateTime(2026, 4, 14),
    vendor: 'Walk-in sales',
  );

  final TransactionData expenseTransaction = TransactionData(
    id: 'tx-2',
    type: TransactionType.expense,
    occurredOn: DateTime(2026, 4, 15),
    amountMinor: 8500,
    categoryId: 'cat-rent',
    categoryName: 'Rent',
    paymentMethod: PaymentMethodType.bankTransfer,
    createdAt: DateTime(2026, 4, 15),
  );

  final RecurringUiItem upcomingItem = RecurringUiItem(
    record: RecurringExpenseData(
      id: 'rec-1',
      name: 'Rent',
      categoryId: 'cat-rent',
      categoryName: 'Rent',
      amountMinor: 85000,
      frequency: RecurringFrequencyType.monthly,
      nextDueOn: DateTime(2026, 5, 1),
      reminderDaysBefore: 3,
      reserveEnabled: false,
      isActive: true,
    ),
    status: RecurringUiStatus.soon,
    statusLabel: 'In 2 days',
    frequencyMeta: 'Every month · Thu 1 May',
    icon: Icons.home_rounded,
  );

  DashboardSnapshot buildSnapshot({
    List<TransactionData> recent = const [],
    List<RecurringUiItem> upcoming = const [],
    ReservePlannerSnapshot? reservePlanner,
  }) {
    return DashboardSnapshot(
      weekLabel: 'Mon 14 → Sun 20 Apr',
      incomeMinor: 40000,
      expenseMinor: 8500,
      cashIncomeMinor: 12000,
      cardIncomeMinor: 18000,
      netDeltaMinor: 5000,
      reservePlanner:
          reservePlanner ??
          ReservePlannerSnapshot(
            totalSuggestedWeeklyReserveMinor: 27500,
            eligibleItemCount: 2,
            items: <ReservePlannerItem>[
              ReservePlannerItem(
                id: 'res-rent',
                name: 'Rent',
                amountMinor: 85000,
                frequency: RecurringFrequencyType.monthly,
                nextDueOn: DateTime(2026, 5, 1),
                daysUntilDue: 10,
                weeksUntilDue: 2,
                suggestedWeeklyReserveMinor: 42500,
              ),
              ReservePlannerItem(
                id: 'res-net',
                name: 'Broadband',
                amountMinor: 5500,
                frequency: RecurringFrequencyType.monthly,
                nextDueOn: DateTime(2026, 4, 25),
                daysUntilDue: 4,
                weeksUntilDue: 1,
                suggestedWeeklyReserveMinor: 5500,
              ),
            ],
          ),
      recentTransactions: recent,
      upcomingRecurring: upcoming,
    );
  }

  Widget buildTestApp(DashboardSnapshot snapshot) {
    return ProviderScope(
      overrides: <Override>[
        dashboardSnapshotProvider.overrideWith((_) async => snapshot),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DashboardScreen()),
      ),
    );
  }

  Widget buildRouterTestApp(DashboardSnapshot snapshot) {
    final GoRouter router = GoRouter(
      initialLocation: '/summary',
      routes: <RouteBase>[
        GoRoute(
          path: '/summary',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: DashboardScreen());
          },
        ),
        GoRoute(
          path: '/transactions',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Text('Transactions route'));
          },
        ),
        GoRoute(
          path: '/summary/income',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Text('Income detail route'));
          },
        ),
        GoRoute(
          path: '/summary/expenses',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Text('Expense detail route'));
          },
        ),
        GoRoute(
          path: '/summary/net-profit',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Text('Net profit detail route'));
          },
        ),
        GoRoute(
          path: '/settings/recurring',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Text('Recurring route'));
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: <Override>[
        dashboardSnapshotProvider.overrideWith((_) async => snapshot),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Widget buildErrorApp() {
    return ProviderScope(
      overrides: <Override>[
        dashboardSnapshotProvider.overrideWith(
          (_) async => throw Exception('fail'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DashboardScreen()),
      ),
    );
  }

  testWidgets('renders week label from snapshot', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(buildSnapshot()));
    await tester.pumpAndSettle();

    expect(find.text('MON 14 → SUN 20 APR'), findsOneWidget);
  });

  testWidgets('renders summary cards with snapshot values', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(buildSnapshot()));
    await tester.pumpAndSettle();

    expect(find.byType(HeroSummaryCard), findsOneWidget);
    expect(find.byType(SummaryMetricCard), findsNWidgets(2));
    expect(find.byType(CashSplitSummaryCard), findsOneWidget);
    // net = 40000 - 8500 = 31500
    expect(find.text('£315.00'), findsWidgets);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(
      find.text('Bank transfer income is included in total income'),
      findsOneWidget,
    );
  });

  testWidgets('renders upcoming recurring items', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(buildSnapshot(upcoming: [upcomingItem])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byType(UpcomingPaymentItem), findsOneWidget);
    expect(find.text('Rent'), findsWidgets);
    expect(find.text('£850.00'), findsOneWidget);
  });

  testWidgets('upcoming preview is limited to 3 items and sorted by due date', (
    WidgetTester tester,
  ) async {
    final List<RecurringUiItem> upcoming = <RecurringUiItem>[
      _recurringItem(
        id: 'rec-4',
        name: 'Fourth',
        nextDueOn: DateTime(2026, 5, 8),
      ),
      _recurringItem(
        id: 'rec-2',
        name: 'Second',
        nextDueOn: DateTime(2026, 4, 24),
      ),
      _recurringItem(
        id: 'rec-3',
        name: 'Third',
        nextDueOn: DateTime(2026, 5, 1),
      ),
      _recurringItem(
        id: 'rec-1',
        name: 'First',
        nextDueOn: DateTime(2026, 4, 22),
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(buildSnapshot(upcoming: upcoming)));
    await tester.pumpAndSettle();

    expect(find.byType(UpcomingPaymentItem), findsNWidgets(3));
    expect(find.text('Fourth'), findsNothing);
    _expectVerticalOrder(tester, <String>['First', 'Second', 'Third']);
  });

  testWidgets('renders reserve planner card with preview items', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(buildSnapshot()));
    await tester.pumpAndSettle();

    expect(find.byType(ReservePlannerCard), findsOneWidget);
    expect(find.text('RESERVE PLANNER'), findsOneWidget);
    expect(find.text('Broadband'), findsOneWidget);
  });

  testWidgets('tapping income summary card opens income detail route', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRouterTestApp(buildSnapshot()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard-income-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Income detail route'), findsOneWidget);
  });

  testWidgets('tapping expense summary card opens expense detail route', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRouterTestApp(buildSnapshot()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard-expense-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expense detail route'), findsOneWidget);
  });

  testWidgets('tapping net profit hero card opens net profit detail route', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRouterTestApp(buildSnapshot()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard-net-profit-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Net profit detail route'), findsOneWidget);
  });

  testWidgets('renders recent transactions', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(
        buildSnapshot(recent: [incomeTransaction, expenseTransaction]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    expect(find.byType(TransactionListItem), findsNWidgets(2));
    expect(find.text('Walk-in sales'), findsOneWidget);
    expect(find.text('Rent'), findsWidgets);
  });

  testWidgets(
    'recent preview is limited to 4 items and sorted by occurredOn then createdAt descending',
    (WidgetTester tester) async {
      final List<TransactionData> recent = <TransactionData>[
        _transaction(
          id: 'tx-3',
          title: 'Third newest',
          occurredOn: DateTime(2026, 4, 16),
          createdAt: DateTime(2026, 4, 16, 10),
        ),
        _transaction(
          id: 'tx-1',
          title: 'Newest tie later create',
          occurredOn: DateTime(2026, 4, 18),
          createdAt: DateTime(2026, 4, 18, 11),
        ),
        _transaction(
          id: 'tx-5',
          title: 'Dropped fifth',
          occurredOn: DateTime(2026, 4, 14),
          createdAt: DateTime(2026, 4, 14, 8),
        ),
        _transaction(
          id: 'tx-2',
          title: 'Newest tie earlier create',
          occurredOn: DateTime(2026, 4, 18),
          createdAt: DateTime(2026, 4, 18, 9),
        ),
        _transaction(
          id: 'tx-4',
          title: 'Fourth newest',
          occurredOn: DateTime(2026, 4, 15),
          createdAt: DateTime(2026, 4, 15, 12),
        ),
      ];

      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(buildSnapshot(recent: recent)));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionListItem), findsNWidgets(4));
      expect(find.text('Dropped fifth'), findsNothing);
      _expectVerticalOrder(tester, <String>[
        'Newest tie later create',
        'Newest tie earlier create',
        'Third newest',
        'Fourth newest',
      ]);
    },
  );

  testWidgets('recent section shows empty state and hides see all when empty', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(buildSnapshot(recent: [])));
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    expect(find.byType(TransactionListItem), findsNothing);
    expect(find.text('No recent transactions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('dashboard-recent-see-all')),
      findsNothing,
    );
  });

  testWidgets('shows error state when provider throws', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildErrorApp());
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load dashboard'), findsOneWidget);
    expect(find.byType(UpcomingPaymentItem), findsNothing);
    expect(find.byType(TransactionListItem), findsNothing);
  });

  testWidgets(
    'upcoming section shows empty state and hides see all when empty',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(buildSnapshot(upcoming: [])));
      await tester.pumpAndSettle();

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.byType(UpcomingPaymentItem), findsNothing);
      expect(find.text('No upcoming payments'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('dashboard-upcoming-see-all')),
        findsNothing,
      );
    },
  );

  testWidgets('upcoming see all navigates to recurring route', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildRouterTestApp(
        buildSnapshot(upcoming: <RecurringUiItem>[upcomingItem]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard-upcoming-see-all')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recurring route'), findsOneWidget);
  });

  testWidgets('recent see all navigates to transactions route', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildRouterTestApp(
        buildSnapshot(recent: <TransactionData>[incomeTransaction]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard-recent-see-all')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transactions route'), findsOneWidget);
  });
}

RecurringUiItem _recurringItem({
  required String id,
  required String name,
  required DateTime nextDueOn,
}) {
  return RecurringUiItem(
    record: RecurringExpenseData(
      id: id,
      name: name,
      categoryId: 'cat-$id',
      categoryName: name,
      amountMinor: 4000,
      frequency: RecurringFrequencyType.monthly,
      nextDueOn: nextDueOn,
      reminderDaysBefore: 3,
      reserveEnabled: false,
      isActive: true,
    ),
    status: RecurringUiStatus.soon,
    statusLabel: 'Soon',
    frequencyMeta: 'Every month · preview',
    icon: Icons.event_repeat_rounded,
  );
}

TransactionData _transaction({
  required String id,
  required String title,
  required DateTime occurredOn,
  required DateTime createdAt,
}) {
  return TransactionData(
    id: id,
    type: TransactionType.income,
    occurredOn: occurredOn,
    amountMinor: 1000,
    categoryId: 'cat-$id',
    categoryName: 'Sales',
    paymentMethod: PaymentMethodType.card,
    createdAt: createdAt,
    vendor: title,
  );
}

void _expectVerticalOrder(WidgetTester tester, List<String> labels) {
  double? previousTop;
  for (final String label in labels) {
    final Finder finder = find.text(label);
    expect(finder, findsOneWidget);
    final double top = tester.getTopLeft(finder).dy;
    if (previousTop != null) {
      expect(top, greaterThan(previousTop));
    }
    previousTop = top;
  }
}
