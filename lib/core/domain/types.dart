final class DomainValidationException implements Exception {
  const DomainValidationException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'DomainValidationException($code): $message';
}

enum AppCurrency { gbp }

extension AppCurrencyX on AppCurrency {
  String get code => switch (this) {
    AppCurrency.gbp => 'GBP',
  };

  String get symbol => switch (this) {
    AppCurrency.gbp => '£',
  };

  static AppCurrency fromCode(String rawValue) {
    final String value = rawValue.trim().toUpperCase();
    return switch (value) {
      'GBP' => AppCurrency.gbp,
      _ => throw DomainValidationException(
          code: 'currency.unsupported',
          message: 'MVP only supports GBP, got "$rawValue".',
        ),
    };
  }
}

enum CategoryType { income, expense }

extension CategoryTypeX on CategoryType {
  String get dbValue => name;

  static CategoryType fromDbValue(String rawValue) {
    final String value = rawValue.trim().toLowerCase();
    return switch (value) {
      'income' => CategoryType.income,
      'expense' => CategoryType.expense,
      _ => throw DomainValidationException(
          code: 'category_type.invalid',
          message: 'Category type must be income or expense, got "$rawValue".',
        ),
    };
  }
}

enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get dbValue => name;

  static TransactionType fromDbValue(String rawValue) {
    final String value = rawValue.trim().toLowerCase();
    return switch (value) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      _ => throw DomainValidationException(
          code: 'transaction_type.invalid',
          message:
              'Transaction type must be income or expense, got "$rawValue".',
        ),
    };
  }
}

enum PaymentMethodType { cash, card, bankTransfer, other }

extension PaymentMethodTypeX on PaymentMethodType {
  String get dbValue => switch (this) {
    PaymentMethodType.cash => 'cash',
    PaymentMethodType.card => 'card',
    PaymentMethodType.bankTransfer => 'bank_transfer',
    PaymentMethodType.other => 'other',
  };

  static PaymentMethodType fromDbValue(String rawValue) {
    final String value = rawValue.trim().toLowerCase();
    return switch (value) {
      'cash' => PaymentMethodType.cash,
      'card' => PaymentMethodType.card,
      'bank_transfer' => PaymentMethodType.bankTransfer,
      'other' => PaymentMethodType.other,
      _ => throw DomainValidationException(
          code: 'payment_method.invalid',
          message:
              'Payment method must be cash, card, bank_transfer or other, got "$rawValue".',
        ),
    };
  }
}

enum SourcePlatformType { direct, uber, justEat, other }

extension SourcePlatformTypeX on SourcePlatformType {
  String get dbValue => switch (this) {
    SourcePlatformType.direct => 'direct',
    SourcePlatformType.uber => 'uber',
    SourcePlatformType.justEat => 'just_eat',
    SourcePlatformType.other => 'other',
  };

  static SourcePlatformType fromDbValue(String rawValue) {
    final String value = rawValue.trim().toLowerCase();
    return switch (value) {
      'direct' => SourcePlatformType.direct,
      'uber' => SourcePlatformType.uber,
      'just_eat' => SourcePlatformType.justEat,
      'other' => SourcePlatformType.other,
      _ => throw DomainValidationException(
          code: 'source_platform.invalid',
          message:
              'Source platform must be direct, uber, just_eat or other, got "$rawValue".',
        ),
    };
  }
}

enum RecurringFrequencyType { weekly, monthly, quarterly, yearly }

extension RecurringFrequencyTypeX on RecurringFrequencyType {
  String get dbValue => name;

  static RecurringFrequencyType fromDbValue(String rawValue) {
    final String value = rawValue.trim().toLowerCase();
    return switch (value) {
      'weekly' => RecurringFrequencyType.weekly,
      'monthly' => RecurringFrequencyType.monthly,
      'quarterly' => RecurringFrequencyType.quarterly,
      'yearly' => RecurringFrequencyType.yearly,
      _ => throw DomainValidationException(
          code: 'recurring_frequency.invalid',
          message:
              'Recurring frequency must be weekly, monthly, quarterly or yearly, got "$rawValue".',
        ),
    };
  }
}

final class BusinessDate implements Comparable<BusinessDate> {
  BusinessDate._(this.value);

  final DateTime value;

  factory BusinessDate(DateTime input) {
    final DateTime normalized = DateTime(input.year, input.month, input.day);
    return BusinessDate._(normalized);
  }

  factory BusinessDate.fromIso(String isoDate) {
    final String value = isoDate.trim();
    if (value.isEmpty) {
      throw const DomainValidationException(
        code: 'date.required',
        message: 'Business date is required.',
      );
    }

    try {
      return BusinessDate(DateTime.parse(value));
    } on FormatException {
      throw DomainValidationException(
        code: 'date.invalid',
        message: 'Invalid business date "$isoDate".',
      );
    }
  }

  String get iso8601Date {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  @override
  int compareTo(BusinessDate other) => value.compareTo(other.value);
}

final class MinorAmount {
  const MinorAmount._(this.value);

  final int value;

  factory MinorAmount(int rawValue) {
    if (rawValue <= 0) {
      throw DomainValidationException(
        code: 'amount.non_positive',
        message: 'Amount must be greater than zero minor units, got $rawValue.',
      );
    }

    return MinorAmount._(rawValue);
  }
}

String requireTrimmedText(String rawValue, String fieldName) {
  final String value = rawValue.trim();
  if (value.isEmpty) {
    throw DomainValidationException(
      code: '$fieldName.required',
      message: '$fieldName cannot be empty.',
    );
  }
  return value;
}

String? normalizeOptionalText(String? rawValue, String fieldName) {
  if (rawValue == null) {
    return null;
  }

  final String value = rawValue.trim();
  if (value.isEmpty) {
    throw DomainValidationException(
      code: '$fieldName.blank',
      message: '$fieldName cannot be blank when provided.',
    );
  }

  return value;
}
