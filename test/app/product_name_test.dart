import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gider/l10n/app_locale.dart';
import 'package:gider/l10n/app_localizations.dart';

void main() {
  test('visible product name is Halfway across app surfaces', () {
    expect(const AppLocalizations(AppLocale.en).appTitle, 'Halfway');
    expect(const AppLocalizations(AppLocale.tr).appTitle, 'Halfway');

    final String androidStrings = File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();
    expect(
      androidStrings,
      contains('<string name="app_name">Halfway</string>'),
    );

    final Map<String, dynamic> manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['name'], 'Halfway');
    expect(manifest['short_name'], 'Halfway');

    final String indexHtml = File('web/index.html').readAsStringSync();
    expect(
      indexHtml,
      contains('<meta name="apple-mobile-web-app-title" content="Halfway">'),
    );
    expect(indexHtml, contains('<title>Halfway</title>'));
  });
}
