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
  _FakeTransactionSyncGateway(this._handler);

  final Future<String> Function(Map<String, dynamic> payload) _handler;

  @override
  Future<String> createTransaction(Map<String, dynamic> payload) {
    return _handler(payload);
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
          (Map<String, dynamic> payload) async => payload['local_id'] as String,
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
          (_) async => throw TimeoutException('network timeout'),
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
          (_) async => throw const SyncRemoteException(
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
            (_) async => throw const SyncRemoteException(
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
          (Map<String, dynamic> payload) async => payload['local_id'] as String,
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
  });
}
