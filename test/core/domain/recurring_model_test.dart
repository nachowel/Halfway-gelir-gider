import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/recurring_model.dart';
import 'package:gider/core/domain/types.dart';

void main() {
  group('RecurringModel.fromPayload', () {
    test('accepts a valid recurring expense payload', () {
      final RecurringModel model = RecurringModel.fromPayload(
        id: 'rec-rent',
        name: ' Rent ',
        categoryId: 'cat-rent',
        categoryType: 'expense',
        amountMinor: 340000,
        currency: 'GBP',
        frequency: 'monthly',
        nextDueOn: DateTime(2026, 5, 1, 11, 20),
        reminderDaysBefore: 5,
        defaultPaymentMethod: 'bank_transfer',
        reserveEnabled: true,
      );

      expect(model.id, 'rec-rent');
      expect(model.name, 'Rent');
      expect(model.categoryId, 'cat-rent');
      expect(model.categoryType, CategoryType.expense);
      expect(model.amount.value, 340000);
      expect(model.currency, AppCurrency.gbp);
      expect(model.frequency, RecurringFrequencyType.monthly);
      expect(model.nextDueOn.iso8601Date, '2026-05-01');
      expect(model.reminderDaysBefore, 5);
      expect(model.defaultPaymentMethod, PaymentMethodType.bankTransfer);
      expect(model.reserveEnabled, isTrue);
      expect(model.isActive, isTrue);
    });

    test('rejects non-expense category types', () {
      expect(
        () => RecurringModel.fromPayload(
          name: 'Card Sales',
          categoryId: 'cat-card-sales',
          categoryType: 'income',
          amountMinor: 1000,
          currency: 'GBP',
          frequency: 'monthly',
          nextDueOn: DateTime(2026, 5, 1),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'recurring.category_type.invalid',
          ),
        ),
      );
    });

    test('rejects negative reminder_days_before', () {
      expect(
        () => RecurringModel.fromPayload(
          name: 'Internet',
          categoryId: 'cat-internet',
          categoryType: 'expense',
          amountMinor: 4500,
          currency: 'GBP',
          frequency: 'monthly',
          nextDueOn: DateTime(2026, 5, 10),
          reminderDaysBefore: -1,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'recurring.reminder_days_before.invalid',
          ),
        ),
      );
    });

    test('rejects invalid frequency payload', () {
      expect(
        () => RecurringModel.fromPayload(
          name: 'Insurance',
          categoryId: 'cat-insurance',
          categoryType: 'expense',
          amountMinor: 12000,
          currency: 'GBP',
          frequency: 'biweekly',
          nextDueOn: DateTime(2026, 5, 10),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'recurring_frequency.invalid',
          ),
        ),
      );
    });
  });
}
