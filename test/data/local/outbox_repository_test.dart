import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/data/app_models.dart';
import 'package:gider/data/local/app_database.dart';
import 'package:gider/data/local/outbox_repository.dart';

void main() {
  group('OutboxRepository', () {
    late AppDatabase database;
    late OutboxRepository repository;

    setUp(() {
      database = AppDatabase(executor: NativeDatabase.memory());
      repository = OutboxRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'offline transaction is cached locally and queued in outbox',
      () async {
        final QueuedCreateTransaction queued = await repository
            .queueCreateTransaction(
              draft: EntryDraft(
                type: TransactionType.expense,
                occurredOn: DateTime(2026, 4, 20),
                amountMinor: 4200,
                categoryId: 'category-rent',
                paymentMethod: PaymentMethodType.card,
                vendor: 'Shell',
              ),
              categoryType: CategoryType.expense,
              categoryName: 'Fuel',
            );

        final localTransaction = await repository.findLocalTransaction(
          queued.localTransactionId,
        );
        final List<PendingOutboxEntry> entries = await repository
            .pendingEntries();

        expect(localTransaction, isNotNull);
        expect(localTransaction!.categoryName, 'Fuel');
        expect(localTransaction.syncStatus, 'pending_create');
        expect(localTransaction.amountMinor, 4200);

        expect(entries, hasLength(1));
        expect(entries.single.id, queued.outboxEntryId);
        expect(entries.single.operation, OutboxOperationType.createTransaction);
        expect(entries.single.entityType, OutboxEntityType.transaction);
        expect(entries.single.attemptCount, 0);
        expect(entries.single.payload['category_name'], 'Fuel');
        expect(entries.single.payload['vendor'], 'Shell');
        expect(
          entries.single.dedupeKey,
          repository.createTransactionDedupeKey(queued.localTransactionId),
        );

        final PendingOutboxEntry? openEntry = await repository
            .findOpenCreateTransactionEntry(queued.localTransactionId);
        expect(openEntry, isNotNull);
        expect(openEntry!.id, queued.outboxEntryId);
      },
    );

    test('failed outbox entry stores retry metadata', () async {
      final QueuedCreateTransaction queued = await repository
          .queueCreateTransaction(
            draft: EntryDraft(
              type: TransactionType.income,
              occurredOn: DateTime(2026, 4, 21),
              amountMinor: 18600,
              categoryId: 'category-sales',
              paymentMethod: PaymentMethodType.cash,
            ),
            categoryType: CategoryType.income,
            categoryName: 'Cash Sales',
          );

      final DateTime retryAt = DateTime.utc(2026, 4, 21, 12, 0);
      await repository.markFailed(
        entryId: queued.outboxEntryId,
        errorMessage: 'network timeout',
        retryAt: retryAt,
      );

      final List<PendingOutboxEntry> entries = await repository
          .pendingEntries();
      final PendingOutboxEntry entry = entries.single;

      expect(entry.status, OutboxEntryStatus.failed);
      expect(entry.attemptCount, 1);
      expect(entry.nextRetryAt?.toUtc(), retryAt);
      expect(entry.lastError, 'network timeout');
    });
  });
}
