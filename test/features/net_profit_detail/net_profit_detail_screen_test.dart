import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/features/net_profit_detail/domain/net_profit_detail_models.dart';
import 'package:gider/features/net_profit_detail/presentation/net_profit_detail_screen.dart';

import '../../support/localization_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final NetProfitDetailViewModel populatedViewModel = NetProfitDetailViewModel(
    query: const NetProfitDetailQuery.thisWeek(),
    selectedRangeLabel: 'Mon 20 Apr – Sun 26 Apr',
    rangeStart: DateTime(2026, 4, 20),
    rangeEnd: DateTime(2026, 4, 26),
    netProfitMinor: 3000,
    incomeMinor: 15000,
    expenseMinor: 12000,
    marginPercent: 20,
    health: const NetProfitHealth(
      marginPercent: 20,
      label: 'Moderate',
      description: 'Margin is positive but still under pressure.',
    ),
    comparison: const NetProfitComparison(
      incomeMinor: 15000,
      expenseMinor: 12000,
      expenseRatioPercent: 80,
      message: 'Expenses are eating 80% of income',
    ),
    dailyProfitSeries: <NetProfitChartPoint>[
      NetProfitChartPoint(
        date: DateTime(2026, 4, 20),
        incomeMinor: 10000,
        expenseMinor: 3000,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 21),
        incomeMinor: 5000,
        expenseMinor: 7000,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 22),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 23),
        incomeMinor: 0,
        expenseMinor: 2000,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 24),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 25),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 26),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
    ],
    breakdownRows: <NetProfitBreakdownRow>[
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 20),
        incomeMinor: 10000,
        expenseMinor: 3000,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 21),
        incomeMinor: 5000,
        expenseMinor: 7000,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 22),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 23),
        incomeMinor: 0,
        expenseMinor: 2000,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 24),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 25),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 26),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
    ],
    kpis: const <NetProfitKpi>[
      NetProfitKpi(
        title: 'Net profit',
        primary: '£30.00',
        secondary: 'Income - Expenses',
      ),
      NetProfitKpi(
        title: 'Total income',
        primary: '£150.00',
        secondary: 'Selected range',
      ),
      NetProfitKpi(
        title: 'Total expenses',
        primary: '£120.00',
        secondary: 'Selected range',
      ),
    ],
    bestDayInsight: const NetProfitInsight(
      title: 'Best day',
      primary: 'Mon',
      secondary: '£70.00',
    ),
    worstDayInsight: const NetProfitInsight(
      title: 'Worst day',
      primary: 'Thu',
      secondary: '-£20.00',
    ),
    averageDailyProfitInsight: const NetProfitInsight(
      title: 'Average daily profit',
      primary: '£4.29',
      secondary: 'Across 7 days',
    ),
    showExpensePressureWarning: true,
    expensePressureMessage: 'Expenses are consuming most of your income',
    isEmpty: false,
    hasDisabledChartState: false,
    incomePaymentBreakdowns: const <NetProfitPaymentBreakdown>[
      NetProfitPaymentBreakdown(label: 'Cash', amountMinor: 5000),
      NetProfitPaymentBreakdown(label: 'Card', amountMinor: 10000),
    ],
    expensePaymentBreakdowns: const <NetProfitPaymentBreakdown>[
      NetProfitPaymentBreakdown(label: 'Cash expenses', amountMinor: 7000),
      NetProfitPaymentBreakdown(label: 'Card expenses', amountMinor: 5000),
    ],
    dailyBreakdowns: <NetProfitDailyBreakdown>[
      NetProfitDailyBreakdown(
        date: DateTime(2026, 4, 20),
        incomeMinor: 10000,
        expenseMinor: 3000,
        cashIncomeMinor: 0,
        cardIncomeMinor: 10000,
        incomeTransactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 20),
            title: 'Card Sales',
            subtitle: 'Card Sales · Card · Direct',
            amountMinor: 10000,
            paymentMethod: PaymentMethodType.card,
          ),
        ],
        expenseTransactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 20),
            title: 'Bread Bacon',
            subtitle: 'Stock Purchase · Card',
            amountMinor: 3000,
            paymentMethod: PaymentMethodType.card,
          ),
        ],
      ),
      NetProfitDailyBreakdown(
        date: DateTime(2026, 4, 21),
        incomeMinor: 5000,
        expenseMinor: 7000,
        cashIncomeMinor: 5000,
        cardIncomeMinor: 0,
        incomeTransactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 21),
            title: 'Cash Sales',
            subtitle: 'Cash Sales · Cash · Direct',
            amountMinor: 5000,
            paymentMethod: PaymentMethodType.cash,
          ),
        ],
        expenseTransactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 21),
            title: 'Yusuf abi',
            subtitle: 'Staff Wages · Cash',
            amountMinor: 7000,
            paymentMethod: PaymentMethodType.cash,
          ),
        ],
      ),
    ],
    expenseCategoryBreakdowns: <NetProfitExpenseCategoryBreakdown>[
      NetProfitExpenseCategoryBreakdown(
        categoryName: 'Staff Wages',
        amountMinor: 7000,
        transactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 21),
            title: 'Yusuf abi',
            subtitle: 'Staff Wages · Cash',
            amountMinor: 7000,
            paymentMethod: PaymentMethodType.cash,
          ),
        ],
      ),
      NetProfitExpenseCategoryBreakdown(
        categoryName: 'Stock Purchase',
        amountMinor: 3000,
        transactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 20),
            title: 'Bread Bacon',
            subtitle: 'Stock Purchase · Card',
            amountMinor: 3000,
            paymentMethod: PaymentMethodType.card,
          ),
        ],
      ),
    ],
    incomeSourceBreakdowns: <NetProfitIncomeSourceBreakdown>[
      NetProfitIncomeSourceBreakdown(
        label: 'Cash Sales',
        amountMinor: 5000,
        days: <NetProfitIncomeSourceDayBreakdown>[
          NetProfitIncomeSourceDayBreakdown(
            date: DateTime(2026, 4, 21),
            amountMinor: 5000,
          ),
        ],
      ),
      NetProfitIncomeSourceBreakdown(
        label: 'Card Sales',
        amountMinor: 10000,
        days: <NetProfitIncomeSourceDayBreakdown>[
          NetProfitIncomeSourceDayBreakdown(
            date: DateTime(2026, 4, 20),
            amountMinor: 10000,
          ),
        ],
      ),
    ],
  );

  final NetProfitDetailViewModel emptyViewModel = NetProfitDetailViewModel(
    query: const NetProfitDetailQuery.thisWeek(),
    selectedRangeLabel: 'Mon 20 Apr – Sun 26 Apr',
    rangeStart: DateTime(2026, 4, 20),
    rangeEnd: DateTime(2026, 4, 26),
    netProfitMinor: 0,
    incomeMinor: 0,
    expenseMinor: 0,
    marginPercent: 0,
    health: const NetProfitHealth(
      marginPercent: 0,
      label: 'No margin yet',
      description: 'Profit margin appears once income is recorded.',
    ),
    comparison: const NetProfitComparison(
      incomeMinor: 0,
      expenseMinor: 0,
      expenseRatioPercent: 0,
      message: 'No activity in the selected range',
    ),
    dailyProfitSeries: <NetProfitChartPoint>[
      NetProfitChartPoint(
        date: DateTime(2026, 4, 20),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 21),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 22),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 23),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 24),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 25),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitChartPoint(
        date: DateTime(2026, 4, 26),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
    ],
    breakdownRows: <NetProfitBreakdownRow>[
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 20),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 21),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 22),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 23),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 24),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 25),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 26),
        incomeMinor: 0,
        expenseMinor: 0,
      ),
    ],
    kpis: const <NetProfitKpi>[
      NetProfitKpi(
        title: 'Net profit',
        primary: '£0.00',
        secondary: 'Income - Expenses',
        isEmpty: true,
      ),
      NetProfitKpi(
        title: 'Total income',
        primary: '£0.00',
        secondary: 'Selected range',
        isEmpty: true,
      ),
      NetProfitKpi(
        title: 'Total expenses',
        primary: '£0.00',
        secondary: 'Selected range',
        isEmpty: true,
      ),
    ],
    bestDayInsight: const NetProfitInsight(
      title: 'Best day',
      primary: 'No profit yet',
      secondary: 'Selected range is empty',
      isEmpty: true,
    ),
    worstDayInsight: const NetProfitInsight(
      title: 'Worst day',
      primary: 'No loss yet',
      secondary: 'Selected range is empty',
      isEmpty: true,
    ),
    averageDailyProfitInsight: const NetProfitInsight(
      title: 'Average daily profit',
      primary: '£0.00',
      secondary: 'Across 7 days',
      isEmpty: true,
    ),
    showExpensePressureWarning: false,
    expensePressureMessage: null,
    isEmpty: true,
    hasDisabledChartState: true,
  );

  final NetProfitDetailViewModel lastWeekViewModel = NetProfitDetailViewModel(
    query: const NetProfitDetailQuery.lastWeek(),
    selectedRangeLabel: 'Mon 13 Apr – Sun 19 Apr',
    rangeStart: DateTime(2026, 4, 13),
    rangeEnd: DateTime(2026, 4, 19),
    netProfitMinor: 8000,
    incomeMinor: 12000,
    expenseMinor: 4000,
    marginPercent: 67,
    health: const NetProfitHealth(
      marginPercent: 67,
      label: 'Healthy',
      description: 'Margin is healthy.',
    ),
    comparison: const NetProfitComparison(
      incomeMinor: 12000,
      expenseMinor: 4000,
      expenseRatioPercent: 33,
      message: 'Expenses are eating 33% of income',
    ),
    dailyProfitSeries: <NetProfitChartPoint>[
      NetProfitChartPoint(
        date: DateTime(2026, 4, 13),
        incomeMinor: 12000,
        expenseMinor: 4000,
      ),
    ],
    breakdownRows: <NetProfitBreakdownRow>[
      NetProfitBreakdownRow(
        date: DateTime(2026, 4, 13),
        incomeMinor: 12000,
        expenseMinor: 4000,
      ),
    ],
    kpis: const <NetProfitKpi>[
      NetProfitKpi(
        title: 'Net profit',
        primary: '£80.00',
        secondary: 'Income - Expenses',
      ),
      NetProfitKpi(
        title: 'Total income',
        primary: '£120.00',
        secondary: 'Selected range',
      ),
      NetProfitKpi(
        title: 'Total expenses',
        primary: '£40.00',
        secondary: 'Selected range',
      ),
    ],
    bestDayInsight: const NetProfitInsight(
      title: 'Best day',
      primary: 'Mon',
      secondary: '£80.00',
    ),
    worstDayInsight: const NetProfitInsight(
      title: 'Worst day',
      primary: 'Mon',
      secondary: '£80.00',
    ),
    averageDailyProfitInsight: const NetProfitInsight(
      title: 'Average daily profit',
      primary: '£80.00',
      secondary: 'Across 1 day',
    ),
    showExpensePressureWarning: false,
    expensePressureMessage: null,
    isEmpty: false,
    hasDisabledChartState: false,
    incomePaymentBreakdowns: const <NetProfitPaymentBreakdown>[
      NetProfitPaymentBreakdown(label: 'Card', amountMinor: 12000),
    ],
    expensePaymentBreakdowns: const <NetProfitPaymentBreakdown>[
      NetProfitPaymentBreakdown(label: 'Card expenses', amountMinor: 4000),
    ],
    dailyBreakdowns: <NetProfitDailyBreakdown>[
      NetProfitDailyBreakdown(
        date: DateTime(2026, 4, 13),
        incomeMinor: 12000,
        expenseMinor: 4000,
        cashIncomeMinor: 0,
        cardIncomeMinor: 12000,
        incomeTransactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 13),
            title: 'Last Week Card Sales',
            subtitle: 'Card Sales · Card · Direct',
            amountMinor: 12000,
            paymentMethod: PaymentMethodType.card,
          ),
        ],
        expenseTransactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 13),
            title: 'Sausage Butcher',
            subtitle: 'Stock Purchase · Card',
            amountMinor: 4000,
            paymentMethod: PaymentMethodType.card,
          ),
        ],
      ),
    ],
    expenseCategoryBreakdowns: <NetProfitExpenseCategoryBreakdown>[
      NetProfitExpenseCategoryBreakdown(
        categoryName: 'Stock Purchase',
        amountMinor: 4000,
        transactions: <NetProfitTransactionRow>[
          NetProfitTransactionRow(
            date: DateTime(2026, 4, 13),
            title: 'Sausage Butcher',
            subtitle: 'Stock Purchase · Card',
            amountMinor: 4000,
            paymentMethod: PaymentMethodType.card,
          ),
        ],
      ),
    ],
    incomeSourceBreakdowns: <NetProfitIncomeSourceBreakdown>[
      NetProfitIncomeSourceBreakdown(
        label: 'Card Sales',
        amountMinor: 12000,
        days: <NetProfitIncomeSourceDayBreakdown>[
          NetProfitIncomeSourceDayBreakdown(
            date: DateTime(2026, 4, 13),
            amountMinor: 12000,
          ),
        ],
      ),
    ],
  );

  Widget buildApp(NetProfitDetailViewModel viewModel) {
    return ProviderScope(
      overrides: <Override>[
        currentDateTimeProvider.overrideWith((ref) => DateTime(2026, 4, 22)),
        netProfitDetailProvider.overrideWith((ref, query) async => viewModel),
      ],
      child: buildLocalizedTestApp(home: const NetProfitDetailScreen()),
    );
  }

  Widget buildAppForRanges() {
    return ProviderScope(
      overrides: <Override>[
        currentDateTimeProvider.overrideWith((ref) => DateTime(2026, 4, 22)),
        netProfitDetailProvider.overrideWith((ref, query) async {
          return switch (query.preset) {
            NetProfitDetailRangePreset.lastWeek => lastWeekViewModel,
            _ => populatedViewModel,
          };
        }),
      ],
      child: buildLocalizedTestApp(home: const NetProfitDetailScreen()),
    );
  }

  testWidgets('renders populated net profit detail sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(populatedViewModel));
    await tester.pumpAndSettle();

    expect(find.text('Net profit'), findsWidgets);
    expect(find.text('Mon 20 Apr – Sun 26 Apr'), findsOneWidget);
    expect(find.text('£30.00'), findsOneWidget);
    expect(find.text('Margin 20%'), findsOneWidget);
    expect(find.text('Expenses are eating 80% of income'), findsOneWidget);
    expect(
      find.text('Expenses are consuming most of your income'),
      findsOneWidget,
    );
    expect(find.text('Profit by day'), findsOneWidget);
    expect(find.text('Daily breakdown'), findsOneWidget);
    expect(find.text('Payment breakdown'), findsOneWidget);
    expect(find.text('Expenses this week'), findsOneWidget);
    expect(find.text('Income this week'), findsOneWidget);
    expect(find.text('Average daily profit'), findsOneWidget);
  });

  testWidgets('expands daily rows and weekly detail sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(populatedViewModel));
    await tester.pumpAndSettle();

    expect(find.text('Bread Bacon'), findsNothing);
    expect(find.text('Yusuf abi'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('daily-row-2026-04-20')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Card Sales'), findsWidgets);
    expect(find.text('Bread Bacon'), findsOneWidget);
    expect(find.text('Stock Purchase · Card'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('weekly-expense-details-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stock Purchase'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('expense-category-Stock Purchase')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mon 20 Apr · Card'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('weekly-income-details-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cash Sales'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('income-source-Cash Sales')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tue 21 Apr'), findsWidgets);
  });

  testWidgets('updates breakdown content when date range changes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildAppForRanges());
    await tester.pumpAndSettle();

    expect(find.text('Mon 20 Apr – Sun 26 Apr'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('weekly-expense-details-toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('expense-category-Stock Purchase')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bread Bacon'), findsOneWidget);

    await tester.tap(find.text('Last week'));
    await tester.pumpAndSettle();

    expect(find.text('Mon 13 Apr – Sun 19 Apr'), findsOneWidget);
    expect(find.text('Bread Bacon'), findsNothing);
    expect(find.text('Sausage Butcher'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('daily-row-2026-04-13')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last Week Card Sales'), findsOneWidget);
    expect(find.text('Sausage Butcher'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('weekly-income-details-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Card Sales'), findsWidgets);
  });

  testWidgets('renders disabled empty state safely', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(emptyViewModel));
    await tester.pumpAndSettle();

    expect(find.text('£0.00'), findsWidgets);
    expect(find.text('No margin yet'), findsOneWidget);
    expect(find.text('No activity in the selected range'), findsOneWidget);
    expect(find.text('No profit records in this range'), findsOneWidget);
    expect(find.text('No profit yet'), findsOneWidget);
    expect(find.text('No loss yet'), findsOneWidget);
  });
}
