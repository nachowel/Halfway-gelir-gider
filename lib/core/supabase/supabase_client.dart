import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseConfigException implements Exception {
  const SupabaseConfigException(this.message);

  final String message;

  @override
  String toString() => 'SupabaseConfigException: $message';
}

final class SupabaseRuntimeConfig {
  const SupabaseRuntimeConfig({
    required this.url,
    required this.anonKey,
  });

  final String url;
  final String anonKey;

  static const String _urlKey = 'NEXT_PUBLIC_SUPABASE_URL';
  static const String _anonKeyKey = 'NEXT_PUBLIC_SUPABASE_ANON_KEY';

  factory SupabaseRuntimeConfig.fromEnvironment() {
    const String url = String.fromEnvironment(_urlKey);
    const String anonKey = String.fromEnvironment(_anonKeyKey);

    final List<String> missingKeys = <String>[
      if (url.isEmpty) _urlKey,
      if (anonKey.isEmpty) _anonKeyKey,
    ];

    if (missingKeys.isNotEmpty) {
      throw SupabaseConfigException(
        'Missing required Supabase configuration: ${missingKeys.join(', ')}. '
        'Run Flutter with compile-time defines, for example '
        '`--dart-define-from-file=.env.local`.',
      );
    }

    return const SupabaseRuntimeConfig(url: url, anonKey: anonKey);
  }
}

abstract final class AppSupabaseClient {
  static Future<void> initialize() async {
    final SupabaseRuntimeConfig config =
        SupabaseRuntimeConfig.fromEnvironment();

    await Supabase.initialize(
      url: config.url,
      anonKey: config.anonKey,
    );
  }
}
