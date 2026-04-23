enum AppLockStatus { disabled, unlocked, locked, unlocking, unavailable }

enum AppLockTimeout { immediately, oneMinute, fiveMinutes, fifteenMinutes }

extension AppLockTimeoutX on AppLockTimeout {
  Duration get duration => switch (this) {
    AppLockTimeout.immediately => Duration.zero,
    AppLockTimeout.oneMinute => const Duration(minutes: 1),
    AppLockTimeout.fiveMinutes => const Duration(minutes: 5),
    AppLockTimeout.fifteenMinutes => const Duration(minutes: 15),
  };

  String get storageValue => switch (this) {
    AppLockTimeout.immediately => 'immediately',
    AppLockTimeout.oneMinute => 'one_minute',
    AppLockTimeout.fiveMinutes => 'five_minutes',
    AppLockTimeout.fifteenMinutes => 'fifteen_minutes',
  };

  static AppLockTimeout fromStorageValue(String? value) {
    return AppLockTimeout.values.firstWhere(
      (AppLockTimeout option) => option.storageValue == value,
      orElse: () => AppLockTimeout.fiveMinutes,
    );
  }
}

class AppLockConfig {
  const AppLockConfig({required this.enabled, required this.timeout});

  const AppLockConfig.disabled()
    : enabled = false,
      timeout = AppLockTimeout.fiveMinutes;

  final bool enabled;
  final AppLockTimeout timeout;

  AppLockConfig copyWith({bool? enabled, AppLockTimeout? timeout}) {
    return AppLockConfig(
      enabled: enabled ?? this.enabled,
      timeout: timeout ?? this.timeout,
    );
  }
}

class AppLockState {
  const AppLockState({
    required this.isReady,
    required this.config,
    required this.status,
    this.lastPausedAt,
    this.failureMessage,
    this.isEnableInProgress = false,
  });

  const AppLockState.loading()
    : isReady = false,
      config = const AppLockConfig.disabled(),
      status = AppLockStatus.disabled,
      lastPausedAt = null,
      failureMessage = null,
      isEnableInProgress = false;

  final bool isReady;
  final AppLockConfig config;
  final AppLockStatus status;
  final DateTime? lastPausedAt;
  final String? failureMessage;
  final bool isEnableInProgress;

  bool get allowsProtectedAccess {
    if (!isReady) {
      return false;
    }
    if (!config.enabled) {
      return true;
    }
    return status == AppLockStatus.unlocked;
  }

  bool get blocksProtectedAccess => !allowsProtectedAccess;

  AppLockState copyWith({
    bool? isReady,
    AppLockConfig? config,
    AppLockStatus? status,
    DateTime? lastPausedAt,
    bool clearLastPausedAt = false,
    String? failureMessage,
    bool clearFailureMessage = false,
    bool? isEnableInProgress,
  }) {
    return AppLockState(
      isReady: isReady ?? this.isReady,
      config: config ?? this.config,
      status: status ?? this.status,
      lastPausedAt: clearLastPausedAt
          ? null
          : lastPausedAt ?? this.lastPausedAt,
      failureMessage: clearFailureMessage
          ? null
          : failureMessage ?? this.failureMessage,
      isEnableInProgress: isEnableInProgress ?? this.isEnableInProgress,
    );
  }
}

enum AppUnlockAttemptStatus { success, failed, canceled, unavailable }

class AppUnlockAttemptResult {
  const AppUnlockAttemptResult(this.status, {this.message});

  const AppUnlockAttemptResult.success()
    : status = AppUnlockAttemptStatus.success,
      message = null;

  final AppUnlockAttemptStatus status;
  final String? message;
}

enum AppLockEnableStatus { enabled, failed, canceled, unavailable }

class AppLockEnableResult {
  const AppLockEnableResult(this.status, {this.message});

  bool get enabled => status == AppLockEnableStatus.enabled;

  final AppLockEnableStatus status;
  final String? message;
}

class ProtectedAccessLockedException implements Exception {
  const ProtectedAccessLockedException();

  @override
  String toString() => 'Protected content is locked.';
}
