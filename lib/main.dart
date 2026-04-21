import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/supabase/supabase_client.dart';
import 'app/providers/app_providers.dart';
import 'l10n/app_locale_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_GB');
  await initializeDateFormatting('tr_TR');

  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final SharedPreferencesAppLocaleStorage localeStorage =
      SharedPreferencesAppLocaleStorage(preferences);
  Intl.defaultLocale = localeStorage.load().intlTag;

  try {
    await AppSupabaseClient.initialize();
  } on SupabaseConfigException catch (error) {
    runApp(
      ProviderScope(
        overrides: <Override>[
          appLocaleStorageProvider.overrideWithValue(localeStorage),
        ],
        child: _BootstrapFailureApp(message: error.message),
      ),
    );
    return;
  }

  runApp(
    ProviderScope(
      overrides: <Override>[
        appLocaleStorageProvider.overrideWithValue(localeStorage),
      ],
      child: const GiderApp(),
    ),
  );
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFF15282B),
      builder: (_, __) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textDirection: ui.TextDirection.ltr),
          ),
        );
      },
    );
  }
}
