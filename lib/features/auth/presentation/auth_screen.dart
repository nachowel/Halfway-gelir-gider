import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/router/route_access.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/hi_fi/hi_fi_screen_background.dart';
import '../../../shared/layout/mobile_scaffold.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({this.from, super.key});

  final String? from;

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(child: _LoginCard(from: from));
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({this.from, super.key});

  final String? from;

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(child: _SignUpCard(from: from));
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HiFiScreenBackground(
        child: SafeArea(
          child: MobileScaffold(
            maxWidth: 460,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenSide),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends ConsumerStatefulWidget {
  const _LoginCard({required this.from});

  final String? from;

  @override
  ConsumerState<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends ConsumerState<_LoginCard> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _emailSubmitting = false;
  bool _googleSubmitting = false;
  bool _passwordVisible = false;
  String? _emailError;
  String? _passwordError;

  bool get _busy => _emailSubmitting || _googleSubmitting;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    setState(() {
      _emailError = email.contains('@') ? null : 'Enter a valid email.';
      _passwordError = password.length >= 6
          ? null
          : 'Password must be at least 6 characters.';
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _emailSubmitting = true);
    try {
      await ref
          .watch(giderRepositoryProvider)
          .signIn(email: email, password: password);
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
        setState(() => _emailSubmitting = false);
      }
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _googleSubmitting = true);
    try {
      await ref.watch(giderRepositoryProvider).signInWithGoogle();
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
        setState(() => _googleSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthCardFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('GIDER', style: AppTypography.eye),
          const SizedBox(height: 14),
          Text(
            'Sign in',
            style: AppTypography.h1.copyWith(
              fontSize: 36,
              height: 1.0,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.72,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Use your email or Google to get back to this week.',
            style: AppTypography.body.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Email',
            style: AppTypography.meta.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          AppInput(
            controller: _emailController,
            readOnly: _busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            fillColor: AppColors.surface.withValues(alpha: 0.92),
            containerPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
            enabledBorderWidth: 1.3,
            focusedBorderWidth: 1.7,
            focusGlowOpacity: 0.16,
            inputPadding: const EdgeInsets.symmetric(vertical: 9),
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Password',
            style: AppTypography.meta.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          AppInput(
            controller: _passwordController,
            readOnly: _busy,
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            fillColor: AppColors.surface.withValues(alpha: 0.92),
            containerPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
            enabledBorderWidth: 1.3,
            focusedBorderWidth: 1.7,
            focusGlowOpacity: 0.16,
            inputPadding: const EdgeInsets.symmetric(vertical: 9),
            suffix: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _busy
                  ? null
                  : () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Sign in',
            onPressed: _busy ? null : _submit,
            size: AppButtonSize.compact,
            loading: _emailSubmitting,
          ),
          const SizedBox(height: 9),
          _QuietAuthSeparator(label: 'or continue with'),
          const SizedBox(height: 8),
          AppButton(
            label: 'Continue with Google',
            onPressed: _busy ? null : _submitGoogle,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.compact,
            loading: _googleSubmitting,
            leading: const _GoogleMark(),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: <Widget>[
                Text(
                  'Don’t have an account?',
                  style: AppTypography.bodySoft.copyWith(
                    fontSize: 11.8,
                    color: AppColors.inkSoft,
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          context.push(
                            buildAuthLocation(kSignupRoute, from: widget.from),
                          );
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    textStyle: AppTypography.button.copyWith(
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.brand.withValues(alpha: 0.45),
                      decorationThickness: 1.1,
                    ),
                  ),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCardFrame extends StatelessWidget {
  const _AuthCardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.95)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x18094A4D),
            offset: Offset(0, 12),
            blurRadius: 22,
            spreadRadius: -10,
          ),
          BoxShadow(
            color: Color(0x0C09282B),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: child,
      ),
    );
  }
}

class _QuietAuthSeparator extends StatelessWidget {
  const _QuietAuthSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.7),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: AppTypography.meta.copyWith(
              fontSize: 10.5,
              color: AppColors.inkFade,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1209282B),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Text(
        'G',
        style: AppTypography.button.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4285F4),
        ),
      ),
    );
  }
}

class _SignUpCard extends ConsumerStatefulWidget {
  const _SignUpCard({required this.from});

  final String? from;

  @override
  ConsumerState<_SignUpCard> createState() => _SignUpCardState();
}

class _SignUpCardState extends ConsumerState<_SignUpCard> {
  late final TextEditingController _businessController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _submitting = false;
  bool _passwordVisible = false;
  String? _businessError;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _businessController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _businessController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String businessName = _businessController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    setState(() {
      _businessError = businessName.isEmpty
          ? 'Enter your business name.'
          : null;
      _emailError = email.contains('@') ? null : 'Enter a valid email.';
      _passwordError = password.length >= 6
          ? null
          : 'Password must be at least 6 characters.';
    });
    if (_businessError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .watch(giderRepositoryProvider)
          .signUp(email: email, password: password, businessName: businessName);
      if (!mounted) return;
      context.go(buildAuthLocation(kLoginRoute, from: widget.from));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Account created. You can sign in now.'),
        ),
      );
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
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthCardFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: _submitting
                    ? null
                    : () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(
                          buildAuthLocation(kLoginRoute, from: widget.from),
                        );
                      },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  textStyle: AppTypography.meta.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkFade,
                  ),
                ),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 15,
                  color: AppColors.inkFade,
                ),
                label: const Text('Back'),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text('CREATE ACCOUNT', style: AppTypography.eye),
          const SizedBox(height: 8),
          Text(
            'Create your account',
            style: AppTypography.h1.copyWith(
              fontSize: 30,
              height: 1.04,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your business and start tracking.',
            style: AppTypography.body.copyWith(
              height: 1.32,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Business name',
            style: AppTypography.meta.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          AppInput(
            controller: _businessController,
            readOnly: _submitting,
            textInputAction: TextInputAction.next,
            errorText: _businessError,
            helper: 'Shown on your dashboard and in settings.',
            fillColor: AppColors.surface.withValues(alpha: 0.92),
            containerPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
            enabledBorderWidth: 1.3,
            focusedBorderWidth: 1.7,
            focusGlowOpacity: 0.16,
            inputPadding: const EdgeInsets.symmetric(vertical: 9),
            onChanged: (_) {
              if (_businessError != null) setState(() => _businessError = null);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Email',
            style: AppTypography.meta.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          AppInput(
            controller: _emailController,
            readOnly: _submitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            fillColor: AppColors.surface.withValues(alpha: 0.92),
            containerPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
            enabledBorderWidth: 1.3,
            focusedBorderWidth: 1.7,
            focusGlowOpacity: 0.16,
            inputPadding: const EdgeInsets.symmetric(vertical: 9),
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Password',
            style: AppTypography.meta.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          AppInput(
            controller: _passwordController,
            readOnly: _submitting,
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            fillColor: AppColors.surface.withValues(alpha: 0.92),
            containerPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
            enabledBorderWidth: 1.3,
            focusedBorderWidth: 1.7,
            focusGlowOpacity: 0.16,
            inputPadding: const EdgeInsets.symmetric(vertical: 9),
            suffix: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _submitting
                  ? null
                  : () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Create account',
            onPressed: _submitting ? null : _submit,
            size: AppButtonSize.compact,
            loading: _submitting,
          ),
        ],
      ),
    );
  }
}
