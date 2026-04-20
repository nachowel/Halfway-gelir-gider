import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/app_models.dart';

final class SessionController {
  const SessionController(this._client);

  final SupabaseClient _client;

  AppAuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  Stream<AppAuthUser?> authStateChanges() async* {
    yield currentUser;

    await for (final AuthState state in _client.auth.onAuthStateChange) {
      yield _mapUser(state.session?.user);
    }
  }

  AppAuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return AppAuthUser(
      id: user.id,
      email: user.email ?? '',
    );
  }
}
