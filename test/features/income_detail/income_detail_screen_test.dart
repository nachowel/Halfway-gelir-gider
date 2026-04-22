import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/features/income_detail/domain/income_detail_models.dart';
import 'package:gider/features/income_detail/presentation/income_detail_screen.dart';

import '../../support/localization_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppTheme.configure);

  final IncomeDetailViewModel populatedViewModel = IncomeDetailViewModel(
    query: const IncomeDetailQuery.thisWeek(),
    selectedRangeLabel: 'Mon 20 Apr – Sun 26 Apr',
    rangeStart: DateTime(2026, 4, 20),
    rangeEnd: DateTime(2026, 4, 26),
    totalIncomeMinor: 20000,
    cashIncomeMinor: 12000,
    cardIncomeMinor: 8000,
    cashSharePercent: 60,
    cardSharePercent: 40,
    chartSeries: <IncomeDetailChartPoint>[
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 20),
        cashMinor: 3000,
        cardMinor: 1000,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 21),
        cashMinor: 4000,
        cardMinor: 2000,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 22),
        cashMinor: 2000,
        cardMinor: 0,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 23),
        cashMinor: 3000,
        cardMinor: 2000,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 24),
        cashMinor: 0,
        cardMinor: 2000,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 25),
        cashMinor: 0,
        cardMinor: 1000,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 26),
        cashMinor: 0,
        cardMinor: 0,
      ),
    ],
    breakdownRows: <IncomeDetailBreakdownRow>[
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 20),
        cashMinor: 3000,
        cardMinor: 1000,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 21),
        cashMinor: 4000,
        cardMinor: 2000,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 22),
        cashMinor: 2000,
        cardMinor: 0,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 23),
        cashMinor: 3000,
        cardMinor: 2000,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 24),
        cashMinor: 0,
        cardMinor: 2000,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 25),
        cashMinor: 0,
        cardMinor: 1000,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 26),
        cashMinor: 0,
        cardMinor: 0,
      ),
    ],
    highestDayInsight: const IncomeDetailInsight(
      title: 'Highest day',
      primary: 'Tue',
      secondary: '£60.00',
    ),
    averagePerDayInsight: const IncomeDetailInsight(
      title: 'Average per day',
      primary: '£28.57',
      secondary: 'Across 7 days',
    ),
    bestPaymentMixInsight: const IncomeDetailInsight(
      title: 'Best mix (cash)',
      primary: 'Mon',
      secondary: '75% cash',
    ),
    isEmpty: false,
    hasDisabledChartState: false,
  );

  final IncomeDetailViewModel emptyViewModel = IncomeDetailViewModel(
    query: const IncomeDetailQuery.thisWeek(),
    selectedRangeLabel: 'Mon 20 Apr – Sun 26 Apr',
    rangeStart: DateTime(2026, 4, 20),
    rangeEnd: DateTime(2026, 4, 26),
    totalIncomeMinor: 0,
    cashIncomeMinor: 0,
    cardIncomeMinor: 0,
    cashSharePercent: 0,
    cardSharePercent: 0,
    chartSeries: <IncomeDetailChartPoint>[
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 20),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 21),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 22),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 23),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 24),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 25),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailChartPoint(
        date: DateTime(2026, 4, 26),
        cashMinor: 0,
        cardMinor: 0,
      ),
    ],
    breakdownRows: <IncomeDetailBreakdownRow>[
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 20),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 21),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 22),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 23),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 24),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 25),
        cashMinor: 0,
        cardMinor: 0,
      ),
      IncomeDetailBreakdownRow(
        date: DateTime(2026, 4, 26),
        cashMinor: 0,
        cardMinor: 0,
      ),
    ],
    highestDayInsight: const IncomeDetailInsight(
      title: 'Highest day',
      primary: 'No income yet',
      secondary: 'Selected range is empty',
      isEmpty: true,
    ),
    averagePerDayInsight: const IncomeDetailInsight(
      title: 'Average per day',
      primary: '£0.00',
      secondary: 'Across 7 days',
      isEmpty: true,
    ),
    bestPaymentMixInsight: const IncomeDetailInsight(
      title: 'Best mix (cash)',
      primary: 'No payment mix yet',
      secondary: 'No income days in range',
      isEmpty: true,
    ),
    isEmpty: true,
    hasDisabledChartState: true,
  );

  Widget buildApp(IncomeDetailViewModel viewModel) {
    return ProviderScope(
      overrides: <Override>[
        incomeDetailProvider.overrideWith((ref, query) async => viewModel),
      ],
      child: buildLocalizedTestApp(
        theme: AppTheme.light(),
        home: const IncomeDetailScreen(),
      ),
    );
  }

  testWidgets('renders populated income detail sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(populatedViewModel));
    await tester.pumpAndSettle();

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Mon 20 Apr – Sun 26 Apr'), findsOneWidget);
    expect(find.text('£200.00'), findsOneWidget);
    expect(find.text('£120.00'), findsOneWidget);
    expect(find.text('£80.00'), findsOneWidget);
    expect(find.text('Income by day'), findsOneWidget);
    expect(find.text('Breakdown'), findsOneWidget);
    expect(find.text('Highest day'), findsOneWidget);
    expect(find.text('Across 7 days'), findsOneWidget);
    expect(find.text('75% cash'), findsOneWidget);
  });

  testWidgets('renders disabled empty state safely', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(emptyViewModel));
    await tester.pumpAndSettle();

    expect(find.text('£0.00'), findsWidgets);
    expect(find.text('0%'), findsNWidgets(2));
    expect(find.text('No income records in this range'), findsOneWidget);
    expect(find.text('No income yet'), findsOneWidget);
    expect(find.text('No payment mix yet'), findsOneWidget);
  });
}
