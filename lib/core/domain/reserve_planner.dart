import 'types.dart';

final class ReservePlannerRecurringExpense {
  const ReservePlannerRecurringExpense({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.frequency,
    required this.nextDueOn,
    required this.isActive,
    required this.reserveEnabled,
  });

  final String id;
  final String name;
  final int amountMinor;
  final RecurringFrequencyType frequency;
  final DateTime nextDueOn;
  final bool isActive;
  final bool reserveEnabled;
}

final class ReservePlannerSuggestionItem {
  const ReservePlannerSuggestionItem({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.frequency,
    required this.nextDueOn,
    required this.daysUntilDue,
    required this.weeksUntilDue,
    required this.suggestedWeeklyReserveMinor,
  });

  final String id;
  final String name;
  final int amountMinor;
  final RecurringFrequencyType frequency;
  final DateTime nextDueOn;
  final int daysUntilDue;
  final int weeksUntilDue;
  final int suggestedWeeklyReserveMinor;
}

final class ReservePlannerComputation {
  const ReservePlannerComputation({
    required this.totalSuggestedWeeklyReserveMinor,
    required this.items,
  });

  final int totalSuggestedWeeklyReserveMinor;
  final List<ReservePlannerSuggestionItem> items;
}

ReservePlannerComputation buildReservePlanner({
  required DateTime today,
  required Iterable<ReservePlannerRecurringExpense> recurringExpenses,
}) {
  final DateTime normalizedToday = DateTime(today.year, today.month, today.day);
  final List<ReservePlannerSuggestionItem> items =
      recurringExpenses
          .where(
            (ReservePlannerRecurringExpense item) =>
                item.isActive && item.reserveEnabled,
          )
          .map((ReservePlannerRecurringExpense item) {
            final DateTime nextDueOn = DateTime(
              item.nextDueOn.year,
              item.nextDueOn.month,
              item.nextDueOn.day,
            );
            final int daysUntilDue = _maxZero(
              nextDueOn.difference(normalizedToday).inDays,
            );
            final int weeksUntilDue = _maxOne(_ceilDiv(daysUntilDue, 7));
            final int suggestedWeeklyReserveMinor = _ceilDiv(
              item.amountMinor,
              weeksUntilDue,
            );
            return ReservePlannerSuggestionItem(
              id: item.id,
              name: item.name,
              amountMinor: item.amountMinor,
              frequency: item.frequency,
              nextDueOn: nextDueOn,
              daysUntilDue: daysUntilDue,
              weeksUntilDue: weeksUntilDue,
              suggestedWeeklyReserveMinor: suggestedWeeklyReserveMinor,
            );
          })
          .toList()
        ..sort((
          ReservePlannerSuggestionItem a,
          ReservePlannerSuggestionItem b,
        ) {
          final int dueDateComparison = a.nextDueOn.compareTo(b.nextDueOn);
          if (dueDateComparison != 0) return dueDateComparison;
          return b.amountMinor.compareTo(a.amountMinor);
        });

  final int totalSuggestedWeeklyReserveMinor = items.fold<int>(
    0,
    (int sum, ReservePlannerSuggestionItem item) =>
        sum + item.suggestedWeeklyReserveMinor,
  );

  return ReservePlannerComputation(
    totalSuggestedWeeklyReserveMinor: totalSuggestedWeeklyReserveMinor,
    items: items,
  );
}

int _ceilDiv(int numerator, int denominator) {
  if (denominator <= 0) {
    throw ArgumentError.value(denominator, 'denominator', 'Must be positive.');
  }
  return (numerator + denominator - 1) ~/ denominator;
}

int _maxZero(int value) => value < 0 ? 0 : value;

int _maxOne(int value) => value < 1 ? 1 : value;
