import 'package:flutter_test/flutter_test.dart';
import 'package:gider/core/app_lock/app_lock_controller.dart';
import 'package:gider/core/app_lock/app_lock_models.dart';
import 'package:gider/core/app_lock/app_lock_settings_store.dart';
import 'package:gider/core/app_lock/local_auth_unlock_service.dart';

void main() {
  test('enable requires successful device auth before persisting ON', () async {
    final InMemoryAppLockSettingsStore store = InMemoryAppLockSettingsStore();
    final _FakeUnlockService unlockService = _FakeUnlockService(
      available: true,
      nextResult: const AppUnlockAttemptResult.success(),
    );
    final AppLockController controller = AppLockController(
      settingsStore: store,
      unlockService: unlockService,
    );
    await _waitReady(controller);

    final AppLockEnableResult result = await controller.enable(
      localizedReason: 'To turn on App Lock, verify with your device.',
    );

    expect(result.enabled, isTrue);
    expect(controller.state.config.enabled, isTrue);
    expect(controller.state.status, AppLockStatus.unlocked);
    expect((await store.load()).enabled, isTrue);
    expect(unlockService.authenticateCalls, 1);
  });

  test('enable fail or cancel leaves setting OFF', () async {
    final InMemoryAppLockSettingsStore store = InMemoryAppLockSettingsStore();
    final AppLockController controller = AppLockController(
      settingsStore: store,
      unlockService: _FakeUnlockService(
        available: true,
        nextResult: const AppUnlockAttemptResult(
          AppUnlockAttemptStatus.canceled,
        ),
      ),
    );
    await _waitReady(controller);

    final AppLockEnableResult result = await controller.enable(
      localizedReason: 'verify',
    );

    expect(result.status, AppLockEnableStatus.canceled);
    expect(controller.state.config.enabled, isFalse);
    expect(controller.state.status, AppLockStatus.disabled);
    expect((await store.load()).enabled, isFalse);
  });

  test('local config persists enabled and timeout values', () async {
    final InMemoryAppLockSettingsStore store = InMemoryAppLockSettingsStore();
    final AppLockController controller = AppLockController(
      settingsStore: store,
      unlockService: _FakeUnlockService(
        available: true,
        nextResult: const AppUnlockAttemptResult.success(),
      ),
    );
    await _waitReady(controller);

    await controller.enable(
      localizedReason: 'verify',
      timeout: AppLockTimeout.oneMinute,
    );
    await controller.setTimeout(AppLockTimeout.fifteenMinutes);

    final AppLockConfig saved = await store.load();
    expect(saved.enabled, isTrue);
    expect(saved.timeout, AppLockTimeout.fifteenMinutes);
  });

  test('cold start restores enabled config as locked', () async {
    final InMemoryAppLockSettingsStore store = InMemoryAppLockSettingsStore(
      const AppLockConfig(enabled: true, timeout: AppLockTimeout.fiveMinutes),
    );
    final AppLockController controller = AppLockController(
      settingsStore: store,
      unlockService: _FakeUnlockService(available: true),
    );

    await _waitReady(controller);

    expect(controller.state.config.enabled, isTrue);
    expect(controller.state.status, AppLockStatus.locked);
    expect(controller.state.allowsProtectedAccess, isFalse);
  });

  test('resume after timeout locks without duplicate auth prompt', () async {
    DateTime now = DateTime(2026, 4, 23, 12);
    final _FakeUnlockService unlockService = _FakeUnlockService(
      available: true,
      nextResult: const AppUnlockAttemptResult.success(),
    );
    final AppLockController controller = AppLockController.preloaded(
      initialState: const AppLockState(
        isReady: true,
        config: AppLockConfig(enabled: true, timeout: AppLockTimeout.oneMinute),
        status: AppLockStatus.unlocked,
      ),
      settingsStore: InMemoryAppLockSettingsStore(),
      unlockService: unlockService,
      clock: () => now,
    );

    controller.markPaused();
    now = now.add(const Duration(minutes: 2));
    controller.handleResumed();

    expect(controller.state.status, AppLockStatus.locked);
    expect(unlockService.authenticateCalls, 0);
  });
}

Future<void> _waitReady(AppLockController controller) async {
  for (int i = 0; i < 10; i++) {
    if (controller.state.isReady) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('AppLockController did not become ready.');
}

class _FakeUnlockService implements AppUnlockService {
  _FakeUnlockService({
    required this.available,
    this.nextResult = const AppUnlockAttemptResult(
      AppUnlockAttemptStatus.failed,
    ),
  });

  final bool available;
  final AppUnlockAttemptResult nextResult;
  int authenticateCalls = 0;

  @override
  Future<AppUnlockAttemptResult> authenticate({
    required String localizedReason,
  }) async {
    authenticateCalls++;
    return nextResult;
  }

  @override
  Future<bool> isLocalAuthenticationAvailable() async => available;
}
