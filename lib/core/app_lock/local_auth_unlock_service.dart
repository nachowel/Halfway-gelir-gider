import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/types/auth_exception.dart';

import 'app_lock_models.dart';

abstract class AppUnlockService {
  Future<bool> isLocalAuthenticationAvailable();

  Future<AppUnlockAttemptResult> authenticate({
    required String localizedReason,
  });
}

class LocalAuthUnlockService implements AppUnlockService {
  LocalAuthUnlockService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> isLocalAuthenticationAvailable() async {
    if (kIsWeb) {
      return false;
    }
    try {
      // This is intentionally not a biometrics-only check. local_auth uses
      // this signal for biometric or device credential authentication support.
      return _localAuthentication.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AppUnlockAttemptResult> authenticate({
    required String localizedReason,
  }) async {
    if (!await isLocalAuthenticationAvailable()) {
      return const AppUnlockAttemptResult(
        AppUnlockAttemptStatus.unavailable,
        message: 'Device authentication is unavailable.',
      );
    }

    try {
      final bool unlocked = await _localAuthentication.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
      if (unlocked) {
        return const AppUnlockAttemptResult.success();
      }
      return const AppUnlockAttemptResult(AppUnlockAttemptStatus.failed);
    } on LocalAuthException catch (error) {
      return _mapLocalAuthException(error);
    } catch (_) {
      return const AppUnlockAttemptResult(
        AppUnlockAttemptStatus.unavailable,
        message: 'Device authentication is unavailable.',
      );
    }
  }

  AppUnlockAttemptResult _mapLocalAuthException(LocalAuthException error) {
    return switch (error.code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout => const AppUnlockAttemptResult(
        AppUnlockAttemptStatus.canceled,
      ),
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
      LocalAuthExceptionCode.uiUnavailable => AppUnlockAttemptResult(
        AppUnlockAttemptStatus.unavailable,
        message: error.description ?? 'Device authentication is unavailable.',
      ),
      LocalAuthExceptionCode.authInProgress ||
      LocalAuthExceptionCode.temporaryLockout ||
      LocalAuthExceptionCode.biometricLockout ||
      LocalAuthExceptionCode.userRequestedFallback ||
      LocalAuthExceptionCode.deviceError ||
      LocalAuthExceptionCode.unknownError => AppUnlockAttemptResult(
        AppUnlockAttemptStatus.failed,
        message: error.description,
      ),
    };
  }
}

class UnsupportedAppUnlockService implements AppUnlockService {
  const UnsupportedAppUnlockService();

  @override
  Future<bool> isLocalAuthenticationAvailable() async => false;

  @override
  Future<AppUnlockAttemptResult> authenticate({
    required String localizedReason,
  }) async {
    return const AppUnlockAttemptResult(
      AppUnlockAttemptStatus.unavailable,
      message: 'Device authentication is unavailable.',
    );
  }
}
