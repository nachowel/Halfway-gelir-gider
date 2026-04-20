import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';
import 'app_typography.dart';

/// ThemeData wiring. The hi-fi visual contract (`flutter-visual-fidelity-handoff.md`)
/// is the source of truth; this theme only exposes tokens to Material primitives
/// that happen to be used inside reusable widgets. Screen composition stays
/// on the Hi-Fi* primitives, not on Material defaults.
abstract final class AppTheme {
  static ThemeData light() {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: AppColors.onInk,
      primaryContainer: AppColors.brandSoft,
      onPrimaryContainer: AppColors.brandStrong,
      secondary: AppColors.amber,
      onSecondary: AppColors.amberInk,
      secondaryContainer: AppColors.amberSoft,
      onSecondaryContainer: AppColors.amberInk,
      tertiary: AppColors.income,
      onTertiary: AppColors.onInk,
      tertiaryContainer: AppColors.incomeSoft,
      onTertiaryContainer: AppColors.incomeInk,
      error: AppColors.expense,
      onError: AppColors.onInk,
      errorContainer: AppColors.expenseSoft,
      onErrorContainer: AppColors.expenseInk,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerLowest: AppColors.bg,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface2,
      surfaceContainerHigh: AppColors.surface2,
      surfaceContainerHighest: AppColors.bgTint,
      outline: AppColors.border,
      outlineVariant: AppColors.borderSoft,
      onSurfaceVariant: AppColors.inkSoft,
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: AppTypography.numXxl,
      displayMedium: AppTypography.numXl,
      displaySmall: AppTypography.numLg,
      headlineLarge: AppTypography.h1,
      headlineMedium: AppTypography.h2,
      headlineSmall: AppTypography.numMd,
      titleLarge: AppTypography.h2,
      titleMedium: AppTypography.ttl,
      titleSmall: AppTypography.lbl,
      labelLarge: AppTypography.button,
      labelMedium: AppTypography.lbl,
      labelSmall: AppTypography.eye,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.bodySoft,
      bodySmall: AppTypography.meta,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      // Let individual hi-fi primitives paint their own backgrounds; the
      // AppBar and BottomAppBar are not part of the hi-fi composition.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h2,
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.brandSoft.withAlpha(80),
      highlightColor: AppColors.brandSoft.withAlpha(40),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
      primaryIconTheme: const IconThemeData(color: AppColors.onInk, size: 20),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.onInk),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheetTop),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        // The actual FAB is HiFiFab; this only styles any stray Material FABs.
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      // Default text selection / cursor
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brand,
        selectionColor: AppColors.brandSoft,
        selectionHandleColor: AppColors.brand,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.58),
        hintStyle: AppTypography.input.copyWith(color: AppColors.inkFade),
        labelStyle: AppTypography.lbl,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: AppTypography.button,
          side: const BorderSide(color: AppColors.brand),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }

  /// Ensure Google Fonts uses bundled/cached versions predictably.
  static void configure() {
    GoogleFonts.config.allowRuntimeFetching = kIsWeb;
  }
}
