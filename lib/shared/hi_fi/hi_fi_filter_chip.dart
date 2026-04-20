import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

/// Chip from hi-fi `.chip` / `.chip.on` / `.chip.brand`.
///   padding 5px 11px, full pill, 11.5px/500 Inter
///   default: translucent white + soft border
///   selected: ink fill + cream label
class HiFiFilterChip extends StatelessWidget {
  const HiFiFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone = HiFiFilterChipTone.ink,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final HiFiFilterChipTone tone;

  ({Color bg, Color fg, Color border}) _colors() {
    if (!selected) {
      return (
        bg: const Color(0x8CFFFFFF), // rgba(255,255,255,0.55)
        fg: AppColors.inkSoft,
        border: AppColors.borderSoft,
      );
    }
    switch (tone) {
      case HiFiFilterChipTone.ink:
        return (bg: AppColors.ink, fg: AppColors.onInk, border: AppColors.ink);
      case HiFiFilterChipTone.brand:
        return (
          bg: AppColors.brand,
          fg: AppColors.onInk,
          border: AppColors.brand,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    return Material(
      color: c.bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: c.fg,
            ),
          ),
        ),
      ),
    );
  }
}

enum HiFiFilterChipTone { ink, brand }
