// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
import 'dart:convert';

import 'package:gider/data/app_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/auth/session_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _TestSupabaseClient extends SupabaseClient {
  _TestSupabaseClient({required GoTrueClient authClient})
    : _authClient = authClient,
      super('http://127.0.0.1:54321', 'test-anon-key');

  final GoTrueClient _authClient;

  @override
  GoTrueClient get auth => _authClient;
}

void main() {
  setUpAll(() {
    registerFallbackValue(SignOutScope.local);
  });

  group('SessionController.authStateChanges', () {
    test('restored valid session emits the restored user', () async {
      final _MockGoTrueClient authClient = _MockGoTrueClient();
      final Session session = _session(expiresAt: _futureSeconds());
      when(() => authClient.currentUser).thenReturn(null);
      when(
        () => authClient.onAuthStateChangeSync,
      ).thenAnswer((_) => const Stream<AuthState>.empty());
      when(() => authClient.onAuthStateChange).thenAnswer(
        (_) => Stream<AuthState>.value(
          AuthState(AuthChangeEvent.initialSession, session),
        ),
      );

      final SessionController controller = SessionController(
        _TestSupabaseClient(authClient: authClient),
      );

      await expectLater(
        controller.authStateChanges(),
        emits(
          isA<AppAuthUser>()
              .having((AppAuthUser user) => user.id, 'id', 'user-1')
              .having(
                (AppAuthUser user) => user.email,
                'email',
                'owner@example.com',
              ),
        ),
      );
    });

    test(
      'expired initial session waits for signedOut before emitting auth',
      () async {
        final _MockGoTrueClient authClient = _MockGoTrueClient();
        final Session expired = _session(expiresAt: _pastSeconds());
        when(() => authClient.currentUser).thenReturn(null);
        when(
          () => authClient.onAuthStateChangeSync,
        ).thenAnswer((_) => const Stream<AuthState>.empty());
        when(() => authClient.onAuthStateChange).thenAnswer(
          (_) => Stream<AuthState>.fromIterable(<AuthState>[
            AuthState(AuthChangeEvent.initialSession, expired),
            const AuthState(AuthChangeEvent.signedOut, null),
          ]),
        );

        final SessionController controller = SessionController(
          _TestSupabaseClient(authClient: authClient),
        );

        await expectLater(controller.authStateChanges(), emits(null));
      },
    );

    test('signedOut emits unauthenticated state', () async {
      final _MockGoTrueClient authClient = _MockGoTrueClient();
      when(() => authClient.currentUser).thenReturn(null);
      when(
        () => authClient.onAuthStateChangeSync,
      ).thenAnswer((_) => const Stream<AuthState>.empty());
      when(() => authClient.onAuthStateChange).thenAnswer(
        (_) => Stream<AuthState>.value(
          const AuthState(AuthChangeEvent.signedOut, null),
        ),
      );

      final SessionController controller = SessionController(
        _TestSupabaseClient(authClient: authClient),
      );

      await expectLater(controller.authStateChanges(), emits(null));
    });

    test(
      'stale refresh token error on stream emits null and clears local session',
      () async {
        final _MockGoTrueClient authClient = _MockGoTrueClient();
        when(() => authClient.currentUser).thenReturn(null);
        when(
          () => authClient.onAuthStateChangeSync,
        ).thenAnswer((_) => const Stream<AuthState>.empty());
        when(() => authClient.onAuthStateChange).thenAnswer(
          (_) => Stream<AuthState>.error(
            AuthApiException(
              'Invalid Refresh Token: Already Used',
              statusCode: '400',
              code: 'refresh_token_already_used',
            ),
          ),
        );
        when(
          () => authClient.signOut(scope: SignOutScope.local),
        ).thenAnswer((_) async {});

        final SessionController controller = SessionController(
          _TestSupabaseClient(authClient: authClient),
        );

        await expectLater(controller.authStateChanges(), emits(null));
        verify(
          () => authClient.signOut(scope: SignOutScope.local),
        ).called(1);
      },
    );

    test(
      'stream keeps delivering after stale recovery: null then signedIn user',
      () async {
        final _MockGoTrueClient authClient = _MockGoTrueClient();
        final Session good = _session(expiresAt: _futureSeconds());

        when(() => authClient.currentUser).thenReturn(null);
        when(
          () => authClient.onAuthStateChangeSync,
        ).thenAnswer((_) => const Stream<AuthState>.empty());
        Stream<AuthState> upstream() async* {
          yield* Stream<AuthState>.error(
            AuthApiException(
              'Invalid Refresh Token',
              statusCode: '400',
              code: 'invalid_refresh_token',
            ),
          );
          yield AuthState(AuthChangeEvent.signedIn, good);
        }

        when(
          () => authClient.onAuthStateChange,
        ).thenAnswer((_) => upstream());
        when(
          () => authClient.signOut(scope: SignOutScope.local),
        ).thenAnswer((_) async {});

        final SessionController controller = SessionController(
          _TestSupabaseClient(authClient: authClient),
        );

        final List<AppAuthUser?> emitted = await controller
            .authStateChanges()
            .take(2)
            .toList();

        expect(emitted, hasLength(2));
        expect(emitted[0], isNull);
        expect(emitted[1], isA<AppAuthUser>());
        expect(emitted[1]!.id, 'user-1');
        verify(
          () => authClient.signOut(scope: SignOutScope.local),
        ).called(1);
      },
    );

    test(
      'message-only stale match when code and exception subtype are absent',
      () async {
        final _MockGoTrueClient authClient = _MockGoTrueClient();
        when(() => authClient.currentUser).thenReturn(null);
        when(
          () => authClient.onAuthStateChangeSync,
        ).thenAnswer((_) => const Stream<AuthState>.empty());
        when(() => authClient.onAuthStateChange).thenAnswer(
          (_) => Stream<AuthState>.error(
            AuthException('Invalid Refresh Token: Not Found'),
          ),
        );
        when(
          () => authClient.signOut(scope: SignOutScope.local),
        ).thenAnswer((_) async {});

        final SessionController controller = SessionController(
          _TestSupabaseClient(authClient: authClient),
        );

        await expectLater(controller.authStateChanges(), emits(null));
        verify(
          () => authClient.signOut(scope: SignOutScope.local),
        ).called(1);
      },
    );

    test(
      'non-stale AuthException on stream surfaces as error without signOut',
      () async {
        final _MockGoTrueClient authClient = _MockGoTrueClient();
        when(() => authClient.currentUser).thenReturn(null);
        when(
          () => authClient.onAuthStateChangeSync,
        ).thenAnswer((_) => const Stream<AuthState>.empty());
        when(() => authClient.onAuthStateChange).thenAnswer(
          (_) => Stream<AuthState>.error(
            AuthApiException(
              'Rate limit exceeded',
              statusCode: '429',
              code: 'over_request_rate_limit',
            ),
          ),
        );

        final SessionController controller = SessionController(
          _TestSupabaseClient(authClient: authClient),
        );

        await expectLater(
          controller.authStateChanges(),
          emitsError(isA<AuthApiException>()),
        );
        verifyNever(
          () => authClient.signOut(scope: any(named: 'scope')),
        );
      },
    );

    test('stays pending until Supabase emits initial session', () async {
      final _MockGoTrueClient authClient = _MockGoTrueClient();
      when(() => authClient.currentUser).thenReturn(null);
      when(
        () => authClient.onAuthStateChangeSync,
      ).thenAnswer((_) => const Stream<AuthState>.empty());
      when(() => authClient.onAuthStateChange).thenAnswer((_) async* {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        yield AuthState(
          AuthChangeEvent.initialSession,
          _session(expiresAt: _futureSeconds()),
        );
      });

      final SessionController controller = SessionController(
        _TestSupabaseClient(authClient: authClient),
      );
      final Stopwatch stopwatch = Stopwatch()..start();

      final AppAuthUser? user = await controller.authStateChanges().first;

      expect(user, isA<AppAuthUser>());
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(30));
    });
  });
}

Session _session({required int expiresAt}) {
  return Session(
    accessToken: _jwt(expiresAt: expiresAt),
    refreshToken: 'refresh-token',
    tokenType: 'bearer',
    user: const User(
      id: 'user-1',
      appMetadata: <String, dynamic>{},
      userMetadata: <String, dynamic>{},
      aud: 'authenticated',
      email: 'owner@example.com',
      createdAt: '2026-04-20T00:00:00Z',
    ),
  );
}

String _jwt({required int expiresAt}) {
  String encode(Object value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return '${encode(<String, String>{'alg': 'none'})}.'
      '${encode(<String, Object>{'exp': expiresAt})}.';
}

int _futureSeconds() {
  return DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
}

int _pastSeconds() {
  return DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch ~/
      1000;
}
