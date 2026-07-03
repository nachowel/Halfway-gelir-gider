import '../../../data/app_models.dart';

const int kTransactionNoteMaxLength = 28;

String buildTransactionTitle(TransactionData transaction) {
  return transaction.categoryName;
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
