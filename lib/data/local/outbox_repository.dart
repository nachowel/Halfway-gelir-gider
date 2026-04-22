import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/domain/category_model.dart' as domain_category;
import '../../core/domain/transaction_model.dart' as domain_transaction;
import '../../core/domain/types.dart'
    show
        AppCurrencyX,
        CategoryTypeX,
        PaymentMethodTypeX,
        SourcePlatformTypeX,
        TransactionTypeX;
import '../app_models.dart';
import 'app_database.dart';

enum OutboxEntityType { transaction, category, recurringExpense }

enum OutboxOperationType {
  createTransaction,
  updateTransaction,
  deleteTransaction,
  createRecurringExpense,
  markRecurringPaid,
}

enum OutboxEntryStatus { pending, processing, failed, completed }

enum LocalSyncStatus { pendingCreate, syncing, syncFailed, synced }

extension on LocalSyncStatus {
  String get dbValue => switch (this) {
    LocalSyncStatus.pendingCreate => 'pending_create',
    LocalSyncStatus.syncing => 'syncing',
    LocalSyncStatus.syncFailed => 'sync_failed',
    LocalSyncStatus.synced => 'synced',
  };
}

class QueuedCreateTransaction {
  const QueuedCreateTransaction({
    required this.localTransactionId,
    required this.outboxEntryId,
  });

  final String localTransactionId;
  final String outboxEntryId;
}

class PendingOutboxEntry {
  const PendingOutboxEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.status,
    required this.payload,
    required this.attemptCount,
    required this.createdAt,
    required this.updatedAt,
    this.dedupeKey,
    this.processingStartedAt,
    this.nextRetryAt,
    this.lastError,
  });

  final String id;
  final OutboxEntityType entityType;
  final String entityId;
  final OutboxOperationType operation;
  final OutboxEntryStatus status;
  final Map<String, dynamic> payload;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? dedupeKey;
  final DateTime? processingStartedAt;
  final DateTime? nextRetryAt;
  final String? lastError;
}

class OutboxRepository {
  OutboxRepository(this._database);

  final AppDatabase _database;

  String createTransactionDedupeKey(String localTransactionId) {
    return '${OutboxEntityType.transaction.name}:${OutboxOperationType.createTransaction.name}:$localTransactionId';
  }

  String updateTransactionDedupeKey(String transactionId) {
    return 'transaction:update:$transactionId';
  }

  String deleteTransactionDedupeKey(String transactionId) {
    return 'transaction:delete:$transactionId';
  }

