import 'package:flutter/material.dart';

/// Colors extracted directly from `:root` in `.agent/design-reference/gider-hi-fi.html`.
/// Palette is locked per `flutter-visual-fidelity-handoff.md` §2.
abstract final class AppColors {
  // Surfaces / neutrals
  static const Color bg = Color(0xFFF1ECE1);
  static const Color bgTint = Color(0xFFE6E9DF);
  static const Color surface = Color(0xFFFBF7ED);
  static const Color surface2 = Color(0xFFF6EFDF);
  static const Color border = Color(0xFFE0D7C2);
  static const Color borderSoft = Color(0xFFEBE2CD);

  // Ink
  static const Color ink = Color(0xFF15282B);
  static const Color inkSoft = Color(0xFF4A5C60);
  static const Color inkFade = Color(0xFF8C9699);

  // Brand (petrol teal)
  static const Color brand = Color(0xFF0E6B6F);
  static const Color brandStrong = Color(0xFF094A4D);
  static const Color brandSoft = Color(0xFFCDE7E4);
  static const Color brandTint = Color(0xFFE5F1EE);

  // Mint
  static const Color mint = Color(0xFFD8E9D0);
  static const Color mintStrong = Color(0xFFBCD7B0);

  // Income (green)
  static const Color income = Color(0xFF2F8A4D);
  static const Color incomeSoft = Color(0xFFD9ECDD);
  static const Color incomeInk = Color(0xFF1E5F34);

  // Card income (blue)
  static const Color cardIncome = Color(0xFF2E6FAF);
  static const Color cardIncomeSoft = Color(0xFFDCE8F5);
  static const Color cardIncomeInk = Color(0xFF1F527F);

  // Expense (terracotta)
  static const Color expense = Color(0xFFC2492A);
  static const Color expenseSoft = Color(0xFFF3DBCF);
  static const Color expenseInk = Color(0xFF8A3018);

  // Amber / highlight
  static const Color amber = Color(0xFFE8A93A);
  static const Color amberSoft = Color(0xFFFCE7B6);
  static const Color amberInk = Color(0xFF8A6418);
  static const Color highlight = Color(0xFFF6D66C);
  static const Color highlightSoft = Color(0xFFFBEAB2);

  // Hero amber card ink (derived from hi-fi inline override `color:#1e2b10`)
  static const Color heroInk = Color(0xFF1E2B10);
  static const Color heroEye = Color(0xFF6B4918);

  // Screen gradient stops (hi-fi `.screen.*` classes)
  static const Color screenCreamTop = Color(0xFFFBF7ED);
  static const Color screenCreamBottom = Color(0xFFF4ECD9);
  static const Color screenMintTop = Color(0xFFEAF3E8);
  static const Color screenMintBottom = Color(0xFFDCE9D5);
  static const Color screenTealMintTop = Color(0xFFE9F2EF);
  static const Color screenTealMintBottom = Color(0xFFD4E6E1);
  static const Color screenWarmTop = Color(0xFFFAF2E0);
  static const Color screenWarmBottom = Color(0xFFF0E4C5);

  // Highlight card gradient stops
  static const Color cardHighlightA = Color(0xFFFADDAF);
  static const Color cardHighlightB = Color(0xFFF6C77A);
  static const Color cardHighlightC = Color(0xFFE8A93A);
  static const Color cardHighlightBorder = Color(0xFFD29A2E);

  // Mint card gradient stops
  static const Color cardMintA = Color(0xFFE3EFDD);
  static const Color cardMintB = Color(0xFFD4E6CC);
  static const Color cardMintBorder = Color(0xFFC5D9BC);

  // Teal (brand) card gradient stops
  static const Color cardTealA = Color(0xFF0F6B6F);
  static const Color cardTealB = Color(0xFF094A4D);

  // Bar gradient stops
  static const Color barBrandA = Color(0xFF0E6B6F);
  static const Color barBrandB = Color(0xFF2AA79B);
  static const Color barIncomeA = Color(0xFF2F8A4D);
  static const Color barIncomeB = Color(0xFF4EB36D);
  static const Color barExpenseA = Color(0xFFC2492A);
  static const Color barExpenseB = Color(0xFFE07150);
  static const Color barAmberA = Color(0xFFE8A93A);
  static const Color barAmberB = Color(0xFFF6D66C);

  // Cream text used on inked surfaces
  static const Color onInk = Color(0xFFFBF7ED);
}

/// Radii per hi-fi tokens (`--radius-sm`, `--radius`, etc.) and component rules.
abstract final class AppRadius {
  static const double sm = 10;
  static const double base = 14;
  static const double lg = 20;
  static const double xl = 28;

  static const double input = 14;
  static const double button = 16;
  static const double bottomNav = 22;
  static const double sheetTop = 26;
  static const double sheetBottom = 24;
  static const double iconTile = 12;
  static const double iconTileSm = 10;
  static const double keypadKey = 12;
}

