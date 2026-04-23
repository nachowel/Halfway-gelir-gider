import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/app_lock/app_lock_models.dart';
import '../../../data/app_models.dart';
import '../../../l10n/app_locale.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import '../../../shared/hi_fi/hi_fi_settings_group.dart';
import '../../../shared/overlay/app_overlay.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;

  Future<void> _editBusinessName(BusinessSettingsData settings) async {
    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditBusinessNameSheet(settings: settings),
    );
  }

  Future<void> _confirmSignOut() async {
    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return HiFiBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                sheetContext.strings.security.toUpperCase(),
                style: AppTypography.eye,
              ),
              const SizedBox(height: 4),
              Text(
                sheetContext.strings.signOutDeviceQuestion,
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                sheetContext.strings.signOutDeviceBody,
                style: AppTypography.bodySoft.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: HiFiButton(
                      label: sheetContext.strings.cancel,
                      variant: HiFiButtonVariant.ghost,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: HiFiButton(
                      label: sheetContext.strings.signOut,
                      variant: HiFiButtonVariant.expense,
                      loading: _signingOut,
                      onPressed: _signingOut
                          ? null
                          : () {
                              Navigator.of(sheetContext).pop();
                              _signOut();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickLanguage(AppLocale currentLocale) async {
    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppLocalizations strings = sheetContext.strings;
        return HiFiBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.language.toUpperCase(), style: AppTypography.eye),
              const SizedBox(height: 4),
              Text(strings.chooseLanguage, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.languageAppliesImmediately,
                style: AppTypography.bodySoft.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final AppLocale locale in AppLocale.values) ...<Widget>[
                HiFiSettingsGroup(
                  title: '',
                  rows: <HiFiSettingsGroupRowData>[
                    HiFiSettingsGroupRowData(
                      label: strings.languageName(locale),
                      trailing: currentLocale == locale
                          ? const HiFiReadonlyPillValue(label: '✓')
                          : null,
                      onTap: () async {
                        await ref
                            .read(appLocaleProvider.notifier)
                            .setLocale(locale);
                        if (!sheetContext.mounted) {
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
                if (locale != AppLocale.values.last)
                  const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleAppLock(bool value) async {
    final AppLocalizations strings = context.strings;
    if (!value) {
      await ref.read(appLockControllerProvider.notifier).disable();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(strings.appLockEnableReason),
      ),
    );

    final AppLockEnableResult result = await ref
        .read(appLockControllerProvider.notifier)
        .enable(localizedReason: strings.appLockEnableReason);

    if (!mounted) {
      return;
    }

    final String message = switch (result.status) {
      AppLockEnableStatus.enabled => strings.appLockTurnedOn,
      AppLockEnableStatus.unavailable => strings.appLockUnavailableEnable,
      AppLockEnableStatus.canceled => strings.appLockCanceled,
      AppLockEnableStatus.failed =>
        result.message ?? strings.genericErrorTryAgain,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.enabled ? AppColors.income : AppColors.expense,
        content: Text(message),
      ),
    );
  }

  Future<void> _pickAppLockTimeout(AppLockTimeout currentTimeout) async {
    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppLocalizations strings = sheetContext.strings;
        return HiFiBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.security.toUpperCase(), style: AppTypography.eye),
              const SizedBox(height: 4),
              Text(strings.appLockTimeout, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              for (final AppLockTimeout timeout in AppLockTimeout.values)
                HiFiSettingsGroup(
                  title: '',
                  rows: <HiFiSettingsGroupRowData>[
                    HiFiSettingsGroupRowData(
                      label: strings.appLockTimeoutOptionLabel(timeout),
                      trailing: timeout == currentTimeout
                          ? const HiFiReadonlyPillValue(label: '✓')
                          : null,
                      onTap: () async {
                        await ref
                            .read(appLockControllerProvider.notifier)
                            .setTimeout(timeout);
                        if (!sheetContext.mounted) {
                          return;
                        }
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await ref.read(giderRepositoryProvider).signOut();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.expense,
          content: Text(error.message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final AppLocale currentLocale = ref.watch(appLocaleProvider);
    final bool appLockSupported = ref.watch(appLockSupportedPlatformProvider);
    final AppLockState appLockState = ref.watch(appLockControllerProvider);
    final AsyncValue<BusinessSettingsData> settingsState = ref.watch(
      businessSettingsProvider,
    );

    return settingsState.when(
      data: (BusinessSettingsData settings) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenSide,
          AppSpacing.xs,
          AppSpacing.screenSide,
          120,
        ),
        children: <Widget>[
          RichText(
            text: TextSpan(
              style: AppTypography.h1,
              children: <InlineSpan>[
                TextSpan(
                  text: strings.settings,
                  style: AppTypography.h1.copyWith(
                    color: AppColors.brand,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(strings.preferencesAccount, style: AppTypography.lbl),
          const SizedBox(height: AppSpacing.sm),
          _ProfileCard(
            businessName: settings.businessName,
            email: settings.email,
            timezone: settings.timezone,
            onTap: () => _editBusinessName(settings),
          ),
          const SizedBox(height: AppSpacing.lg),
          HiFiSettingsGroup(
            title: strings.preferences,
            rows: <HiFiSettingsGroupRowData>[
              HiFiSettingsGroupRowData(
                label: strings.language,
                trailing: HiFiReadonlyPillValue(
                  label: strings.languageName(currentLocale),
                ),
                onTap: () => _pickLanguage(currentLocale),
              ),
              HiFiSettingsGroupRowData(
                label: strings.weekStarts,
                trailing: HiFiReadonlyPillValue(
                  label: settings.weekStartsOn == 1
                      ? strings.monday
                      : strings.customWeekStart,
                ),
              ),
              HiFiSettingsGroupRowData(
                label: strings.currency,
                trailing: HiFiReadonlyPillValue(label: settings.currency),
              ),
              HiFiSettingsGroupRowData(
                label: strings.timezone,
                trailing: HiFiReadonlyPillValue(label: settings.timezone),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          HiFiSettingsGroup(
            title: strings.data,
            rows: <HiFiSettingsGroupRowData>[
              HiFiSettingsGroupRowData(
                label: strings.categories,
                value:
                    '7 ${strings.expense.toLowerCase()} · 3 ${strings.income.toLowerCase()}',
                onTap: () => context.push('/settings/categories'),
              ),
              HiFiSettingsGroupRowData(
                label: strings.suppliers,
                onTap: () => context.push('/settings/suppliers'),
              ),
              HiFiSettingsGroupRowData(
                label: strings.recurringExpenses,
                value: '5 ${strings.active.toLowerCase()}',
                onTap: () => context.push('/settings/recurring'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          HiFiSettingsGroup(
            title: strings.security,
            rows: <HiFiSettingsGroupRowData>[
              if (appLockSupported)
                HiFiSettingsGroupRowData(
                  label: strings.appLock,
                  trailing: Switch(
                    key: const ValueKey<String>('app-lock-toggle'),
                    value: appLockState.isReady && appLockState.config.enabled,
                    onChanged:
                        !appLockState.isReady || appLockState.isEnableInProgress
                        ? null
                        : _toggleAppLock,
                  ),
                ),
              if (appLockSupported && appLockState.config.enabled)
                HiFiSettingsGroupRowData(
                  label: strings.appLockTimeout,
                  trailing: HiFiReadonlyPillValue(
                    label: strings.appLockTimeoutOptionLabel(
                      appLockState.config.timeout,
                    ),
                  ),
                  onTap: () => _pickAppLockTimeout(appLockState.config.timeout),
                ),
              HiFiSettingsGroupRowData(
                label: strings.signOut,
                destructive: true,
                onTap: _confirmSignOut,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(strings.versionPrivate, style: AppTypography.meta),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenSide),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(strings.settingsLoadError, style: AppTypography.h2),
              const SizedBox(height: 8),
              Text(error.toString(), style: AppTypography.bodySoft),
              const SizedBox(height: AppSpacing.md),
              HiFiButton(
                label: strings.tryAgain,
                onPressed: () => ref.invalidate(businessSettingsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.businessName,
    required this.email,
    required this.timezone,
    required this.onTap,
  });

  final String businessName;
  final String email;
  final String timezone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HiFiCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink),
                ),
                alignment: Alignment.center,
                child: Text(
                  businessName.characters.first.toUpperCase(),
                  style: AppTypography.numMd.copyWith(color: AppColors.onInk),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      businessName,
                      style: AppTypography.body.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$email · $timezone',
                      style: AppTypography.meta.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.inkFade,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditBusinessNameSheet extends ConsumerStatefulWidget {
  const _EditBusinessNameSheet({required this.settings});

  final BusinessSettingsData settings;

  @override
  ConsumerState<_EditBusinessNameSheet> createState() =>
      _EditBusinessNameSheetState();
}

class _EditBusinessNameSheetState
    extends ConsumerState<_EditBusinessNameSheet> {
  late final TextEditingController _businessController;
  late final TextEditingController _emailController;

  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _businessController = TextEditingController(
      text: widget.settings.businessName,
    );
    _emailController = TextEditingController(text: widget.settings.email);
  }

  @override
  void dispose() {
    _businessController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String value = _businessController.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = context.strings.businessNameCannotBeEmpty);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(giderRepositoryProvider).updateBusinessName(value);
      ref.read(refreshKeyProvider.notifier).state++;
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.expense,
          content: Text(error.message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.profile.toUpperCase(), style: AppTypography.eye),
          const SizedBox(height: 4),
          Text(strings.updateBusinessName, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          HiFiInputField(
            controller: _businessController,
            label: strings.businessName,
            errorText: _errorText,
            autofocus: true,
            readOnly: _saving,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.sm),
          HiFiInputField(
            controller: _emailController,
            label: strings.email,
            readOnly: true,
          ),
          const SizedBox(height: AppSpacing.md),
          HiFiButton(
            label: strings.saveChanges,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
