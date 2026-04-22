import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/app/providers/app_providers.dart';
import 'package:gider/app/shell/app_shell.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/features/reports/domain/monthly_reports_models.dart';
import 'package:gider/features/reports/presentation/reports_screen.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:gider/shared/hi_fi/hi_fi_fab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppTheme.configure);

  MonthlyReportsViewModel buildReport({
    required DateTime selectedMonth,
    int incomeMinor = 260000,
    int expenseMinor = 115000,
    int netMinor = 145000,
    MonthlyReportsComparison? comparison,
    MonthlyReportsHealth? health,
    List<MonthlyReportsCategoryRow> categories =
        const <MonthlyReportsCategoryRow>[],
    List<MonthlyReportsSupplierRow> suppliers =
        const <MonthlyReportsSupplierRow>[],
    List<MonthlyReportsInsightItem>? insights,
    List<MonthlyReportsTrendPoint> trendSeries =
        const <MonthlyReportsTrendPoint>[],
    MonthlyReportsDailySummary? dailySummary,
    bool? isEmpty,
    bool? hasCategoryData,
    bool? hasSupplierData,
    bool? hasTrendData,
  }) {
    return MonthlyReportsViewModel(
      selectedMonth: selectedMonth,
      monthLabel: switch (selectedMonth.month) {
        3 => 'Mart',
        4 => 'Nisan',
        _ => 'Nisan',
      },
      yearLabel: selectedMonth.year.toString(),
      totalIncomeMinor: incomeMinor,
      totalExpensesMinor: expenseMinor,
      netProfitMinor: netMinor,
      previousMonthComparison: comparison,
      health:
          health ??
          const MonthlyReportsHealth(
            profitMarginPercent: 55.8,
            expenseRatioPercent: 44.2,
            label: 'Strong',
            description: 'Income is staying comfortably ahead of costs.',
            state: MonthlyReportsHealthState.strong,
          ),
      categoryBreakdownRows: categories,
      supplierBreakdownRows: suppliers,
      insights:
          insights ??
          const <MonthlyReportsInsightItem>[
            MonthlyReportsInsightItem(
              title: 'Top expense',
              primary: 'Rent',
              secondary: '£850 · 74%',
              tone: MonthlyReportsInsightTone.expense,
            ),
            MonthlyReportsInsightItem(
              title: 'Top income stream',
              primary: 'Card Sales',
              secondary: '£2,200',
              tone: MonthlyReportsInsightTone.income,
            ),
            MonthlyReportsInsightItem(
              title: 'Net day range',
              primary: 'Best 18 Nisan +£320',
              secondary: 'Worst 5 Nisan -£80',
              tone: MonthlyReportsInsightTone.brand,
            ),
          ],
      trendSeries: trendSeries,
      dailySummary:
          dailySummary ??
          MonthlyReportsDailySummary(
            bestDay: MonthlyReportsDayMetric(
              date: DateTime(2026, 4, 18),
              netMinor: 32000,
            ),
            worstDay: MonthlyReportsDayMetric(
              date: DateTime(2026, 4, 5),
              netMinor: -8000,
            ),
            averageDailyNetMinor: 4800,
            calendarDayCount: 30,
            usesCalendarDays: true,
          ),
      isEmpty: isEmpty ?? (incomeMinor == 0 && expenseMinor == 0),
      hasCategoryData: hasCategoryData ?? categories.isNotEmpty,
      hasSupplierData: hasSupplierData ?? suppliers.isNotEmpty,
      hasTrendData:
          hasTrendData ??
          trendSeries.any(
            (MonthlyReportsTrendPoint point) => point.hasActivity,
          ),
    );
  }

  Widget buildValueApp({
    required MonthlyReportsViewModel aprilReport,
    MonthlyReportsViewModel? marchReport,
  }) {
    return ProviderScope(
      overrides: <Override>[
        selectedReportsMonthProvider.overrideWith((_) => DateTime(2026, 4, 1)),
        reportsSnapshotProvider.overrideWith((ref) async {
          final DateTime selectedMonth = ref.watch(
            selectedReportsMonthProvider,
          );
          if (marchReport != null && selectedMonth.month == 3) {
            return marchReport;
          }
          return aprilReport;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ReportsScreen()),
      ),
    );
  }

  Widget buildShellApp({
    required MonthlyReportsViewModel aprilReport,
    MonthlyReportsViewModel? marchReport,
  }) {
    return ProviderScope(
      overrides: <Override>[
        selectedReportsMonthProvider.overrideWith((_) => DateTime(2026, 4, 1)),
        reportsSnapshotProvider.overrideWith((ref) async {
          final DateTime selectedMonth = ref.watch(
            selectedReportsMonthProvider,
          );
          if (marchReport != null && selectedMonth.month == 3) {
            return marchReport;
          }
          return aprilReport;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppShell(
          currentLocation: '/reports',
          child: ReportsScreen(),
        ),
      ),
    );
  }

  Widget buildErrorApp() {
    return ProviderScope(
      overrides: <Override>[
        reportsSnapshotProvider.overrideWith(
          (_) async => throw Exception('network fail'),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ReportsScreen()),
      ),
    );
  }

  testWidgets('renders richer monthly overview sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildValueApp(
        aprilReport: buildReport(
          selectedMonth: DateTime(2026, 4, 1),
          comparison: const MonthlyReportsComparison(
            previousNetMinor: 110000,
            changeMinor: 35000,
            percentageChange: 31.8,
          ),
          categories: const <MonthlyReportsCategoryRow>[
            MonthlyReportsCategoryRow(
              categoryName: 'Rent',
              amountMinor: 85000,
              sharePercent: 73.9,
              shareFraction: 0.739,
              icon: Icons.home_rounded,
            ),
            MonthlyReportsCategoryRow(
              categoryName: 'Fuel',
              amountMinor: 30000,
              sharePercent: 26.1,
              shareFraction: 0.261,
              icon: Icons.local_gas_station_rounded,
            ),
          ],
          trendSeries: <MonthlyReportsTrendPoint>[
            MonthlyReportsTrendPoint(
              monthStart: DateTime(2026, 1, 1),
              monthLabel: 'Oca',
              incomeMinor: 180000,
              expenseMinor: 120000,
              netMinor: 60000,
              incomeFraction: 0.7,
              expenseFraction: 0.6,
              isCurrentMonth: false,
            ),
            MonthlyReportsTrendPoint(
              monthStart: DateTime(2026, 2, 1),
              monthLabel: 'Sub',
              incomeMinor: 210000,
              expenseMinor: 125000,
              netMinor: 85000,
              incomeFraction: 0.8,
              expenseFraction: 0.63,
              isCurrentMonth: false,
            ),
            MonthlyReportsTrendPoint(
              monthStart: DateTime(2026, 3, 1),
              monthLabel: 'Mar',
              incomeMinor: 220000,
              expenseMinor: 110000,
              netMinor: 110000,
              incomeFraction: 0.85,
              expenseFraction: 0.55,
              isCurrentMonth: false,
            ),
            MonthlyReportsTrendPoint(
              monthStart: DateTime(2026, 4, 1),
              monthLabel: 'Nis',
              incomeMinor: 260000,
              expenseMinor: 115000,
              netMinor: 145000,
              incomeFraction: 1,
              expenseFraction: 0.57,
              isCurrentMonth: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Monthly profit & loss'), findsOneWidget);
    expect(find.text('£2,600.00'), findsOneWidget);
    expect(find.text('£1,150.00'), findsOneWidget);
    expect(find.text('£1,450.00'), findsOneWidget);
    expect(find.text('VS LAST MONTH'), findsOneWidget);
    expect(find.text('TOP INSIGHTS'), findsOneWidget);
    expect(find.text('CATEGORY · EXPENSES'), findsOneWidget);
    expect(find.text('MONTHLY TREND'), findsOneWidget);
    expect(find.text('DAILY SUMMARY'), findsOneWidget);
    expect(find.text('Rent'), findsAtLeastNWidgets(1));
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Profit margin'), findsOneWidget);
    expect(find.text('Expense ratio'), findsOneWidget);
  });

  testWidgets('supports switching the selected month from the header pill', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildValueApp(
        aprilReport: buildReport(
          selectedMonth: DateTime(2026, 4, 1),
          incomeMinor: 260000,
          expenseMinor: 115000,
          netMinor: 145000,
        ),
        marchReport: buildReport(
          selectedMonth: DateTime(2026, 3, 1),
          incomeMinor: 200000,
          expenseMinor: 90000,
          netMinor: 110000,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nisan'), findsWidgets);
    expect(find.text('£2,600.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reports-month-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reports-month-March')));
    await tester.pumpAndSettle();

    expect(find.text('Mart'), findsWidgets);
    expect(find.text('£2,000.00'), findsOneWidget);
    expect(find.text('£900.00'), findsOneWidget);
    expect(find.text('£1,100.00'), findsOneWidget);
  });

  testWidgets('month picker opens as bounded modal sheet and hides shell fab', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildShellApp(
        aprilReport: buildReport(selectedMonth: DateTime(2026, 4, 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HiFiFab), findsOneWidget);

    await tester.tap(find.byKey(const Key('reports-month-selector')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    expect(find.byType(HiFiFab), findsNothing);
    expect(find.byKey(const Key('app-sheet-handle')), findsOneWidget);
    expect(find.byKey(const Key('reports-month-sheet')), findsOneWidget);
    expect(find.byKey(const Key('reports-month-grid')), findsOneWidget);

    final double sheetHeight = tester
        .getSize(find.byKey(const Key('reports-month-sheet')))
        .height;
    expect(sheetHeight, lessThan(932 * 0.8));
    expect(sheetHeight, greaterThan(200));
  });

  testWidgets('shows safe empty states across report sections', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildValueApp(
        aprilReport: buildReport(
          selectedMonth: DateTime(2026, 4, 1),
          incomeMinor: 0,
          expenseMinor: 0,
          netMinor: 0,
          health: const MonthlyReportsHealth(
            profitMarginPercent: null,
            expenseRatioPercent: null,
            label: 'No activity',
            description: 'Start recording the month to assess business health.',
            state: MonthlyReportsHealthState.empty,
          ),
          insights: const <MonthlyReportsInsightItem>[
            MonthlyReportsInsightItem(
              title: 'Top expense',
              primary: 'No expense yet',
              secondary: 'No categories this month',
              tone: MonthlyReportsInsightTone.expense,
              isEmpty: true,
            ),
            MonthlyReportsInsightItem(
              title: 'Highest expense day',
              primary: 'No spend yet',
              secondary: 'No expense days this month',
              tone: MonthlyReportsInsightTone.expense,
              isEmpty: true,
            ),
            MonthlyReportsInsightItem(
              title: 'Net day range',
              primary: 'No net day yet',
              secondary: 'Active days appear once entries are added',
              tone: MonthlyReportsInsightTone.brand,
              isEmpty: true,
            ),
          ],
          trendSeries: <MonthlyReportsTrendPoint>[
            MonthlyReportsTrendPoint(
              monthStart: DateTime(2026, 4, 1),
              monthLabel: 'Nis',
              incomeMinor: 0,
              expenseMinor: 0,
              netMinor: 0,
              incomeFraction: 0,
              expenseFraction: 0,
              isCurrentMonth: true,
            ),
          ],
          dailySummary: const MonthlyReportsDailySummary(
            bestDay: MonthlyReportsDayMetric(
              date: null,
              netMinor: 0,
              isEmpty: true,
            ),
            worstDay: MonthlyReportsDayMetric(
              date: null,
              netMinor: 0,
              isEmpty: true,
            ),
            averageDailyNetMinor: 0,
            calendarDayCount: 30,
            usesCalendarDays: true,
          ),
          hasCategoryData: false,
          hasTrendData: false,
          isEmpty: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('£0.00'), findsAtLeastNWidgets(3));
    expect(find.text('No expense categories yet this month'), findsOneWidget);
    expect(find.text('No monthly trend yet'), findsOneWidget);
    expect(find.text('No active day'), findsNWidgets(2));
    expect(find.text('No activity'), findsOneWidget);
  });

  testWidgets('shows error state when provider throws', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildErrorApp());
    await tester.pumpAndSettle();

    expect(find.text("Couldn’t load reports"), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
  });
}
