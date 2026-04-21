import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseConfigException implements Exception {
  const SupabaseConfigException(this.message);

  final String message;

  @override
  String toString() => 'SupabaseConfigException: $message';
}

final class SupabaseRuntimeConfig {
  const SupabaseRuntimeConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  static const String _urlKey = 'NEXT_PUBLIC_SUPABASE_URL';
  static const String _anonKeyKey = 'NEXT_PUBLIC_SUPABASE_ANON_KEY';

  factory SupabaseRuntimeConfig.fromEnvironment() {
    const String rawUrl = String.fromEnvironment(_urlKey);
    const String rawAnonKey = String.fromEnvironment(_anonKeyKey);

    debugPrint('SUPABASE_URL_RAW=[$rawUrl]');
    debugPrint('SUPABASE_URL_LENGTH=${rawUrl.length}');
    debugPrint('SUPABASE_ANON_KEY_LENGTH=${rawAnonKey.length}');

    return SupabaseRuntimeConfig.fromValues(
      url: rawUrl,
      anonKey: rawAnonKey,
      urlKey: _urlKey,
      anonKeyKey: _anonKeyKey,
    );
  }

  factory SupabaseRuntimeConfig.fromValues({
    required String url,
    required String anonKey,
    String urlKey = _urlKey,
    String anonKeyKey = _anonKeyKey,
  }) {
    final String normalizedUrl = url.trim();
    final String normalizedAnonKey = anonKey.trim();

    final List<String> missingKeys = <String>[
      if (normalizedUrl.isEmpty) urlKey,
      if (normalizedAnonKey.isEmpty) anonKeyKey,
    ];

    if (missingKeys.isNotEmpty) {
      throw SupabaseConfigException(
        'Missing required Supabase configuration: ${missingKeys.join(', ')}. '
        'Run Flutter with compile-time defines, for example '
        '`--dart-define-from-file=.env.local`.',
      );
    }

    if (!normalizedUrl.startsWith('https://')) {
      throw SupabaseConfigException(
        'Invalid Supabase URL in $urlKey. Expected an https:// URL, got '
        '[$normalizedUrl].',
      );
    }

    final Uri parsedUrl = Uri.parse(normalizedUrl);
    if (parsedUrl.host.trim().isEmpty) {
      throw SupabaseConfigException(
        'Invalid Supabase URL in $urlKey. Parsed host is empty for '
        '[$normalizedUrl].',
      );
    }

    return SupabaseRuntimeConfig(
      url: normalizedUrl,
      anonKey: normalizedAnonKey,
    );
  }
}

abstract final class AppSupabaseClient {
  static Future<void> initialize() async {
    final SupabaseRuntimeConfig config =
        SupabaseRuntimeConfig.fromEnvironment();

    await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  }
}
