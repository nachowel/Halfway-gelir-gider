import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
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

  Widget buildApp(NetProfitDetailViewModel viewModel) {
    return ProviderScope(
      overrides: <Override>[
        netProfitDetailProvider.overrideWith((ref, query) async => viewModel),
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
    expect(find.text('Average daily profit'), findsOneWidget);
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
