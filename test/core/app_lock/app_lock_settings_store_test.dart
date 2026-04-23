import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/app_lock/app_lock_models.dart';
import 'package:gider/core/app_lock/app_lock_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('app lock enabled and timeout are persisted locally', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const SharedPreferencesAppLockSettingsStore store =
        SharedPreferencesAppLockSettingsStore();

    await store.save(
      const AppLockConfig(enabled: true, timeout: AppLockTimeout.oneMinute),
    );

    final AppLockConfig restored = await store.load();
    expect(restored.enabled, isTrue);
    expect(restored.timeout, AppLockTimeout.oneMinute);
  });

  test('app restart restores saved lock config', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_lock.enabled': true,
      'app_lock.timeout': 'fifteen_minutes',
    });
    const SharedPreferencesAppLockSettingsStore store =
        SharedPreferencesAppLockSettingsStore();

    final AppLockConfig restored = await store.load();

    expect(restored.enabled, isTrue);
    expect(restored.timeout, AppLockTimeout.fifteenMinutes);
  });
}
