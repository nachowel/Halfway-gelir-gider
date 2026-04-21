import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/monthly_summary.dart';
import 'package:gider/core/domain/types.dart';

void main() {
  group('monthlySummaryRangeFor', () {
    test('returns first and last day of month for a mid-month date', () {
      final MonthlySummaryRange range = monthlySummaryRangeFor(
        DateTime(2026, 4, 21),
      );

      expect(range.start, DateTime(2026, 4, 1));
      expect(range.end, DateTime(2026, 4, 30));
    });
  });

  group('buildMonthlySummary', () {
    test('computes totals and groups only expenses in descending order', () {
      final MonthlySummarySnapshot summary = buildMonthlySummary(
        month: DateTime(2026, 4, 21),
        transactions: const <MonthlySummaryTransaction>[
          MonthlySummaryTransaction(
            type: TransactionType.income,
            amountMinor: 220000,
            categoryName: 'Card Sales',
          ),
          MonthlySummaryTransaction(
            type: TransactionType.expense,
            amountMinor: 85000,
            categoryName: 'Rent',
          ),
          MonthlySummaryTransaction(
            type: TransactionType.expense,
            amountMinor: 12000,
            categoryName: 'Fuel',
          ),
          MonthlySummaryTransaction(
            type: TransactionType.expense,
            amountMinor: 18000,
            categoryName: 'Fuel',
          ),
          MonthlySummaryTransaction(
            type: TransactionType.income,
            amountMinor: 40000,
            categoryName: 'Uber Settlement',
          ),
        ],
      );

      expect(summary.totalIncomeMinor, 260000);
      expect(summary.totalExpenseMinor, 115000);
      expect(summary.netMinor, 145000);
      expect(
        summary.categoryTotals.map(
          (MonthlyCategoryTotal item) => item.categoryName,
        ),
        <String>['Rent', 'Fuel'],
      );
      expect(
        summary.categoryTotals.map(
          (MonthlyCategoryTotal item) => item.amountMinor,
        ),
        <int>[85000, 30000],
      );
    });

    test('returns empty category totals when month has no expenses', () {
      final MonthlySummarySnapshot summary = buildMonthlySummary(
        month: DateTime(2026, 4, 21),
        transactions: const <MonthlySummaryTransaction>[
          MonthlySummaryTransaction(
            type: TransactionType.income,
            amountMinor: 180000,
            categoryName: 'Cash Sales',
          ),
        ],
      );

      expect(summary.totalIncomeMinor, 180000);
      expect(summary.totalExpenseMinor, 0);
      expect(summary.categoryTotals, isEmpty);
    });
  });
}
