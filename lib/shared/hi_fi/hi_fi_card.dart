import 'package:flutter/material.dart';

import '../widgets/app_card.dart';

enum HiFiCardVariant { surface, mint, teal, highlight }

enum HiFiCardElevation { sm, md, lg, none }

extension on HiFiCardVariant {
  AppCardVariant get asAppVariant {
    switch (this) {
      case HiFiCardVariant.surface:
        return AppCardVariant.surface;
      case HiFiCardVariant.mint:
        return AppCardVariant.mint;
      case HiFiCardVariant.teal:
        return AppCardVariant.teal;
      case HiFiCardVariant.highlight:
        return AppCardVariant.highlight;
    }
  }
}

extension on HiFiCardElevation {
  AppCardElevation get asAppElevation {
    switch (this) {
      case HiFiCardElevation.sm:
        return AppCardElevation.sm;
      case HiFiCardElevation.md:
        return AppCardElevation.md;
      case HiFiCardElevation.lg:
        return AppCardElevation.lg;
      case HiFiCardElevation.none:
        return AppCardElevation.none;
    }
  }
}

class HiFiCard extends StatelessWidget {
  const HiFiCard({
    required this.child,
    this.variant = HiFiCardVariant.surface,
    this.elevation = HiFiCardElevation.sm,
    this.padding = const EdgeInsets.all(15),
    this.radius = 20,
    this.border,
    this.onTap,
    super.key,
  });

  const HiFiCard.compact({
    required this.child,
    this.variant = HiFiCardVariant.surface,
    this.elevation = HiFiCardElevation.sm,
    this.radius = 20,
    this.border,
    this.onTap,
    super.key,
  }) : padding = const EdgeInsets.all(13);

  const HiFiCard.flush({
    required this.child,
    this.variant = HiFiCardVariant.surface,
    this.elevation = HiFiCardElevation.sm,
    this.radius = 20,
    this.border,
    this.onTap,
    super.key,
  }) : padding = EdgeInsets.zero;

  final Widget child;
  final HiFiCardVariant variant;
  final HiFiCardElevation elevation;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Border? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: variant.asAppVariant,
      elevation: elevation.asAppElevation,
      padding: padding,
      radius: radius,
      border: border,
      onTap: onTap,
      child: child,
    );
  }
}
