import 'package:flutter/material.dart';

import '../widgets/app_chip.dart';

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

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      selected: selected,
      onTap: onTap,
      tone: tone == HiFiFilterChipTone.brand
          ? AppChipTone.brand
          : AppChipTone.ink,
    );
  }
}

enum HiFiFilterChipTone { ink, brand }
