import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/supabase/supabase_client.dart';

void main() {
  group('SupabaseRuntimeConfig.fromValues', () {
    test('trims URL and anon key', () {
      final SupabaseRuntimeConfig config = SupabaseRuntimeConfig.fromValues(
        url: '  https://fplldhooqbnmrcsnoqde.supabase.co  ',
        anonKey: '  test-anon-key  ',
      );

      expect(config.url, 'https://fplldhooqbnmrcsnoqde.supabase.co');
      expect(config.anonKey, 'test-anon-key');
    });

    test('throws when URL is empty after trim', () {
      expect(
        () => SupabaseRuntimeConfig.fromValues(
          url: '   ',
          anonKey: 'test-anon-key',
        ),
        throwsA(
          isA<SupabaseConfigException>().having(
            (SupabaseConfigException error) => error.message,
            'message',
            contains('NEXT_PUBLIC_SUPABASE_URL'),
          ),
        ),
      );
    });

    test('throws when URL does not start with https', () {
      expect(
        () => SupabaseRuntimeConfig.fromValues(
          url: 'http://fplldhooqbnmrcsnoqde.supabase.co',
          anonKey: 'test-anon-key',
        ),
        throwsA(
          isA<SupabaseConfigException>().having(
            (SupabaseConfigException error) => error.message,
            'message',
            contains('https://'),
          ),
        ),
      );
    });

    test('throws when parsed URL host is empty', () {
      expect(
        () => SupabaseRuntimeConfig.fromValues(
          url: 'https://',
          anonKey: 'test-anon-key',
        ),
        throwsA(
          isA<SupabaseConfigException>().having(
            (SupabaseConfigException error) => error.message,
            'message',
            contains('Parsed host is empty'),
          ),
        ),
      );
    });

    test('supports env bypass with hardcoded valid Supabase URL', () {
      final SupabaseRuntimeConfig config = SupabaseRuntimeConfig.fromValues(
        url: 'https://fplldhooqbnmrcsnoqde.supabase.co',
        anonKey: 'test-anon-key',
      );

      expect(config.url, 'https://fplldhooqbnmrcsnoqde.supabase.co');
      expect(config.anonKey, 'test-anon-key');
    });
  });
}
