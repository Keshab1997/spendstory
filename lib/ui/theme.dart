/// Builds the two `ThemeData` objects from the tokens in [SsColors].
///
/// Material 3 is the base, but almost nothing is left at its default: the
/// colour scheme, text theme, page transitions and component shapes are all
/// overridden so the app reads as SpendStory rather than as stock Material.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildSsTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? SsColors.dark : SsColors.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: c.violet600,
        brightness: brightness,
      ).copyWith(
        primary: c.violet600,
        onPrimary: Colors.white,
        secondary: c.teal500,
        onSecondary: Colors.white,
        surface: c.surface,
        onSurface: c.textPrimary,
        error: c.danger,
        outline: c.border,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: SsText.family,
    fontFamilyFallback: SsText.fallback,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    extensions: <ThemeExtension<dynamic>>[c],

    textTheme: TextTheme(
      displayLarge: SsText.displayMoney.copyWith(color: c.textPrimary),
      headlineLarge: SsText.h1.copyWith(color: c.textPrimary),
      headlineMedium: SsText.h2.copyWith(color: c.textPrimary),
      titleMedium: SsText.h3.copyWith(color: c.textPrimary),
      bodyMedium: SsText.body.copyWith(color: c.textPrimary),
      bodyLarge: SsText.bodyStrong.copyWith(color: c.textPrimary),
      bodySmall: SsText.caption.copyWith(color: c.textSecondary),
      labelSmall: SsText.micro.copyWith(color: c.textSecondary),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: c.textPrimary,
      titleTextStyle: SsText.h2.copyWith(color: c.textPrimary),
    ),

    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),

    // The bottom sheet is the Add/Edit surface (docs/04 §3) — it gets the
    // large radius and a drag handle rather than Material's default.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceElev,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.border,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(SsRadius.lg)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceTint,
      hintStyle: SsText.body.copyWith(color: c.textTertiary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SsSpace.x4,
        vertical: SsSpace.x3,
      ),
      border: OutlineInputBorder(
        borderRadius: SsRadius.rMd,
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: SsRadius.rMd,
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SsRadius.rMd,
        borderSide: BorderSide(color: c.violet600, width: 1.6),
      ),
    ),

    // Tab switching and pushes are a fade-forward, not Material's default
    // zoom — docs/04 §3. iOS keeps the platform default.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.isDark ? c.surfaceElev : c.textPrimary,
      contentTextStyle: SsText.body.copyWith(
        color: c.isDark ? c.textPrimary : Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: SsRadius.rMd),
    ),

    // Chips are pill-shaped everywhere, never Material's 8dp corner.
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceTint,
      selectedColor: c.violet100,
      side: BorderSide(color: c.border),
      labelStyle: SsText.caption.copyWith(color: c.textPrimary),
      secondaryLabelStyle: SsText.caption.copyWith(color: c.violet600),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(
        horizontal: SsSpace.x3,
        vertical: SsSpace.x1,
      ),
    ),
  );
}
