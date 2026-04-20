import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// High-fidelity hero surface used by the dashboard net-profit card.
/// Keeps the locked layout intact while adding the layered depth recipe:
/// base gradient, soft ambient shadow, radial atmosphere, and edge shading.
class HiFiHeroCard extends StatelessWidget {
  const HiFiHeroCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.cardHighlightBorder),
        gradient: const LinearGradient(
          begin: Alignment(-0.8, -1),
          end: Alignment(0.8, 1),
          colors: <Color>[
            Color(0xFFF2C078),
            Color(0xFFE2A94B),
            Color(0xFFD89A35),
          ],
          stops: <double>[0.0, 0.6, 1.0],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: Color(0x26D89A35),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
          const BoxShadow(
            color: Color(0x0DFFF9EC),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.6, -0.4),
                      radius: 1.2,
                      colors: <Color>[
                        Colors.white.withAlpha(64),
                        Colors.transparent,
                      ],
                      stops: const <double>[0.0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Colors.white.withAlpha(20),
                        Colors.transparent,
                        Colors.black.withAlpha(13),
                      ],
                      stops: const <double>[0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -18,
              top: -30,
              child: IgnorePointer(
                child: Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        Colors.white.withAlpha(38),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
