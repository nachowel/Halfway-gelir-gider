import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class SecureWindowController {
  Future<void> setSecure(bool secure);
}

class AndroidSecureWindowController implements SecureWindowController {
  AndroidSecureWindowController({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.nacho.gider/window_secure');

  final MethodChannel _channel;

  @override
  Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', <String, Object>{
        'secure': secure,
      });
    } on MissingPluginException {
      // Host side not registered (e.g. running a host-side unit test). Swallow.
    } on PlatformException {
      // Best-effort hardening; failing to toggle the flag must not crash the app.
    }
  }
}

class NoopSecureWindowController implements SecureWindowController {
  const NoopSecureWindowController();

  @override
  Future<void> setSecure(bool secure) async {}
}

SecureWindowController defaultSecureWindowController() {
  if (kIsWeb) {
    return const NoopSecureWindowController();
  }
  if (Platform.isAndroid) {
    return AndroidSecureWindowController();
  }
  return const NoopSecureWindowController();
}
