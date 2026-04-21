import 'package:flutter_test/flutter_test.dart';
import 'package:gider/features/expense_detail/domain/expense_detail_models.dart';
import 'package:gider/features/expense_detail/domain/expense_detail_service.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';

void main() {
  final ExpenseDetailService service = ExpenseDetailService();
  const AppLocalizations strings = AppLocalizations(AppLocale.en);

  group('ExpenseDetailService', () {
    test('this week resolves Monday to Sunday', () {
      final ExpenseDetailRange range = service.resolveRange(
        today: DateTime(2026, 4, 23),
        query: const ExpenseDetailQuery.thisWeek(),
        strings: strings,
      );

      expect(range.start, DateTime(2026, 4, 20));
      expect(range.end, DateTime(2026, 4, 26));
      expect(range.dayCount, 7);
    });

    test(
      'buildViewModel computes category totals, daily totals, and warning',
      () {
        final ExpenseDetailViewModel viewModel = service.buildViewModel(
          query: const ExpenseDetailQuery.thisWeek(),
          range: ExpenseDetailRange(
            start: DateTime(2026, 4, 20),
            end: DateTime(2026, 4, 26),
            label: 'Mon 20 Apr – Sun 26 Apr',
          ),
          transactions: <ExpenseDetailTransaction>[
            ExpenseDetailTransaction(
              occurredOn: DateTime(2026, 4, 20, 10),
              amountMinor: 6000,
              categoryName: 'Stock',
              paymentMethod: ExpenseDetailPaymentMethod.card,
            ),
            ExpenseDetailTransaction(
              occurredOn: DateTime(2026, 4, 20, 11),
              amountMinor: 3000,
              categoryName: 'Stock',
              paymentMethod: ExpenseDetailPaymentMethod.cash,
            ),
            ExpenseDetailTransaction(
              occurredOn: DateTime(2026, 4, 21, 10),
              amountMinor: 2000,
              categoryName: 'Utilities',
              paymentMethod: ExpenseDetailPaymentMethod.other,
            ),
            ExpenseDetailTransaction(
              occurredOn: DateTime(2026, 4, 23, 10),
              amountMinor: 1000,
              categoryName: 'Supplies',
              paymentMethod: ExpenseDetailPaymentMethod.cash,
            ),
          ],
          strings: strings,
        );

        expect(viewModel.totalExpensesMinor, 12000);
        expect(viewModel.cashExpensesMinor, 4000);
        expect(viewModel.cardExpensesMinor, 6000);
        expect(viewModel.topCategoryName, 'Stock');
        expect(viewModel.topCategoryMinor, 9000);
        expect(viewModel.largestDayDate, DateTime(2026, 4, 20));
        expect(viewModel.largestDayMinor, 9000);
        expect(viewModel.categoryBreakdownRows, hasLength(3));
        expect(viewModel.categoryBreakdownRows.first.categoryName, 'Stock');
        expect(viewModel.categoryBreakdownRows.first.sharePercent, 75);
        expect(viewModel.compositionItems, hasLength(2));
        expect(viewModel.compositionItems.first.label, 'Stock');
        expect(viewModel.compositionItems.first.percent, 75);
        expect(viewModel.chartSeries, hasLength(7));
        expect(viewModel.chartSeries[0].totalMinor, 9000);
        expect(viewModel.chartSeries[2].totalMinor, 0);
        expect(viewModel.dailyBreakdownRows[1].otherMinor, 2000);
        expect(viewModel.highestSpendDayInsight.primary, 'Mon');
        expect(viewModel.highestSpendDayInsight.secondary, '£90.00');
        expect(viewModel.averagePerDayInsight.primary, '£17.14');
        expect(viewModel.topCategoryInsight.primary, 'Stock');
        expect(
          viewModel.warningInsightMessage,
          'Most spending is concentrated in one category.',
        );
        expect(viewModel.isEmpty, isFalse);
        expect(viewModel.hasDisabledChartState, isFalse);
      },
    );

    test(
      'buildViewModel returns safe empty state when range has no expense',
      () {
        final ExpenseDetailViewModel viewModel = service.buildViewModel(
          query: const ExpenseDetailQuery.lastMonth(),
          range: ExpenseDetailRange(
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 31),
            label: 'Sun 1 Mar – Tue 31 Mar',
          ),
          transactions: <ExpenseDetailTransaction>[],
          strings: strings,
        );

        expect(viewModel.totalExpensesMinor, 0);
        expect(viewModel.cashExpensesMinor, 0);
        expect(viewModel.cardExpensesMinor, 0);
        expect(viewModel.topCategoryName, isNull);
        expect(viewModel.largestDayDate, isNull);
        expect(viewModel.chartSeries, hasLength(31));
        expect(viewModel.categoryBreakdownRows, isEmpty);
        expect(viewModel.dailyBreakdownRows, hasLength(31));
        expect(viewModel.warningInsightMessage, isNull);
        expect(viewModel.highestSpendDayInsight.isEmpty, isTrue);
        expect(viewModel.topCategoryInsight.isEmpty, isTrue);
        expect(viewModel.isEmpty, isTrue);
        expect(viewModel.hasDisabledChartState, isTrue);
      },
    );
  });
}
