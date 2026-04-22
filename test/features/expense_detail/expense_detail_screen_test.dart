import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/features/expense_detail/domain/expense_detail_models.dart';
import 'package:gider/features/expense_detail/presentation/expense_detail_screen.dart';
import 'package:gider/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppTheme.configure);

  final ExpenseDetailViewModel populatedViewModel = ExpenseDetailViewModel(
    query: const ExpenseDetailQuery.thisWeek(),
    selectedRangeLabel: 'Mon 20 Apr – Sun 26 Apr',
    rangeStart: DateTime(2026, 4, 20),
    rangeEnd: DateTime(2026, 4, 26),
    totalExpensesMinor: 18000,
    cashExpensesMinor: 7000,
    cardExpensesMinor: 9000,
    topCategoryName: 'Stock',
    topCategoryMinor: 9000,
    largestDayDate: DateTime(2026, 4, 20),
    largestDayMinor: 9000,
    kpis: const <ExpenseKpiDescriptor>[
      ExpenseKpiDescriptor(
        title: 'Total expenses',
        primary: '£180.00',
        secondary: 'Selected range',
      ),
      ExpenseKpiDescriptor(
        title: 'Highest category',
        primary: 'Stock',
        secondary: '£90.00',
      ),
      ExpenseKpiDescriptor(
        title: 'Largest day',
        primary: 'Mon',
        secondary: '£90.00',
      ),
    ],
    compositionItems: const <ExpenseCompositionItem>[
      ExpenseCompositionItem(label: 'Stock', percent: 50, amountMinor: 9000),
      ExpenseCompositionItem(
        label: 'Utilities',
        percent: 33.3,
        amountMinor: 6000,
      ),
    ],
    chartSeries: <ExpenseDetailChartPoint>[
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 20),
        totalMinor: 9000,
        cashMinor: 3000,
        cardMinor: 6000,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 21),
        totalMinor: 6000,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 6000,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 22),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 23),
        totalMinor: 3000,
        cashMinor: 3000,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 24),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 25),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 26),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
    ],
    categoryBreakdownRows: const <ExpenseCategoryBreakdownRow>[
      ExpenseCategoryBreakdownRow(
        categoryName: 'Stock',
        totalMinor: 9000,
        sharePercent: 50,
        transactionCount: 2,
      ),
      ExpenseCategoryBreakdownRow(
        categoryName: 'Utilities',
        totalMinor: 6000,
        sharePercent: 33.3,
        transactionCount: 1,
      ),
      ExpenseCategoryBreakdownRow(
        categoryName: 'Supplies',
        totalMinor: 3000,
        sharePercent: 16.7,
        transactionCount: 1,
      ),
    ],
    dailyBreakdownRows: <ExpenseDailyBreakdownRow>[
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 20),
        totalMinor: 9000,
        cashMinor: 3000,
        cardMinor: 6000,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 21),
        totalMinor: 6000,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 6000,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 22),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 23),
        totalMinor: 3000,
        cashMinor: 3000,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 24),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 25),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 26),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
    ],
    averagePerDayInsight: const ExpenseDetailInsight(
      title: 'Average per day',
      primary: '£25.71',
      secondary: 'Across 7 days',
    ),
    highestSpendDayInsight: const ExpenseDetailInsight(
      title: 'Highest spend day',
      primary: 'Mon',
      secondary: '£90.00',
    ),
    topCategoryInsight: const ExpenseDetailInsight(
      title: 'Top category',
      primary: 'Stock',
      secondary: '£90.00',
    ),
    warningInsightMessage: 'Most spending is concentrated in one category.',
    isEmpty: false,
    hasDisabledChartState: false,
  );

  final ExpenseDetailViewModel emptyViewModel = ExpenseDetailViewModel(
    query: const ExpenseDetailQuery.thisWeek(),
    selectedRangeLabel: 'Mon 20 Apr – Sun 26 Apr',
    rangeStart: DateTime(2026, 4, 20),
    rangeEnd: DateTime(2026, 4, 26),
    totalExpensesMinor: 0,
    cashExpensesMinor: 0,
    cardExpensesMinor: 0,
    topCategoryName: null,
    topCategoryMinor: 0,
    largestDayDate: null,
    largestDayMinor: 0,
    kpis: const <ExpenseKpiDescriptor>[
      ExpenseKpiDescriptor(
        title: 'Total expenses',
        primary: '£0.00',
        secondary: 'Selected range',
        isEmpty: true,
      ),
      ExpenseKpiDescriptor(
        title: 'Highest category',
        primary: 'No category yet',
        secondary: '£0.00',
        isEmpty: true,
      ),
      ExpenseKpiDescriptor(
        title: 'Largest day',
        primary: 'No spend yet',
        secondary: '£0.00',
        isEmpty: true,
      ),
    ],
    compositionItems: const <ExpenseCompositionItem>[
      ExpenseCompositionItem(
        label: 'No category yet',
        percent: 0,
        amountMinor: 0,
        isPlaceholder: true,
      ),
      ExpenseCompositionItem(
        label: 'No category yet',
        percent: 0,
        amountMinor: 0,
        isPlaceholder: true,
      ),
    ],
    chartSeries: <ExpenseDetailChartPoint>[
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 20),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 21),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 22),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 23),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 24),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 25),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 26),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
    ],
    categoryBreakdownRows: const <ExpenseCategoryBreakdownRow>[],
    dailyBreakdownRows: <ExpenseDailyBreakdownRow>[
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 20),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 21),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 22),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 23),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 24),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 25),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 26),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
    ],
    averagePerDayInsight: const ExpenseDetailInsight(
      title: 'Average per day',
      primary: '£0.00',
      secondary: 'Across 7 days',
      isEmpty: true,
    ),
    highestSpendDayInsight: const ExpenseDetailInsight(
      title: 'Highest spend day',
      primary: 'No spend yet',
      secondary: 'Selected range is empty',
      isEmpty: true,
    ),
    topCategoryInsight: const ExpenseDetailInsight(
      title: 'Top category',
      primary: 'No category yet',
      secondary: 'No expenses in range',
      isEmpty: true,
    ),
    warningInsightMessage: null,
    isEmpty: true,
    hasDisabledChartState: true,
  );

  final ExpenseDetailViewModel highAxisViewModel = ExpenseDetailViewModel(
    query: const ExpenseDetailQuery.thisWeek(),
    selectedRangeLabel: 'Mon 20 Apr – Sun 26 Apr',
    rangeStart: DateTime(2026, 4, 20),
    rangeEnd: DateTime(2026, 4, 26),
    totalExpensesMinor: 57700,
    cashExpensesMinor: 0,
    cardExpensesMinor: 57700,
    topCategoryName: 'Stock',
    topCategoryMinor: 57700,
    largestDayDate: DateTime(2026, 4, 21),
    largestDayMinor: 57700,
    kpis: const <ExpenseKpiDescriptor>[
      ExpenseKpiDescriptor(
        title: 'Total expenses',
        primary: '£577.00',
        secondary: 'Selected range',
      ),
      ExpenseKpiDescriptor(
        title: 'Highest category',
        primary: 'Stock',
        secondary: '£577.00',
      ),
      ExpenseKpiDescriptor(
        title: 'Largest day',
        primary: 'Tue',
        secondary: '£577.00',
      ),
    ],
    compositionItems: const <ExpenseCompositionItem>[
      ExpenseCompositionItem(label: 'Stock', percent: 100, amountMinor: 57700),
      ExpenseCompositionItem(
        label: 'No second category',
        percent: 0,
        amountMinor: 0,
        isPlaceholder: true,
      ),
    ],
    chartSeries: <ExpenseDetailChartPoint>[
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 20),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 21),
        totalMinor: 57700,
        cashMinor: 0,
        cardMinor: 57700,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 22),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 23),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 24),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 25),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDetailChartPoint(
        date: DateTime(2026, 4, 26),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
    ],
    categoryBreakdownRows: const <ExpenseCategoryBreakdownRow>[
      ExpenseCategoryBreakdownRow(
        categoryName: 'Stock',
        totalMinor: 57700,
        sharePercent: 100,
        transactionCount: 1,
      ),
    ],
    dailyBreakdownRows: <ExpenseDailyBreakdownRow>[
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 20),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 21),
        totalMinor: 57700,
        cashMinor: 0,
        cardMinor: 57700,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 22),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 23),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 24),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 25),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
      ExpenseDailyBreakdownRow(
        date: DateTime(2026, 4, 26),
        totalMinor: 0,
        cashMinor: 0,
        cardMinor: 0,
        otherMinor: 0,
      ),
    ],
    averagePerDayInsight: const ExpenseDetailInsight(
      title: 'Average per day',
      primary: '£82.43',
      secondary: 'Across 7 days',
    ),
    highestSpendDayInsight: const ExpenseDetailInsight(
      title: 'Highest spend day',
      primary: 'Tue',
      secondary: '£577.00',
    ),
    topCategoryInsight: const ExpenseDetailInsight(
      title: 'Top category',
      primary: 'Stock',
      secondary: '£577.00',
    ),
    warningInsightMessage: 'Most spending is concentrated in one category.',
    isEmpty: false,
    hasDisabledChartState: false,
  );

  Widget buildApp(ExpenseDetailViewModel viewModel) {
    return ProviderScope(
      overrides: <Override>[
        expenseDetailProvider.overrideWith((ref, query) async => viewModel),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExpenseDetailScreen(),
      ),
    );
  }

  testWidgets('renders populated expense detail sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(populatedViewModel));
    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Mon 20 Apr – Sun 26 Apr'), findsOneWidget);
    expect(find.text('£180.00'), findsOneWidget);
    expect(find.text('Category breakdown'), findsOneWidget);
    expect(find.text('Daily breakdown'), findsOneWidget);
    expect(find.text('Stock'), findsWidgets);
    expect(
      find.text('Most spending is concentrated in one category.'),
      findsOneWidget,
    );
    expect(find.text('Across 7 days'), findsOneWidget);
  });

  testWidgets('renders disabled expense empty state safely', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(emptyViewModel));
    await tester.pumpAndSettle();

    expect(find.text('£0.00'), findsWidgets);
    expect(find.text('No expense records in this range'), findsOneWidget);
    expect(find.text('No expense categories in this range'), findsOneWidget);
    expect(find.text('No spend yet'), findsWidgets);
    expect(find.text('No category yet'), findsWidgets);
  });

  testWidgets('renders compact single-line y-axis labels for high values', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(highAxisViewModel));
    await tester.pumpAndSettle();

    expect(find.text('£1k'), findsOneWidget);
    expect(find.text('£500'), findsOneWidget);
    expect(find.text('£250'), findsOneWidget);
  });
}
