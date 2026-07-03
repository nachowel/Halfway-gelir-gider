import 'package:flutter_test/flutter_test.dart';
import 'package:gider/features/balances/domain/balance_models.dart';

void main() {
  group('balance calculations', () {
    test('payable balance calculation uses increases minus decreases', () {
      final BalanceAccountData account = _account(
        direction: BalanceDirection.payable,
        movements: <BalanceMovementData>[
          _movement(type: BalanceMovementType.increase, amountMinor: 10000),
          _movement(type: BalanceMovementType.decrease, amountMinor: 3500),
        ],
      );

      expect(account.totalIncreasedMinor, 10000);
      expect(account.totalDecreasedMinor, 3500);
      expect(account.remainingMinor, 6500);
    });

    test('receivable balance calculation uses increases minus decreases', () {
      final BalanceAccountData account = _account(
        direction: BalanceDirection.receivable,
        movements: <BalanceMovementData>[
          _movement(type: BalanceMovementType.increase, amountMinor: 25000),
          _movement(type: BalanceMovementType.decrease, amountMinor: 11000),
        ],
      );

      expect(account.totalIncreasedMinor, 25000);
      expect(account.totalDecreasedMinor, 11000);
      expect(account.remainingMinor, 14000);
    });

    test('cannot close account if remaining balance is not zero', () {
      final BalanceAccountData account = _account(
        movements: <BalanceMovementData>[
          _movement(type: BalanceMovementType.increase, amountMinor: 5000),
          _movement(type: BalanceMovementType.decrease, amountMinor: 1000),
        ],
      );

      expect(account.canClose, isFalse);
    });

    test('can close account if remaining balance is zero', () {
      final BalanceAccountData account = _account(
        movements: <BalanceMovementData>[
          _movement(type: BalanceMovementType.increase, amountMinor: 5000),
          _movement(type: BalanceMovementType.decrease, amountMinor: 5000),
        ],
      );

      expect(account.canClose, isTrue);
    });

    test('currency decimal digits hide whole-pound decimals', () {
      expect(balanceCurrencyDecimalDigits(1800000), 0);
      expect(balanceCurrencyDecimalDigits(1000), 0);
      expect(balanceCurrencyDecimalDigits(-1800000), 0);
      expect(balanceCurrencyDecimalDigits(1050), 2);
      expect(balanceCurrencyDecimalDigits(-1050), 2);
    });
  });
}

BalanceAccountData _account({
  BalanceDirection direction = BalanceDirection.payable,
  required List<BalanceMovementData> movements,
}) {
  return BalanceAccountData(
    id: 'account-1',
    direction: direction,
    name: 'Loan',
    counterpartyName: 'Counterparty',
    type: BalanceAccountType.personal,
    openedAt: DateTime(2026, 4, 20),
    status: BalanceAccountStatus.active,
    createdAt: DateTime(2026, 4, 20),
    updatedAt: DateTime(2026, 4, 20),
    movements: movements,
  );
}

BalanceMovementData _movement({
  required BalanceMovementType type,
  required int amountMinor,
}) {
  return BalanceMovementData(
    id: 'movement-${type.name}-$amountMinor',
    accountId: 'account-1',
    type: type,
    amountMinor: amountMinor,
    occurredAt: DateTime(2026, 4, 20),
    paymentMethod: BalancePaymentMethod.cash,
    createdAt: DateTime(2026, 4, 20),
  );
}
