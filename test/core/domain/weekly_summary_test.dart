import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/types.dart';
import 'package:gider/core/domain/weekly_summary.dart';

void main() {
  group('weeklySummaryRangeFor', () {
    test('returns Monday-Sunday range for a midweek date', () {
      final WeeklySummaryRange range = weeklySummaryRangeFor(
        DateTime(2026, 4, 22),
      );

      expect(range.start, DateTime(2026, 4, 20));
      expect(range.end, DateTime(2026, 4, 26));
      expect(range.previous.start, DateTime(2026, 4, 13));
      expect(range.previous.end, DateTime(2026, 4, 19));
    });
  });

  group('buildWeeklySummary', () {
    test('includes bank transfer income in total but not cash/card split', () {
      final WeeklySummarySnapshot summary = buildWeeklySummary(
        today: DateTime(2026, 4, 22),
        currentWeekTransactions: const <WeeklySummaryTransaction>[
          WeeklySummaryTransaction(
            type: TransactionType.income,
            paymentMethod: PaymentMethodType.cash,
            amountMinor: 12000,
          ),
          WeeklySummaryTransaction(
            type: TransactionType.income,
            paymentMethod: PaymentMethodType.card,
            amountMinor: 18000,
          ),
          WeeklySummaryTransaction(
            type: TransactionType.income,
            paymentMethod: PaymentMethodType.bankTransfer,
            amountMinor: 10000,
          ),
          WeeklySummaryTransaction(
            type: TransactionType.expense,
            paymentMethod: PaymentMethodType.card,
            amountMinor: 9000,
          ),
        ],
        previousWeekTransactions: const <WeeklySummaryTransaction>[
          WeeklySummaryTransaction(
            type: TransactionType.income,
            paymentMethod: PaymentMethodType.cash,
            amountMinor: 30000,
          ),
          WeeklySummaryTransaction(
            type: TransactionType.expense,
            paymentMethod: PaymentMethodType.card,
            amountMinor: 5000,
          ),
        ],
      );

      expect(summary.incomeMinor, 40000);
      expect(summary.expenseMinor, 9000);
      expect(summary.netMinor, 31000);
      expect(summary.cashIncomeMinor, 12000);
      expect(summary.cardIncomeMinor, 18000);
      expect(summary.cashCardIncomeMinor, 30000);
      expect(summary.cashCardSplitProgress, closeTo(0.4, 0.0001));
      expect(summary.previousWeekNetMinor, 25000);
      expect(summary.netDeltaMinor, 6000);
    });

    test('returns zero split progress when there is no cash/card income', () {
      final WeeklySummarySnapshot summary = buildWeeklySummary(
        today: DateTime(2026, 4, 22),
        currentWeekTransactions: const <WeeklySummaryTransaction>[
          WeeklySummaryTransaction(
            type: TransactionType.income,
            paymentMethod: PaymentMethodType.bankTransfer,
            amountMinor: 22000,
          ),
        ],
        previousWeekTransactions: const <WeeklySummaryTransaction>[],
      );

      expect(summary.incomeMinor, 22000);
      expect(summary.cashIncomeMinor, 0);
      expect(summary.cardIncomeMinor, 0);
      expect(summary.cashCardIncomeMinor, 0);
      expect(summary.cashCardSplitProgress, 0);
    });
  });
}
