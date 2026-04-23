import 'package:shared_preferences/shared_preferences.dart';

import 'app_lock_models.dart';

abstract class AppLockSettingsStore {
  Future<AppLockConfig> load();
  Future<void> save(AppLockConfig config);
}

class SharedPreferencesAppLockSettingsStore implements AppLockSettingsStore {
  const SharedPreferencesAppLockSettingsStore();

  static const String _enabledKey = 'app_lock.enabled';
  static const String _timeoutKey = 'app_lock.timeout';

  @override
  Future<AppLockConfig> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppLockConfig(
      enabled: prefs.getBool(_enabledKey) ?? false,
      timeout: AppLockTimeoutX.fromStorageValue(prefs.getString(_timeoutKey)),
    );
  }

  @override
  Future<void> save(AppLockConfig config) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, config.enabled);
    await prefs.setString(_timeoutKey, config.timeout.storageValue);
  }
}

class InMemoryAppLockSettingsStore implements AppLockSettingsStore {
  InMemoryAppLockSettingsStore([AppLockConfig? initial])
    : _config = initial ?? const AppLockConfig.disabled();

  AppLockConfig _config;

  @override
  Future<AppLockConfig> load() async => _config;

  @override
  Future<void> save(AppLockConfig config) async {
    _config = config;
  }
}
