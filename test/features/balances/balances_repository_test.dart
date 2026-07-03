// ignore_for_file: invalid_use_of_internal_member

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/types.dart' show DomainValidationException;
import 'package:gider/data/app_repository.dart';
import 'package:gider/features/balances/data/balances_repository.dart';
import 'package:gider/features/balances/domain/balance_models.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _TestSupabaseClient extends SupabaseClient {
  _TestSupabaseClient({
    required GoTrueClient authClient,
    required http.Client httpClient,
  }) : _authClient = authClient,
       super('http://127.0.0.1:54321', 'test-anon-key', httpClient: httpClient);

  final GoTrueClient _authClient;

  @override
  GoTrueClient get auth => _authClient;
}

void main() {
  group('BalancesRepository', () {
    test(
      'initial opening amount creates movement and no transaction',
      () async {
        final List<String> requestedPaths = <String>[];
        Map<String, dynamic>? accountBody;
        Map<String, dynamic>? movementBody;
        final BalancesRepository repository = BalancesRepository(
          _buildClient((http.Request request) async {
            requestedPaths.add(request.url.path);
            if (request.url.path.endsWith('/rest/v1/transactions')) {
              fail('Balance account creation must not create transactions.');
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/balance_accounts')) {
              accountBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(
                request,
                _accountRow(movementsClosed: false),
                statusCode: 201,
              );
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/balance_movements')) {
              movementBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/balance_accounts')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                _accountRow(movementsClosed: false),
              ]);
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/balance_movements')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                _movementRow(
                  id: 'movement-opening',
                  type: 'increase',
                  amountMinor: 12500,
                ),
              ]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.createAccount(
          BalanceAccountDraft(
            direction: BalanceDirection.payable,
            name: '  Family loan  ',
            counterpartyName: '  Alex  ',
            type: BalanceAccountType.personal,
            openingAmountMinor: 12500,
            openedAt: DateTime(2026, 4, 20),
            notes: '  short term  ',
          ),
        );

        expect(accountBody, isNotNull);
        expect(accountBody!['user_id'], 'user-1');
        expect(accountBody!['direction'], 'payable');
        expect(accountBody!['name'], 'Family loan');
        expect(accountBody!['counterparty_name'], 'Alex');
        expect(accountBody!['type'], 'personal');
        expect(accountBody!['opened_at'], '2026-04-20');
        expect(accountBody!['status'], 'active');
        expect(accountBody!['notes'], 'short term');
        expect(movementBody, isNotNull);
        expect(movementBody!['account_id'], 'account-1');
        expect(movementBody!['type'], 'increase');
        expect(movementBody!['amount_minor'], 12500);
        expect(movementBody!['occurred_at'], '2026-04-20');
        expect(movementBody!['payment_method'], 'other');
        expect(
          requestedPaths.where((String path) => path.endsWith('/transactions')),
          isEmpty,
        );
      },
    );

    test('blank counterparty is optional and sent as null', () async {
      Map<String, dynamic>? accountBody;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            accountBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(
              request,
              _accountRow(movementsClosed: false, counterpartyName: null),
              statusCode: 201,
            );
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false, counterpartyName: null),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      final BalanceAccountData account = await repository.createAccount(
        BalanceAccountDraft(
          direction: BalanceDirection.payable,
          name: 'Family loan',
          counterpartyName: '   ',
          type: BalanceAccountType.personal,
          openingAmountMinor: 0,
          openedAt: DateTime(2026, 4, 20),
        ),
      );

      expect(accountBody, isNotNull);
      expect(accountBody!['counterparty_name'], isNull);
      expect(account.counterpartyName, isEmpty);
    });

    test('payable payment creates decrease movement', () async {
      Map<String, dynamic>? movementBody;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.url.path.endsWith('/rest/v1/transactions')) {
            fail('Balance payment must not create transactions.');
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 9000,
              ),
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            movementBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.addMovement(
        accountId: 'account-1',
        draft: BalanceMovementDraft(
          type: BalanceMovementType.decrease,
          amountMinor: 3000,
          occurredAt: DateTime(2026, 4, 25),
          paymentMethod: BalancePaymentMethod.cash,
        ),
      );

      expect(movementBody, isNotNull);
      expect(movementBody!['type'], 'decrease');
      expect(movementBody!['amount_minor'], 3000);
    });

    test('receivable collection creates decrease movement', () async {
      Map<String, dynamic>? movementBody;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.url.path.endsWith('/rest/v1/transactions')) {
            fail('Balance collection must not create transactions.');
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false, direction: 'receivable'),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 9000,
              ),
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            movementBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.addMovement(
        accountId: 'account-1',
        draft: BalanceMovementDraft(
          type: BalanceMovementType.decrease,
          amountMinor: 3000,
          occurredAt: DateTime(2026, 4, 25),
          paymentMethod: BalancePaymentMethod.cash,
        ),
      );

      expect(movementBody, isNotNull);
      expect(movementBody!['type'], 'decrease');
      expect(movementBody!['amount_minor'], 3000);
    });

    test('payment cannot exceed remaining balance', () async {
      bool insertCalled = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 2000,
              ),
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            insertCalled = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.addMovement(
          accountId: 'account-1',
          draft: BalanceMovementDraft(
            type: BalanceMovementType.decrease,
            amountMinor: 3000,
            occurredAt: DateTime(2026, 4, 25),
            paymentMethod: BalancePaymentMethod.cash,
          ),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'balance.remaining_negative',
          ),
        ),
      );
      expect(insertCalled, isFalse);
    });

    test('collection cannot exceed remaining balance', () async {
      bool insertCalled = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false, direction: 'receivable'),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 2000,
              ),
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            insertCalled = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.addMovement(
          accountId: 'account-1',
          draft: BalanceMovementDraft(
            type: BalanceMovementType.decrease,
            amountMinor: 3000,
            occurredAt: DateTime(2026, 4, 25),
            paymentMethod: BalancePaymentMethod.cash,
          ),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'balance.remaining_negative',
          ),
        ),
      );
      expect(insertCalled, isFalse);
    });

    test('rolls back account when opening movement insert fails', () async {
      bool deleteCalled = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.url.path.endsWith('/rest/v1/transactions')) {
            fail('Balance account creation must not create transactions.');
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(
              request,
              _accountRow(movementsClosed: false),
              statusCode: 201,
            );
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <String, dynamic>{
              'message': 'movement insert failed',
            }, statusCode: 500);
          }

          if (request.method == 'DELETE' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            deleteCalled = true;
            expect(request.url.queryParameters['id'], 'eq.account-1');
            expect(request.url.queryParameters['user_id'], 'eq.user-1');
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.createAccount(
          BalanceAccountDraft(
            direction: BalanceDirection.payable,
            name: 'Family loan',
            counterpartyName: 'Alex',
            type: BalanceAccountType.personal,
            openingAmountMinor: 12500,
            openedAt: DateTime(2026, 4, 20),
          ),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'balance.opening_movement_failed',
          ),
        ),
      );
      expect(deleteCalled, isTrue);
    });

    test('cannot close account if remaining balance is not zero', () async {
      bool patchCalled = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 9000,
              ),
              _movementRow(
                id: 'movement-2',
                type: 'decrease',
                amountMinor: 4000,
              ),
            ]);
          }

          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            patchCalled = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.closeAccount('account-1'),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'balance.close_requires_zero',
          ),
        ),
      );
      expect(patchCalled, isFalse);
    });

    test('can close account if remaining balance is zero', () async {
      Map<String, dynamic>? patchBody;
      Uri? patchUrl;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: true),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 9000,
              ),
              _movementRow(
                id: 'movement-2',
                type: 'decrease',
                amountMinor: 9000,
              ),
            ]);
          }

          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            patchUrl = request.url;
            patchBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.closeAccount('account-1');

      expect(patchBody, isNotNull);
      expect(patchBody!['status'], 'closed');
      expect(patchUrl!.queryParameters['id'], 'eq.account-1');
      expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
    });

    test('delete account is allowed when remaining balance is zero', () async {
      bool deleteCalled = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.url.path.endsWith('/rest/v1/transactions')) {
            fail('Balance account delete must not create transactions.');
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: true),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 9000,
              ),
              _movementRow(
                id: 'movement-2',
                type: 'decrease',
                amountMinor: 9000,
              ),
            ]);
          }

          if (request.method == 'DELETE' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            deleteCalled = true;
            expect(request.url.queryParameters['id'], 'eq.account-1');
            expect(request.url.queryParameters['user_id'], 'eq.user-1');
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.deleteAccount('account-1');

      expect(deleteCalled, isTrue);
    });

    test(
      'delete account is blocked when remaining balance is not zero',
      () async {
        bool deleteCalled = false;
        final BalancesRepository repository = BalancesRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/balance_accounts')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                _accountRow(movementsClosed: false),
              ]);
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/balance_movements')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                _movementRow(
                  id: 'movement-1',
                  type: 'increase',
                  amountMinor: 9000,
                ),
                _movementRow(
                  id: 'movement-2',
                  type: 'decrease',
                  amountMinor: 4000,
                ),
              ]);
            }

            if (request.method == 'DELETE' &&
                request.url.path.endsWith('/rest/v1/balance_accounts')) {
              deleteCalled = true;
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await expectLater(
          repository.deleteAccount('account-1'),
          throwsA(
            isA<DomainValidationException>().having(
              (DomainValidationException error) => error.code,
              'code',
              'balance.delete_requires_zero',
            ),
          ),
        );
        expect(deleteCalled, isFalse);
      },
    );

    test('account is removed from list after delete', () async {
      bool deleted = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(
              request,
              deleted
                  ? <Map<String, dynamic>>[]
                  : <Map<String, dynamic>>[_accountRow(movementsClosed: true)],
            );
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 9000,
              ),
              _movementRow(
                id: 'movement-2',
                type: 'decrease',
                amountMinor: 9000,
              ),
            ]);
          }

          if (request.method == 'DELETE' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            deleted = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      expect(await repository.fetchAccounts(), hasLength(1));

      await repository.deleteAccount('account-1');

      expect(await repository.fetchAccounts(), isEmpty);
    });

    test('account update patches editable fields only', () async {
      Map<String, dynamic>? patchBody;
      Uri? patchUrl;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.url.path.endsWith('/rest/v1/transactions')) {
            fail('Balance account update must not create transactions.');
          }

          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            patchUrl = request.url;
            patchBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.updateAccount(
        accountId: 'account-1',
        draft: BalanceAccountEditDraft(
          name: '  Updated loan  ',
          counterpartyName: '  Nazim  ',
          type: BalanceAccountType.bank,
          openedAt: DateTime(2026, 4, 21),
          notes: '  fixed note  ',
        ),
      );

      expect(patchUrl!.queryParameters['id'], 'eq.account-1');
      expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
      expect(patchBody, isNotNull);
      expect(patchBody!['name'], 'Updated loan');
      expect(patchBody!['counterparty_name'], 'Nazim');
      expect(patchBody!['type'], 'bank');
      expect(patchBody!['opened_at'], '2026-04-21');
      expect(patchBody!['notes'], 'fixed note');
      expect(patchBody!.containsKey('direction'), isFalse);
      expect(patchBody!.containsKey('status'), isFalse);
    });

    test(
      'movement update patches movement and does not create transaction',
      () async {
        Map<String, dynamic>? patchBody;
        Uri? patchUrl;
        final BalancesRepository repository = BalancesRepository(
          _buildClient((http.Request request) async {
            if (request.url.path.endsWith('/rest/v1/transactions')) {
              fail('Balance movement update must not create transactions.');
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/balance_accounts')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                _accountRow(movementsClosed: false),
              ]);
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/balance_movements')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                _movementRow(
                  id: 'movement-1',
                  type: 'increase',
                  amountMinor: 9000,
                ),
                _movementRow(
                  id: 'movement-2',
                  type: 'decrease',
                  amountMinor: 4000,
                ),
              ]);
            }

            if (request.method == 'PATCH' &&
                request.url.path.endsWith('/rest/v1/balance_movements')) {
              patchUrl = request.url;
              patchBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.updateMovement(
          accountId: 'account-1',
          movementId: 'movement-2',
          draft: BalanceMovementDraft(
            type: BalanceMovementType.decrease,
            amountMinor: 2500,
            occurredAt: DateTime(2026, 4, 22),
            paymentMethod: BalancePaymentMethod.bank,
            notes: '  corrected  ',
          ),
        );

        expect(patchUrl!.queryParameters['id'], 'eq.movement-2');
        expect(patchUrl!.queryParameters['account_id'], 'eq.account-1');
        expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
        expect(patchBody, isNotNull);
        expect(patchBody!['type'], 'decrease');
        expect(patchBody!['amount_minor'], 2500);
        expect(patchBody!['occurred_at'], '2026-04-22');
        expect(patchBody!['payment_method'], 'bank');
        expect(patchBody!['notes'], 'corrected');
      },
    );

    test(
      'movement delete deletes movement and does not create transaction',
      () async {
        bool deleteCalled = false;
        final BalancesRepository repository = BalancesRepository(
          _buildClient((http.Request request) async {
            if (request.url.path.endsWith('/rest/v1/transactions')) {
              fail('Balance movement delete must not create transactions.');
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/balance_accounts')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                _accountRow(movementsClosed: false),
              ]);
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/balance_movements')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                _movementRow(
                  id: 'movement-1',
                  type: 'increase',
                  amountMinor: 9000,
                ),
                _movementRow(
                  id: 'movement-2',
                  type: 'decrease',
                  amountMinor: 4000,
                ),
              ]);
            }

            if (request.method == 'DELETE' &&
                request.url.path.endsWith('/rest/v1/balance_movements')) {
              deleteCalled = true;
              expect(request.url.queryParameters['id'], 'eq.movement-2');
              expect(request.url.queryParameters['account_id'], 'eq.account-1');
              expect(request.url.queryParameters['user_id'], 'eq.user-1');
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.deleteMovement(
          accountId: 'account-1',
          movementId: 'movement-2',
        );

        expect(deleteCalled, isTrue);
      },
    );

    test('movement edit recalculates remaining balance', () async {
      bool updated = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 9000,
              ),
              _movementRow(
                id: 'movement-2',
                type: 'decrease',
                amountMinor: updated ? 2500 : 4000,
              ),
            ]);
          }

          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            updated = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.updateMovement(
        accountId: 'account-1',
        movementId: 'movement-2',
        draft: BalanceMovementDraft(
          type: BalanceMovementType.decrease,
          amountMinor: 2500,
          occurredAt: DateTime(2026, 4, 22),
          paymentMethod: BalancePaymentMethod.cash,
        ),
      );
      final BalanceAccountData? account = await repository.fetchAccount(
        'account-1',
      );

      expect(account!.remainingMinor, 6500);
    });

    test('negative remaining balance is blocked on movement update', () async {
      bool patchCalled = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 5000,
              ),
              _movementRow(
                id: 'movement-2',
                type: 'decrease',
                amountMinor: 3000,
              ),
            ]);
          }

          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            patchCalled = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.updateMovement(
          accountId: 'account-1',
          movementId: 'movement-1',
          draft: BalanceMovementDraft(
            type: BalanceMovementType.decrease,
            amountMinor: 5000,
            occurredAt: DateTime(2026, 4, 22),
            paymentMethod: BalancePaymentMethod.cash,
          ),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'balance.remaining_negative',
          ),
        ),
      );
      expect(patchCalled, isFalse);
    });

    test('negative remaining balance is blocked on movement delete', () async {
      bool deleteCalled = false;
      final BalancesRepository repository = BalancesRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_accounts')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _accountRow(movementsClosed: false),
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              _movementRow(
                id: 'movement-1',
                type: 'increase',
                amountMinor: 5000,
              ),
              _movementRow(
                id: 'movement-2',
                type: 'decrease',
                amountMinor: 3000,
              ),
            ]);
          }

          if (request.method == 'DELETE' &&
              request.url.path.endsWith('/rest/v1/balance_movements')) {
            deleteCalled = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.deleteMovement(
          accountId: 'account-1',
          movementId: 'movement-1',
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'balance.remaining_negative',
          ),
        ),
      );
      expect(deleteCalled, isFalse);
    });
  });

  test('adjustment is not exposed in balance movement UI', () {
    final String source = File(
      'lib/features/balances/presentation/balances_screen.dart',
    ).readAsStringSync();
    final RegExp movementValues = RegExp(
      r'values:\s*const\s*<BalanceMovementType>\[[\s\S]*?\]',
    );
    final Match? match = movementValues.firstMatch(source);

    expect(match, isNotNull);
    expect(match!.group(0), contains('BalanceMovementType.increase'));
    expect(match.group(0), contains('BalanceMovementType.decrease'));
    expect(match.group(0), isNot(contains('BalanceMovementType.adjustment')));
  });

  test('movement labels differ by account direction', () {
    const AppLocalizations strings = AppLocalizations(AppLocale.tr);
    const AppLocalizations english = AppLocalizations(AppLocale.en);

    expect(
      strings.balanceMovementActionLabel(
        BalanceDirection.payable,
        BalanceMovementType.increase,
      ),
      'Yeni borç ekle',
    );
    expect(
      strings.balanceMovementActionLabel(
        BalanceDirection.payable,
        BalanceMovementType.decrease,
      ),
      'Borç öde',
    );
    expect(
      strings.balanceMovementActionLabel(
        BalanceDirection.receivable,
        BalanceMovementType.increase,
      ),
      'Alacak ekle',
    );
    expect(
      strings.balanceMovementActionLabel(
        BalanceDirection.receivable,
        BalanceMovementType.decrease,
      ),
      'Tahsil et',
    );
    expect(
      english.balanceMovementActionLabel(
        BalanceDirection.payable,
        BalanceMovementType.increase,
      ),
      'Add new debt',
    );
    expect(
      english.balanceMovementActionLabel(
        BalanceDirection.receivable,
        BalanceMovementType.decrease,
      ),
      'Collect',
    );
  });

  test('delete account labels are localized', () {
    const AppLocalizations strings = AppLocalizations(AppLocale.tr);
    const AppLocalizations english = AppLocalizations(AppLocale.en);

    expect(strings.deleteBalanceAccount, 'Hesabı sil');
    expect(english.deleteBalanceAccount, 'Delete account');
    expect(
      strings.deleteBalanceAccountConfirmMessage,
      'Bu hesabı silmek istediğinize emin misiniz?',
    );
    expect(
      english.deleteBalanceAccountConfirmMessage,
      'Are you sure you want to delete this account?',
    );
    expect(
      strings.balanceDeleteRequiresZero,
      'Bu hesabı silmek için bakiye sıfır olmalı',
    );
    expect(
      english.balanceDeleteRequiresZero,
      'Balance must be zero to delete this account',
    );
  });

  group('existing summaries ignore balances', () {
    test('weekly summary does not query balance movements', () async {
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          _failOnBalanceTables(request);
          return _existingSummaryResponse(request);
        }),
        clock: () => DateTime(2026, 4, 22),
      );

      final snapshot = await repository.fetchDashboardSnapshot(
        const AppLocalizations(AppLocale.en),
      );

      expect(snapshot.incomeMinor, 0);
      expect(snapshot.expenseMinor, 0);
      expect(snapshot.netMinor, 0);
    });

    test('monthly report does not query balance movements', () async {
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          _failOnBalanceTables(request);
          return _existingSummaryResponse(request);
        }),
      );

      final dataset = await repository.fetchMonthlyReportsDataset(
        DateTime(2026, 4, 1),
      );

      expect(dataset.transactions, isEmpty);
    });
  });
}

