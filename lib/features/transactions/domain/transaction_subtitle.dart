import '../../../data/app_models.dart';

const int kTransactionNoteMaxLength = 28;

String buildTransactionTitle(TransactionData transaction) {
  if (transaction.type == TransactionType.income) {
    return transaction.categoryName;
  }
  return _expensePayeeLabel(transaction) ?? transaction.categoryName;
}

String buildTransactionSubtitle({
  required TransactionData transaction,
  required String Function(PaymentMethodType) paymentLabel,
  required String Function(SourcePlatformType) sourcePlatformLabel,
  int noteMaxLength = kTransactionNoteMaxLength,
}) {
  final String? entity = _entityLabel(transaction);
  final String payment = paymentLabel(transaction.paymentMethod);
  final String? platform = transaction.sourcePlatform == null
      ? null
      : sourcePlatformLabel(transaction.sourcePlatform!);
  final String? note = _truncatedNote(transaction.note, noteMaxLength);

  if (transaction.type == TransactionType.expense) {
    return <String>[transaction.categoryName, payment].join(' · ');
  }

  if (entity != null) {
    return <String>[
      entity,
      if (note != null) note,
      payment,
      if (platform != null) platform,
    ].join(' · ');
  }

  return <String>[
    transaction.categoryName,
    payment,
    if (platform != null) platform,
  ].join(' · ');
}

String? _expensePayeeLabel(TransactionData transaction) {
  if (_isStaffWagesCategory(transaction.categoryName)) {
    return _firstPresent(<String?>[
      transaction.staffName,
      transaction.supplierName,
      transaction.vendor,
    ]);
  }

  if (_isSupplierOrStockCategory(transaction.categoryName)) {
    return _firstPresent(<String?>[
      transaction.supplierName,
      transaction.vendor,
      transaction.staffName,
    ]);
  }

  return _firstPresent(<String?>[
    transaction.supplierName,
    transaction.vendor,
    transaction.staffName,
  ]);
}

bool _isStaffWagesCategory(String categoryName) {
  return _normalizedCategoryName(categoryName) == 'staff wages';
}

bool _isSupplierOrStockCategory(String categoryName) {
  final String normalized = _normalizedCategoryName(categoryName);
  return normalized.contains('stock') || normalized.contains('supplier');
}

String _normalizedCategoryName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String? _firstPresent(List<String?> values) {
  for (final String? value in values) {
    final String? trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

String? _entityLabel(TransactionData transaction) {
  final String? supplier = transaction.supplierName?.trim();
  if (supplier != null && supplier.isNotEmpty) {
    return supplier;
  }
  final String? vendor = transaction.vendor?.trim();
  if (vendor != null && vendor.isNotEmpty) {
    return vendor;
  }
  return null;
}

String? _truncatedNote(String? note, int maxLength) {
  if (note == null) {
    return null;
  }
  final String trimmed = note.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  final String cut = trimmed.substring(0, maxLength).trimRight();
  return '$cut…';
}
