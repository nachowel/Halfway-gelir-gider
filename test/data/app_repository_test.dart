// ignore_for_file: invalid_use_of_internal_member

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/types.dart' show DomainValidationException;
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
import 'package:gider/data/local/app_database.dart';
import 'package:gider/data/local/outbox_repository.dart';
import 'package:gider/data/sync/sync_engine.dart';
import 'package:gider/data/sync/sync_service.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockSyncService extends Mock implements SyncService {}

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

class _FakeConnectivityProbe implements ConnectivityProbe {
  const _FakeConnectivityProbe(this.online);

  final bool online;

  @override
  Future<bool> isOnline() async => online;
}

void main() {
  group('GiderRepository boundary', () {
    test(
      'saveCategory rejects invalid category payload before update',
      () async {
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await expectLater(
          repository.saveCategory(
            id: 'category-1',
            type: CategoryType.expense,
            name: '   ',
          ),
          throwsA(
            isA<DomainValidationException>().having(
              (DomainValidationException error) => error.code,
              'code',
              'category_name.required',
            ),
          ),
        );
      },
    );

    test('saveCategory creates trimmed category payload', () async {
      Map<String, dynamic>? requestBody;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'id,type,name') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'seed-expense',
                'type': 'expense',
                'name': 'Rent',
              },
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] ==
                  'id,type,name,icon,color_token,is_archived,sort_order') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'seed-expense',
                'type': 'expense',
                'name': 'Rent',
                'icon': 'home_rounded',
                'color_token': 'expense',
                'is_archived': false,
                'sort_order': 0,
              },
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/categories')) {
            final Object decoded = jsonDecode(request.body);
            if (decoded is List<dynamic> && decoded.length > 1) {
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }
            requestBody = decoded is List<dynamic>
                ? decoded.single as Map<String, dynamic>
                : decoded as Map<String, dynamic>;
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.saveCategory(
        type: CategoryType.expense,
        name: '  Packaging  ',
      );

      expect(requestBody, isNotNull);
      expect(requestBody!['user_id'], 'user-1');
      expect(requestBody!['type'], 'expense');
      expect(requestBody!['name'], 'Packaging');
      expect(requestBody!['color_token'], 'expense');
      expect(requestBody!['sort_order'], 1);
    });

    test(
      'saveCategory updates existing row via PATCH with trimmed name',
      () async {
        Map<String, dynamic>? patchBody;
        Uri? patchUrl;
        bool postCalled = false;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'PATCH' &&
                request.url.path.endsWith('/rest/v1/categories')) {
              patchUrl = request.url;
              patchBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/categories')) {
              postCalled = true;
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.saveCategory(
          id: 'category-1',
          type: CategoryType.expense,
          name: '  Packaging  ',
        );

        expect(postCalled, isFalse);
        expect(patchBody, isNotNull);
        expect(patchBody!.keys, <String>['name']);
        expect(patchBody!['name'], 'Packaging');
        expect(patchUrl, isNotNull);
        expect(patchUrl!.queryParameters['id'], 'eq.category-1');
        expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
      },
    );

    test('archiveCategory marks remote row archived', () async {
      Map<String, dynamic>? requestBody;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/categories')) {
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.archiveCategory(id: 'category-1');

      expect(requestBody, isNotNull);
      expect(requestBody!['is_archived'], isTrue);
    });

    test(
      'createTransaction rejects transaction/category type mismatch',
      () async {
        bool insertCalled = false;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'type') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{'type': 'expense'},
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              insertCalled = true;
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await expectLater(
          repository.createTransaction(
            EntryDraft(
              type: TransactionType.income,
              occurredOn: DateTime(2026, 4, 20),
              amountMinor: 1200,
              categoryId: 'category-1',
              paymentMethod: PaymentMethodType.cash,
            ),
          ),
          throwsA(
            isA<DomainValidationException>().having(
              (DomainValidationException error) => error.code,
              'code',
              'transaction.category_type_mismatch',
            ),
          ),
        );

        expect(insertCalled, isFalse);
      },
    );

    test('createTransaction posts a GBP expense payload', () async {
      Map<String, dynamic>? requestBody;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'type') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{'type': 'expense'},
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.createTransaction(
        EntryDraft(
          type: TransactionType.expense,
          occurredOn: DateTime(2026, 4, 20),
          amountMinor: 8500,
          categoryId: 'category-1',
          paymentMethod: PaymentMethodType.card,
          vendor: 'Bakery Co',
          note: 'weekly stock',
        ),
      );

      expect(requestBody, isNotNull);
      expect(requestBody!['user_id'], 'user-1');
      expect(requestBody!['type'], 'expense');
      expect(requestBody!['occurred_on'], '2026-04-20');
      expect(requestBody!['amount_minor'], 8500);
      expect(requestBody!['currency'], 'GBP');
      expect(requestBody!['category_id'], 'category-1');
      expect(requestBody!['payment_method'], 'card');
      expect(requestBody!['source_platform'], isNull);
      expect(requestBody!['vendor'], 'Bakery Co');
      expect(requestBody!['supplier_id'], isNull);
      expect(requestBody!['note'], 'weekly stock');
    });

    test(
      'createTransaction preserves supplier_id and vendor for expense payloads',
      () async {
        Map<String, dynamic>? requestBody;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'type') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{'type': 'expense'},
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              requestBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.createTransaction(
          EntryDraft(
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 20),
            amountMinor: 8500,
            categoryId: 'category-1',
            paymentMethod: PaymentMethodType.card,
            vendor: 'Bakery Co',
            supplierId: 'supplier-1',
          ),
        );

        expect(requestBody, isNotNull);
        expect(requestBody!['vendor'], 'Bakery Co');
        expect(requestBody!['supplier_id'], 'supplier-1');
      },
    );

    test(
      'createTransaction preserves source_platform for Uber settlement',
      () async {
        Map<String, dynamic>? requestBody;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'type') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{'type': 'income'},
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              requestBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.createTransaction(
          EntryDraft(
            type: TransactionType.income,
            occurredOn: DateTime(2026, 4, 19),
            amountMinor: 124000,
            categoryId: 'category-1',
            paymentMethod: PaymentMethodType.bankTransfer,
            sourcePlatform: SourcePlatformType.uber,
          ),
        );

        expect(requestBody, isNotNull);
        expect(requestBody!['type'], 'income');
        expect(requestBody!['source_platform'], 'uber');
        expect(requestBody!['payment_method'], 'bank_transfer');
        expect(requestBody!['occurred_on'], '2026-04-19');
        expect(requestBody!['supplier_id'], isNull);
      },
    );

    test('createTransaction rejects supplier_id on income payloads', () async {
      bool insertCalled = false;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'type') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{'type': 'income'},
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            insertCalled = true;
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.createTransaction(
          EntryDraft(
            type: TransactionType.income,
            occurredOn: DateTime(2026, 4, 19),
            amountMinor: 124000,
            categoryId: 'category-1',
            paymentMethod: PaymentMethodType.bankTransfer,
            sourcePlatform: SourcePlatformType.uber,
            supplierId: 'supplier-1',
          ),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'transaction.supplier_expense_only',
          ),
        ),
      );

      expect(insertCalled, isFalse);
    });

    test('updateTransaction patches all draft fields on owned row', () async {
      Map<String, dynamic>? patchBody;
      Uri? patchUrl;
      bool postCalled = false;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'type') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{'type': 'income'},
            ]);
          }

          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            patchUrl = request.url;
            patchBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            postCalled = true;
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.updateTransaction(
        id: 'tx-1',
        draft: EntryDraft(
          type: TransactionType.income,
          occurredOn: DateTime(2026, 4, 19),
          amountMinor: 156000,
          categoryId: 'category-1',
          paymentMethod: PaymentMethodType.card,
          sourcePlatform: SourcePlatformType.justEat,
          note: 'settlement correction',
        ),
      );

      expect(postCalled, isFalse);
      expect(patchBody, isNotNull);
      expect(patchBody!['type'], 'income');
      expect(patchBody!['occurred_on'], '2026-04-19');
      expect(patchBody!['amount_minor'], 156000);
      expect(patchBody!['currency'], 'GBP');
      expect(patchBody!['category_id'], 'category-1');
      expect(patchBody!['payment_method'], 'card');
      expect(patchBody!['source_platform'], 'just_eat');
      expect(patchBody!['note'], 'settlement correction');
      expect(patchBody!['supplier_id'], isNull);
      expect(patchBody!.containsKey('user_id'), isFalse);
      expect(patchUrl, isNotNull);
      expect(patchUrl!.queryParameters['id'], 'eq.tx-1');
      expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
    });

    test(
      'updateTransaction preserves supplier_id and vendor for expense payloads',
      () async {
        Map<String, dynamic>? patchBody;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'type') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{'type': 'expense'},
              ]);
            }

            if (request.method == 'PATCH' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              patchBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.updateTransaction(
          id: 'tx-1',
          draft: EntryDraft(
            type: TransactionType.expense,
            occurredOn: DateTime(2026, 4, 19),
            amountMinor: 156000,
            categoryId: 'category-1',
            paymentMethod: PaymentMethodType.card,
            vendor: 'Wholesale Ltd',
            supplierId: 'supplier-1',
            note: 'restock',
          ),
        );

        expect(patchBody, isNotNull);
        expect(patchBody!['vendor'], 'Wholesale Ltd');
        expect(patchBody!['supplier_id'], 'supplier-1');
      },
    );

    test('deleteTransaction soft-deletes via deleted_at PATCH', () async {
      Map<String, dynamic>? patchBody;
      Uri? patchUrl;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            patchUrl = request.url;
            patchBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.deleteTransaction(id: 'tx-1');

      expect(patchBody, isNotNull);
      expect(patchBody!.keys, <String>['deleted_at']);
      expect(patchBody!['deleted_at'], isA<String>());
      expect(DateTime.tryParse(patchBody!['deleted_at'] as String), isNotNull);
      expect(patchUrl, isNotNull);
      expect(patchUrl!.queryParameters['id'], 'eq.tx-1');
      expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
    });

    test('createTransaction queues to outbox when offline', () async {
      final AppDatabase database = AppDatabase(
        executor: NativeDatabase.memory(),
      );
      addTearDown(database.close);
      final OutboxRepository outboxRepository = OutboxRepository(database);
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'type,name') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{'type': 'expense', 'name': 'Rent'},
            ]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
        outboxRepository: outboxRepository,
        connectivityProbe: const _FakeConnectivityProbe(false),
      );

      await repository.createTransaction(
        EntryDraft(
          type: TransactionType.expense,
          occurredOn: DateTime(2026, 4, 20),
          amountMinor: 8500,
          categoryId: 'category-1',
          paymentMethod: PaymentMethodType.card,
        ),
      );

      final List<PendingOutboxEntry> entries = await outboxRepository
          .pendingEntries();
      expect(entries, hasLength(1));
      expect(entries.single.operation, OutboxOperationType.createTransaction);
    });

    test(
      'createTransaction throws when online sync leaves queued entry incomplete',
      () async {
        final AppDatabase database = AppDatabase(
          executor: NativeDatabase.memory(),
        );
        addTearDown(database.close);
        final OutboxRepository outboxRepository = OutboxRepository(database);
        final _MockSyncService syncService = _MockSyncService();
        when(
          () => syncService.syncNow(maxEntries: any(named: 'maxEntries')),
        ).thenAnswer(
          (_) async => const SyncRunResult(
            recoveredStaleProcessing: 0,
            processedEntries: 0,
            succeededEntries: 0,
            alreadyAppliedEntries: 0,
            retryableFailures: 0,
            nonRetryableFailures: 0,
          ),
        );

        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'type,name') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{'type': 'income', 'name': 'Card Sales'},
              ]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
          outboxRepository: outboxRepository,
          connectivityProbe: const _FakeConnectivityProbe(true),
          syncService: syncService,
        );

        await expectLater(
          repository.createTransaction(
            EntryDraft(
              type: TransactionType.income,
              occurredOn: DateTime(2026, 4, 20),
              amountMinor: 8500,
              categoryId: 'category-1',
              paymentMethod: PaymentMethodType.card,
            ),
          ),
          throwsA(isA<Exception>()),
        );

        final List<PendingOutboxEntry> entries = await outboxRepository
            .pendingEntries();
        expect(entries, hasLength(1));
        expect(entries.single.operation, OutboxOperationType.createTransaction);
        verify(() => syncService.syncNow(maxEntries: 20)).called(1);
      },
    );

    test('updateTransaction queues to outbox when offline', () async {
      final AppDatabase database = AppDatabase(
        executor: NativeDatabase.memory(),
      );
      addTearDown(database.close);
      final OutboxRepository outboxRepository = OutboxRepository(database);
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'type,name') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{'type': 'income', 'name': 'Card Sales'},
            ]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
        outboxRepository: outboxRepository,
        connectivityProbe: const _FakeConnectivityProbe(false),
      );

      await repository.updateTransaction(
        id: 'tx-offline-update',
        draft: EntryDraft(
          type: TransactionType.income,
          occurredOn: DateTime(2026, 4, 21),
          amountMinor: 156000,
          categoryId: 'category-1',
          paymentMethod: PaymentMethodType.card,
        ),
      );

      final List<PendingOutboxEntry> entries = await outboxRepository
          .pendingEntries();
      expect(entries, hasLength(1));
      expect(entries.single.operation, OutboxOperationType.updateTransaction);
      expect(entries.single.entityId, 'tx-offline-update');
    });

    test('deleteTransaction queues to outbox when offline', () async {
      final AppDatabase database = AppDatabase(
        executor: NativeDatabase.memory(),
      );
      addTearDown(database.close);
      final OutboxRepository outboxRepository = OutboxRepository(database);
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
        outboxRepository: outboxRepository,
        connectivityProbe: const _FakeConnectivityProbe(false),
      );

      await repository.deleteTransaction(id: 'tx-offline-delete');

      final List<PendingOutboxEntry> entries = await outboxRepository
          .pendingEntries();
      expect(entries, hasLength(1));
      expect(entries.single.operation, OutboxOperationType.deleteTransaction);
      expect(entries.single.entityId, 'tx-offline-delete');
    });

    test(
      'fetchReportsSnapshot computes monthly totals and expense-only breakdown in descending order',
      () async {
        String isoDate(DateTime value) {
          final String year = value.year.toString().padLeft(4, '0');
          final String month = value.month.toString().padLeft(2, '0');
          final String day = value.day.toString().padLeft(2, '0');
          return '$year-$month-$day';
        }

        Map<String, dynamic> txRow({
          required String id,
          required String type,
          required int amountMinor,
          required DateTime occurredOn,
          required String categoryName,
          required String categoryType,
        }) {
          return <String, dynamic>{
            'id': id,
            'type': type,
            'occurred_on': isoDate(occurredOn),
            'amount_minor': amountMinor,
            'currency': 'GBP',
            'payment_method': 'card',
            'source_platform': null,
            'note': null,
            'vendor': null,
            'attachment_path': null,
            'recurring_expense_id': null,
            'created_at': '2026-04-21T08:00:00Z',
            'category': <String, dynamic>{
              'id': 'cat-$id',
              'name': categoryName,
              'type': categoryType,
            },
          };
        }

        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'id,type,name') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'cat-income',
                  'type': 'income',
                  'name': 'Card Sales',
                },
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/categories')) {
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                txRow(
                  id: 'income-1',
                  type: 'income',
                  amountMinor: 220000,
                  occurredOn: DateTime(2026, 4, 3),
                  categoryName: 'Card Sales',
                  categoryType: 'income',
                ),
                txRow(
                  id: 'income-2',
                  type: 'income',
                  amountMinor: 40000,
                  occurredOn: DateTime(2026, 4, 18),
                  categoryName: 'Uber Settlement',
                  categoryType: 'income',
                ),
                txRow(
                  id: 'expense-1',
                  type: 'expense',
                  amountMinor: 85000,
                  occurredOn: DateTime(2026, 4, 5),
                  categoryName: 'Rent',
                  categoryType: 'expense',
                ),
                txRow(
                  id: 'expense-2',
                  type: 'expense',
                  amountMinor: 12000,
                  occurredOn: DateTime(2026, 4, 10),
                  categoryName: 'Fuel',
                  categoryType: 'expense',
                ),
                txRow(
                  id: 'expense-3',
                  type: 'expense',
                  amountMinor: 18000,
                  occurredOn: DateTime(2026, 4, 16),
                  categoryName: 'Fuel',
                  categoryType: 'expense',
                ),
              ]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final ReportsSnapshot snapshot = await repository.fetchReportsSnapshot(
          DateTime(2026, 4, 21),
          const AppLocalizations(AppLocale.tr),
        );

        expect(snapshot.monthLabel, 'Nisan');
        expect(snapshot.yearLabel, '2026');
        expect(snapshot.incomeMinor, 260000);
        expect(snapshot.expenseMinor, 115000);
        expect(snapshot.netMinor, 145000);
        expect(
          snapshot.breakdown.map(
            (ReportBreakdownItem item) => item.categoryName,
          ),
          <String>['Rent', 'Fuel'],
        );
        expect(
          snapshot.breakdown.map(
            (ReportBreakdownItem item) => item.amountMinor,
          ),
          <int>[85000, 30000],
        );
      },
    );

    test(
      'fetchMonthlyReportsDataset returns raw transaction window plus category icon maps',
      () async {
        String isoDate(DateTime value) {
          final String year = value.year.toString().padLeft(4, '0');
          final String month = value.month.toString().padLeft(2, '0');
          final String day = value.day.toString().padLeft(2, '0');
          return '$year-$month-$day';
        }

        Map<String, dynamic> txRow({
          required String id,
          required String type,
          required int amountMinor,
          required DateTime occurredOn,
          required String categoryName,
          required String categoryType,
        }) {
          return <String, dynamic>{
            'id': id,
            'type': type,
            'occurred_on': isoDate(occurredOn),
            'amount_minor': amountMinor,
            'currency': 'GBP',
            'payment_method': 'card',
            'source_platform': null,
            'note': null,
            'vendor': null,
            'attachment_path': null,
            'recurring_expense_id': null,
            'created_at': '2026-04-21T08:00:00Z',
            'category': <String, dynamic>{
              'id': 'cat-$id',
              'name': categoryName,
              'type': categoryType,
            },
          };
        }

        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'id,type,name') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'cat-income',
                  'type': 'income',
                  'name': 'Card Sales',
                },
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/categories')) {
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                txRow(
                  id: 'income-1',
                  type: 'income',
                  amountMinor: 220000,
                  occurredOn: DateTime(2026, 4, 3),
                  categoryName: 'Card Sales',
                  categoryType: 'income',
                ),
                txRow(
                  id: 'expense-1',
                  type: 'expense',
                  amountMinor: 85000,
                  occurredOn: DateTime(2026, 4, 5),
                  categoryName: 'Rent',
                  categoryType: 'expense',
                ),
              ]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final MonthlyReportsDataset dataset = await repository
            .fetchMonthlyReportsDataset(
              DateTime(2026, 4, 21),
              trendMonthCount: 4,
            );

        expect(dataset.selectedMonth, DateTime(2026, 4, 1));
        expect(dataset.trendMonthCount, 4);
        expect(dataset.transactions, hasLength(2));
        expect(dataset.expenseCategoryIcons['Rent'], Icons.home_rounded);
        expect(
          dataset.incomeCategoryIcons['Card Sales'],
          Icons.payments_rounded,
        );
      },
    );

    test('createRecurringExpense rejects invalid recurring payload', () async {
      bool insertCalled = false;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'type') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{'type': 'expense'},
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/recurring_expenses')) {
            insertCalled = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.createRecurringExpense(
          RecurringDraft(
            name: '   ',
            categoryId: 'category-1',
            amountMinor: 85000,
            frequency: RecurringFrequencyType.monthly,
            nextDueOn: DateTime(2026, 5, 1),
          ),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'recurring_name.required',
          ),
        ),
      );

      expect(insertCalled, isFalse);
    });

    test('fetchTransactions rejects invalid remote row parse', () async {
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'id,type,name') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'seed-category',
                'type': 'expense',
                'name': 'Rent',
              },
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/categories')) {
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'tx-1',
                'type': 'income',
                'occurred_on': '2026-04-20',
                'amount_minor': 1200,
                'currency': 'GBP',
                'payment_method': 'cash',
                'source_platform': null,
                'note': null,
                'vendor': null,
                'attachment_path': null,
                'recurring_expense_id': null,
                'created_at': '2026-04-20T10:00:00Z',
                'category': <String, dynamic>{
                  'id': 'category-1',
                  'name': 'Rent',
                  'type': 'expense',
                },
              },
            ]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.fetchTransactions(),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException error) => error.code,
            'code',
            'transaction.category_type_mismatch',
          ),
        ),
      );
    });

    test(
      'fetchBusinessSettings returns bootstrap-incomplete when settings row missing',
      () async {
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/profiles')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'email': 'owner@example.com',
                  'full_name': null,
                },
              ]);
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/business_settings')) {
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final BusinessSettingsData settings = await repository
            .fetchBusinessSettings();

        expect(settings.businessName, 'owner');
        expect(settings.isBootstrapComplete, isFalse);
        expect(settings.currency, 'GBP');
        expect(settings.timezone, 'Europe/London');
        expect(settings.weekStartsOn, 1);
      },
    );

    test(
      'fetchTransactions falls back when supplier relation is missing from schema cache',
      () async {
        int transactionRequestCount = 0;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'id,type,name') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'seed-income',
                  'type': 'income',
                  'name': 'Cash Sales',
                },
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/categories')) {
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              transactionRequestCount += 1;
              if (transactionRequestCount == 1) {
                expect(
                  request.url.queryParameters['select'],
                  contains('supplier:suppliers(id,name)'),
                );
                return _jsonResponse(request, <String, dynamic>{
                  'code': 'PGRST200',
                  'message':
                      "Could not find a relationship between 'transactions' and 'suppliers' in the schema cache",
                  'details': null,
                  'hint': null,
                }, statusCode: 400);
              }

              expect(
                request.url.queryParameters['select'],
                isNot(contains('supplier:suppliers(id,name)')),
              );
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'tx-1',
                  'type': 'income',
                  'occurred_on': '2026-04-20',
                  'amount_minor': 1200,
                  'currency': 'GBP',
                  'payment_method': 'cash',
                  'source_platform': null,
                  'note': null,
                  'vendor': null,
                  'attachment_path': null,
                  'recurring_expense_id': null,
                  'supplier_id': 'supplier-1',
                  'created_at': '2026-04-20T10:00:00Z',
                  'category': <String, dynamic>{
                    'id': 'category-1',
                    'name': 'Cash Sales',
                    'type': 'income',
                  },
                },
              ]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final List<TransactionData> transactions = await repository
            .fetchTransactions();

        expect(transactionRequestCount, 2);
        expect(transactions, hasLength(1));
        expect(transactions.single.id, 'tx-1');
        expect(transactions.single.supplierId, 'supplier-1');
        expect(transactions.single.supplierName, isNull);
      },
    );

    test(
      'fetchTransaction falls back when supplier relation is missing from schema cache',
      () async {
        int transactionRequestCount = 0;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              transactionRequestCount += 1;
              if (transactionRequestCount == 1) {
                expect(
                  request.url.queryParameters['select'],
                  contains('supplier:suppliers(id,name)'),
                );
                return _jsonResponse(request, <String, dynamic>{
                  'code': 'PGRST200',
                  'message':
                      "Could not find a relationship between 'transactions' and 'suppliers' in the schema cache",
                  'details': null,
                  'hint': null,
                }, statusCode: 400);
              }

              expect(
                request.url.queryParameters['select'],
                isNot(contains('supplier:suppliers(id,name)')),
              );
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'tx-1',
                  'type': 'expense',
                  'occurred_on': '2026-04-20',
                  'amount_minor': 5000,
                  'currency': 'GBP',
                  'payment_method': 'card',
                  'source_platform': null,
                  'note': 'stock run',
                  'vendor': 'Wholesale Ltd',
                  'attachment_path': null,
                  'recurring_expense_id': null,
                  'supplier_id': 'supplier-1',
                  'created_at': '2026-04-20T10:00:00Z',
                  'category': <String, dynamic>{
                    'id': 'category-1',
                    'name': 'Supplies',
                    'type': 'expense',
                  },
                },
              ]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final TransactionData? transaction = await repository.fetchTransaction(
          id: 'tx-1',
        );

        expect(transactionRequestCount, 2);
        expect(transaction, isNotNull);
        expect(transaction!.id, 'tx-1');
        expect(transaction.supplierId, 'supplier-1');
        expect(transaction.supplierName, isNull);
      },
    );

    test('fetchTransactions maps supplier relation for historical expense rows', () async {
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'id,type,name') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'seed-expense',
                'type': 'expense',
                'name': 'Rent',
              },
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/categories')) {
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            expect(
              request.url.queryParameters['select'],
              contains('supplier:suppliers(id,name)'),
            );
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'tx-joined',
                'type': 'expense',
                'occurred_on': '2026-04-20',
                'amount_minor': 5000,
                'currency': 'GBP',
                'payment_method': 'card',
                'source_platform': null,
                'note': 'stock run',
                'vendor': 'Wholesale Ltd',
                'attachment_path': null,
                'recurring_expense_id': null,
                'supplier_id': 'supplier-joined',
                'created_at': '2026-04-20T10:00:00Z',
                'category': <String, dynamic>{
                  'id': 'category-1',
                  'name': 'Supplies',
                  'type': 'expense',
                },
                'supplier': <String, dynamic>{
                  'id': 'supplier-joined',
                  'name': 'Archived Supplier',
                },
              },
            ]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      final List<TransactionData> transactions = await repository
          .fetchTransactions(type: TransactionType.expense);

      expect(transactions, hasLength(1));
      expect(transactions.single.id, 'tx-joined');
      expect(transactions.single.vendor, 'Wholesale Ltd');
      expect(transactions.single.supplierId, 'supplier-joined');
      expect(transactions.single.supplierName, 'Archived Supplier');
    });

    test(
      'fetchBusinessSettings does not write on read when profile is missing',
      () async {
        final GiderRepository repository = GiderRepository(
          _buildClient(
            (http.Request request) async {
              if (request.method == 'GET' &&
                  request.url.path.endsWith('/rest/v1/profiles')) {
                return _jsonResponse(request, <Map<String, dynamic>>[]);
              }

              if (request.method == 'GET' &&
                  request.url.path.endsWith('/rest/v1/business_settings')) {
                return _jsonResponse(request, <Map<String, dynamic>>[]);
              }

              fail('Unexpected HTTP call: ${request.method} ${request.url}');
            },
            currentUser: const User(
              id: 'user-1',
              appMetadata: <String, dynamic>{},
              userMetadata: <String, dynamic>{'full_name': 'Little Lane Deli'},
              aud: 'authenticated',
              email: 'owner@example.com',
              createdAt: '2026-04-20T00:00:00Z',
            ),
          ),
        );

        final BusinessSettingsData settings = await repository
            .fetchBusinessSettings();

        expect(settings.businessName, 'owner');
        expect(settings.isBootstrapComplete, isFalse);
      },
    );

    test(
      'fetchBusinessSettings reports bootstrap complete when business_name is set',
      () async {
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/profiles')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'email': 'owner@example.com',
                  'full_name': 'Little Lane Deli',
                },
              ]);
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/business_settings')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'business_name': 'Little Lane Deli',
                  'timezone': 'Europe/London',
                  'currency': 'GBP',
                  'week_starts_on': 1,
                },
              ]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final BusinessSettingsData settings = await repository
            .fetchBusinessSettings();

        expect(settings.businessName, 'Little Lane Deli');
        expect(settings.isBootstrapComplete, isTrue);
      },
    );

    test(
      'updateBusinessName patches existing row and does not upsert',
      () async {
        Map<String, dynamic>? patchBody;
        Uri? patchUrl;
        bool postCalled = false;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'PATCH' &&
                request.url.path.endsWith('/rest/v1/business_settings')) {
              patchUrl = request.url;
              patchBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{'user_id': 'user-1'},
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/business_settings')) {
              postCalled = true;
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.updateBusinessName('  Little Lane Deli  ');

        expect(postCalled, isFalse);
        expect(patchBody, isNotNull);
        expect(patchBody!.keys, <String>['business_name']);
        expect(patchBody!['business_name'], 'Little Lane Deli');
        expect(patchUrl, isNotNull);
        expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
      },
    );

    test(
      'updateBusinessName falls back to upsert onConflict=user_id when 0 rows match',
      () async {
        Map<String, dynamic>? postBody;
        Uri? postUrl;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'PATCH' &&
                request.url.path.endsWith('/rest/v1/business_settings')) {
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/business_settings')) {
              postUrl = request.url;
              postBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await repository.updateBusinessName('Little Lane Deli');

        expect(postBody, isNotNull);
        expect(postBody!['user_id'], 'user-1');
        expect(postBody!['business_name'], 'Little Lane Deli');
        expect(postUrl, isNotNull);
        expect(postUrl!.queryParameters['on_conflict'], 'user_id');
      },
    );

    test('signUp does not write to business_settings or profiles', () async {
      final _MockGoTrueClient authClient = _MockGoTrueClient();
      when(
        () => authClient.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => AuthResponse(
          user: const User(
            id: 'user-1',
            appMetadata: <String, dynamic>{},
            userMetadata: <String, dynamic>{'full_name': 'Little Lane Deli'},
            aud: 'authenticated',
            email: 'owner@example.com',
            createdAt: '2026-04-20T00:00:00Z',
          ),
        ),
      );
      when(
        () => authClient.onAuthStateChange,
      ).thenAnswer((_) => const Stream<AuthState>.empty());
      when(
        () => authClient.onAuthStateChangeSync,
      ).thenAnswer((_) => const Stream<AuthState>.empty());
      when(() => authClient.currentUser).thenReturn(null);

      final _TestSupabaseClient client = _TestSupabaseClient(
        authClient: authClient,
        httpClient: MockClient((http.Request request) async {
          fail(
            'signUp must not hit REST endpoints (trigger owns bootstrap). '
            'Got ${request.method} ${request.url}',
          );
        }),
      );
      final GiderRepository repository = GiderRepository(client);

      await repository.signUp(
        email: 'owner@example.com',
        password: 'correct horse battery staple',
        businessName: 'Little Lane Deli',
      );

      final VerificationResult captured = verify(
        () => authClient.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: captureAny(named: 'data'),
        ),
      )..called(1);
      final Map<String, dynamic> data =
          captured.captured.single as Map<String, dynamic>;
      expect(data['full_name'], 'Little Lane Deli');
    });

    test('createRecurringExpense posts valid payload', () async {
      Map<String, dynamic>? requestBody;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          // category type lookup (select=type)
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              (request.url.queryParameters['select'] == 'type' ||
                  request.url.queryParameters['select'] == 'id,type,name')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'cat-expense',
                'type': 'expense',
                'name': 'Rent',
              },
            ]);
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/recurring_expenses')) {
            final Object decoded = jsonDecode(request.body);
            requestBody = decoded is List<dynamic>
                ? decoded.single as Map<String, dynamic>
                : decoded as Map<String, dynamic>;
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }
          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.createRecurringExpense(
        RecurringDraft(
          name: '  Rent  ',
          categoryId: 'cat-expense',
          amountMinor: 85000,
          frequency: RecurringFrequencyType.monthly,
          nextDueOn: DateTime(2026, 5, 1),
          reserveEnabled: true,
        ),
      );

      expect(requestBody, isNotNull);
      expect(requestBody!['name'], 'Rent');
      expect(requestBody!['amount_minor'], 85000);
      expect(requestBody!['frequency'], 'monthly');
      expect(requestBody!['is_active'], true);
      expect(requestBody!['reserve_enabled'], true);
      expect(requestBody!['user_id'], 'user-1');
    });

    test('updateRecurringExpense patches via PATCH', () async {
      Map<String, dynamic>? patchBody;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              (request.url.queryParameters['select'] == 'type' ||
                  request.url.queryParameters['select'] == 'id,type,name')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'cat-expense',
                'type': 'expense',
                'name': 'Rent',
              },
            ]);
          }
          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/recurring_expenses')) {
            patchBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }
          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.updateRecurringExpense(
        id: 'rec-1',
        draft: RecurringDraft(
          name: 'Rent updated',
          categoryId: 'cat-expense',
          amountMinor: 90000,
          frequency: RecurringFrequencyType.monthly,
          nextDueOn: DateTime(2026, 6, 1),
          reserveEnabled: true,
        ),
      );

      expect(patchBody, isNotNull);
      expect(patchBody!['name'], 'Rent updated');
      expect(patchBody!['amount_minor'], 90000);
      expect(patchBody!['frequency'], 'monthly');
      expect(patchBody!['reserve_enabled'], true);
    });

    test(
      'fetchDashboardSnapshot computes weekly totals and delta with bank transfer income',
      () async {
        final DateTime today = DateTime.now();
        final DateTime normalizedToday = DateTime(
          today.year,
          today.month,
          today.day,
        );
        String isoDate(DateTime value) {
          final String year = value.year.toString().padLeft(4, '0');
          final String month = value.month.toString().padLeft(2, '0');
          final String day = value.day.toString().padLeft(2, '0');
          return '$year-$month-$day';
        }

        Map<String, dynamic> txRow({
          required String id,
          required String type,
          required int amountMinor,
          required String paymentMethod,
          required DateTime occurredOn,
          required String createdAt,
          String categoryName = 'Sales',
          String categoryType = 'income',
          String? vendor,
        }) {
          return <String, dynamic>{
            'id': id,
            'type': type,
            'occurred_on': isoDate(occurredOn),
            'amount_minor': amountMinor,
            'currency': 'GBP',
            'payment_method': paymentMethod,
            'source_platform': null,
            'note': null,
            'vendor': vendor,
            'attachment_path': null,
            'recurring_expense_id': null,
            'created_at': createdAt,
            'category': <String, dynamic>{
              'id': 'cat-${categoryType == 'income' ? 'income' : 'expense'}',
              'name': categoryName,
              'type': categoryType,
            },
          };
        }

        final List<Map<String, dynamic>> currentWeekRows =
            <Map<String, dynamic>>[
              txRow(
                id: 'tx-cash',
                type: 'income',
                amountMinor: 12000,
                paymentMethod: 'cash',
                occurredOn: normalizedToday,
                createdAt: '2026-04-21T08:00:00Z',
                vendor: 'Walk-in sales',
              ),
              txRow(
                id: 'tx-card',
                type: 'income',
                amountMinor: 18000,
                paymentMethod: 'card',
                occurredOn: normalizedToday.subtract(const Duration(days: 1)),
                createdAt: '2026-04-20T08:00:00Z',
                vendor: 'Card terminal',
              ),
              txRow(
                id: 'tx-transfer',
                type: 'income',
                amountMinor: 10000,
                paymentMethod: 'bank_transfer',
                occurredOn: normalizedToday.subtract(const Duration(days: 2)),
                createdAt: '2026-04-19T08:00:00Z',
                categoryName: 'Uber Settlement',
                vendor: 'Uber',
              ),
              txRow(
                id: 'tx-expense',
                type: 'expense',
                amountMinor: 9000,
                paymentMethod: 'card',
                occurredOn: normalizedToday.subtract(const Duration(days: 3)),
                createdAt: '2026-04-18T08:00:00Z',
                categoryName: 'Supplies',
                categoryType: 'expense',
                vendor: 'Supplier',
              ),
            ];
        final List<Map<String, dynamic>> recentRows = <Map<String, dynamic>>[
          txRow(
            id: 'recent-5',
            type: 'expense',
            amountMinor: 2500,
            paymentMethod: 'cash',
            occurredOn: normalizedToday.subtract(const Duration(days: 4)),
            createdAt: '2026-04-17T12:00:00Z',
            categoryName: 'Stock Purchase',
            categoryType: 'expense',
          ),
          txRow(
            id: 'recent-1',
            type: 'income',
            amountMinor: 5000,
            paymentMethod: 'cash',
            occurredOn: normalizedToday,
            createdAt: '2026-04-21T12:00:00Z',
            vendor: 'Recent 1',
          ),
          txRow(
            id: 'recent-2',
            type: 'expense',
            amountMinor: 2000,
            paymentMethod: 'card',
            occurredOn: normalizedToday.subtract(const Duration(days: 1)),
            createdAt: '2026-04-20T12:00:00Z',
            categoryName: 'Rent',
            categoryType: 'expense',
          ),
          txRow(
            id: 'recent-4',
            type: 'income',
            amountMinor: 4000,
            paymentMethod: 'bank_transfer',
            occurredOn: normalizedToday.subtract(const Duration(days: 3)),
            createdAt: '2026-04-18T12:00:00Z',
            vendor: 'Recent 4',
          ),
          txRow(
            id: 'recent-3',
            type: 'income',
            amountMinor: 3000,
            paymentMethod: 'card',
            occurredOn: normalizedToday.subtract(const Duration(days: 2)),
            createdAt: '2026-04-19T12:00:00Z',
            vendor: 'Recent 3',
          ),
          txRow(
            id: 'recent-6',
            type: 'expense',
            amountMinor: 1500,
            paymentMethod: 'card',
            occurredOn: normalizedToday.subtract(const Duration(days: 5)),
            createdAt: '2026-04-16T12:00:00Z',
            categoryName: 'Utilities',
            categoryType: 'expense',
          ),
        ];
        final List<Map<String, dynamic>> previousWeekRows =
            <Map<String, dynamic>>[
              txRow(
                id: 'prev-income',
                type: 'income',
                amountMinor: 30000,
                paymentMethod: 'cash',
                occurredOn: normalizedToday.subtract(const Duration(days: 7)),
                createdAt: '2026-04-14T08:00:00Z',
              ),
              txRow(
                id: 'prev-expense',
                type: 'expense',
                amountMinor: 5000,
                paymentMethod: 'card',
                occurredOn: normalizedToday.subtract(const Duration(days: 8)),
                createdAt: '2026-04-13T08:00:00Z',
                categoryName: 'Rent',
                categoryType: 'expense',
              ),
            ];

        int transactionRequestCount = 0;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories')) {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'cat-income',
                  'type': 'income',
                  'name': 'Cash Sales',
                },
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/categories')) {
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/transactions')) {
              transactionRequestCount += 1;
              final List<Map<String, dynamic>> response =
                  switch (transactionRequestCount) {
                    1 => currentWeekRows,
                    2 => recentRows,
                    3 => previousWeekRows,
                    _ => <Map<String, dynamic>>[],
                  };
              return _jsonResponse(request, response);
            }

            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/recurring_expenses')) {
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final DashboardSnapshot snapshot = await repository
            .fetchDashboardSnapshot(const AppLocalizations(AppLocale.en));

        expect(snapshot.incomeMinor, 40000);
        expect(snapshot.expenseMinor, 9000);
        expect(snapshot.netMinor, 31000);
        expect(snapshot.cashIncomeMinor, 12000);
        expect(snapshot.cardIncomeMinor, 18000);
        expect(snapshot.netDeltaMinor, 6000);
        expect(
          snapshot.recentTransactions.map((TransactionData tx) => tx.id),
          <String>['recent-1', 'recent-2', 'recent-3', 'recent-4'],
        );
        expect(snapshot.upcomingRecurring, isEmpty);
      },
    );

    test('fetchDashboardSnapshot includes reserve planner summary', () async {
      final DateTime today = DateTime.now();
      final DateTime normalizedToday = DateTime(
        today.year,
        today.month,
        today.day,
      );
      final DateTime electricityDue = normalizedToday.add(
        const Duration(days: 1),
      );
      final DateTime gasDue = normalizedToday.add(const Duration(days: 12));
      final DateTime broadbandDue = normalizedToday.add(
        const Duration(days: 3),
      );
      final DateTime rentDue = normalizedToday.add(const Duration(days: 28));
      String isoDate(DateTime value) {
        final String year = value.year.toString().padLeft(4, '0');
        final String month = value.month.toString().padLeft(2, '0');
        final String day = value.day.toString().padLeft(2, '0');
        return '$year-$month-$day';
      }

      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'cat-expense',
                'type': 'expense',
                'name': 'Rent',
              },
            ]);
          }

          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/categories')) {
            return _jsonResponse(
              request,
              <Map<String, dynamic>>[],
              statusCode: 201,
            );
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'tx-1',
                'type': 'expense',
                'occurred_on': isoDate(normalizedToday),
                'amount_minor': 12000,
                'currency': 'GBP',
                'payment_method': 'bank_transfer',
                'source_platform': null,
                'note': null,
                'vendor': 'Landlord',
                'attachment_path': null,
                'recurring_expense_id': null,
                'created_at': '2026-04-21T08:00:00Z',
                'category': <String, dynamic>{
                  'id': 'cat-expense',
                  'name': 'Rent',
                  'type': 'expense',
                },
              },
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/recurring_expenses')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'rec-gas',
                'name': 'Gas',
                'category_id': 'cat-expense',
                'amount_minor': 18000,
                'currency': 'GBP',
                'frequency': 'monthly',
                'next_due_on': isoDate(gasDue),
                'reminder_days_before': 3,
                'default_payment_method': 'card',
                'reserve_enabled': true,
                'is_active': true,
                'note': null,
                'category': <String, dynamic>{
                  'id': 'cat-expense',
                  'name': 'Rent',
                  'type': 'expense',
                },
              },
              <String, dynamic>{
                'id': 'rec-electricity',
                'name': 'Electricity',
                'category_id': 'cat-expense',
                'amount_minor': 6000,
                'currency': 'GBP',
                'frequency': 'monthly',
                'next_due_on': isoDate(electricityDue),
                'reminder_days_before': 3,
                'default_payment_method': 'card',
                'reserve_enabled': true,
                'is_active': true,
                'note': null,
                'category': <String, dynamic>{
                  'id': 'cat-expense',
                  'name': 'Rent',
                  'type': 'expense',
                },
              },
              <String, dynamic>{
                'id': 'rec-rent',
                'name': 'Rent',
                'category_id': 'cat-expense',
                'amount_minor': 120000,
                'currency': 'GBP',
                'frequency': 'monthly',
                'next_due_on': isoDate(rentDue),
                'reminder_days_before': 3,
                'default_payment_method': 'bank_transfer',
                'reserve_enabled': true,
                'is_active': true,
                'note': null,
                'category': <String, dynamic>{
                  'id': 'cat-expense',
                  'name': 'Rent',
                  'type': 'expense',
                },
              },
              <String, dynamic>{
                'id': 'rec-broadband',
                'name': 'Broadband',
                'category_id': 'cat-expense',
                'amount_minor': 4500,
                'currency': 'GBP',
                'frequency': 'monthly',
                'next_due_on': isoDate(broadbandDue),
                'reminder_days_before': 3,
                'default_payment_method': 'card',
                'reserve_enabled': true,
                'is_active': true,
                'note': null,
                'category': <String, dynamic>{
                  'id': 'cat-expense',
                  'name': 'Rent',
                  'type': 'expense',
                },
              },
              <String, dynamic>{
                'id': 'rec-disabled',
                'name': 'Disabled',
                'category_id': 'cat-expense',
                'amount_minor': 9999,
                'currency': 'GBP',
                'frequency': 'monthly',
                'next_due_on': '2026-04-25',
                'reminder_days_before': 3,
                'default_payment_method': 'card',
                'reserve_enabled': false,
                'is_active': true,
                'note': null,
                'category': <String, dynamic>{
                  'id': 'cat-expense',
                  'name': 'Rent',
                  'type': 'expense',
                },
              },
            ]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      final DashboardSnapshot snapshot = await repository
          .fetchDashboardSnapshot(const AppLocalizations(AppLocale.en));

      expect(snapshot.reservePlanner.eligibleItemCount, 4);
      expect(snapshot.reservePlanner.totalSuggestedWeeklyReserveMinor, 49500);
      expect(
        snapshot.reservePlanner.items.map((ReservePlannerItem item) => item.id),
        <String>['rec-electricity', 'rec-broadband', 'rec-gas', 'rec-rent'],
      );
      expect(
        snapshot.upcomingRecurring.map(
          (RecurringUiItem item) => item.record.id,
        ),
        <String>['rec-electricity', 'rec-broadband', 'rec-disabled'],
      );
    });

    test('deactivateRecurringExpense patches is_active to false', () async {
      Map<String, dynamic>? patchBody;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/recurring_expenses')) {
            patchBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }
          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.deactivateRecurringExpense(id: 'rec-1');

      expect(patchBody, isNotNull);
      expect(patchBody!['is_active'], false);
      expect(patchBody!.containsKey('name'), isFalse);
    });

    test('saveSupplier rejects attaching to an income category', () async {
      bool insertCalled = false;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'type,is_archived') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{'type': 'income', 'is_archived': false},
            ]);
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/suppliers')) {
            insertCalled = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }
          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.saveSupplier(
          draft: const SupplierDraft(
            expenseCategoryId: 'cat-income',
            name: 'Acme Ltd',
          ),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException e) => e.code,
            'code',
            'supplier.category_type_invalid',
          ),
        ),
      );
      expect(insertCalled, isFalse);
    });

    test(
      'saveSupplier rejects duplicate name within the same category',
      () async {
        bool insertCalled = false;
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/categories') &&
                request.url.queryParameters['select'] == 'type,is_archived') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{'type': 'expense', 'is_archived': false},
              ]);
            }
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/suppliers') &&
                request.url.queryParameters['select'] == 'id') {
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{'id': 'existing-supplier'},
              ]);
            }
            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/suppliers')) {
              insertCalled = true;
              return _jsonResponse(request, <Map<String, dynamic>>[]);
            }
            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        await expectLater(
          repository.saveSupplier(
            draft: const SupplierDraft(
              expenseCategoryId: 'cat-expense',
              name: 'Acme Ltd',
            ),
          ),
          throwsA(
            isA<DomainValidationException>().having(
              (DomainValidationException e) => e.code,
              'code',
              'supplier.duplicate_name',
            ),
          ),
        );
        expect(insertCalled, isFalse);
      },
    );

    test('saveSupplier rejects archived expense categories', () async {
      bool insertCalled = false;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/categories') &&
              request.url.queryParameters['select'] == 'type,is_archived') {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{'type': 'expense', 'is_archived': true},
            ]);
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/rest/v1/suppliers')) {
            insertCalled = true;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }
          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await expectLater(
        repository.saveSupplier(
          draft: const SupplierDraft(
            expenseCategoryId: 'cat-expense',
            name: 'Acme Ltd',
          ),
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (DomainValidationException e) => e.code,
            'code',
            'supplier.category_archived',
          ),
        ),
      );
      expect(insertCalled, isFalse);
    });

    test('archiveSupplier patches is_archived to true', () async {
      Map<String, dynamic>? patchBody;
      Uri? patchUrl;
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/rest/v1/suppliers')) {
            patchUrl = request.url;
            patchBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }
          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.archiveSupplier(id: 'supp-1');

      expect(patchBody, isNotNull);
      expect(patchBody!['is_archived'], isTrue);
      expect(patchUrl!.queryParameters['id'], 'eq.supp-1');
      expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
    });

    test(
      'fetchSuppliers filters archived rows by default and honours category filter',
      () async {
        final List<Uri> observedUrls = <Uri>[];
        final GiderRepository repository = GiderRepository(
          _buildClient((http.Request request) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/rest/v1/suppliers')) {
              observedUrls.add(request.url);
              return _jsonResponse(request, <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'supp-1',
                  'expense_category_id': 'cat-expense',
                  'name': 'Acme Ltd',
                  'notes': null,
                  'is_archived': false,
                  'sort_order': 0,
                  'category': <String, dynamic>{
                    'id': 'cat-expense',
                    'name': 'Rent',
                    'type': 'expense',
                  },
                },
              ]);
            }
            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final List<SupplierData> result = await repository.fetchSuppliers(
          expenseCategoryId: 'cat-expense',
        );

        expect(result, hasLength(1));
        expect(result.single.name, 'Acme Ltd');
        expect(result.single.expenseCategoryName, 'Rent');
        expect(observedUrls, hasLength(1));
        expect(observedUrls.single.queryParameters['is_archived'], 'eq.false');
        expect(
          observedUrls.single.queryParameters['expense_category_id'],
          'eq.cat-expense',
        );
      },
    );

    test('fetchSuppliers includes archived rows when explicitly requested', () async {
      final List<Uri> observedUrls = <Uri>[];
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/suppliers')) {
            observedUrls.add(request.url);
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'supp-archived',
                'expense_category_id': 'cat-expense',
                'name': 'Archived Ltd',
                'notes': null,
                'is_archived': true,
                'sort_order': 1,
                'category': <String, dynamic>{
                  'id': 'cat-expense',
                  'name': 'Rent',
                  'type': 'expense',
                },
              },
            ]);
          }
          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      final List<SupplierData> result = await repository.fetchSuppliers(
        includeArchived: true,
      );

      expect(result, hasLength(1));
      expect(result.single.isArchived, isTrue);
      expect(observedUrls.single.queryParameters.containsKey('is_archived'), isFalse);
    });

    test('fetchTransaction keeps archived supplier links intact', () async {
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/transactions')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'tx-1',
                'type': 'expense',
                'occurred_on': '2026-04-20',
                'amount_minor': 5000,
                'currency': 'GBP',
                'payment_method': 'card',
                'source_platform': null,
                'note': 'stock run',
                'vendor': 'Wholesale Ltd',
                'attachment_path': null,
                'recurring_expense_id': null,
                'supplier_id': 'supplier-archived',
                'created_at': '2026-04-20T10:00:00Z',
                'category': <String, dynamic>{
                  'id': 'category-1',
                  'name': 'Supplies',
                  'type': 'expense',
                },
                'supplier': <String, dynamic>{
                  'id': 'supplier-archived',
                  'name': 'Archived Supplier',
                },
              },
            ]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      final TransactionData? transaction = await repository.fetchTransaction(
        id: 'tx-1',
      );

      expect(transaction, isNotNull);
      expect(transaction!.supplierId, 'supplier-archived');
      expect(transaction.supplierName, 'Archived Supplier');
      expect(transaction.vendor, 'Wholesale Ltd');
    });

    test('fetchBusinessSettings is read-only when both rows exist', () async {
      final List<String> methods = <String>[];
      final GiderRepository repository = GiderRepository(
        _buildClient((http.Request request) async {
          methods.add('${request.method} ${request.url.path}');

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/profiles')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'email': 'owner@example.com',
                'full_name': 'Little Lane Deli',
              },
            ]);
          }

          if (request.method == 'GET' &&
              request.url.path.endsWith('/rest/v1/business_settings')) {
            return _jsonResponse(request, <Map<String, dynamic>>[
              <String, dynamic>{
                'business_name': 'Little Lane Deli',
                'timezone': 'Europe/London',
                'currency': 'GBP',
                'week_starts_on': 1,
              },
            ]);
          }

          fail('Unexpected HTTP call: ${request.method} ${request.url}');
        }),
      );

      await repository.fetchBusinessSettings();

      expect(
        methods.where((String m) => m.startsWith('POST')).toList(),
        isEmpty,
        reason: 'fetchBusinessSettings must not POST',
      );
      expect(
        methods.where((String m) => m.startsWith('PATCH')).toList(),
        isEmpty,
        reason: 'fetchBusinessSettings must not PATCH',
      );
    });
  });
}

_TestSupabaseClient _buildClient(
  Future<http.Response> Function(http.Request request) handler, {
  User? currentUser,
}) {
  final _MockGoTrueClient authClient = _MockGoTrueClient();
  when(() => authClient.currentUser).thenReturn(
    currentUser ??
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
