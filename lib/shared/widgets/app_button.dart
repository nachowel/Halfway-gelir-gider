import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, income, expense, ink }

enum AppButtonSize { regular, compact }

class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.leading,
    this.trailing,
    this.loading = false,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final Widget? trailing;
  final bool loading;
  final bool expanded;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;
  bool _hovered = false;

  bool get _disabled => widget.onPressed == null || widget.loading;

  ({Color background, Color foreground, Color border}) _colors() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (
          background: AppColors.brand,
          foreground: AppColors.onInk,
          border: AppColors.brand,
        );
      case AppButtonVariant.secondary:
        return (
          background: AppColors.surface,
          foreground: AppColors.brand,
          border: AppColors.brand.withValues(alpha: 0.7),
        );
      case AppButtonVariant.ghost:
        return (
          background: Colors.transparent,
          foreground: AppColors.inkSoft,
          border: AppColors.border,
        );
      case AppButtonVariant.income:
        return (
          background: AppColors.income,
          foreground: AppColors.onInk,
          border: AppColors.income,
        );
      case AppButtonVariant.expense:
        return (
          background: AppColors.expense,
          foreground: AppColors.onInk,
          border: AppColors.expense,
        );
      case AppButtonVariant.ink:
        return (
          background: AppColors.ink,
          foreground: AppColors.onInk,
          border: AppColors.ink,
        );
    }
  }

  EdgeInsetsGeometry get _padding {
    switch (widget.size) {
      case AppButtonSize.regular:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      case AppButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    }
  }

  void _setPressed(bool value) {
    if (_pressed == value || _disabled) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value || _disabled) {
      return;
    }
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final ({Color background, Color foreground, Color border}) colors =
        _colors();
    final bool filled = widget.variant != AppButtonVariant.ghost &&
        widget.variant != AppButtonVariant.secondary;
    final BoxDecoration decoration = BoxDecoration(
      color: _disabled
          ? colors.background.withValues(alpha: filled ? 0.45 : 0.18)
          : _hovered && filled
          ? Color.lerp(colors.background, Colors.white, 0.05)
          : colors.background,
      borderRadius: BorderRadius.circular(AppRadius.button),
      border: Border.all(
        color: _disabled
            ? colors.border.withValues(alpha: 0.35)
            : colors.border,
      ),
      boxShadow: filled && !_disabled
          ? (_hovered && !_pressed ? AppShadows.md : AppShadows.sm)
          : const <BoxShadow>[],
    );

    final Widget content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.loading) ...<Widget>[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.leading != null) ...<Widget>[
          IconTheme(
            data: IconThemeData(color: colors.foreground, size: 18),
            child: widget.leading!,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.button.copyWith(
              color: _disabled
                  ? colors.foreground.withValues(alpha: 0.7)
                  : colors.foreground,
            ),
          ),
        ),
        if (!widget.loading && widget.trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(color: colors.foreground, size: 18),
            child: widget.trailing!,
          ),
        ],
      ],
    );

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedSlide(
        offset: _hovered && !_pressed ? const Offset(0, -0.02) : Offset.zero,
        duration: const Duration(milliseconds: 140),
        curve: AppEasing.expressive,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: _pressed
              ? const Duration(milliseconds: 80)
              : const Duration(milliseconds: 140),
          curve: _pressed ? AppEasing.standard : AppEasing.expressive,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _disabled ? null : widget.onPressed,
              onTapDown: (_) => _setPressed(true),
              onTapCancel: () => _setPressed(false),
              onTapUp: (_) => _setPressed(false),
              borderRadius: BorderRadius.circular(AppRadius.button),
              splashColor: colors.foreground.withValues(alpha: 0.08),
              highlightColor: colors.foreground.withValues(alpha: 0.04),
              child: Ink(
                decoration: decoration,
                child: Padding(padding: _padding, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
