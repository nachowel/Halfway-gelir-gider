import 'types.dart';

final class MonthlySummaryRange {
  const MonthlySummaryRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

final class MonthlySummaryTransaction {
  const MonthlySummaryTransaction({
    required this.type,
    required this.amountMinor,
    required this.categoryName,
  });

  final TransactionType type;
  final int amountMinor;
  final String categoryName;
}

final class MonthlyCategoryTotal {
  const MonthlyCategoryTotal({
    required this.categoryName,
    required this.amountMinor,
  });

  final String categoryName;
  final int amountMinor;
}

final class MonthlySummarySnapshot {
  const MonthlySummarySnapshot({
    required this.range,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.categoryTotals,
  });

  final MonthlySummaryRange range;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final List<MonthlyCategoryTotal> categoryTotals;

  int get netMinor => totalIncomeMinor - totalExpenseMinor;
}

MonthlySummaryRange monthlySummaryRangeFor(DateTime month) {
  final DateTime normalized = DateTime(month.year, month.month, 1);
  return MonthlySummaryRange(
    start: normalized,
    end: DateTime(normalized.year, normalized.month + 1, 0),
  );
}

MonthlySummarySnapshot buildMonthlySummary({
  required DateTime month,
  required Iterable<MonthlySummaryTransaction> transactions,
}) {
  int totalIncomeMinor = 0;
  int totalExpenseMinor = 0;
  final Map<String, int> expenseByCategory = <String, int>{};

  for (final MonthlySummaryTransaction transaction in transactions) {
    if (transaction.type == TransactionType.income) {
      totalIncomeMinor += transaction.amountMinor;
      continue;
    }

    totalExpenseMinor += transaction.amountMinor;
    expenseByCategory[transaction.categoryName] =
        (expenseByCategory[transaction.categoryName] ?? 0) +
        transaction.amountMinor;
  }

  final List<MonthlyCategoryTotal> categoryTotals =
      expenseByCategory.entries
          .map(
            (MapEntry<String, int> entry) => MonthlyCategoryTotal(
              categoryName: entry.key,
              amountMinor: entry.value,
            ),
          )
          .toList()
        ..sort(
          (MonthlyCategoryTotal a, MonthlyCategoryTotal b) =>
              b.amountMinor.compareTo(a.amountMinor),
        );

  return MonthlySummarySnapshot(
    range: monthlySummaryRangeFor(month),
    totalIncomeMinor: totalIncomeMinor,
    totalExpenseMinor: totalExpenseMinor,
    categoryTotals: categoryTotals,
  );
}
