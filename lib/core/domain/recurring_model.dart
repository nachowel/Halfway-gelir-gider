import 'types.dart';

final class RecurringModel {
  RecurringModel._({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryType,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.nextDueOn,
    required this.reminderDaysBefore,
    required this.defaultPaymentMethod,
    required this.reserveEnabled,
    required this.isActive,
    required this.note,
  });

  final String? id;
  final String name;
  final String categoryId;
  final CategoryType categoryType;
  final MinorAmount amount;
  final AppCurrency currency;
  final RecurringFrequencyType frequency;
  final BusinessDate nextDueOn;
  final int reminderDaysBefore;
  final PaymentMethodType? defaultPaymentMethod;
  final bool reserveEnabled;
  final bool isActive;
  final String? note;

  factory RecurringModel.fromPayload({
    String? id,
    required String name,
    required String categoryId,
    required String categoryType,
    required int amountMinor,
    required String currency,
    required String frequency,
    required DateTime nextDueOn,
    int reminderDaysBefore = 3,
    String? defaultPaymentMethod,
    bool reserveEnabled = false,
    bool isActive = true,
    String? note,
  }) {
    final CategoryType normalizedCategoryType =
        CategoryTypeX.fromDbValue(categoryType);

    if (normalizedCategoryType != CategoryType.expense) {
      throw DomainValidationException(
        code: 'recurring.category_type.invalid',
        message: 'Recurring expenses must reference an expense category.',
      );
    }

    if (reminderDaysBefore < 0) {
      throw DomainValidationException(
        code: 'recurring.reminder_days_before.invalid',
        message: 'reminder_days_before must be zero or positive.',
      );
    }

    return RecurringModel._(
      id: normalizeOptionalText(id, 'recurring_id'),
      name: requireTrimmedText(name, 'recurring_name'),
      categoryId: requireTrimmedText(categoryId, 'category_id'),
      categoryType: normalizedCategoryType,
      amount: MinorAmount(amountMinor),
      currency: AppCurrencyX.fromCode(currency),
      frequency: RecurringFrequencyTypeX.fromDbValue(frequency),
      nextDueOn: BusinessDate(nextDueOn),
      reminderDaysBefore: reminderDaysBefore,
      defaultPaymentMethod: defaultPaymentMethod == null
          ? null
          : PaymentMethodTypeX.fromDbValue(defaultPaymentMethod),
      reserveEnabled: reserveEnabled,
      isActive: isActive,
      note: normalizeOptionalText(note, 'recurring_note'),
    );
  }
}
