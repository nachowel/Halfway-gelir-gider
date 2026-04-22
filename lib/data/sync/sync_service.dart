import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conflict_policy.dart';
import 'sync_engine.dart';

abstract class ConnectivityProbe {
  Future<bool> isOnline();
}

class ConnectivityPlusProbe implements ConnectivityProbe {
  ConnectivityPlusProbe([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    final List<ConnectivityResult> result = await _connectivity
        .checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}

class SupabaseTransactionSyncGateway implements TransactionSyncGateway {
  SupabaseTransactionSyncGateway(this._client);

  final SupabaseClient _client;

  User get _user {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Authentication required');
    }
    return user;
  }

  @override
  Future<String> createTransaction(Map<String, dynamic> payload) async {
    final bool isIncome = payload['type'] == 'income';
    if (isIncome) {
      debugPrint('INCOME_SUPABASE_INSERT_STARTED');
    }

    try {
      final Map<String, dynamic> row = await _client
          .from('transactions')
          .insert(<String, dynamic>{
            'id': payload['local_id'],
            'user_id': _user.id,
            'type': payload['type'],
            'occurred_on': payload['occurred_on'],
            'amount_minor': payload['amount_minor'],
            'currency': payload['currency'],
            'category_id': payload['category_id'],
            'payment_method': payload['payment_method'],
            'source_platform': payload['source_platform'],
            'note': payload['note'],
            'vendor': payload['vendor'],
            'supplier_id': payload['supplier_id'],
            'attachment_path': payload['attachment_path'],
            'recurring_expense_id': payload['recurring_expense_id'],
          })
          .select('id')
          .single();

      if (isIncome) {
        debugPrint('INCOME_SUPABASE_INSERT_SUCCESS');
      }
      return row['id'] as String;
    } on PostgrestException catch (error) {
      if (isIncome) {
        debugPrint('INCOME_SUPABASE_INSERT_ERROR: ${error.message}');
      }
      throw SyncRemoteException(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    } catch (error) {
      if (isIncome) {
        debugPrint('INCOME_SUPABASE_INSERT_ERROR: $error');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateTransaction(Map<String, dynamic> payload) async {
    try {
      await _client
          .from('transactions')
          .update(<String, dynamic>{
            'type': payload['type'],
            'occurred_on': payload['occurred_on'],
            'amount_minor': payload['amount_minor'],
            'currency': payload['currency'],
            'category_id': payload['category_id'],
            'payment_method': payload['payment_method'],
            'source_platform': payload['source_platform'],
            'note': payload['note'],
            'vendor': payload['vendor'],
            'supplier_id': payload['supplier_id'],
            'attachment_path': payload['attachment_path'],
          })
          .eq('id', payload['id'])
          .eq('user_id', _user.id);
    } on PostgrestException catch (error) {
      throw SyncRemoteException(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }
  }

  @override
  Future<void> deleteTransaction(Map<String, dynamic> payload) async {
    try {
      await _client
          .from('transactions')
          .update(<String, dynamic>{'deleted_at': payload['deleted_at']})
          .eq('id', payload['id'])
          .eq('user_id', _user.id);
    } on PostgrestException catch (error) {
      throw SyncRemoteException(
        message: error.message,
        code: error.code,
        details: error.details,
      );
    }
  }
}

class SyncService {
  SyncService({
    required SyncEngine engine,
    required ConnectivityProbe connectivityProbe,
  }) : _engine = engine,
       _connectivityProbe = connectivityProbe;

  final SyncEngine _engine;
  final ConnectivityProbe _connectivityProbe;

  Future<SyncRunResult> syncNow({int maxEntries = 20}) async {
    if (!await _connectivityProbe.isOnline()) {
      return const SyncRunResult(
        recoveredStaleProcessing: 0,
        processedEntries: 0,
        succeededEntries: 0,
        alreadyAppliedEntries: 0,
        retryableFailures: 0,
        nonRetryableFailures: 0,
      );
    }

    return _engine.processPending(maxEntries: maxEntries);
  }
}
