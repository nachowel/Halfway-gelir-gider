import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

abstract class AppLocaleStorage {
  AppLocale load();

  Future<void> save(AppLocale locale);
}

class InMemoryAppLocaleStorage implements AppLocaleStorage {
  InMemoryAppLocaleStorage([this._value = AppLocale.en]);

  AppLocale _value;

  @override
  AppLocale load() => _value;

  @override
  Future<void> save(AppLocale locale) async {
    _value = locale;
  }
}

class SharedPreferencesAppLocaleStorage implements AppLocaleStorage {
  SharedPreferencesAppLocaleStorage(this._preferences);

  static const String _storageKey = 'app.locale';

  final SharedPreferences _preferences;

  @override
  AppLocale load() {
    return AppLocale.fromLanguageCode(_preferences.getString(_storageKey));
  }

  @override
  Future<void> save(AppLocale locale) {
    return _preferences.setString(_storageKey, locale.languageCode);
  }
}
