import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

enum AppCardVariant { surface, mint, teal, highlight }

enum AppCardElevation { sm, md, lg, none }

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.variant = AppCardVariant.surface,
    this.elevation = AppCardElevation.sm,
    this.padding = const EdgeInsets.all(15),
    this.radius = AppRadius.lg,
    this.border,
    this.onTap,
    super.key,
  });

  const AppCard.compact({
    required this.child,
    this.variant = AppCardVariant.surface,
    this.elevation = AppCardElevation.sm,
    this.radius = AppRadius.lg,
    this.border,
    this.onTap,
    super.key,
  }) : padding = const EdgeInsets.all(13);

  const AppCard.flush({
    required this.child,
    this.variant = AppCardVariant.surface,
    this.elevation = AppCardElevation.sm,
    this.radius = AppRadius.lg,
    this.border,
    this.onTap,
    super.key,
  }) : padding = EdgeInsets.zero;

  final Widget child;
  final AppCardVariant variant;
  final AppCardElevation elevation;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Border? border;
  final VoidCallback? onTap;

  Decoration _decoration() {
    final BorderRadius radiusGeometry = BorderRadius.circular(radius);
    switch (variant) {
      case AppCardVariant.surface:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppColors.surface, Color(0xFFF8F1E4)],
          ),
          border: border ?? Border.all(color: AppColors.border),
          borderRadius: radiusGeometry,
          boxShadow: _shadow(),
        );
      case AppCardVariant.mint:
        return BoxDecoration(
          gradient: AppGradients.cardMint,
          border: border ?? Border.all(color: AppColors.cardMintBorder),
          borderRadius: radiusGeometry,
          boxShadow: _shadow(),
        );
      case AppCardVariant.teal:
        return BoxDecoration(
          gradient: AppGradients.cardTeal,
          border: border ?? Border.all(color: AppColors.cardTealB),
          borderRadius: radiusGeometry,
          boxShadow: _shadow(),
        );
      case AppCardVariant.highlight:
        return BoxDecoration(
          gradient: AppGradients.cardHighlight,
          border: border ?? Border.all(color: AppColors.cardHighlightBorder),
          borderRadius: radiusGeometry,
          boxShadow: _shadow(),
        );
    }
  }

  List<BoxShadow> _shadow() {
    switch (elevation) {
      case AppCardElevation.sm:
        return AppShadows.sm;
      case AppCardElevation.md:
        return AppShadows.md;
      case AppCardElevation.lg:
        return AppShadows.lg;
      case AppCardElevation.none:
        return const <BoxShadow>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = DecoratedBox(
      decoration: _decoration(),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
