import 'types.dart';

final class SupplierModel {
  SupplierModel._({
    required this.id,
    required this.expenseCategoryId,
    required this.name,
    required this.notes,
    required this.sortOrder,
    required this.isArchived,
  });

  final String? id;
  final String expenseCategoryId;
  final String name;
  final String? notes;
  final int sortOrder;
  final bool isArchived;

  factory SupplierModel.fromPayload({
    String? id,
    required String expenseCategoryId,
    required String name,
    String? notes,
    int sortOrder = 0,
    bool isArchived = false,
  }) {
    final String? normalizedId = normalizeOptionalText(id, 'supplier_id');
    final String normalizedCategoryId = requireTrimmedText(
      expenseCategoryId,
      'supplier_expense_category_id',
    );
    final String normalizedName = requireTrimmedText(name, 'supplier_name');
    final String? normalizedNotes = normalizeOptionalText(notes, 'supplier_notes');

    if (sortOrder < 0) {
      throw const DomainValidationException(
        code: 'supplier.sort_order.invalid',
        message: 'Supplier sort_order must be zero or positive.',
      );
    }

    return SupplierModel._(
      id: normalizedId,
      expenseCategoryId: normalizedCategoryId,
      name: normalizedName,
      notes: normalizedNotes,
      sortOrder: sortOrder,
      isArchived: isArchived,
    );
  }
}
