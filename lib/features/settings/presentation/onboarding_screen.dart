import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import '../../../shared/hi_fi/hi_fi_screen_background.dart';
import '../../../shared/hi_fi/hi_fi_settings_group.dart';
import '../../../shared/layout/mobile_scaffold.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BusinessSettingsData> settingsState = ref.watch(
      businessSettingsProvider,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HiFiScreenBackground(
        child: SafeArea(
          child: MobileScaffold(
            maxWidth: 460,
            child: settingsState.when(
              data: (BusinessSettingsData data) =>
                  _OnboardingForm(initialData: data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenSide),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('SETUP', style: AppTypography.eye),
                      const SizedBox(height: 8),
                      Text(
                        'We could not load your setup.',
                        style: AppTypography.h2,
                      ),
                      const SizedBox(height: 8),
                      Text(error.toString(), style: AppTypography.bodySoft),
                      const SizedBox(height: AppSpacing.md),
                      HiFiButton(
                        label: 'Try again',
                        onPressed: () =>
                            ref.invalidate(businessSettingsProvider),
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

class _OnboardingForm extends ConsumerStatefulWidget {
  const _OnboardingForm({required this.initialData});

  final BusinessSettingsData initialData;

  @override
  ConsumerState<_OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends ConsumerState<_OnboardingForm> {
  late final TextEditingController _businessController;
  bool _submitting = false;
  String? _businessError;

  @override
  void initState() {
    super.initState();
    _businessController = TextEditingController(
      text: widget.initialData.businessName,
    );
  }

  @override
  void dispose() {
    _businessController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String businessName = _businessController.text.trim();
    setState(() {
      _businessError = businessName.isEmpty
          ? 'Enter your business name.'
          : null;
    });
    if (_businessError != null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(giderRepositoryProvider).updateBusinessName(businessName);
      ref.read(refreshKeyProvider.notifier).state++;
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
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenSide,
        AppSpacing.lg,
        AppSpacing.screenSide,
        AppSpacing.lg,
      ),
      children: <Widget>[
        Text('SETUP', style: AppTypography.eye),
        const SizedBox(height: 8),
        Text(
          'Finish your business setup',
          style: AppTypography.h1.copyWith(
            fontSize: 34,
            height: 1.02,
            letterSpacing: -0.68,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We lock the app to UK defaults. Add your business name once and continue.',
          style: AppTypography.body.copyWith(
            color: AppColors.inkSoft,
            height: 1.38,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        HiFiInputField(
          controller: _businessController,
          label: 'Business name',
          helper: widget.initialData.email,
          errorText: _businessError,
          autofocus: true,
          readOnly: _submitting,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_businessError != null) {
              setState(() => _businessError = null);
            }
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        const HiFiSettingsGroup(
          title: 'Business defaults',
          rows: <HiFiSettingsGroupRowData>[
            HiFiSettingsGroupRowData(
              label: 'Currency',
              trailing: HiFiReadonlyPillValue(label: 'GBP £'),
            ),
            HiFiSettingsGroupRowData(
              label: 'Timezone',
              trailing: HiFiReadonlyPillValue(label: 'Europe/London'),
            ),
            HiFiSettingsGroupRowData(
              label: 'Week starts',
              trailing: HiFiReadonlyPillValue(label: 'Monday'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        HiFiButton(
          label: 'Continue',
          onPressed: _submitting ? null : _submit,
          loading: _submitting,
        ),
      ],
    );
  }
}
