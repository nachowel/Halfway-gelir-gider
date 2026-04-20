import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import '../../../shared/hi_fi/hi_fi_settings_group.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _signingOut = false;

  Future<void> _editBusinessName(BusinessSettingsData settings) async {
    final TextEditingController controller = TextEditingController(
      text: settings.businessName,
    );
    final TextEditingController emailController = TextEditingController(
      text: settings.email,
    );
    String? errorText;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final NavigatorState navigator = Navigator.of(sheetContext);

            Future<void> save() async {
              final String value = controller.text.trim();
              if (value.isEmpty) {
                setSheetState(
                  () => errorText = 'Business name cannot be empty.',
                );
                return;
              }

              setSheetState(() => saving = true);
              try {
                await ref
                    .read(giderRepositoryProvider)
                    .updateBusinessName(value);
                ref.read(refreshKeyProvider.notifier).state++;
                if (!mounted) {
                  return;
                }
                navigator.pop();
              } on AuthException catch (error) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.expense,
                    content: Text(error.message),
                  ),
                );
              } finally {
                if (mounted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            return HiFiBottomSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('PROFILE', style: AppTypography.eye),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.h2,
                      children: <InlineSpan>[
                        const TextSpan(text: 'Update '),
                        TextSpan(
                          text: 'business',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.brand,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const TextSpan(text: ' name'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HiFiInputField(
                    controller: controller,
                    label: 'Business name',
                    errorText: errorText,
                    autofocus: true,
                    readOnly: saving,
                    onChanged: (_) {
                      if (errorText != null) {
                        setSheetState(() => errorText = null);
                      }
                    },
                    onSubmitted: (_) => save(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  HiFiInputField(
                    controller: emailController,
                    label: 'Email',
                    readOnly: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: HiFiButton(
                          label: 'Cancel',
                          variant: HiFiButtonVariant.ghost,
                          onPressed: saving
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        flex: 16,
                        child: HiFiButton(
                          label: 'Save changes',
                          loading: saving,
                          onPressed: saving ? null : save,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();
    emailController.dispose();
  }

  Future<void> _confirmSignOut() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return HiFiBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('SECURITY', style: AppTypography.eye),
              const SizedBox(height: 4),
              Text('Sign out of this device?', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This closes the current session and returns to the auth flow.',
                style: AppTypography.bodySoft.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: HiFiButton(
                      label: 'Cancel',
                      variant: HiFiButtonVariant.ghost,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 16,
                    child: HiFiButton(
                      label: 'Sign out',
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
                  text: 'Settings',
                  style: AppTypography.h1.copyWith(
                    color: AppColors.brand,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Preferences & account', style: AppTypography.lbl),
          const SizedBox(height: AppSpacing.sm),
          _ProfileCard(
            businessName: settings.businessName,
            email: settings.email,
            timezone: settings.timezone,
            onTap: () => _editBusinessName(settings),
          ),
          const SizedBox(height: AppSpacing.lg),
          HiFiSettingsGroup(
            title: 'Preferences',
            rows: <HiFiSettingsGroupRowData>[
              HiFiSettingsGroupRowData(
                label: 'Week starts',
                trailing: HiFiReadonlyPillValue(
                  label: settings.weekStartsOn == 1 ? 'Monday' : 'Custom',
                ),
              ),
              HiFiSettingsGroupRowData(
                label: 'Currency',
                trailing: HiFiReadonlyPillValue(label: settings.currency),
              ),
              HiFiSettingsGroupRowData(
                label: 'Timezone',
                trailing: HiFiReadonlyPillValue(label: settings.timezone),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          HiFiSettingsGroup(
            title: 'Data',
            rows: <HiFiSettingsGroupRowData>[
              HiFiSettingsGroupRowData(
                label: 'Categories',
                value: '7 expense · 3 income',
                onTap: () => context.push('/settings/categories'),
              ),
              HiFiSettingsGroupRowData(
                label: 'Recurring expenses',
                value: '5 active',
                onTap: () => context.push('/settings/recurring'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          HiFiSettingsGroup(
            title: 'Security',
            rows: <HiFiSettingsGroupRowData>[
              HiFiSettingsGroupRowData(
                label: 'Sign out',
                destructive: true,
                onTap: _confirmSignOut,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text('gider · v1.0 · private', style: AppTypography.meta),
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
              Text('We could not load your settings.', style: AppTypography.h2),
              const SizedBox(height: 8),
              Text(error.toString(), style: AppTypography.bodySoft),
              const SizedBox(height: AppSpacing.md),
              HiFiButton(
                label: 'Try again',
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
