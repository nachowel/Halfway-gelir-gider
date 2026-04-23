import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/app_lock/app_lock_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _signingOut = false;

  Future<void> _unlock() async {
    await ref
        .read(appLockControllerProvider.notifier)
        .unlock(localizedReason: context.strings.appLockUnlockReason);
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(giderRepositoryProvider).signOut();
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final AppLockState state = ref.watch(appLockControllerProvider);
    final bool unlocking = state.status == AppLockStatus.unlocking;
    final bool unavailable = state.status == AppLockStatus.unavailable;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenSide),
            child: Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              child: HiFiCard(
                child: FocusTraversalGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(
                        unavailable
                            ? Icons.lock_clock_rounded
                            : Icons.lock_rounded,
                        size: 36,
                        color: AppColors.ink,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        unavailable
                            ? strings.appLockUnavailableTitle
                            : strings.appLockTitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.h2,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        unavailable
                            ? strings.appLockUnavailableBody
                            : strings.appLockBody,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySoft.copyWith(height: 1.45),
                      ),
                      if (state.failureMessage != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.failureMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.meta.copyWith(
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      HiFiButton(
                        label: unavailable
                            ? strings.tryAgain
                            : strings.appLockUnlockAction,
                        loading: unlocking,
                        onPressed: unlocking ? null : _unlock,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      HiFiButton(
                        label: strings.signOut,
                        variant: HiFiButtonVariant.ghost,
                        loading: _signingOut,
                        onPressed: _signingOut ? null : _signOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
