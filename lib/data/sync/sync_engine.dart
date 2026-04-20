import '../local/outbox_repository.dart';
import 'conflict_policy.dart';

abstract class TransactionSyncGateway {
  Future<String> createTransaction(Map<String, dynamic> payload);
}

class SyncRunResult {
  const SyncRunResult({
    required this.recoveredStaleProcessing,
    required this.processedEntries,
    required this.succeededEntries,
    required this.alreadyAppliedEntries,
    required this.retryableFailures,
    required this.nonRetryableFailures,
  });

  final int recoveredStaleProcessing;
  final int processedEntries;
  final int succeededEntries;
  final int alreadyAppliedEntries;
  final int retryableFailures;
  final int nonRetryableFailures;
}

class SyncEngine {
  SyncEngine({
    required OutboxRepository outboxRepository,
    required TransactionSyncGateway transactionGateway,
    required SyncConflictPolicy conflictPolicy,
    DateTime Function()? clock,
  }) : _outboxRepository = outboxRepository,
       _transactionGateway = transactionGateway,
       _conflictPolicy = conflictPolicy,
       _clock = clock ?? DateTime.now;

  final OutboxRepository _outboxRepository;
  final TransactionSyncGateway _transactionGateway;
  final SyncConflictPolicy _conflictPolicy;
  final DateTime Function() _clock;

  Future<SyncRunResult> processPending({int maxEntries = 20}) async {
    int recovered = await _outboxRepository.recoverStaleProcessing(
      now: _clock().toUtc(),
      timeout: _conflictPolicy.staleProcessingTimeout,
    );

    int processed = 0;
    int succeeded = 0;
    int alreadyApplied = 0;
    int retryableFailures = 0;
    int nonRetryableFailures = 0;

    while (processed < maxEntries) {
      final PendingOutboxEntry? entry = await _outboxRepository
          .claimNextReadyEntry(now: _clock().toUtc());
      if (entry == null) {
        break;
      }

      processed++;

      switch (entry.operation) {
        case OutboxOperationType.createTransaction:
          final _ProcessOutcome outcome = await _processCreateTransaction(
            entry,
          );
          switch (outcome) {
            case _ProcessOutcome.succeeded:
              succeeded++;
            case _ProcessOutcome.alreadyApplied:
              alreadyApplied++;
            case _ProcessOutcome.retryableFailure:
              retryableFailures++;
            case _ProcessOutcome.nonRetryableFailure:
              nonRetryableFailures++;
          }
        case OutboxOperationType.updateTransaction:
        case OutboxOperationType.createRecurringExpense:
        case OutboxOperationType.markRecurringPaid:
          await _outboxRepository.markNonRetryableFailure(
            entryId: entry.id,
            errorMessage: 'Unsupported T8 operation: ${entry.operation.name}.',
          );
          nonRetryableFailures++;
      }
    }

    return SyncRunResult(
      recoveredStaleProcessing: recovered,
      processedEntries: processed,
      succeededEntries: succeeded,
      alreadyAppliedEntries: alreadyApplied,
      retryableFailures: retryableFailures,
      nonRetryableFailures: nonRetryableFailures,
    );
  }

  Future<_ProcessOutcome> _processCreateTransaction(
    PendingOutboxEntry entry,
  ) async {
    final String localTransactionId = entry.entityId;
    try {
      final String remoteId = await _transactionGateway.createTransaction(
        entry.payload,
      );
      await _outboxRepository.finalizeTransactionCreateSuccess(
        entryId: entry.id,
        localTransactionId: localTransactionId,
        remoteId: remoteId,
        syncedAt: _clock().toUtc(),
      );
      return _ProcessOutcome.succeeded;
    } catch (error) {
      final SyncFailureDecision decision = _conflictPolicy.classify(error);
      switch (decision.type) {
        case SyncFailureType.alreadyApplied:
          await _outboxRepository.finalizeTransactionCreateSuccess(
            entryId: entry.id,
            localTransactionId: localTransactionId,
            remoteId: localTransactionId,
            syncedAt: _clock().toUtc(),
          );
          return _ProcessOutcome.alreadyApplied;
        case SyncFailureType.retryable:
          final DateTime retryAt = _clock().toUtc().add(
            _conflictPolicy.retryDelay(entry.attemptCount + 1),
          );
          await _outboxRepository.markRetryableFailure(
            entryId: entry.id,
            errorMessage: decision.message,
            retryAt: retryAt,
          );
          return _ProcessOutcome.retryableFailure;
        case SyncFailureType.nonRetryable:
          await _outboxRepository.markNonRetryableFailure(
            entryId: entry.id,
            errorMessage: decision.message,
          );
          return _ProcessOutcome.nonRetryableFailure;
      }
    }
  }
}

enum _ProcessOutcome {
  succeeded,
  alreadyApplied,
  retryableFailure,
  nonRetryableFailure,
}
