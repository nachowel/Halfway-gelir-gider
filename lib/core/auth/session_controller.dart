import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/app_models.dart';

/// Supabase error codes that indicate the locally stored refresh token is no
/// longer valid against the backend (e.g. the install carried over a session
/// from a previous project ref, the user signed out of all devices, or the
/// token was rotated). In those cases we must clear the local session so the
/// UI returns to a clean unauthenticated state instead of getting stuck on a
/// failed stream.
///
/// Detection is intentionally layered:
///   1. Exception type match (primary — SDK-guaranteed semantics).
///   2. `AuthException.code` string match (primary — stable API contract).
///   3. Message substring match (last-resort compatibility fallback only used
///      when both type and code are unavailable; see `_messageLooksStale`).
const Set<String> _staleRefreshTokenCodes = <String>{
  'refresh_token_not_found',
  'invalid_refresh_token',
  'refresh_token_already_used',
  'session_not_found',
  'bad_jwt',
  'invalid_jwt',
};

bool _isStaleSessionError(Object error) {
  // Primary: exception type match.
  if (error is AuthSessionMissingException) {
    return true;
  }
  if (error is AuthInvalidJwtException) {
    return true;
  }
  if (error is! AuthException) {
    return false;
  }

  // Primary: error code match.
  final String? code = error.code;
  if (code != null) {
    return _staleRefreshTokenCodes.contains(code);
  }

  // Last-resort compatibility fallback: message matching is a last-resort
  // compatibility fallback. It is only consulted when the SDK did not give
  // us a concrete exception subtype AND did not populate `code`. Newer
  // Supabase auth releases always emit `code`; this branch exists only to
  // guard against older releases or pre-HTTP errors that still carry a
  // recognizable message.
  return _messageLooksStale(error.message);
}

bool _messageLooksStale(String raw) {
  final String message = raw.toLowerCase();
  if (!message.contains('refresh token')) {
    return false;
  }
  return message.contains('not found') ||
      message.contains('invalid') ||
      message.contains('already used') ||
      message.contains('expired');
}

final class SessionController {
  const SessionController(this._client);

  final SupabaseClient _client;

  AppAuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  Stream<AppAuthUser?> authStateChanges() async* {
    await for (final AuthState state in _client.auth.onAuthStateChange
        .transform(_staleSessionRecoveryTransformer(_client))) {
      if (state.event == AuthChangeEvent.initialSession &&
          (state.session?.isExpired ?? false)) {
        continue;
      }

      yield _mapUser(state.session?.user);
    }
  }

  AppAuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return AppAuthUser(id: user.id, email: user.email ?? '');
  }
}

StreamTransformer<AuthState, AuthState> _staleSessionRecoveryTransformer(
  SupabaseClient client,
) {
  return StreamTransformer<AuthState, AuthState>.fromHandlers(
    handleError:
        (
          Object error,
          StackTrace stackTrace,
          EventSink<AuthState> sink,
        ) async {
          if (_isStaleSessionError(error)) {
            try {
              await client.auth.signOut(scope: SignOutScope.local);
            } catch (_) {
              // Local sign-out is best-effort; if it fails the next cold start
              // will retry and the UI still recovers via the synthetic
              // signedOut event below.
            }
            sink.add(const AuthState(AuthChangeEvent.signedOut, null));
            return;
          }
          sink.addError(error, stackTrace);
        },
  );
}
