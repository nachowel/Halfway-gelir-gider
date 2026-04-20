import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Type ramp extracted from hi-fi class rules (`.h1`, `.num-xxl`, `.eye`, etc.).
/// Fonts are locked: Fraunces (serif display/numbers), Inter (UI/body),
/// JetBrains Mono (micro labels).
abstract final class AppTypography {
  static TextStyle _fraunces({
    required double size,
    double? height,
    double letterSpacing = -0.01,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing * size,
      fontWeight: weight,
      color: color,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  static TextStyle _inter({
    required double size,
    double? height,
    double letterSpacing = 0,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    bool tabular = false,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: weight,
      color: color,
      fontFeatures: tabular
          ? const <FontFeature>[FontFeature.tabularFigures()]
          : null,
    );
  }

  static TextStyle _mono({
    required double size,
    double letterSpacing = 0,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.inkFade,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      letterSpacing: letterSpacing,
      fontWeight: weight,
      color: color,
    );
  }

  // Headings (Fraunces)
  static TextStyle h1 = _fraunces(size: 26, height: 1.1, letterSpacing: -0.02);
  static TextStyle h2 = _fraunces(
    size: 20,
    height: 1.15,
    letterSpacing: -0.015,
  );

  // Numeric ramp (Fraunces, tabular)
  static TextStyle numXxl = _fraunces(
    size: 56,
    height: 1,
    letterSpacing: -0.035,
  );
  static TextStyle numXl = _fraunces(size: 42, height: 1, letterSpacing: -0.03);
  static TextStyle numLg = _fraunces(size: 28, height: 1, letterSpacing: -0.02);
  static TextStyle numMd = _fraunces(
    size: 20,
    height: 1,
    letterSpacing: -0.015,
  );
  static TextStyle numSm = _fraunces(size: 16, height: 1.1);
  static TextStyle numXs = _inter(
    size: 13,
    weight: FontWeight.w600,
    tabular: true,
  );

  // Small UI / labels
  static TextStyle lbl = _inter(
    size: 12,
    weight: FontWeight.w500,
    color: AppColors.inkSoft,
  );
  static TextStyle delta = _inter(
    size: 12,
    weight: FontWeight.w600,
    tabular: true,
  );
  static TextStyle body = _inter(
    size: 14,
    weight: FontWeight.w500,
    color: AppColors.ink,
  );
  static TextStyle bodySoft = _inter(
    size: 13,
    weight: FontWeight.w400,
    color: AppColors.inkSoft,
  );
  static TextStyle ttl = _inter(
    size: 14,
    weight: FontWeight.w500,
    color: AppColors.ink,
  );
  static TextStyle meta = _inter(
    size: 11.5,
    weight: FontWeight.w400,
    color: AppColors.inkFade,
  );
  static TextStyle button = _inter(size: 15, weight: FontWeight.w600);
  static TextStyle input = _inter(
    size: 14,
    weight: FontWeight.w500,
    color: AppColors.ink,
  );

  // JetBrains Mono eyebrow / meta
  static TextStyle eye = _mono(
    size: 10,
    letterSpacing: 1.4, // 0.14em @ 10px
    weight: FontWeight.w500,
  );
}
