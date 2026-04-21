import 'types.dart';

final class WeeklySummaryRange {
  const WeeklySummaryRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  WeeklySummaryRange get previous => WeeklySummaryRange(
    start: start.subtract(const Duration(days: 7)),
    end: end.subtract(const Duration(days: 7)),
  );
}

final class WeeklySummaryTransaction {
  const WeeklySummaryTransaction({
    required this.type,
    required this.paymentMethod,
    required this.amountMinor,
  });

  final TransactionType type;
  final PaymentMethodType paymentMethod;
  final int amountMinor;
}

final class WeeklySummarySnapshot {
  const WeeklySummarySnapshot({
    required this.range,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.cashIncomeMinor,
    required this.cardIncomeMinor,
    required this.previousWeekNetMinor,
  });

  final WeeklySummaryRange range;
  final int incomeMinor;
  final int expenseMinor;
  final int cashIncomeMinor;
  final int cardIncomeMinor;
  final int previousWeekNetMinor;

  int get netMinor => incomeMinor - expenseMinor;

  int get netDeltaMinor => netMinor - previousWeekNetMinor;

  int get cashCardIncomeMinor => cashIncomeMinor + cardIncomeMinor;

  double get cashCardSplitProgress {
    if (cashCardIncomeMinor == 0) return 0;
    return cashIncomeMinor / cashCardIncomeMinor;
  }
}

WeeklySummaryRange weeklySummaryRangeFor(DateTime date) {
  final DateTime normalized = DateTime(date.year, date.month, date.day);
  final DateTime start = normalized.subtract(
    Duration(days: normalized.weekday - 1),
  );
  final DateTime end = start.add(const Duration(days: 6));
  return WeeklySummaryRange(start: start, end: end);
}

WeeklySummarySnapshot buildWeeklySummary({
  required DateTime today,
  required Iterable<WeeklySummaryTransaction> currentWeekTransactions,
  required Iterable<WeeklySummaryTransaction> previousWeekTransactions,
}) {
  int incomeMinor = 0;
  int expenseMinor = 0;
  int cashIncomeMinor = 0;
  int cardIncomeMinor = 0;

  for (final WeeklySummaryTransaction transaction in currentWeekTransactions) {
    if (transaction.type == TransactionType.income) {
      incomeMinor += transaction.amountMinor;
      if (transaction.paymentMethod == PaymentMethodType.cash) {
        cashIncomeMinor += transaction.amountMinor;
      }
      if (transaction.paymentMethod == PaymentMethodType.card) {
        cardIncomeMinor += transaction.amountMinor;
      }
    } else {
      expenseMinor += transaction.amountMinor;
    }
  }

  int previousWeekNetMinor = 0;
  for (final WeeklySummaryTransaction transaction in previousWeekTransactions) {
    previousWeekNetMinor += transaction.type == TransactionType.income
        ? transaction.amountMinor
        : -transaction.amountMinor;
  }

  return WeeklySummarySnapshot(
    range: weeklySummaryRangeFor(today),
    incomeMinor: incomeMinor,
    expenseMinor: expenseMinor,
    cashIncomeMinor: cashIncomeMinor,
    cardIncomeMinor: cardIncomeMinor,
    previousWeekNetMinor: previousWeekNetMinor,
  );
}