void _failOnBalanceTables(http.Request request) {
  if (request.url.path.endsWith('/rest/v1/balance_accounts') ||
      request.url.path.endsWith('/rest/v1/balance_movements')) {
    fail('Existing summary/report code must not query balance tables.');
  }
}

Future<http.Response> _existingSummaryResponse(http.Request request) async {
  if (request.method == 'GET' &&
      request.url.path.endsWith('/rest/v1/categories') &&
      request.url.queryParameters['select']?.replaceAll(' ', '') ==
          'id,type,name') {
    return _jsonResponse(request, <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'cat-income',
        'type': 'income',
        'name': 'Cash Sales',
      },
      <String, dynamic>{'id': 'cat-expense', 'type': 'expense', 'name': 'Rent'},
    ]);
  }

  if (request.method == 'POST' &&
      request.url.path.endsWith('/rest/v1/categories')) {
    return _jsonResponse(request, <Map<String, dynamic>>[], statusCode: 201);
  }

  if (request.method == 'GET' &&
      request.url.path.endsWith('/rest/v1/transactions')) {
    return _jsonResponse(request, <Map<String, dynamic>>[]);
  }

  if (request.method == 'GET' &&
      request.url.path.endsWith('/rest/v1/recurring_expenses')) {
    return _jsonResponse(request, <Map<String, dynamic>>[]);
  }

  fail('Unexpected HTTP call: ${request.method} ${request.url}');
}