  Future<QueuedCreateTransaction> queueCreateTransaction({
    required EntryDraft draft,
    required CategoryType categoryType,
    required String categoryName,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final String localTransactionId = _generateUuid();
    final String outboxEntryId = _generateUuid();
    final String dedupeKey = createTransactionDedupeKey(localTransactionId);

    final domain_transaction.TransactionModel transaction =
        domain_transaction.TransactionModel.fromPayload(
          id: localTransactionId,
          type: draft.type.dbValue,
          occurredOn: draft.occurredOn,
          amountMinor: draft.amountMinor,
          currency: 'GBP',
          categoryId: draft.categoryId,
          categoryType: categoryType.dbValue,
          paymentMethod: draft.paymentMethod.dbValue,
          sourcePlatform: draft.sourcePlatform?.dbValue,
          note: draft.note,
          vendor: draft.vendor,
          supplierId: draft.supplierId,
          attachmentPath: draft.attachmentPath,
        );

    final Map<String, dynamic> payload = <String, dynamic>{
      'local_id': localTransactionId,
      'type': transaction.type.dbValue,
      'occurred_on': transaction.occurredOn.iso8601Date,
      'amount_minor': transaction.amount.value,
      'currency': transaction.currency.code,
      'category_id': transaction.categoryId,
      'category_type': transaction.categoryType.dbValue,
      'category_name': categoryName,
      'payment_method': transaction.paymentMethod.dbValue,
      'source_platform': transaction.sourcePlatform?.dbValue,
      'note': transaction.note,
      'vendor': transaction.vendor,
      'supplier_id': transaction.supplierId,
      'attachment_path': transaction.attachmentPath,
      'recurring_expense_id': transaction.recurringExpenseId,
    };

    await _database.transaction(() async {
      await _database
          .into(_database.localTransactions)
          .insert(
            LocalTransactionsCompanion.insert(
              id: localTransactionId,
              remoteId: const Value<String?>(null),
              syncStatus: Value<String>(LocalSyncStatus.pendingCreate.dbValue),
              type: transaction.type.dbValue,
              occurredOn: transaction.occurredOn.iso8601Date,
              amountMinor: transaction.amount.value,
              currency: Value<String>(transaction.currency.code),
              categoryId: transaction.categoryId,
              categoryType: transaction.categoryType.dbValue,
              categoryName: categoryName,
              paymentMethod: transaction.paymentMethod.dbValue,
              sourcePlatform: Value<String?>(
                transaction.sourcePlatform?.dbValue,
              ),
              note: Value<String?>(transaction.note),
              vendor: Value<String?>(transaction.vendor),
              supplierId: Value<String?>(transaction.supplierId),
              attachmentPath: Value<String?>(transaction.attachmentPath),
              recurringExpenseId: Value<String?>(
                transaction.recurringExpenseId,
              ),
              syncedAt: const Value<DateTime?>(null),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _database
          .into(_database.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: outboxEntryId,
              entityType: OutboxEntityType.transaction.name,
              entityId: localTransactionId,
              operation: OutboxOperationType.createTransaction.name,
              dedupeKey: Value<String?>(dedupeKey),
              payload: jsonEncode(payload),
              status: Value<String>(OutboxEntryStatus.pending.name),
              processingStartedAt: const Value<DateTime?>(null),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    return QueuedCreateTransaction(
      localTransactionId: localTransactionId,
      outboxEntryId: outboxEntryId,
    );
  }

  Future<String?> queueUpdateTransaction({
    required String transactionId,
    required EntryDraft draft,
    required CategoryType categoryType,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final String updateDedupeKey = updateTransactionDedupeKey(transactionId);
    final String deleteDedupeKey = deleteTransactionDedupeKey(transactionId);

    final domain_transaction.TransactionModel transaction =
        domain_transaction.TransactionModel.fromPayload(
          id: transactionId,
          type: draft.type.dbValue,
          occurredOn: draft.occurredOn,
          amountMinor: draft.amountMinor,
          currency: 'GBP',
          categoryId: draft.categoryId,
          categoryType: categoryType.dbValue,
          paymentMethod: draft.paymentMethod.dbValue,
          sourcePlatform: draft.sourcePlatform?.dbValue,
          note: draft.note,
          vendor: draft.vendor,
          supplierId: draft.supplierId,
          attachmentPath: draft.attachmentPath,
        );

    final Map<String, dynamic> payload = <String, dynamic>{
      'id': transaction.id,
      'type': transaction.type.dbValue,
      'occurred_on': transaction.occurredOn.iso8601Date,
      'amount_minor': transaction.amount.value,
      'currency': transaction.currency.code,
      'category_id': transaction.categoryId,
      'payment_method': transaction.paymentMethod.dbValue,
      'source_platform': transaction.sourcePlatform?.dbValue,
      'note': transaction.note,
      'vendor': transaction.vendor,
      'supplier_id': transaction.supplierId,
      'attachment_path': transaction.attachmentPath,
    };

    return _database.transaction(() async {
      final OutboxEntry? openDelete = await _findOpenEntryByDedupeKey(
        deleteDedupeKey,
      );
      if (openDelete != null) {
        return null;
      }

      await _deleteOpenTransactionEntries(
        transactionId: transactionId,
        operations: const <OutboxOperationType>[
          OutboxOperationType.updateTransaction,
        ],
      );

      final String outboxEntryId = _generateUuid();
      await _database
          .into(_database.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: outboxEntryId,
              entityType: OutboxEntityType.transaction.name,
              entityId: transactionId,
              operation: OutboxOperationType.updateTransaction.name,
              dedupeKey: Value<String?>(updateDedupeKey),
              payload: jsonEncode(payload),
              status: Value<String>(OutboxEntryStatus.pending.name),
              processingStartedAt: const Value<DateTime?>(null),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return outboxEntryId;
    });
  }

  Future<String?> queueDeleteTransaction({
    required String transactionId,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final String dedupeKey = deleteTransactionDedupeKey(transactionId);

    return _database.transaction(() async {
      final OutboxEntry? openDelete = await _findOpenEntryByDedupeKey(
        dedupeKey,
      );
      if (openDelete != null) {
        return null;
      }

      await _deleteOpenTransactionEntries(
        transactionId: transactionId,
        operations: const <OutboxOperationType>[
          OutboxOperationType.updateTransaction,
        ],
      );

      final String outboxEntryId = _generateUuid();
      await _database
          .into(_database.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              id: outboxEntryId,
              entityType: OutboxEntityType.transaction.name,
              entityId: transactionId,
              operation: OutboxOperationType.deleteTransaction.name,
              dedupeKey: Value<String?>(dedupeKey),
              payload: jsonEncode(<String, dynamic>{
                'id': transactionId,
                'deleted_at': now.toIso8601String(),
              }),
              status: Value<String>(OutboxEntryStatus.pending.name),
              processingStartedAt: const Value<DateTime?>(null),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return outboxEntryId;
    });
  }

  Future<LocalTransaction?> findLocalTransaction(String id) {
    return (_database.select(
      _database.localTransactions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<OutboxEntry?> findOutboxEntry(String id) {
    return (_database.select(
      _database.outboxEntries,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<PendingOutboxEntry?> findOpenCreateTransactionEntry(
    String localTransactionId,
  ) async {
    final OutboxEntry? row =
        await (_database.select(_database.outboxEntries)..where((table) {
              return table.dedupeKey.equals(
                    createTransactionDedupeKey(localTransactionId),
                  ) &
                  table.status.isNotValue(OutboxEntryStatus.completed.name);
            }))
            .getSingleOrNull();
    return row == null ? null : _mapPendingEntry(row);
  }

  Future<int> recoverStaleProcessing({
    required DateTime now,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final DateTime cutoff = now.toUtc().subtract(timeout);
    final List<OutboxEntry> staleRows =
        await (_database.select(_database.outboxEntries)..where((table) {
              return table.status.equals(OutboxEntryStatus.processing.name) &
                  table.processingStartedAt.isSmallerOrEqualValue(cutoff);
            }))
            .get();

    for (final OutboxEntry row in staleRows) {
      await markRetryableFailure(
        entryId: row.id,
        errorMessage: 'stale processing recovered',
        retryAt: now.toUtc(),
      );
    }

    return staleRows.length;
  }

  Future<PendingOutboxEntry?> claimNextReadyEntry({
    required DateTime now,
  }) async {
    final DateTime utcNow = now.toUtc();

    return _database.transaction(() async {
      final OutboxEntry? next =
          await ((_database.select(_database.outboxEntries))
                ..where((table) {
                  final Expression<bool> pending = table.status.equals(
                    OutboxEntryStatus.pending.name,
                  );
                  final Expression<bool> retryableFailed =
                      table.status.equals(OutboxEntryStatus.failed.name) &
                      table.nextRetryAt.isNotNull() &
                      table.nextRetryAt.isSmallerOrEqualValue(utcNow);
                  return pending | retryableFailed;
                })
                ..orderBy(<OrderingTerm Function($OutboxEntriesTable)>[
                  (table) => OrderingTerm.asc(table.createdAt),
                ])
                ..limit(1))
              .getSingleOrNull();

      if (next == null) {
        return null;
      }

      await ((_database.update(
        _database.outboxEntries,
      ))..where((table) => table.id.equals(next.id))).write(
        OutboxEntriesCompanion(
          status: Value<String>(OutboxEntryStatus.processing.name),
          processingStartedAt: Value<DateTime>(utcNow),
          updatedAt: Value<DateTime>(utcNow),
        ),
      );

      if (next.entityType == OutboxEntityType.transaction.name) {
        await ((_database.update(
          _database.localTransactions,
        ))..where((table) => table.id.equals(next.entityId))).write(
          LocalTransactionsCompanion(
            syncStatus: Value<String>(LocalSyncStatus.syncing.dbValue),
            updatedAt: Value<DateTime>(utcNow),
          ),
        );
      }

      final OutboxEntry claimed = (await findOutboxEntry(next.id))!;
      return _mapPendingEntry(claimed);
    });
  }

  Future<void> finalizeTransactionCreateSuccess({
    required String entryId,
    required String localTransactionId,
    required String remoteId,
    required DateTime syncedAt,
  }) async {
    final DateTime utcNow = syncedAt.toUtc();

    await _database.transaction(() async {
      await ((_database.update(
        _database.localTransactions,
      ))..where((table) => table.id.equals(localTransactionId))).write(
        LocalTransactionsCompanion(
          remoteId: Value<String>(remoteId),
          syncStatus: Value<String>(LocalSyncStatus.synced.dbValue),
          syncedAt: Value<DateTime>(utcNow),
          updatedAt: Value<DateTime>(utcNow),
        ),
      );

      await ((_database.update(
        _database.outboxEntries,
      ))..where((table) => table.id.equals(entryId))).write(
        OutboxEntriesCompanion(
          status: Value<String>(OutboxEntryStatus.completed.name),
          processingStartedAt: const Value<DateTime?>(null),
          nextRetryAt: const Value<DateTime?>(null),
          lastError: const Value<String?>(null),
          updatedAt: Value<DateTime>(utcNow),
        ),
      );
    });
  }

  Future<void> finalizeEntrySuccess({
    required String entryId,
    DateTime? completedAt,
  }) async {
    final DateTime utcNow = (completedAt ?? DateTime.now()).toUtc();
    final OutboxEntry existing = await (_database.select(
      _database.outboxEntries,
    )..where((table) => table.id.equals(entryId))).getSingle();

    await _database.transaction(() async {
      await ((_database.update(
        _database.outboxEntries,
      ))..where((table) => table.id.equals(entryId))).write(
        OutboxEntriesCompanion(
          status: Value<String>(OutboxEntryStatus.completed.name),
          processingStartedAt: const Value<DateTime?>(null),
          nextRetryAt: const Value<DateTime?>(null),
          lastError: const Value<String?>(null),
          updatedAt: Value<DateTime>(utcNow),
        ),
      );

      if (existing.entityType == OutboxEntityType.transaction.name) {
        await ((_database.update(
          _database.localTransactions,
        ))..where((table) => table.id.equals(existing.entityId))).write(
          LocalTransactionsCompanion(
            syncStatus: Value<String>(LocalSyncStatus.synced.dbValue),
            syncedAt: Value<DateTime>(utcNow),
            updatedAt: Value<DateTime>(utcNow),
          ),
        );
      }
    });
  }

  Future<void> markRetryableFailure({
    required String entryId,
    required String errorMessage,
    required DateTime retryAt,
  }) async {
    final DateTime utcNow = DateTime.now().toUtc();
    final OutboxEntry existing = await (_database.select(
      _database.outboxEntries,
    )..where((table) => table.id.equals(entryId))).getSingle();

    await _database.transaction(() async {
      await ((_database.update(
        _database.outboxEntries,
      ))..where((table) => table.id.equals(entryId))).write(
        OutboxEntriesCompanion(
          status: Value<String>(OutboxEntryStatus.failed.name),
          attemptCount: Value<int>(existing.attemptCount + 1),
          processingStartedAt: const Value<DateTime?>(null),
          nextRetryAt: Value<DateTime>(retryAt.toUtc()),
          lastError: Value<String>(errorMessage),
          updatedAt: Value<DateTime>(utcNow),
        ),
      );

      if (existing.entityType == OutboxEntityType.transaction.name) {
        await _setTransactionSyncFailure(existing.entityId, utcNow);
      }
    });
  }

  Future<void> markNonRetryableFailure({
    required String entryId,
    required String errorMessage,
  }) async {
    final DateTime utcNow = DateTime.now().toUtc();
    final OutboxEntry existing = await (_database.select(
      _database.outboxEntries,
    )..where((table) => table.id.equals(entryId))).getSingle();

    await _database.transaction(() async {
      await ((_database.update(
        _database.outboxEntries,
      ))..where((table) => table.id.equals(entryId))).write(
        OutboxEntriesCompanion(
          status: Value<String>(OutboxEntryStatus.failed.name),
          attemptCount: Value<int>(existing.attemptCount + 1),
          processingStartedAt: const Value<DateTime?>(null),
          nextRetryAt: const Value<DateTime?>(null),
          lastError: Value<String>(errorMessage),
          updatedAt: Value<DateTime>(utcNow),
        ),
      );

      if (existing.entityType == OutboxEntityType.transaction.name) {
        await _setTransactionSyncFailure(existing.entityId, utcNow);
      }
    });
  }

  Future<void> cacheCategory({
    required String id,
    String? remoteId,
    required CategoryType type,
    required String name,
    String? icon,
    String? colorToken,
    int sortOrder = 0,
    bool isArchived = false,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final domain_category.CategoryModel category =
        domain_category.CategoryModel.fromPayload(
          id: id,
          type: type.dbValue,
          name: name,
          icon: icon,
          colorToken: colorToken,
          sortOrder: sortOrder,
          isArchived: isArchived,
        );

    await _database
        .into(_database.localCategories)
        .insertOnConflictUpdate(
          LocalCategoriesCompanion.insert(
            id: category.id!,
            remoteId: Value<String?>(remoteId),
            type: category.type.dbValue,
            name: category.name,
            icon: Value<String?>(category.icon),
            colorToken: Value<String?>(category.colorToken),
            sortOrder: Value<int>(category.sortOrder),
            isArchived: Value<bool>(category.isArchived),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<List<PendingOutboxEntry>> pendingEntries() async {
    final List<OutboxEntry> rows =
        await (_database.select(_database.outboxEntries)
              ..where(
                (table) =>
                    table.status.isNotValue(OutboxEntryStatus.completed.name),
              )
              ..orderBy(<OrderingTerm Function($OutboxEntriesTable)>[
                (table) => OrderingTerm.asc(table.createdAt),
              ]))
            .get();
    return rows.map(_mapPendingEntry).toList(growable: false);
  }

  Future<void> markFailed({
    required String entryId,
    required String errorMessage,
    required DateTime retryAt,
  }) {
    return markRetryableFailure(
      entryId: entryId,
      errorMessage: errorMessage,
      retryAt: retryAt,
    );
  }

  PendingOutboxEntry _mapPendingEntry(OutboxEntry row) {
    return PendingOutboxEntry(
      id: row.id,
      entityType: OutboxEntityType.values.byName(row.entityType),
      entityId: row.entityId,
      operation: OutboxOperationType.values.byName(row.operation),
      status: OutboxEntryStatus.values.byName(row.status),
      dedupeKey: row.dedupeKey,
      payload: jsonDecode(row.payload) as Map<String, dynamic>,
      attemptCount: row.attemptCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      processingStartedAt: row.processingStartedAt,
      nextRetryAt: row.nextRetryAt,
      lastError: row.lastError,
    );
  }

  Future<void> _setTransactionSyncFailure(
    String transactionId,
    DateTime utcNow,
  ) async {
    await ((_database.update(
      _database.localTransactions,
    ))..where((table) => table.id.equals(transactionId))).write(
      LocalTransactionsCompanion(
        syncStatus: Value<String>(LocalSyncStatus.syncFailed.dbValue),
        updatedAt: Value<DateTime>(utcNow),
      ),
    );
  }

  Future<OutboxEntry?> _findOpenEntryByDedupeKey(String dedupeKey) {
    return (_database.select(_database.outboxEntries)..where((table) {
          return table.dedupeKey.equals(dedupeKey) &
              table.status.isNotValue(OutboxEntryStatus.completed.name);
        }))
        .getSingleOrNull();
  }

  Future<void> _deleteOpenTransactionEntries({
    required String transactionId,
    required List<OutboxOperationType> operations,
  }) async {
    if (operations.isEmpty) {
      return;
    }

    await (_database.delete(_database.outboxEntries)..where((table) {
          Expression<bool> operationFilter = table.operation.equals(
            operations.first.name,
          );
          for (final OutboxOperationType operation in operations.skip(1)) {
            operationFilter =
                operationFilter | table.operation.equals(operation.name);
          }

          return table.entityType.equals(OutboxEntityType.transaction.name) &
              table.entityId.equals(transactionId) &
              operationFilter &
              table.status.isNotValue(OutboxEntryStatus.completed.name);
        }))
        .go();
  }

  String _generateUuid() {
    final Random random = Random.secure();
    String hex(int length) {
      final StringBuffer buffer = StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.write(random.nextInt(16).toRadixString(16));
      }
      return buffer.toString();
    }

    return '${hex(8)}-${hex(4)}-4${hex(3)}-${<String>['8', '9', 'a', 'b'][random.nextInt(4)]}${hex(3)}-${hex(12)}';
  }
}
