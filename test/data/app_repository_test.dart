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
      'fetchBusinessSettings persists a default settings row when missing',
      () async {
        bool upsertCalled = false;
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

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/business_settings')) {
              upsertCalled = true;
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final BusinessSettingsData settings = await repository
            .fetchBusinessSettings();

        expect(upsertCalled, isTrue);
        expect(settings.businessName, 'owner');
        expect(settings.isBootstrapComplete, isFalse);
        expect(settings.currency, 'GBP');
        expect(settings.timezone, 'Europe/London');
        expect(settings.weekStartsOn, 1);
      },
    );

    test(
      'fetchBusinessSettings auto-completes bootstrap from profile name',
      () async {
        bool upsertCalled = false;
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
                  'business_name': null,
                  'timezone': 'Europe/London',
                  'currency': 'GBP',
                  'week_starts_on': 1,
                },
              ]);
            }

            if (request.method == 'POST' &&
                request.url.path.endsWith('/rest/v1/business_settings')) {
              upsertCalled = true;
              return _jsonResponse(
                request,
                <Map<String, dynamic>>[],
                statusCode: 201,
              );
            }

            fail('Unexpected HTTP call: ${request.method} ${request.url}');
          }),
        );

        final BusinessSettingsData settings = await repository
            .fetchBusinessSettings();

        expect(upsertCalled, isTrue);
        expect(settings.businessName, 'Little Lane Deli');
        expect(settings.isBootstrapComplete, isTrue);
      },
    );
  });
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
