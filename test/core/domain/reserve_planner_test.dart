import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/reserve_planner.dart';
import 'package:gider/core/domain/types.dart';

void main() {
  group('buildReservePlanner', () {
    test('calculates weekly suggestions from due date distance', () {
      final ReservePlannerComputation result = buildReservePlanner(
        today: DateTime(2026, 4, 21),
        recurringExpenses: <ReservePlannerRecurringExpense>[
          ReservePlannerRecurringExpense(
            id: 'rent',
            name: 'Rent',
            amountMinor: 120000,
            frequency: RecurringFrequencyType.monthly,
            nextDueOn: DateTime(2026, 5, 12),
            isActive: true,
            reserveEnabled: true,
          ),
          ReservePlannerRecurringExpense(
            id: 'broadband',
            name: 'Broadband',
            amountMinor: 4500,
            frequency: RecurringFrequencyType.monthly,
            nextDueOn: DateTime(2026, 4, 26),
            isActive: true,
            reserveEnabled: true,
          ),
        ],
      );

      expect(result.items, hasLength(2));

      final ReservePlannerSuggestionItem broadband = result.items.first;
      expect(broadband.id, 'broadband');
      expect(broadband.daysUntilDue, 5);
      expect(broadband.weeksUntilDue, 1);
      expect(broadband.suggestedWeeklyReserveMinor, 4500);

      final ReservePlannerSuggestionItem rent = result.items.last;
      expect(rent.id, 'rent');
      expect(rent.daysUntilDue, 21);
      expect(rent.weeksUntilDue, 3);
      expect(rent.suggestedWeeklyReserveMinor, 40000);

      expect(result.totalSuggestedWeeklyReserveMinor, 44500);
    });

    test('excludes inactive or reserve-disabled recurring expenses', () {
      final ReservePlannerComputation result = buildReservePlanner(
        today: DateTime(2026, 4, 21),
        recurringExpenses: <ReservePlannerRecurringExpense>[
          ReservePlannerRecurringExpense(
            id: 'active',
            name: 'Active reserve',
            amountMinor: 10000,
            frequency: RecurringFrequencyType.monthly,
            nextDueOn: DateTime(2026, 4, 28),
            isActive: true,
            reserveEnabled: true,
          ),
          ReservePlannerRecurringExpense(
            id: 'disabled',
            name: 'Disabled reserve',
            amountMinor: 20000,
            frequency: RecurringFrequencyType.monthly,
            nextDueOn: DateTime(2026, 4, 28),
            isActive: true,
            reserveEnabled: false,
          ),
          ReservePlannerRecurringExpense(
            id: 'inactive',
            name: 'Inactive reserve',
            amountMinor: 30000,
            frequency: RecurringFrequencyType.monthly,
            nextDueOn: DateTime(2026, 4, 28),
            isActive: false,
            reserveEnabled: true,
          ),
        ],
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.id, 'active');
      expect(result.totalSuggestedWeeklyReserveMinor, 10000);
    });

    test('overdue items recommend the full amount this week', () {
      final ReservePlannerComputation result = buildReservePlanner(
        today: DateTime(2026, 4, 21),
        recurringExpenses: <ReservePlannerRecurringExpense>[
          ReservePlannerRecurringExpense(
            id: 'insurance',
            name: 'Insurance',
            amountMinor: 27500,
            frequency: RecurringFrequencyType.quarterly,
            nextDueOn: DateTime(2026, 4, 18),
            isActive: true,
            reserveEnabled: true,
          ),
        ],
      );

      expect(result.items.single.daysUntilDue, 0);
      expect(result.items.single.weeksUntilDue, 1);
      expect(result.items.single.suggestedWeeklyReserveMinor, 27500);
    });
  });
}
