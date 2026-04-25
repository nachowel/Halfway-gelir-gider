import '../../../core/domain/types.dart' as domain;

enum BalanceDirection { payable, receivable }

extension BalanceDirectionX on BalanceDirection {
  String get dbValue => name;

  static BalanceDirection fromDb(String value) =>
      switch (value.trim().toLowerCase()) {
        'payable' => BalanceDirection.payable,
        'receivable' => BalanceDirection.receivable,
        _ => throw domain.DomainValidationException(
          code: 'balance.direction_invalid',
          message: 'Balance direction must be payable or receivable.',
        ),
      };
}

enum BalanceAccountType { personal, bank, supplier, customer, other }

extension BalanceAccountTypeX on BalanceAccountType {
  String get dbValue => name;

  static BalanceAccountType fromDb(String value) =>
      switch (value.trim().toLowerCase()) {
        'personal' => BalanceAccountType.personal,
        'bank' => BalanceAccountType.bank,
        'supplier' => BalanceAccountType.supplier,
        'customer' => BalanceAccountType.customer,
        'other' => BalanceAccountType.other,
        _ => throw domain.DomainValidationException(
          code: 'balance.account_type_invalid',
          message: 'Balance account type is invalid.',
        ),
      };
}

enum BalanceAccountStatus { active, closed }

extension BalanceAccountStatusX on BalanceAccountStatus {
  String get dbValue => name;

  static BalanceAccountStatus fromDb(String value) =>
      switch (value.trim().toLowerCase()) {
        'active' => BalanceAccountStatus.active,
        'closed' => BalanceAccountStatus.closed,
        _ => throw domain.DomainValidationException(
          code: 'balance.status_invalid',
          message: 'Balance account status is invalid.',
        ),
      };
}

enum BalanceMovementType { increase, decrease, adjustment }

extension BalanceMovementTypeX on BalanceMovementType {
  String get dbValue => name;

  static BalanceMovementType fromDb(String value) =>
      switch (value.trim().toLowerCase()) {
        'increase' => BalanceMovementType.increase,
        'decrease' => BalanceMovementType.decrease,
        'adjustment' => BalanceMovementType.adjustment,
        _ => throw domain.DomainValidationException(
          code: 'balance.movement_type_invalid',
          message: 'Balance movement type is invalid.',
        ),
      };
}

enum BalancePaymentMethod { cash, card, bank, other }

extension BalancePaymentMethodX on BalancePaymentMethod {
  String get dbValue => name;

  static BalancePaymentMethod fromDb(String value) =>
      switch (value.trim().toLowerCase()) {
        'cash' => BalancePaymentMethod.cash,
        'card' => BalancePaymentMethod.card,
        'bank' => BalancePaymentMethod.bank,
        'other' => BalancePaymentMethod.other,
        _ => throw domain.DomainValidationException(
          code: 'balance.payment_method_invalid',
          message: 'Balance payment method is invalid.',
        ),
      };
}

class BalanceMovementData {
  const BalanceMovementData({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amountMinor,
    required this.occurredAt,
    required this.paymentMethod,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String accountId;
  final BalanceMovementType type;
  final int amountMinor;
  final DateTime occurredAt;
  final BalancePaymentMethod paymentMethod;
  final String? notes;
  final DateTime createdAt;
}

class BalanceAccountData {
  const BalanceAccountData({
    required this.id,
    required this.direction,
    required this.name,
    required this.counterpartyName,
    required this.type,
    required this.openedAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.movements,
    this.notes,
  });

  final String id;
  final BalanceDirection direction;
  final String name;
  final String counterpartyName;
  final BalanceAccountType type;
  final DateTime openedAt;
  final BalanceAccountStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BalanceMovementData> movements;

  int get totalIncreasedMinor => balanceTotalIncreased(movements);
  int get totalDecreasedMinor => balanceTotalDecreased(movements);
  int get remainingMinor => calculateBalanceRemaining(movements);
  bool get canClose => remainingMinor == 0;
}

class BalanceSummaryData {
  const BalanceSummaryData({
    required this.accounts,
    required this.iOweMinor,
    required this.owedToMeMinor,
  });

  final List<BalanceAccountData> accounts;
  final int iOweMinor;
  final int owedToMeMinor;

  int get netPositionMinor => owedToMeMinor - iOweMinor;

  List<BalanceAccountData> byDirection(BalanceDirection direction) {
    return accounts
        .where((BalanceAccountData account) => account.direction == direction)
        .toList();
  }
}

class BalanceAccountDraft {
  const BalanceAccountDraft({
    required this.direction,
    required this.name,
    required this.counterpartyName,
    required this.type,
    required this.openingAmountMinor,
    required this.openedAt,
    this.notes,
  });

  final BalanceDirection direction;
  final String name;
  final String counterpartyName;
  final BalanceAccountType type;
  final int openingAmountMinor;
  final DateTime openedAt;
  final String? notes;
}

class BalanceMovementDraft {
  const BalanceMovementDraft({
    required this.type,
    required this.amountMinor,
    required this.occurredAt,
    required this.paymentMethod,
    this.notes,
  });

  final BalanceMovementType type;
  final int amountMinor;
  final DateTime occurredAt;
  final BalancePaymentMethod paymentMethod;
  final String? notes;
}

class BalanceAccountEditDraft {
  const BalanceAccountEditDraft({
    required this.name,
    required this.counterpartyName,
    required this.type,
    required this.openedAt,
    this.notes,
  });

  final String name;
  final String counterpartyName;
  final BalanceAccountType type;
  final DateTime openedAt;
  final String? notes;
}

int calculateBalanceRemaining(Iterable<BalanceMovementData> movements) {
  return movements.fold<int>(0, (int total, BalanceMovementData movement) {
    return total + balanceMovementSignedAmount(movement);
  });
}

int balanceMovementSignedAmount(BalanceMovementData movement) {
  return switch (movement.type) {
    BalanceMovementType.increase => movement.amountMinor,
    BalanceMovementType.decrease => -movement.amountMinor,
    BalanceMovementType.adjustment => movement.amountMinor,
  };
}

int balanceTotalIncreased(Iterable<BalanceMovementData> movements) {
  return movements.fold<int>(0, (int total, BalanceMovementData movement) {
    if (movement.type == BalanceMovementType.decrease) {
      return total;
    }
    return total + movement.amountMinor;
  });
}

int balanceTotalDecreased(Iterable<BalanceMovementData> movements) {
  return movements.fold<int>(0, (int total, BalanceMovementData movement) {
    if (movement.type != BalanceMovementType.decrease) {
      return total;
    }
    return total + movement.amountMinor;
  });
}

int balanceCurrencyDecimalDigits(int amountMinor) {
  return amountMinor.abs() % 100 == 0 ? 0 : 2;
}

void validateBalanceAccountDraft(BalanceAccountDraft draft) {
  domain.requireTrimmedText(draft.name, 'balance_account_name');
  if (draft.openingAmountMinor < 0) {
    throw const domain.DomainValidationException(
      code: 'balance.opening_amount_negative',
      message: 'Opening amount cannot be negative.',
    );
  }
}

void validateBalanceAccountEditDraft(BalanceAccountEditDraft draft) {
  domain.requireTrimmedText(draft.name, 'balance_account_name');
}

void validateBalanceMovementDraft(BalanceMovementDraft draft) {
  domain.MinorAmount(draft.amountMinor);
}
