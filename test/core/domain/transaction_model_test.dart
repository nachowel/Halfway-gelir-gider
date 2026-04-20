import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/transaction_model.dart';
import 'package:gider/core/domain/types.dart';

void main() {
  group('TransactionModel.fromPayload', () {
    test('accepts a valid income payload', () {
      final TransactionModel model = TransactionModel.fromPayload(
        id: 'tx-1',
        type: 'income',
        occurredOn: DateTime(2026, 4, 20, 18, 45),
        amountMinor: 125000,
        currency: 'GBP',
        categoryId: 'cat-cash-sales',
        categoryType: 'income',
        paymentMethod: 'cash',
        sourcePlatform: 'direct',
        note: ' Lunch rush ',
      );

      expect(model.id, 'tx-1');
      expect(model.type, TransactionType.income);
      expect(model.occurredOn.iso8601Date, '2026-04-20');
      expect(model.amount.value, 125000);
      expect(model.currency, AppCurrency.gbp);
      expect(model.categoryId, 'cat-cash-sales');
      expect(model.categoryType, CategoryType.income);
      expect(model.paymentMethod, PaymentMethodType.cash);
      expect(model.sourcePlatform, SourcePlatformType.direct);
      expect(model.note, 'Lunch rush');
    });

    test('rejects non-positive amount', () {
      expect(
        () => TransactionModel.fromPayload(
          type: 'expense',
          occurredOn: DateTime(2026, 4, 20),
          amountMinor: 0,
          currency: 'GBP',
          categoryId: 'cat-rent',
          categoryType: 'expense',
          paymentMethod: 'card',
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'amount.non_positive',
          ),
        ),
      );
    });

    test('rejects category type mismatch', () {
      expect(
        () => TransactionModel.fromPayload(
          type: 'income',
          occurredOn: DateTime(2026, 4, 20),
          amountMinor: 1000,
          currency: 'GBP',
          categoryId: 'cat-rent',
          categoryType: 'expense',
          paymentMethod: 'bank_transfer',
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'transaction.category_type_mismatch',
          ),
        ),
      );
    });

    test('rejects unsupported currency payload', () {
      expect(
        () => TransactionModel.fromPayload(
          type: 'income',
          occurredOn: DateTime(2026, 4, 20),
          amountMinor: 1000,
          currency: 'USD',
          categoryId: 'cat-cash-sales',
          categoryType: 'income',
          paymentMethod: 'cash',
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'currency.unsupported',
          ),
        ),
      );
    });
  });
}
