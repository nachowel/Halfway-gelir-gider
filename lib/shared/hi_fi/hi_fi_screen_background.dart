import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Screen backgrounds from hi-fi `.screen.cream|mint|tealmint|warm`.
/// The body also layers two radial "atmosphere" gradients (hi-fi `body`):
///   - top-right mint glow (188,215,176,0.45)
///   - left-middle teal-soft glow (205,231,228,0.55)
/// These are baked in by default; pass [withAtmosphere]: false to suppress.
enum HiFiScreenTone { cream, mint, tealMint, warm }

class HiFiScreenBackground extends StatelessWidget {
  const HiFiScreenBackground({
    required this.child,
    this.tone = HiFiScreenTone.cream,
    this.withAtmosphere = true,
    super.key,
  });

  final Widget child;
  final HiFiScreenTone tone;
  final bool withAtmosphere;

  LinearGradient get _base {
    switch (tone) {
      case HiFiScreenTone.cream:
        return AppGradients.screenCream;
      case HiFiScreenTone.mint:
        return AppGradients.screenMint;
      case HiFiScreenTone.tealMint:
        return AppGradients.screenTealMint;
      case HiFiScreenTone.warm:
        return AppGradients.screenWarm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _base),
      child: withAtmosphere
          ? Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const _AtmosphereGlow(
                  alignment: Alignment(1.08, -1.18),
                  color: Color(0x82BCD7B0),
                  size: Size(760, 400),
                ),
                const _AtmosphereGlow(
                  alignment: Alignment(-1.18, -0.06),
                  color: Color(0x96CDE7E4),
                  size: Size(660, 380),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

class _AtmosphereGlow extends StatelessWidget {
  const _AtmosphereGlow({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[color, color.withAlpha(0)],
              stops: const <double>[0, 0.6],
            ),
          ),
        ),
      ),
    );
  }
}
