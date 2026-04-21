import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/features/reports/domain/monthly_reports_models.dart';
import 'package:gider/features/reports/domain/monthly_reports_service.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';

void main() {
  TransactionData transaction({
    required String id,
    required TransactionType type,
    required DateTime occurredOn,
    required int amountMinor,
    required String categoryName,
    SourcePlatformType? sourcePlatform,
  }) {
    return TransactionData(
      id: id,
      type: type,
      occurredOn: occurredOn,
      amountMinor: amountMinor,
      categoryId: 'cat-$id',
      categoryName: categoryName,
      paymentMethod: PaymentMethodType.card,
      createdAt: DateTime(2026, 4, 21),
      sourcePlatform: sourcePlatform,
    );
  }

  group('MonthlyReportsService', () {
    test(
      'buildViewModel computes monthly overview, comparison, trend, and daily summary',
      () {
        final MonthlyReportsService service = MonthlyReportsService();
        const AppLocalizations strings = AppLocalizations(AppLocale.tr);
        final MonthlyReportsViewModel report = service.buildViewModel(
          MonthlyReportsDataset(
            selectedMonth: DateTime(2026, 4, 1),
            trendMonthCount: 4,
            transactions: <TransactionData>[
              transaction(
                id: 'jan-income',
                type: TransactionType.income,
                occurredOn: DateTime(2026, 1, 4),
                amountMinor: 180000,
                categoryName: 'Card Sales',
              ),
              transaction(
                id: 'jan-expense',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 1, 9),
                amountMinor: 120000,
                categoryName: 'Rent',
              ),
              transaction(
                id: 'feb-income',
                type: TransactionType.income,
                occurredOn: DateTime(2026, 2, 3),
                amountMinor: 210000,
                categoryName: 'Card Sales',
              ),
              transaction(
                id: 'feb-expense',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 2, 11),
                amountMinor: 125000,
                categoryName: 'Rent',
              ),
              transaction(
                id: 'mar-income',
                type: TransactionType.income,
                occurredOn: DateTime(2026, 3, 4),
                amountMinor: 200000,
                categoryName: 'Card Sales',
              ),
              transaction(
                id: 'mar-expense',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 3, 7),
                amountMinor: 90000,
                categoryName: 'Rent',
              ),
              transaction(
                id: 'apr-income-1',
                type: TransactionType.income,
                occurredOn: DateTime(2026, 4, 3),
                amountMinor: 220000,
                categoryName: 'Card Sales',
              ),
              transaction(
                id: 'apr-income-2',
                type: TransactionType.income,
                occurredOn: DateTime(2026, 4, 18),
                amountMinor: 40000,
                categoryName: 'Uber Settlement',
                sourcePlatform: SourcePlatformType.uber,
              ),
              transaction(
                id: 'apr-expense-1',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 5),
                amountMinor: 85000,
                categoryName: 'Rent',
              ),
              transaction(
                id: 'apr-expense-2',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 10),
                amountMinor: 12000,
                categoryName: 'Fuel',
              ),
              transaction(
                id: 'apr-expense-3',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 16),
                amountMinor: 18000,
                categoryName: 'Fuel',
              ),
            ],
            expenseCategoryIcons: const <String, IconData>{
              'Rent': Icons.home_rounded,
              'Fuel': Icons.local_gas_station_rounded,
            },
            incomeCategoryIcons: const <String, IconData>{
              'Card Sales': Icons.payments_rounded,
              'Uber Settlement': Icons.local_taxi_rounded,
            },
          ),
          strings,
        );

        expect(report.monthLabel, 'Nisan');
        expect(report.yearLabel, '2026');
        expect(report.totalIncomeMinor, 260000);
        expect(report.totalExpensesMinor, 115000);
        expect(report.netProfitMinor, 145000);
        expect(report.isEmpty, isFalse);

        expect(report.previousMonthComparison, isNotNull);
        expect(report.previousMonthComparison!.previousNetMinor, 110000);
        expect(report.previousMonthComparison!.changeMinor, 35000);
        expect(
          report.previousMonthComparison!.percentageChange,
          closeTo(31.8, 0.1),
        );

        expect(report.health.state, MonthlyReportsHealthState.strong);
        expect(report.health.profitMarginPercent, closeTo(55.8, 0.1));
        expect(report.health.expenseRatioPercent, closeTo(44.2, 0.1));

        expect(
          report.categoryBreakdownRows.map(
            (MonthlyReportsCategoryRow row) => row.categoryName,
          ),
          <String>[
            strings.systemCategoryName('Rent'),
            strings.systemCategoryName('Fuel'),
          ],
        );
        expect(
          report.categoryBreakdownRows.map(
            (MonthlyReportsCategoryRow row) => row.amountMinor,
          ),
          <int>[85000, 30000],
        );
        expect(
          report.categoryBreakdownRows.first.sharePercent,
          closeTo(73.9, 0.1),
        );

        expect(report.insights[0].title, strings.topExpense);
        expect(
          report.insights[0].primary,
          strings.systemCategoryName('Rent'),
        );
        expect(report.insights[1].title, strings.topIncomeStream);
        expect(
          report.insights[1].primary,
          strings.systemCategoryName('Card Sales'),
        );
        expect(report.insights[2].title, strings.netDayRange);

        expect(report.trendSeries, hasLength(4));
        expect(
          report.trendSeries.map(
            (MonthlyReportsTrendPoint point) => point.monthLabel,
          ),
          <String>['Oca', 'Şub', 'Mar', 'Nis'],
        );
        expect(report.trendSeries.last.isCurrentMonth, isTrue);

        expect(report.dailySummary.bestDay.date, DateTime(2026, 4, 3));
        expect(report.dailySummary.bestDay.netMinor, 220000);
        expect(report.dailySummary.worstDay.date, DateTime(2026, 4, 5));
        expect(report.dailySummary.worstDay.netMinor, -85000);
        expect(report.dailySummary.averageDailyNetMinor, 4833);
        expect(report.dailySummary.calendarDayCount, 30);
      },
    );

    test(
      'buildViewModel handles expense-only month without divide-by-zero errors',
      () {
        final MonthlyReportsService service = MonthlyReportsService();
        const AppLocalizations strings = AppLocalizations(AppLocale.tr);
        final MonthlyReportsViewModel report = service.buildViewModel(
          MonthlyReportsDataset(
            selectedMonth: DateTime(2026, 4, 1),
            trendMonthCount: 4,
            transactions: <TransactionData>[
              transaction(
                id: 'expense-1',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 2),
                amountMinor: 45000,
                categoryName: 'Rent',
              ),
            ],
            expenseCategoryIcons: const <String, IconData>{
              'Rent': Icons.home_rounded,
            },
            incomeCategoryIcons: const <String, IconData>{},
          ),
          strings,
        );

        expect(report.totalIncomeMinor, 0);
        expect(report.totalExpensesMinor, 45000);
        expect(report.netProfitMinor, -45000);
        expect(report.health.state, MonthlyReportsHealthState.weak);
        expect(report.health.profitMarginPercent, isNull);
        expect(report.health.expenseRatioPercent, isNull);
        expect(report.previousMonthComparison, isNull);
        expect(report.insights[1].title, strings.highestExpenseDay);
        expect(report.insights[1].primary, '2 Nis');
        expect(report.dailySummary.bestDay.date, DateTime(2026, 4, 2));
        expect(report.dailySummary.worstDay.date, DateTime(2026, 4, 2));
      },
    );
  });
}
