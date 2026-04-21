import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_typography.dart';

/// Pill from hi-fi `.pill` family — used for status, delta, semantic state.
/// Full-pill radius, 11px/500 Inter, 3x10 padding.
enum HiFiPillTone {
  neutral,
  brand,
  brandSoft,
  income,
  expense,
  amber,
  dark,
  ghost,
}

class HiFiPill extends StatelessWidget {
  const HiFiPill({
    required this.label,
    this.tone = HiFiPillTone.neutral,
    this.leading,
    super.key,
  });

  final String label;
  final HiFiPillTone tone;
  final Widget? leading;

  ({Color bg, Color fg, Color border}) _colors() {
    switch (tone) {
      case HiFiPillTone.neutral:
        return (
          bg: AppColors.surface2,
          fg: AppColors.inkSoft,
          border: AppColors.border,
        );
      case HiFiPillTone.brand:
        return (
          bg: AppColors.brand,
          fg: AppColors.onInk,
          border: AppColors.brand,
        );
      case HiFiPillTone.brandSoft:
        return (
          bg: AppColors.brandSoft,
          fg: AppColors.brandStrong,
          border: Colors.transparent,
        );
      case HiFiPillTone.income:
        return (
          bg: AppColors.incomeSoft,
          fg: AppColors.incomeInk,
          border: Colors.transparent,
        );
      case HiFiPillTone.expense:
        return (
          bg: AppColors.expenseSoft,
          fg: AppColors.expenseInk,
          border: Colors.transparent,
        );
      case HiFiPillTone.amber:
        return (
          bg: AppColors.amberSoft,
          fg: AppColors.amberInk,
          border: Colors.transparent,
        );
      case HiFiPillTone.dark:
        return (bg: AppColors.ink, fg: AppColors.onInk, border: AppColors.ink);
      case HiFiPillTone.ghost:
        return (
          bg: Colors.transparent,
          fg: AppColors.inkSoft,
          border: AppColors.border,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            IconTheme.merge(
              data: IconThemeData(color: c.fg, size: 12),
              child: leading!,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.delta.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
