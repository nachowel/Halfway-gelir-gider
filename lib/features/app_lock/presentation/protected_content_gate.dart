import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/app_lock/app_lock_controller.dart';
import '../../../core/app_lock/app_lock_models.dart';
import '../../../l10n/app_localizations.dart';
import 'app_lock_screen.dart';

class ProtectedContentGate extends ConsumerWidget {
  const ProtectedContentGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool allowsProtectedAccess = ref.watch(
      appLockAllowsProtectedAccessProvider,
    );
    if (allowsProtectedAccess) {
      return child;
    }

    final bool appLockReady = ref.watch(
      appLockControllerProvider.select((AppLockState state) => state.isReady),
    );
    if (!appLockReady) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.sm),
              Text(context.strings.checkingAppLock),
            ],
          ),
        ),
      );
    }

    return const AppLockScreen();
  }
}

class AppLockLifecycleObserver extends ConsumerStatefulWidget {
  const AppLockLifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockLifecycleObserver> createState() =>
      _AppLockLifecycleObserverState();
}

class _AppLockLifecycleObserverState
    extends ConsumerState<AppLockLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final AppLockController controller = ref.read(
      appLockControllerProvider.notifier,
    );
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        controller.markPaused();
      case AppLifecycleState.resumed:
        controller.handleResumed();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
