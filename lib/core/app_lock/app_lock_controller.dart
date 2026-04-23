import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_models.dart';
import 'app_lock_settings_store.dart';
import 'local_auth_unlock_service.dart';

typedef AppLockClock = DateTime Function();

class AppLockController extends StateNotifier<AppLockState> {
  AppLockController({
    required AppLockSettingsStore settingsStore,
    required AppUnlockService unlockService,
    AppLockClock? clock,
  }) : _settingsStore = settingsStore,
       _unlockService = unlockService,
       _clock = clock ?? DateTime.now,
       super(const AppLockState.loading()) {
    _load();
  }

  AppLockController.preloaded({
    required AppLockState initialState,
    required AppLockSettingsStore settingsStore,
    required AppUnlockService unlockService,
    AppLockClock? clock,
  }) : _settingsStore = settingsStore,
       _unlockService = unlockService,
       _clock = clock ?? DateTime.now,
       super(initialState);

  final AppLockSettingsStore _settingsStore;
  final AppUnlockService _unlockService;
  final AppLockClock _clock;

  Future<void> _load() async {
    final AppLockConfig config = await _settingsStore.load();
    if (!mounted) {
      return;
    }
    state = AppLockState(
      isReady: true,
      config: config,
      status: config.enabled ? AppLockStatus.locked : AppLockStatus.disabled,
    );
  }

  Future<AppLockEnableResult> enable({
    required String localizedReason,
    AppLockTimeout? timeout,
  }) async {
    if (state.isEnableInProgress) {
      return const AppLockEnableResult(AppLockEnableStatus.failed);
    }

    state = state.copyWith(isEnableInProgress: true, clearFailureMessage: true);

    try {
      if (!await _unlockService.isLocalAuthenticationAvailable()) {
        state = state.copyWith(
          isEnableInProgress: false,
          status: AppLockStatus.disabled,
          failureMessage: 'Device authentication is unavailable.',
        );
        return const AppLockEnableResult(
          AppLockEnableStatus.unavailable,
          message: 'Device authentication is unavailable.',
        );
      }

      final AppUnlockAttemptResult result = await _unlockService.authenticate(
        localizedReason: localizedReason,
      );
      if (result.status != AppUnlockAttemptStatus.success) {
        state = state.copyWith(
          isEnableInProgress: false,
          status: AppLockStatus.disabled,
          failureMessage: result.message,
        );
        return AppLockEnableResult(
          _enableStatusForAttempt(result.status),
          message: result.message,
        );
      }

      final AppLockConfig config = AppLockConfig(
        enabled: true,
        timeout: timeout ?? state.config.timeout,
      );
      await _settingsStore.save(config);
      if (!mounted) {
        return const AppLockEnableResult(AppLockEnableStatus.enabled);
      }
      state = state.copyWith(
        isReady: true,
        config: config,
        status: AppLockStatus.unlocked,
        isEnableInProgress: false,
        clearFailureMessage: true,
        clearLastPausedAt: true,
      );
      return const AppLockEnableResult(AppLockEnableStatus.enabled);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          isEnableInProgress: false,
          status: AppLockStatus.disabled,
          failureMessage: 'Device authentication is unavailable.',
        );
      }
      return const AppLockEnableResult(
        AppLockEnableStatus.unavailable,
        message: 'Device authentication is unavailable.',
      );
    }
  }

  Future<void> disable() async {
    const AppLockConfig config = AppLockConfig.disabled();
    await _settingsStore.save(config);
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      isReady: true,
      config: config,
      status: AppLockStatus.disabled,
      clearFailureMessage: true,
      clearLastPausedAt: true,
    );
  }

  Future<void> setTimeout(AppLockTimeout timeout) async {
    final AppLockConfig config = state.config.copyWith(timeout: timeout);
    await _settingsStore.save(config);
    if (!mounted) {
      return;
    }
    state = state.copyWith(config: config);
  }

  void markPaused() {
    if (!state.isReady || !state.config.enabled) {
      return;
    }
    state = state.copyWith(lastPausedAt: _clock());
  }

  void handleResumed() {
    if (!state.isReady ||
        !state.config.enabled ||
        state.status == AppLockStatus.locked ||
        state.status == AppLockStatus.unlocking ||
        state.status == AppLockStatus.unavailable) {
      return;
    }

    final DateTime? lastPausedAt = state.lastPausedAt;
    if (lastPausedAt == null) {
      return;
    }

    final Duration elapsed = _clock().difference(lastPausedAt);
    if (state.config.timeout == AppLockTimeout.immediately ||
        elapsed >= state.config.timeout.duration) {
      lock();
      return;
    }

    state = state.copyWith(clearLastPausedAt: true);
  }

  void lock() {
    if (!state.isReady || !state.config.enabled) {
      return;
    }
    state = state.copyWith(
      status: AppLockStatus.locked,
      clearFailureMessage: true,
      clearLastPausedAt: true,
    );
  }

  Future<void> unlock({required String localizedReason}) async {
    if (!state.isReady ||
        !state.config.enabled ||
        state.status == AppLockStatus.unlocking) {
      return;
    }

    if (!await _unlockService.isLocalAuthenticationAvailable()) {
      state = state.copyWith(
        status: AppLockStatus.unavailable,
        failureMessage: 'Device authentication is unavailable.',
      );
      return;
    }

    state = state.copyWith(
      status: AppLockStatus.unlocking,
      clearFailureMessage: true,
    );
    final AppUnlockAttemptResult result = await _unlockService.authenticate(
      localizedReason: localizedReason,
    );
    if (!mounted) {
      return;
    }

    switch (result.status) {
      case AppUnlockAttemptStatus.success:
        state = state.copyWith(
          status: AppLockStatus.unlocked,
          clearFailureMessage: true,
          clearLastPausedAt: true,
        );
      case AppUnlockAttemptStatus.unavailable:
        state = state.copyWith(
          status: AppLockStatus.unavailable,
          failureMessage: result.message,
        );
      case AppUnlockAttemptStatus.failed:
      case AppUnlockAttemptStatus.canceled:
        state = state.copyWith(
          status: AppLockStatus.locked,
          failureMessage: result.message,
        );
    }
  }

  AppLockEnableStatus _enableStatusForAttempt(AppUnlockAttemptStatus status) {
    return switch (status) {
      AppUnlockAttemptStatus.success => AppLockEnableStatus.enabled,
      AppUnlockAttemptStatus.failed => AppLockEnableStatus.failed,
      AppUnlockAttemptStatus.canceled => AppLockEnableStatus.canceled,
      AppUnlockAttemptStatus.unavailable => AppLockEnableStatus.unavailable,
    };
  }
}