Map<String, dynamic> _accountRow({
  required bool movementsClosed,
  Object? counterpartyName = 'Alex',
  String direction = 'payable',
}) {
  return <String, dynamic>{
    'id': 'account-1',
    'direction': direction,
    'name': movementsClosed ? 'Closed account' : 'Family loan',
    'counterparty_name': counterpartyName,
    'type': 'personal',
    'opened_at': '2026-04-20',
    'status': 'active',
    'notes': null,
    'created_at': '2026-04-20T10:00:00Z',
    'updated_at': '2026-04-20T10:00:00Z',
  };
}

Map<String, dynamic> _movementRow({
  required String id,
  required String type,
  required int amountMinor,
}) {
  return <String, dynamic>{
    'id': id,
    'account_id': 'account-1',
    'type': type,
    'amount_minor': amountMinor,
    'occurred_at': '2026-04-20',
    'payment_method': 'cash',
    'notes': null,
    'created_at': '2026-04-20T10:00:00Z',
  };
}

_TestSupabaseClient _buildClient(
  Future<http.Response> Function(http.Request request) handler,
) {
  final _MockGoTrueClient authClient = _MockGoTrueClient();
  when(() => authClient.currentUser).thenReturn(
    const User(
      id: 'user-1',
      appMetadata: <String, dynamic>{},
      userMetadata: <String, dynamic>{},
      aud: 'authenticated',
      email: 'owner@example.com',
      createdAt: '2026-04-20T00:00:00Z',
    ),
  );
  when(
    () => authClient.onAuthStateChange,
  ).thenAnswer((_) => const Stream<AuthState>.empty());
  when(
    () => authClient.onAuthStateChangeSync,
  ).thenAnswer((_) => const Stream<AuthState>.empty());

  return _TestSupabaseClient(
    authClient: authClient,
    httpClient: MockClient(handler),
  );
}

http.Response _jsonResponse(
  http.Request request,
  Object body, {
  int statusCode = 200,
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    request: request,
    headers: <String, String>{'content-type': 'application/json'},
  );
}
