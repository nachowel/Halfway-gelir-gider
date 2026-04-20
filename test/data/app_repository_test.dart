// ignore_for_file: invalid_use_of_internal_member

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/domain/types.dart' show DomainValidationException;
import 'package:gider/data/app_models.dart';
import 'package:gider/data/app_repository.dart';
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
      expect(requestBody!['note'], 'weekly stock');
    });

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
      },
    );

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
      expect(patchBody!.containsKey('user_id'), isFalse);
      expect(patchUrl, isNotNull);
      expect(patchUrl!.queryParameters['id'], 'eq.tx-1');
      expect(patchUrl!.queryParameters['user_id'], 'eq.user-1');
    });

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

      final VerificationResult captured =
          verify(
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

    test(
      'fetchBusinessSettings is read-only when both rows exist',
      () async {
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
      },
    );
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
