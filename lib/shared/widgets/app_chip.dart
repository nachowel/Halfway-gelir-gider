import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

enum AppChipTone { ink, brand }

class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone = AppChipTone.ink,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final AppChipTone tone;

  ({Color bg, Color fg, Color border}) _colors() {
    if (!selected) {
      return (
        bg: const Color(0x8CFFFFFF),
        fg: AppColors.inkSoft,
        border: AppColors.borderSoft,
      );
    }

    switch (tone) {
      case AppChipTone.ink:
        return (bg: AppColors.ink, fg: AppColors.onInk, border: AppColors.ink);
      case AppChipTone.brand:
        return (
          bg: AppColors.brand,
          fg: AppColors.onInk,
          border: AppColors.brand,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg, Color border}) colors = _colors();

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: colors.fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
