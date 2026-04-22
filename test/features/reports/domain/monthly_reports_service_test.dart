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
    String? supplierId,
    String? supplierName,
    String? vendor,
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
      supplierId: supplierId,
      supplierName: supplierName,
      vendor: vendor,
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
        expect(report.hasSupplierData, isTrue);
        expect(report.supplierBreakdownRows, hasLength(1));
        expect(report.supplierBreakdownRows.first.supplierLabel, strings.unassigned);
        expect(report.supplierBreakdownRows.first.amountMinor, 115000);
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
        expect(report.hasSupplierData, isTrue);
        expect(report.supplierBreakdownRows, hasLength(1));
        expect(report.supplierBreakdownRows.first.supplierLabel, strings.unassigned);
        expect(report.supplierBreakdownRows.first.amountMinor, 45000);
      },
    );

    test(
      'expenses with supplierId go into supplier bucket using supplier name',
      () {
        final MonthlyReportsService service = MonthlyReportsService();
        const AppLocalizations strings = AppLocalizations(AppLocale.tr);
        final MonthlyReportsViewModel report = service.buildViewModel(
          MonthlyReportsDataset(
            selectedMonth: DateTime(2026, 4, 1),
            trendMonthCount: 1,
            transactions: <TransactionData>[
              transaction(
                id: 'exp-1',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 5),
                amountMinor: 50000,
                categoryName: 'Stock Purchase',
                supplierId: 'sup-1',
                supplierName: 'Best Vendor Ltd',
              ),
              transaction(
                id: 'exp-2',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 10),
                amountMinor: 30000,
                categoryName: 'Stock Purchase',
                supplierId: 'sup-1',
                supplierName: 'Best Vendor Ltd',
              ),
            ],
            expenseCategoryIcons: const <String, IconData>{},
            incomeCategoryIcons: const <String, IconData>{},
          ),
          strings,
        );

        expect(report.hasSupplierData, isTrue);
        expect(report.supplierBreakdownRows, hasLength(1));
        expect(
          report.supplierBreakdownRows.first.supplierLabel,
          'Best Vendor Ltd',
        );
        expect(report.supplierBreakdownRows.first.amountMinor, 80000);
      },
    );

    test(
      'expenses without supplierId but with vendor go into normalized vendor bucket',
      () {
        final MonthlyReportsService service = MonthlyReportsService();
        const AppLocalizations strings = AppLocalizations(AppLocale.tr);
        final MonthlyReportsViewModel report = service.buildViewModel(
          MonthlyReportsDataset(
            selectedMonth: DateTime(2026, 4, 1),
            trendMonthCount: 1,
            transactions: <TransactionData>[
              transaction(
                id: 'exp-1',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 5),
                amountMinor: 20000,
                categoryName: 'Fuel',
                vendor: 'Shell Station',
              ),
              transaction(
                id: 'exp-2',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 12),
                amountMinor: 15000,
                categoryName: 'Fuel',
                vendor: 'shell station',
              ),
            ],
            expenseCategoryIcons: const <String, IconData>{},
            incomeCategoryIcons: const <String, IconData>{},
          ),
          strings,
        );

        expect(report.hasSupplierData, isTrue);
        expect(report.supplierBreakdownRows, hasLength(1));
        expect(
          report.supplierBreakdownRows.first.supplierLabel,
          'Shell Station',
        );
        expect(report.supplierBreakdownRows.first.amountMinor, 35000);
      },
    );

    test(
      'expenses with broken supplier join go into Former supplier bucket',
      () {
        final MonthlyReportsService service = MonthlyReportsService();
        const AppLocalizations strings = AppLocalizations(AppLocale.tr);
        final MonthlyReportsViewModel report = service.buildViewModel(
          MonthlyReportsDataset(
            selectedMonth: DateTime(2026, 4, 1),
            trendMonthCount: 1,
            transactions: <TransactionData>[
              transaction(
                id: 'exp-1',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 5),
                amountMinor: 40000,
                categoryName: 'Supplies',
                supplierId: 'sup-deleted',
                supplierName: null,
              ),
            ],
            expenseCategoryIcons: const <String, IconData>{},
            incomeCategoryIcons: const <String, IconData>{},
          ),
          strings,
        );

        expect(report.hasSupplierData, isTrue);
        expect(report.supplierBreakdownRows, hasLength(1));
        expect(
          report.supplierBreakdownRows.first.supplierLabel,
          strings.formerSupplier,
        );
        expect(report.supplierBreakdownRows.first.amountMinor, 40000);
      },
    );

    test(
      'expenses without supplierId and vendor go into Unassigned bucket',
      () {
        final MonthlyReportsService service = MonthlyReportsService();
        const AppLocalizations strings = AppLocalizations(AppLocale.tr);
        final MonthlyReportsViewModel report = service.buildViewModel(
          MonthlyReportsDataset(
            selectedMonth: DateTime(2026, 4, 1),
            trendMonthCount: 1,
            transactions: <TransactionData>[
              transaction(
                id: 'exp-1',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 5),
                amountMinor: 25000,
                categoryName: 'Rent',
              ),
            ],
            expenseCategoryIcons: const <String, IconData>{},
            incomeCategoryIcons: const <String, IconData>{},
          ),
          strings,
        );

        expect(report.hasSupplierData, isTrue);
        expect(report.supplierBreakdownRows, hasLength(1));
        expect(
          report.supplierBreakdownRows.first.supplierLabel,
          strings.unassigned,
        );
        expect(report.supplierBreakdownRows.first.amountMinor, 25000);
      },
    );

    test('archived supplier still appears in report with its name', () {
      final MonthlyReportsService service = MonthlyReportsService();
      const AppLocalizations strings = AppLocalizations(AppLocale.tr);
      final MonthlyReportsViewModel report = service.buildViewModel(
        MonthlyReportsDataset(
          selectedMonth: DateTime(2026, 4, 1),
          trendMonthCount: 1,
          transactions: <TransactionData>[
            transaction(
              id: 'exp-1',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 5),
              amountMinor: 60000,
              categoryName: 'Stock Purchase',
              supplierId: 'sup-archived',
              supplierName: 'Old Supplier Inc',
            ),
          ],
          expenseCategoryIcons: const <String, IconData>{},
          incomeCategoryIcons: const <String, IconData>{},
        ),
        strings,
      );

      expect(report.hasSupplierData, isTrue);
      expect(report.supplierBreakdownRows.first.supplierLabel, 'Old Supplier Inc');
    });

    test('supplier breakdown is sorted by expense total descending', () {
      final MonthlyReportsService service = MonthlyReportsService();
      const AppLocalizations strings = AppLocalizations(AppLocale.tr);
      final MonthlyReportsViewModel report = service.buildViewModel(
        MonthlyReportsDataset(
          selectedMonth: DateTime(2026, 4, 1),
          trendMonthCount: 1,
          transactions: <TransactionData>[
            transaction(
              id: 'exp-1',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 5),
              amountMinor: 10000,
              categoryName: 'Fuel',
              vendor: 'Vendor B',
            ),
            transaction(
              id: 'exp-2',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 10),
              amountMinor: 50000,
              categoryName: 'Fuel',
              vendor: 'Vendor A',
            ),
          ],
          expenseCategoryIcons: const <String, IconData>{},
          incomeCategoryIcons: const <String, IconData>{},
        ),
        strings,
      );

      expect(report.supplierBreakdownRows, hasLength(2));
      expect(report.supplierBreakdownRows[0].amountMinor, 50000);
      expect(report.supplierBreakdownRows[1].amountMinor, 10000);
    });

    test('category sheet top 5 supplier list is correct', () {
      final MonthlyReportsService service = MonthlyReportsService();
      const AppLocalizations strings = AppLocalizations(AppLocale.tr);
      final MonthlyReportsDataset dataset = MonthlyReportsDataset(
        selectedMonth: DateTime(2026, 4, 1),
        trendMonthCount: 1,
        transactions: <TransactionData>[
          transaction(
            id: 'exp-1',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 1),
            amountMinor: 10000,
            categoryName: 'Supplies',
            vendor: 'Vendor A',
          ),
          transaction(
            id: 'exp-2',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 2),
            amountMinor: 20000,
            categoryName: 'Supplies',
            vendor: 'Vendor B',
          ),
          transaction(
            id: 'exp-3',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 3),
            amountMinor: 30000,
            categoryName: 'Supplies',
            vendor: 'Vendor C',
          ),
          transaction(
            id: 'exp-4',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 4),
            amountMinor: 40000,
            categoryName: 'Supplies',
            vendor: 'Vendor D',
          ),
          transaction(
            id: 'exp-5',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 5),
            amountMinor: 50000,
            categoryName: 'Supplies',
            vendor: 'Vendor E',
          ),
          transaction(
            id: 'exp-6',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 6),
            amountMinor: 60000,
            categoryName: 'Supplies',
            vendor: 'Vendor F',
          ),
        ],
        expenseCategoryIcons: const <String, IconData>{},
        incomeCategoryIcons: const <String, IconData>{},
      );

      final List<MonthlyReportsCategorySupplierRow> rows =
          service.buildCategorySupplierRows(
            dataset,
            strings.systemCategoryName('Supplies'),
            DateTime(2026, 4, 1),
            strings,
          );

      expect(rows, hasLength(6));
      expect(rows.first.supplierLabel, 'Vendor F');
      expect(rows.first.amountMinor, 60000);
      expect(rows[4].supplierLabel, 'Vendor B');
      expect(rows[4].amountMinor, 20000);
    });

    test('supplier modal last 6 month totals are correct', () {
      final MonthlyReportsService service = MonthlyReportsService();
      const AppLocalizations strings = AppLocalizations(AppLocale.tr);
      final MonthlyReportsDataset dataset = MonthlyReportsDataset(
        selectedMonth: DateTime(2026, 4, 1),
        trendMonthCount: 6,
        transactions: <TransactionData>[
          transaction(
            id: 'nov',
            type: TransactionType.expense,
            occurredOn: DateTime(2025, 11, 10),
            amountMinor: 10000,
            categoryName: 'Rent',
            supplierId: 'sup-1',
            supplierName: 'Landlord',
          ),
          transaction(
            id: 'dec',
            type: TransactionType.expense,
            occurredOn: DateTime(2025, 12, 10),
            amountMinor: 20000,
            categoryName: 'Rent',
            supplierId: 'sup-1',
            supplierName: 'Landlord',
          ),
          transaction(
            id: 'jan',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 1, 10),
            amountMinor: 30000,
            categoryName: 'Rent',
            supplierId: 'sup-1',
            supplierName: 'Landlord',
          ),
          transaction(
            id: 'feb',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 2, 10),
            amountMinor: 40000,
            categoryName: 'Rent',
            supplierId: 'sup-1',
            supplierName: 'Landlord',
          ),
          transaction(
            id: 'mar',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 3, 10),
            amountMinor: 50000,
            categoryName: 'Rent',
            supplierId: 'sup-1',
            supplierName: 'Landlord',
          ),
          transaction(
            id: 'apr',
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 10),
            amountMinor: 60000,
            categoryName: 'Rent',
            supplierId: 'sup-1',
            supplierName: 'Landlord',
          ),
        ],
        expenseCategoryIcons: const <String, IconData>{},
        incomeCategoryIcons: const <String, IconData>{},
      );

      final List<SupplierMonthSpendRow> rows =
          service.buildSupplierTrendRows(
            dataset,
            'supplier:sup-1',
            DateTime(2026, 4, 1),
            strings,
          );

      expect(rows, hasLength(6));
      expect(rows[0].totalMinor, 10000);
      expect(rows[1].totalMinor, 20000);
      expect(rows[2].totalMinor, 30000);
      expect(rows[3].totalMinor, 40000);
      expect(rows[4].totalMinor, 50000);
      expect(rows[5].totalMinor, 60000);
    });

    test('income transactions do not affect supplier breakdown', () {
      final MonthlyReportsService service = MonthlyReportsService();
      const AppLocalizations strings = AppLocalizations(AppLocale.tr);
      final MonthlyReportsViewModel report = service.buildViewModel(
        MonthlyReportsDataset(
          selectedMonth: DateTime(2026, 4, 1),
          trendMonthCount: 1,
          transactions: <TransactionData>[
            transaction(
              id: 'inc-1',
              type: TransactionType.income,
              occurredOn: DateTime(2026, 4, 5),
              amountMinor: 100000,
              categoryName: 'Card Sales',
              supplierId: 'sup-1',
              supplierName: 'Some Supplier',
            ),
          ],
          expenseCategoryIcons: const <String, IconData>{},
          incomeCategoryIcons: const <String, IconData>{},
        ),
        strings,
      );

      expect(report.hasSupplierData, isFalse);
      expect(report.supplierBreakdownRows, isEmpty);
    });

    test(
      'broken supplier join with vendor present shows vendor instead of Former supplier',
      () {
        final MonthlyReportsService service = MonthlyReportsService();
        const AppLocalizations strings = AppLocalizations(AppLocale.tr);
        final MonthlyReportsViewModel report = service.buildViewModel(
          MonthlyReportsDataset(
            selectedMonth: DateTime(2026, 4, 1),
            trendMonthCount: 1,
            transactions: <TransactionData>[
              transaction(
                id: 'exp-1',
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 5),
                amountMinor: 40000,
                categoryName: 'Supplies',
                supplierId: 'sup-deleted',
                supplierName: null,
                vendor: 'Fallback Vendor',
              ),
            ],
            expenseCategoryIcons: const <String, IconData>{},
            incomeCategoryIcons: const <String, IconData>{},
          ),
          strings,
        );

        expect(report.hasSupplierData, isTrue);
        expect(report.supplierBreakdownRows, hasLength(1));
        expect(
          report.supplierBreakdownRows.first.supplierLabel,
          'Fallback Vendor',
        );
      },
    );

    test('unassigned is sorted to the bottom of supplier breakdown', () {
      final MonthlyReportsService service = MonthlyReportsService();
      const AppLocalizations strings = AppLocalizations(AppLocale.tr);
      final MonthlyReportsViewModel report = service.buildViewModel(
        MonthlyReportsDataset(
          selectedMonth: DateTime(2026, 4, 1),
          trendMonthCount: 1,
          transactions: <TransactionData>[
            transaction(
              id: 'exp-1',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 5),
              amountMinor: 10000,
              categoryName: 'Fuel',
              vendor: 'Vendor A',
            ),
            transaction(
              id: 'exp-2',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 10),
              amountMinor: 5000,
              categoryName: 'Fuel',
            ),
          ],
          expenseCategoryIcons: const <String, IconData>{},
          incomeCategoryIcons: const <String, IconData>{},
        ),
        strings,
      );

      expect(report.supplierBreakdownRows, hasLength(2));
      expect(report.supplierBreakdownRows[0].supplierLabel, 'Vendor A');
      expect(
        report.supplierBreakdownRows[1].supplierLabel,
        strings.unassigned,
      );
    });

    test('unassigned is hidden when its share is below 3%', () {
      final MonthlyReportsService service = MonthlyReportsService();
      const AppLocalizations strings = AppLocalizations(AppLocale.tr);
      final MonthlyReportsViewModel report = service.buildViewModel(
        MonthlyReportsDataset(
          selectedMonth: DateTime(2026, 4, 1),
          trendMonthCount: 1,
          transactions: <TransactionData>[
            transaction(
              id: 'exp-1',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 5),
              amountMinor: 100000,
              categoryName: 'Fuel',
              vendor: 'Vendor A',
            ),
            transaction(
              id: 'exp-2',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 10),
              amountMinor: 1000,
              categoryName: 'Fuel',
            ),
          ],
          expenseCategoryIcons: const <String, IconData>{},
          incomeCategoryIcons: const <String, IconData>{},
        ),
        strings,
      );

      expect(report.supplierBreakdownRows, hasLength(1));
      expect(report.supplierBreakdownRows.first.supplierLabel, 'Vendor A');
    });

    test('supplier row includes primary category context', () {
      final MonthlyReportsService service = MonthlyReportsService();
      const AppLocalizations strings = AppLocalizations(AppLocale.tr);
      final MonthlyReportsViewModel report = service.buildViewModel(
        MonthlyReportsDataset(
          selectedMonth: DateTime(2026, 4, 1),
          trendMonthCount: 1,
          transactions: <TransactionData>[
            transaction(
              id: 'exp-1',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 5),
              amountMinor: 40000,
              categoryName: 'Delivery/Transport',
              supplierId: 'sup-1',
              supplierName: 'Uber',
            ),
            transaction(
              id: 'exp-2',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 10),
              amountMinor: 10000,
              categoryName: 'Delivery/Transport',
              supplierId: 'sup-1',
              supplierName: 'Uber',
            ),
            transaction(
              id: 'exp-3',
              type: TransactionType.expense,
              occurredOn: DateTime(2026, 4, 12),
              amountMinor: 5000,
              categoryName: 'Fuel',
              supplierId: 'sup-1',
              supplierName: 'Uber',
            ),
          ],
          expenseCategoryIcons: const <String, IconData>{},
          incomeCategoryIcons: const <String, IconData>{},
        ),
        strings,
      );

      expect(report.hasSupplierData, isTrue);
      expect(report.supplierBreakdownRows, hasLength(1));
      expect(
        report.supplierBreakdownRows.first.categoryContext,
        strings.systemCategoryName('Delivery/Transport'),
      );
    });
  });
}
