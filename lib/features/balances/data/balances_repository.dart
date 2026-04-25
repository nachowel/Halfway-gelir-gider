import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/types.dart' as domain;
import '../domain/balance_models.dart';

class BalancesRepository {
  BalancesRepository(this._client);

  final SupabaseClient _client;

  User get _user {
    final User? user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Authentication required');
    }
    return user;
  }

  Future<BalanceSummaryData> fetchSummary() async {
    final List<BalanceAccountData> accounts = await fetchAccounts();
    int iOweMinor = 0;
    int owedToMeMinor = 0;
    for (final BalanceAccountData account in accounts) {
      if (account.status == BalanceAccountStatus.closed) {
        continue;
      }
      if (account.direction == BalanceDirection.payable) {
        iOweMinor += account.remainingMinor;
      } else {
        owedToMeMinor += account.remainingMinor;
      }
    }
    return BalanceSummaryData(
      accounts: accounts,
      iOweMinor: iOweMinor,
      owedToMeMinor: owedToMeMinor,
    );
  }

  Future<List<BalanceAccountData>> fetchAccounts() async {
    final List<dynamic> accountRows = await _client
        .from('balance_accounts')
        .select(
          'id, direction, name, counterparty_name, type, opened_at, status, '
          'notes, created_at, updated_at',
        )
        .eq('user_id', _user.id)
        .order('opened_at', ascending: false)
        .order('created_at', ascending: false);

    if (accountRows.isEmpty) {
      return <BalanceAccountData>[];
    }

    final List<String> accountIds = accountRows
        .map((dynamic row) => row['id'] as String)
        .toList();
    final List<BalanceMovementData> movements = await _fetchMovements(
      accountIds: accountIds,
    );
    final Map<String, List<BalanceMovementData>> movementsByAccount =
        <String, List<BalanceMovementData>>{};
    for (final BalanceMovementData movement in movements) {
      movementsByAccount
          .putIfAbsent(movement.accountId, () => <BalanceMovementData>[])
          .add(movement);
    }

    return accountRows.map<BalanceAccountData>((dynamic row) {
      final String accountId = row['id'] as String;
      return _mapAccount(
        row as Map<String, dynamic>,
        movements:
            movementsByAccount[accountId] ?? const <BalanceMovementData>[],
      );
    }).toList();
  }

  Future<BalanceAccountData?> fetchAccount(String id) async {
    final String accountId = domain.requireTrimmedText(
      id,
      'balance_account_id',
    );
    final Map<String, dynamic>? row = await _client
        .from('balance_accounts')
        .select(
          'id, direction, name, counterparty_name, type, opened_at, status, '
          'notes, created_at, updated_at',
        )
        .eq('id', accountId)
        .eq('user_id', _user.id)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final List<BalanceMovementData> movements = await _fetchMovements(
      accountIds: <String>[accountId],
    );
    return _mapAccount(row, movements: movements);
  }

  Future<BalanceAccountData> createAccount(BalanceAccountDraft draft) async {
    validateBalanceAccountDraft(draft);

    final Map<String, dynamic> inserted = await _client
        .from('balance_accounts')
        .insert(<String, dynamic>{
          'user_id': _user.id,
          'direction': draft.direction.dbValue,
          'name': domain.requireTrimmedText(draft.name, 'balance_account_name'),
          'counterparty_name': _normalizeOptionalText(draft.counterpartyName),
          'type': draft.type.dbValue,
          'opened_at': _isoDate(draft.openedAt),
          'status': BalanceAccountStatus.active.dbValue,
          'notes': _normalizeOptionalText(draft.notes),
        })
        .select(
          'id, direction, name, counterparty_name, type, opened_at, status, '
          'notes, created_at, updated_at',
        )
        .single();

    final String accountId = inserted['id'] as String;
    if (draft.openingAmountMinor > 0) {
      try {
        await addMovement(
          accountId: accountId,
          draft: BalanceMovementDraft(
            type: BalanceMovementType.increase,
            amountMinor: draft.openingAmountMinor,
            occurredAt: draft.openedAt,
            paymentMethod: BalancePaymentMethod.other,
            notes: 'Opening amount',
          ),
        );
      } catch (_, stackTrace) {
        try {
          await _deleteCreatedAccount(accountId);
        } catch (_) {
          Error.throwWithStackTrace(
            const domain.DomainValidationException(
              code: 'balance.opening_movement_failed_rollback_failed',
              message:
                  'Could not save the opening balance. The account was created, but cleanup failed; please remove it manually.',
            ),
            stackTrace,
          );
        }
        Error.throwWithStackTrace(
          const domain.DomainValidationException(
            code: 'balance.opening_movement_failed',
            message:
                'Could not save the opening balance. The account was rolled back; please try again.',
          ),
          stackTrace,
        );
      }
    }

    return (await fetchAccount(accountId)) ??
        _mapAccount(inserted, movements: const <BalanceMovementData>[]);
  }

  Future<void> addMovement({
    required String accountId,
    required BalanceMovementDraft draft,
  }) async {
    final String resolvedAccountId = domain.requireTrimmedText(
      accountId,
      'balance_account_id',
    );
    validateBalanceMovementDraft(draft);
    if (draft.type == BalanceMovementType.decrease) {
      final BalanceAccountData account = await _fetchExistingAccount(
        resolvedAccountId,
      );
      _ensureNonNegativeRemaining(<BalanceMovementData>[
        ...account.movements,
        BalanceMovementData(
          id: 'draft',
          accountId: resolvedAccountId,
          type: draft.type,
          amountMinor: draft.amountMinor,
          occurredAt: draft.occurredAt,
          paymentMethod: draft.paymentMethod,
          notes: _normalizeOptionalText(draft.notes),
          createdAt: DateTime.now(),
        ),
      ]);
    }

    await _client.from('balance_movements').insert(<String, dynamic>{
      'user_id': _user.id,
      'account_id': resolvedAccountId,
      'type': draft.type.dbValue,
      'amount_minor': draft.amountMinor,
      'occurred_at': _isoDate(draft.occurredAt),
      'payment_method': draft.paymentMethod.dbValue,
      'notes': _normalizeOptionalText(draft.notes),
    });
  }

  Future<void> updateAccount({
    required String accountId,
    required BalanceAccountEditDraft draft,
  }) async {
    final String resolvedAccountId = domain.requireTrimmedText(
      accountId,
      'balance_account_id',
    );
    validateBalanceAccountEditDraft(draft);

    await _client
        .from('balance_accounts')
        .update(<String, dynamic>{
          'name': domain.requireTrimmedText(draft.name, 'balance_account_name'),
          'counterparty_name': _normalizeOptionalText(draft.counterpartyName),
          'type': draft.type.dbValue,
          'opened_at': _isoDate(draft.openedAt),
          'notes': _normalizeOptionalText(draft.notes),
        })
        .eq('id', resolvedAccountId)
        .eq('user_id', _user.id);
  }

  Future<void> updateMovement({
    required String accountId,
    required String movementId,
    required BalanceMovementDraft draft,
  }) async {
    final String resolvedAccountId = domain.requireTrimmedText(
      accountId,
      'balance_account_id',
    );
    final String resolvedMovementId = domain.requireTrimmedText(
      movementId,
      'balance_movement_id',
    );
    validateBalanceMovementDraft(draft);

    final BalanceAccountData account = await _fetchExistingAccount(
      resolvedAccountId,
    );
    final List<BalanceMovementData> updatedMovements = account.movements.map((
      BalanceMovementData movement,
    ) {
      if (movement.id != resolvedMovementId) {
        return movement;
      }
      return BalanceMovementData(
        id: movement.id,
        accountId: movement.accountId,
        type: draft.type,
        amountMinor: draft.amountMinor,
        occurredAt: draft.occurredAt,
        paymentMethod: draft.paymentMethod,
        notes: _normalizeOptionalText(draft.notes),
        createdAt: movement.createdAt,
      );
    }).toList();
    if (!updatedMovements.any(
      (BalanceMovementData movement) => movement.id == resolvedMovementId,
    )) {
      throw const domain.DomainValidationException(
        code: 'balance.movement_not_found',
        message: 'Balance movement was not found.',
      );
    }
    _ensureNonNegativeRemaining(updatedMovements);

    await _client
        .from('balance_movements')
        .update(<String, dynamic>{
          'type': draft.type.dbValue,
          'amount_minor': draft.amountMinor,
          'occurred_at': _isoDate(draft.occurredAt),
          'payment_method': draft.paymentMethod.dbValue,
          'notes': _normalizeOptionalText(draft.notes),
        })
        .eq('id', resolvedMovementId)
        .eq('account_id', resolvedAccountId)
        .eq('user_id', _user.id);
  }

  Future<void> deleteMovement({
    required String accountId,
    required String movementId,
  }) async {
    final String resolvedAccountId = domain.requireTrimmedText(
      accountId,
      'balance_account_id',
    );
    final String resolvedMovementId = domain.requireTrimmedText(
      movementId,
      'balance_movement_id',
    );
    final BalanceAccountData account = await _fetchExistingAccount(
      resolvedAccountId,
    );
    if (!account.movements.any(
      (BalanceMovementData movement) => movement.id == resolvedMovementId,
    )) {
      throw const domain.DomainValidationException(
        code: 'balance.movement_not_found',
        message: 'Balance movement was not found.',
      );
    }
    final List<BalanceMovementData> remainingMovements = account.movements
        .where(
          (BalanceMovementData movement) => movement.id != resolvedMovementId,
        )
        .toList();
    _ensureNonNegativeRemaining(remainingMovements);

    await _client
        .from('balance_movements')
        .delete()
        .eq('id', resolvedMovementId)
        .eq('account_id', resolvedAccountId)
        .eq('user_id', _user.id);
  }

  Future<void> closeAccount(String id) async {
    final String accountId = domain.requireTrimmedText(
      id,
      'balance_account_id',
    );
    final BalanceAccountData? account = await fetchAccount(accountId);
    if (account == null) {
      throw const domain.DomainValidationException(
        code: 'balance.account_not_found',
        message: 'Balance account was not found.',
      );
    }
    if (!account.canClose) {
      throw const domain.DomainValidationException(
        code: 'balance.close_requires_zero',
        message:
            'Account can only be closed when the remaining balance is zero.',
      );
    }

    await _client
        .from('balance_accounts')
        .update(<String, dynamic>{
          'status': BalanceAccountStatus.closed.dbValue,
        })
        .eq('id', accountId)
        .eq('user_id', _user.id);
  }

  Future<void> _deleteCreatedAccount(String accountId) async {
    await _client
        .from('balance_accounts')
        .delete()
        .eq('id', accountId)
        .eq('user_id', _user.id);
  }

  Future<BalanceAccountData> _fetchExistingAccount(String accountId) async {
    final BalanceAccountData? account = await fetchAccount(accountId);
    if (account == null) {
      throw const domain.DomainValidationException(
        code: 'balance.account_not_found',
        message: 'Balance account was not found.',
      );
    }
    return account;
  }

  void _ensureNonNegativeRemaining(Iterable<BalanceMovementData> movements) {
    if (calculateBalanceRemaining(movements) < 0) {
      throw const domain.DomainValidationException(
        code: 'balance.remaining_negative',
        message: 'Remaining balance cannot be negative.',
      );
    }
  }

  Future<List<BalanceMovementData>> _fetchMovements({
    required List<String> accountIds,
  }) async {
    if (accountIds.isEmpty) {
      return <BalanceMovementData>[];
    }

    final List<dynamic> rows = await _client
        .from('balance_movements')
        .select(
          'id, account_id, type, amount_minor, occurred_at, payment_method, '
          'notes, created_at',
        )
        .eq('user_id', _user.id)
        .inFilter('account_id', accountIds)
        .order('occurred_at', ascending: false)
        .order('created_at', ascending: false);

    return rows
        .map((dynamic row) => _mapMovement(row as Map<String, dynamic>))
        .toList();
  }

  BalanceAccountData _mapAccount(
    Map<String, dynamic> row, {
    required List<BalanceMovementData> movements,
  }) {
    return BalanceAccountData(
      id: row['id'] as String,
      direction: BalanceDirectionX.fromDb(row['direction'] as String),
      name: row['name'] as String,
      counterpartyName: (row['counterparty_name'] as String?) ?? '',
      type: BalanceAccountTypeX.fromDb(row['type'] as String),
      openedAt: DateTime.parse(row['opened_at'] as String),
      status: BalanceAccountStatusX.fromDb(row['status'] as String),
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      movements: movements,
    );
  }

  BalanceMovementData _mapMovement(Map<String, dynamic> row) {
    return BalanceMovementData(
      id: row['id'] as String,
      accountId: row['account_id'] as String,
      type: BalanceMovementTypeX.fromDb(row['type'] as String),
      amountMinor: row['amount_minor'] as int,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      paymentMethod: BalancePaymentMethodX.fromDb(
        row['payment_method'] as String,
      ),
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  String _isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String? _normalizeOptionalText(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
