import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/local/app_database.dart';
import 'package:gider/data/local/outbox_repository.dart';
import 'package:gider/data/sync/conflict_policy.dart';
import 'package:gider/data/sync/sync_engine.dart';

class _FakeTransactionSyncGateway implements TransactionSyncGateway {
  _FakeTransactionSyncGateway({
    Future<String> Function(Map<String, dynamic> payload)? onCreate,
    Future<void> Function(Map<String, dynamic> payload)? onUpdate,
    Future<void> Function(Map<String, dynamic> payload)? onDelete,
  }) : _onCreate = onCreate,
       _onUpdate = onUpdate,
       _onDelete = onDelete;

  final Future<String> Function(Map<String, dynamic> payload)? _onCreate;
  final Future<void> Function(Map<String, dynamic> payload)? _onUpdate;
  final Future<void> Function(Map<String, dynamic> payload)? _onDelete;

  @override
  Future<String> createTransaction(Map<String, dynamic> payload) {
    return _onCreate!(payload);
  }

  @override
  Future<void> updateTransaction(Map<String, dynamic> payload) {
    return _onUpdate!(payload);
  }

  @override
  Future<void> deleteTransaction(Map<String, dynamic> payload) {
    return _onDelete!(payload);
  }
}

void main() {
  group('SyncEngine', () {
    late AppDatabase database;
    late OutboxRepository outboxRepository;
    late SyncConflictPolicy conflictPolicy;
    late DateTime now;

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      outboxRepository = OutboxRepository(database);
      conflictPolicy = const SyncConflictPolicy();
      now = DateTime.utc(2026, 4, 20, 10, 0);
    });

    tearDown(() async {
      await database.close();
    });

    Future<QueuedCreateTransaction> queueExpense() {
      return outboxRepository.queueCreateTransaction(
        draft: EntryDraft(
          type: TransactionType.expense,
          occurredOn: DateTime(2026, 4, 20),
          amountMinor: 4200,
          categoryId: 'c1111111-1111-4111-8111-111111111111',
          paymentMethod: PaymentMethodType.card,
          vendor: 'Shell',
        ),
        categoryType: CategoryType.expense,
        categoryName: 'Fuel',
      );
    }

    test('successful create finalizes local transaction and outbox', () async {
      final QueuedCreateTransaction queued = await queueExpense();
      final SyncEngine engine = SyncEngine(
        outboxRepository: outboxRepository,
        transactionGateway: _FakeTransactionSyncGateway(
          onCreate: (Map<String, dynamic> payload) async =>
              payload['local_id'] as String,
        ),
        conflictPolicy: conflictPolicy,
        clock: () => now,
      );

      final SyncRunResult result = await engine.processPending();
      final LocalTransaction local = (await outboxRepository
          .findLocalTransaction(queued.localTransactionId))!;
      final OutboxEntry outbox = (await outboxRepository.findOutboxEntry(
        queued.outboxEntryId,
      ))!;

      expect(result.succeededEntries, 1);
      expect(local.remoteId, queued.localTransactionId);
      expect(local.syncStatus, 'synced');
      expect(local.syncedAt, isNotNull);
      expect(outbox.status, 'completed');
      expect(outbox.processingStartedAt, isNull);
    });

    test('retryable errors mark entry failed with backoff', () async {
      final QueuedCreateTransaction queued = await queueExpense();
      final SyncEngine engine = SyncEngine(
        outboxRepository: outboxRepository,
        transactionGateway: _FakeTransactionSyncGateway(
          onCreate: (_) async => throw TimeoutException('network timeout'),
        ),
        conflictPolicy: conflictPolicy,
        clock: () => now,
      );

      final SyncRunResult result = await engine.processPending();
      final LocalTransaction local = (await outboxRepository
          .findLocalTransaction(queued.localTransactionId))!;
      final OutboxEntry outbox = (await outboxRepository.findOutboxEntry(
        queued.outboxEntryId,
      ))!;

      expect(result.retryableFailures, 1);
      expect(local.syncStatus, 'sync_failed');
      expect(outbox.status, 'failed');
      expect(outbox.attemptCount, 1);
      expect(outbox.nextRetryAt?.toUtc(), now.add(const Duration(seconds: 30)));
    });

    test('non-retryable errors stop further retries', () async {
      final QueuedCreateTransaction queued = await queueExpense();
      final SyncEngine engine = SyncEngine(
        outboxRepository: outboxRepository,
        transactionGateway: _FakeTransactionSyncGateway(
          onCreate: (_) async => throw const SyncRemoteException(
            message: 'invalid category reference',
            code: '23503',
          ),
        ),
        conflictPolicy: conflictPolicy,
        clock: () => now,
      );

      final SyncRunResult result = await engine.processPending();
      final OutboxEntry outbox = (await outboxRepository.findOutboxEntry(
        queued.outboxEntryId,
      ))!;

      expect(result.nonRetryableFailures, 1);
      expect(outbox.status, 'failed');
      expect(outbox.nextRetryAt, isNull);
      expect(outbox.lastError, contains('invalid category'));
    });

    test(
      'duplicate remote create is treated as already applied success',
      () async {
        final QueuedCreateTransaction queued = await queueExpense();
        final SyncEngine engine = SyncEngine(
          outboxRepository: outboxRepository,
          transactionGateway: _FakeTransactionSyncGateway(
            onCreate: (_) async => throw const SyncRemoteException(
              message: 'duplicate key value violates unique constraint',
              code: '23505',
            ),
          ),
          conflictPolicy: conflictPolicy,
          clock: () => now,
        );

        final SyncRunResult result = await engine.processPending();
        final LocalTransaction local = (await outboxRepository
            .findLocalTransaction(queued.localTransactionId))!;
        final OutboxEntry outbox = (await outboxRepository.findOutboxEntry(
          queued.outboxEntryId,
        ))!;

        expect(result.alreadyAppliedEntries, 1);
        expect(local.syncStatus, 'synced');
        expect(local.remoteId, queued.localTransactionId);
        expect(outbox.status, 'completed');
      },
    );

    test('stale processing entries are recovered and retried', () async {
      final QueuedCreateTransaction queued = await queueExpense();
      final DateTime staleStartedAt = now.subtract(const Duration(minutes: 10));

      await (database.update(
        database.outboxEntries,
      )..where((table) => table.id.equals(queued.outboxEntryId))).write(
        OutboxEntriesCompanion(
          status: const Value<String>('processing'),
          processingStartedAt: Value<DateTime>(staleStartedAt),
          updatedAt: Value<DateTime>(staleStartedAt),
        ),
      );
      await (database.update(
        database.localTransactions,
      )..where((table) => table.id.equals(queued.localTransactionId))).write(
        LocalTransactionsCompanion(syncStatus: const Value<String>('syncing')),
      );

      final SyncEngine engine = SyncEngine(
        outboxRepository: outboxRepository,
        transactionGateway: _FakeTransactionSyncGateway(
          onCreate: (Map<String, dynamic> payload) async =>
              payload['local_id'] as String,
        ),
        conflictPolicy: conflictPolicy,
        clock: () => now,
      );

      final SyncRunResult result = await engine.processPending();
      final OutboxEntry outbox = (await outboxRepository.findOutboxEntry(
        queued.outboxEntryId,
      ))!;

      expect(result.recoveredStaleProcessing, 1);
      expect(result.succeededEntries, 1);
      expect(outbox.status, 'completed');
    });

    test('successful update completes queued transaction update', () async {
      final String? entryId = await outboxRepository.queueUpdateTransaction(
        transactionId: 'tx-1',
        draft: EntryDraft(
          type: TransactionType.expense,
          occurredOn: DateTime(2026, 4, 21),
          amountMinor: 5100,
          categoryId: 'c1111111-1111-4111-8111-111111111111',
          paymentMethod: PaymentMethodType.card,
          vendor: 'Updated vendor',
        ),
        categoryType: CategoryType.expense,
      );
      final SyncEngine engine = SyncEngine(
        outboxRepository: outboxRepository,
        transactionGateway: _FakeTransactionSyncGateway(onUpdate: (_) async {}),
        conflictPolicy: conflictPolicy,
        clock: () => now,
      );

      final SyncRunResult result = await engine.processPending();
      final OutboxEntry outbox = (await outboxRepository.findOutboxEntry(
        entryId!,
      ))!;

      expect(result.succeededEntries, 1);
      expect(outbox.status, 'completed');
    });

    test('successful delete completes queued transaction delete', () async {
      final String? entryId = await outboxRepository.queueDeleteTransaction(
        transactionId: 'tx-del',
      );
      final SyncEngine engine = SyncEngine(
        outboxRepository: outboxRepository,
        transactionGateway: _FakeTransactionSyncGateway(onDelete: (_) async {}),
        conflictPolicy: conflictPolicy,
        clock: () => now,
      );

      final SyncRunResult result = await engine.processPending();
      final OutboxEntry outbox = (await outboxRepository.findOutboxEntry(
        entryId!,
      ))!;

      expect(result.succeededEntries, 1);
      expect(outbox.status, 'completed');
    });

    test(
      'update retryable errors mark queued entry failed with backoff',
      () async {
        final String? entryId = await outboxRepository.queueUpdateTransaction(
          transactionId: 'tx-retry',
          draft: EntryDraft(
            type: TransactionType.income,
            occurredOn: DateTime(2026, 4, 21),
            amountMinor: 22000,
            categoryId: 'c1111111-1111-4111-8111-111111111111',
            paymentMethod: PaymentMethodType.cash,
          ),
          categoryType: CategoryType.income,
        );
        final SyncEngine engine = SyncEngine(
          outboxRepository: outboxRepository,
          transactionGateway: _FakeTransactionSyncGateway(
            onUpdate: (_) async => throw TimeoutException('network timeout'),
          ),
          conflictPolicy: conflictPolicy,
          clock: () => now,
        );

        final SyncRunResult result = await engine.processPending();
        final OutboxEntry outbox = (await outboxRepository.findOutboxEntry(
          entryId!,
        ))!;

        expect(result.retryableFailures, 1);
        expect(outbox.status, 'failed');
        expect(outbox.attemptCount, 1);
        expect(
          outbox.nextRetryAt?.toUtc(),
          now.add(const Duration(seconds: 30)),
        );
      },
    );

    test(
      'update followed by delete only flushes delete and never replays stale update',
      () async {
        int updateCalls = 0;
        int deleteCalls = 0;

        await outboxRepository.queueUpdateTransaction(
          transactionId: 'tx-mixed',
          draft: EntryDraft(
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 21),
            amountMinor: 7300,
            categoryId: 'c1111111-1111-4111-8111-111111111111',
            paymentMethod: PaymentMethodType.card,
            vendor: 'Stale update',
          ),
          categoryType: CategoryType.expense,
        );
        final String? deleteEntryId = await outboxRepository
            .queueDeleteTransaction(transactionId: 'tx-mixed');

        final SyncEngine engine = SyncEngine(
          outboxRepository: outboxRepository,
          transactionGateway: _FakeTransactionSyncGateway(
            onUpdate: (_) async {
              updateCalls += 1;
            },
            onDelete: (_) async {
              deleteCalls += 1;
            },
          ),
          conflictPolicy: conflictPolicy,
          clock: () => now,
        );

        final SyncRunResult result = await engine.processPending();
        final List<PendingOutboxEntry> pending = await outboxRepository
            .pendingEntries();
        final OutboxEntry deleteEntry = (await outboxRepository.findOutboxEntry(
          deleteEntryId!,
        ))!;

        expect(result.succeededEntries, 1);
        expect(updateCalls, 0);
        expect(deleteCalls, 1);
        expect(deleteEntry.status, 'completed');
        expect(pending, isEmpty);
      },
    );
  });
}
