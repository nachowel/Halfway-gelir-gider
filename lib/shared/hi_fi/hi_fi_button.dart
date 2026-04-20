import 'package:flutter/material.dart';

import '../widgets/app_button.dart';

enum HiFiButtonVariant { primary, income, expense, ghost, ink }

enum HiFiButtonSize { regular, compact }

extension on HiFiButtonVariant {
  AppButtonVariant get asAppVariant {
    switch (this) {
      case HiFiButtonVariant.primary:
        return AppButtonVariant.primary;
      case HiFiButtonVariant.income:
        return AppButtonVariant.income;
      case HiFiButtonVariant.expense:
        return AppButtonVariant.expense;
      case HiFiButtonVariant.ghost:
        return AppButtonVariant.ghost;
      case HiFiButtonVariant.ink:
        return AppButtonVariant.ink;
    }
  }
}

extension on HiFiButtonSize {
  AppButtonSize get asAppSize {
    switch (this) {
      case HiFiButtonSize.regular:
        return AppButtonSize.regular;
      case HiFiButtonSize.compact:
        return AppButtonSize.compact;
    }
  }
}

class HiFiButton extends StatelessWidget {
  const HiFiButton({
    required this.label,
    required this.onPressed,
    this.variant = HiFiButtonVariant.primary,
    this.size = HiFiButtonSize.regular,
    this.leading,
    this.trailing,
    this.expanded = true,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final HiFiButtonVariant variant;
  final HiFiButtonSize size;
  final Widget? leading;
  final Widget? trailing;
  final bool expanded;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: variant.asAppVariant,
      size: size.asAppSize,
      leading: leading,
      trailing: trailing,
      expanded: expanded,
      loading: loading,
    );
  }
}