/// Spacing rhythm from hi-fi CSS paddings/margins.
/// These values are not a strict grid — match the rhythm, not just the number.
abstract final class AppSpacing {
  static const double micro = 4;
  static const double xxs = 6;
  static const double xs = 8;
  static const double smTight = 10;
  static const double sm = 12;
  static const double md = 14;
  static const double base = 16;
  static const double screenSide = 18;
  static const double lg = 20;
  static const double xl = 24;
  static const double sheetSide = 28;
  static const double xxl = 32;
}

/// Shadow layer sets extracted from hi-fi CSS tokens.
abstract final class AppShadows {
  static const List<BoxShadow> sm = <BoxShadow>[
    BoxShadow(color: Color(0x0D09282B), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0809282B), offset: Offset(0, 1), blurRadius: 1),
  ];

  static const List<BoxShadow> md = <BoxShadow>[
    BoxShadow(color: Color(0x1209282B), offset: Offset(0, 6), blurRadius: 14),
    BoxShadow(color: Color(0x0D09282B), offset: Offset(0, 2), blurRadius: 4),
  ];

  static const List<BoxShadow> lg = <BoxShadow>[
    BoxShadow(color: Color(0x1A09282B), offset: Offset(0, 20), blurRadius: 40),
    BoxShadow(color: Color(0x0F09282B), offset: Offset(0, 6), blurRadius: 14),
  ];

  /// FAB shadow uses brand-tinted drop.
  static const List<BoxShadow> fab = <BoxShadow>[
    BoxShadow(color: Color(0x66094A4D), offset: Offset(0, 8), blurRadius: 20),
    BoxShadow(color: Color(0x33094A4D), offset: Offset(0, 2), blurRadius: 4),
  ];
}

/// Gradients. These must not be flattened to solid colors (handoff §1).
abstract final class AppGradients {
  static const LinearGradient screenCream = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.screenCreamTop, AppColors.screenCreamBottom],
  );
  static const LinearGradient screenMint = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.screenMintTop, AppColors.screenMintBottom],
  );
  static const LinearGradient screenTealMint = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppColors.screenTealMintTop,
      AppColors.screenTealMintBottom,
    ],
  );
  static const LinearGradient screenWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.screenWarmTop, AppColors.screenWarmBottom],
  );

  /// 160deg in CSS ≈ topLeft → bottomRight with a slight bias.
  /// Using Alignment(-0.35, -1) → Alignment(0.35, 1) approximates the diagonal.
  static const LinearGradient cardHighlight = LinearGradient(
    begin: Alignment(-0.55, -1),
    end: Alignment(0.75, 1),
    stops: <double>[0.0, 0.18, 0.52, 1.0],
    colors: <Color>[
      Color(0xFFFCE7B8),
      AppColors.cardHighlightA,
      AppColors.cardHighlightB,
      AppColors.cardHighlightC,
    ],
  );
  static const LinearGradient cardMint = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.7, 1),
    stops: <double>[0, 0.55, 1],
    colors: <Color>[
      Color(0xFFF0F7EB),
      AppColors.cardMintA,
      AppColors.cardMintB,
    ],
  );
  static const LinearGradient cardTeal = LinearGradient(
    begin: Alignment(-0.55, -1),
    end: Alignment(0.65, 1),
    stops: <double>[0, 0.45, 1],
    colors: <Color>[
      Color(0xFF1C7E82),
      AppColors.cardTealA,
      AppColors.cardTealB,
    ],
  );

  /// FAB 145deg gradient — ~topLeft → bottomRight.
  static const LinearGradient fab = LinearGradient(
    begin: Alignment(-0.55, -1),
    end: Alignment(0.8, 1),
    stops: <double>[0, 0.5, 1],
    colors: <Color>[
      Color(0xFF1A7E82),
      AppColors.cardTealA,
      AppColors.cardTealB,
    ],
  );

  static const LinearGradient barBrand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: <double>[0, 0.55, 1],
    colors: <Color>[
      AppColors.barBrandA,
      Color(0xFF159187),
      AppColors.barBrandB,
    ],
  );
  static const LinearGradient barIncome = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: <double>[0, 0.55, 1],
    colors: <Color>[
      AppColors.barIncomeA,
      Color(0xFF3C9E5C),
      AppColors.barIncomeB,
    ],
  );
  static const LinearGradient barExpense = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: <double>[0, 0.55, 1],
    colors: <Color>[
      AppColors.barExpenseA,
      Color(0xFFD55B39),
      AppColors.barExpenseB,
    ],
  );
  static const LinearGradient barAmber = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: <double>[0, 0.55, 1],
    colors: <Color>[
      AppColors.barAmberA,
      Color(0xFFF0BD58),
      AppColors.barAmberB,
    ],
  );
}

/// Durations from the design brief motion spec.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 420);
}

abstract final class AppEasing {
  static const Cubic standard = Cubic(0.4, 0, 0.2, 1);
  static const Cubic expressive = Cubic(0.22, 1, 0.36, 1);
}
