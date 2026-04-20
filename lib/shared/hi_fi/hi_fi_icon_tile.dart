import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Rounded icon container from hi-fi `.av` family:
///   default 38x38 rounded 12, brand-tint bg + brand icon + soft border
///   .sm 32x32 rounded 10
///   .round circle
///   tonal variants: mint, amber, income, expense, ink
enum HiFiIconTileTone { brand, mint, amber, income, expense, ink }

enum HiFiIconTileSize { regular, small }

enum HiFiIconTileShape { rounded, circle }

class HiFiIconTile extends StatelessWidget {
  const HiFiIconTile({
    required this.icon,
    this.tone = HiFiIconTileTone.brand,
    this.size = HiFiIconTileSize.regular,
    this.shape = HiFiIconTileShape.rounded,
    super.key,
  });

  final IconData icon;
  final HiFiIconTileTone tone;
  final HiFiIconTileSize size;
  final HiFiIconTileShape shape;

  ({Color bg, Color fg, Color border}) _colors() {
    switch (tone) {
      case HiFiIconTileTone.brand:
        return (
          bg: AppColors.brandTint,
          fg: AppColors.brand,
          border: const Color(0x260E6B6F), // rgba(14,107,111,0.15)
        );
      case HiFiIconTileTone.mint:
        return (
          bg: AppColors.mint,
          fg: const Color(0xFF2F5A3A),
          border: const Color(0x2E2F8A4D),
        );
      case HiFiIconTileTone.amber:
        return (
          bg: AppColors.amberSoft,
          fg: AppColors.amberInk,
          border: const Color(0x40E8A93A),
        );
      case HiFiIconTileTone.income:
        return (
          bg: AppColors.incomeSoft,
          fg: AppColors.incomeInk,
          border: const Color(0x332F8A4D),
        );
      case HiFiIconTileTone.expense:
        return (
          bg: AppColors.expenseSoft,
          fg: AppColors.expenseInk,
          border: const Color(0x38C2492A),
        );
      case HiFiIconTileTone.ink:
        return (bg: AppColors.ink, fg: AppColors.onInk, border: AppColors.ink);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final double side = size == HiFiIconTileSize.regular ? 38 : 32;
    final double radius = shape == HiFiIconTileShape.circle
        ? side / 2
        : size == HiFiIconTileSize.regular
        ? AppRadius.iconTile
        : AppRadius.iconTileSm;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.border),
      ),
      child: Icon(icon, size: 18, color: c.fg),
    );
  }
}
