import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncFailureType { retryable, nonRetryable, alreadyApplied }

class SyncFailureDecision {
  const SyncFailureDecision({required this.type, required this.message});

  final SyncFailureType type;
  final String message;
}

class SyncRemoteException implements Exception {
  const SyncRemoteException({required this.message, this.code, this.details});

  final String message;
  final String? code;
  final Object? details;

  @override
  String toString() => 'SyncRemoteException(code: $code, message: $message)';
}

class SyncConflictPolicy {
  const SyncConflictPolicy();

  Duration get staleProcessingTimeout => const Duration(minutes: 5);

  Duration retryDelay(int attemptNumber) {
    if (attemptNumber <= 1) return const Duration(seconds: 30);
    if (attemptNumber == 2) return const Duration(minutes: 2);
    if (attemptNumber == 3) return const Duration(minutes: 10);
    return const Duration(minutes: 30);
  }

  SyncFailureDecision classify(Object error) {
    if (error is SyncRemoteException) {
      if (_isAlreadyApplied(error)) {
        return const SyncFailureDecision(
          type: SyncFailureType.alreadyApplied,
          message: 'Remote create already applied.',
        );
      }

      if (_isNonRetryableRemote(error)) {
        return SyncFailureDecision(
          type: SyncFailureType.nonRetryable,
          message: error.message,
        );
      }

      return SyncFailureDecision(
        type: SyncFailureType.retryable,
        message: error.message,
      );
    }

    if (error is AuthException) {
      return SyncFailureDecision(
        type: SyncFailureType.nonRetryable,
        message: error.message,
      );
    }

    if (error is SocketException || error is TimeoutException) {
      return SyncFailureDecision(
        type: SyncFailureType.retryable,
        message: error.toString(),
      );
    }

    return SyncFailureDecision(
      type: SyncFailureType.retryable,
      message: error.toString(),
    );
  }

  bool _isAlreadyApplied(SyncRemoteException error) {
    final String code = error.code ?? '';
    final String message = error.message.toLowerCase();
    return code == '23505' ||
        message.contains('duplicate key') ||
        message.contains('already exists');
  }

  bool _isNonRetryableRemote(SyncRemoteException error) {
    const Set<String> nonRetryableCodes = <String>{
      '23503',
      '23514',
      '22P02',
      '42501',
      'PGRST116',
    };

    final String code = error.code ?? '';
    if (nonRetryableCodes.contains(code)) {
      return true;
    }

    final String message = error.message.toLowerCase();
    return message.contains('validation') ||
        message.contains('required') ||
        message.contains('does not belong') ||
        message.contains('must be') ||
        message.contains('invalid');
  }
}
