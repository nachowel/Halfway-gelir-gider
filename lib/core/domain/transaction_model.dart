import 'types.dart';

final class TransactionModel {
  TransactionModel._({
    required this.id,
    required this.type,
    required this.occurredOn,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.categoryType,
    required this.paymentMethod,
    required this.sourcePlatform,
    required this.note,
    required this.vendor,
    required this.supplierId,
    required this.attachmentPath,
    required this.recurringExpenseId,
  });

  final String? id;
  final TransactionType type;
  final BusinessDate occurredOn;
  final MinorAmount amount;
  final AppCurrency currency;
  final String categoryId;
  final CategoryType categoryType;
  final PaymentMethodType paymentMethod;
  final SourcePlatformType? sourcePlatform;
  final String? note;
  final String? vendor;
  final String? supplierId;
  final String? attachmentPath;
  final String? recurringExpenseId;

  factory TransactionModel.fromPayload({
    String? id,
    required String type,
    required DateTime occurredOn,
    required int amountMinor,
    required String currency,
    required String categoryId,
    required String categoryType,
    required String paymentMethod,
    String? sourcePlatform,
    String? note,
    String? vendor,
    String? supplierId,
    String? attachmentPath,
    String? recurringExpenseId,
  }) {
    final TransactionType normalizedType = TransactionTypeX.fromDbValue(type);
    final CategoryType normalizedCategoryType =
        CategoryTypeX.fromDbValue(categoryType);
    final String? normalizedSupplierId = normalizeOptionalText(
      supplierId,
      'transaction_supplier_id',
    );

    if (normalizedType.name != normalizedCategoryType.name) {
      throw DomainValidationException(
        code: 'transaction.category_type_mismatch',
        message:
            'Transaction type must match category type. Got $type with $categoryType.',
      );
    }

    if (normalizedSupplierId != null &&
        normalizedType != TransactionType.expense) {
      throw const DomainValidationException(
        code: 'transaction.supplier_expense_only',
        message: 'Suppliers can only be attached to expense transactions.',
      );
    }

    return TransactionModel._(
      id: normalizeOptionalText(id, 'transaction_id'),
      type: normalizedType,
      occurredOn: BusinessDate(occurredOn),
      amount: MinorAmount(amountMinor),
      currency: AppCurrencyX.fromCode(currency),
      categoryId: requireTrimmedText(categoryId, 'category_id'),
      categoryType: normalizedCategoryType,
      paymentMethod: PaymentMethodTypeX.fromDbValue(paymentMethod),
      sourcePlatform: sourcePlatform == null
          ? null
          : SourcePlatformTypeX.fromDbValue(sourcePlatform),
      note: normalizeOptionalText(note, 'transaction_note'),
      vendor: normalizeOptionalText(vendor, 'transaction_vendor'),
      supplierId: normalizedSupplierId,
      attachmentPath: normalizeOptionalText(
        attachmentPath,
        'transaction_attachment_path',
      ),
      recurringExpenseId: normalizeOptionalText(
        recurringExpenseId,
        'transaction_recurring_expense_id',
      ),
    );
  }
}
