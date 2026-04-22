import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gider/app/theme/app_theme.dart';
import 'package:gider/l10n/app_localizations.dart';

const List<LocalizationsDelegate<dynamic>> appTestLocalizationsDelegates =
    AppLocalizations.globalDelegates;

const List<Locale> appTestSupportedLocales = AppLocalizations.supportedLocales;

MaterialApp buildLocalizedTestApp({
  required Widget home,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  AppTheme.configure();
  return MaterialApp(
    theme: theme ?? AppTheme.light(),
    locale: locale,
    supportedLocales: appTestSupportedLocales,
    localizationsDelegates: appTestLocalizationsDelegates,
    home: home,
  );
}

MaterialApp buildLocalizedScaffoldTestApp({
  required Widget child,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) {
  return buildLocalizedTestApp(
    theme: theme,
    locale: locale,
    home: Scaffold(body: child),
  );
}
