/// Design tokens — the single source of truth for colour, spacing, radius,
/// elevation and type. Everything in `lib/ui/` reads from here; nothing in the
/// app hardcodes a `Color(0x…)` outside this file.
///
/// Implements `docs/02-DESIGN-SYSTEM.md`. Direction A — **Light & Clean**:
/// light is the default, dark is the *same layout* with a dark token set, never
/// a separate widget tree.
///
/// Access pattern for every widget:
///
/// ```dart
/// final c = SsColors.of(context);          // ThemeExtension lookup
/// final isDark = Theme.of(context).brightness == Brightness.dark;
/// ```
library;

import 'package:flutter/material.dart';

/// The semantic colour set, resolved per brightness.
///
/// A [ThemeExtension] rather than a global constant so that light and dark can
/// be compared in a widget test without a rebuild, and so `Theme.of(context)`
/// stays the only way a widget learns about colour.
@immutable
class SsColors extends ThemeExtension<SsColors> {
  const SsColors({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceElev,
    required this.surfaceTint,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.violet600,
    required this.violet400,
    required this.violet100,
    required this.teal500,
    required this.teal100,
    required this.rose500,
    required this.rose100,
    required this.gold500,
    required this.gold100,
    required this.income,
    required this.expense,
    required this.warning,
    required this.danger,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.glass,
    required this.glassBorder,
    required this.moneyGradient,
    required this.proGradient,
    required this.screenWash,
    required this.ambientGlow,
  });

  final Brightness brightness;

  final Color bg;
  final Color surface;
  final Color surfaceElev;
  final Color surfaceTint;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Accent ramp — shared names, per-theme values.
  final Color violet600;
  final Color violet400;
  final Color violet100;
  final Color teal500;
  final Color teal100;
  final Color rose500;
  final Color rose100;
  final Color gold500;
  final Color gold100;

  // Semantics.
  final Color income;
  final Color expense;
  final Color warning;
  final Color danger;

  final Color border;
  final Color divider;
  final Color shadow;

  /// Glass fill for hero / onboarding / paywall surfaces.
  final Color glass;
  final Color glassBorder;

  final Gradient moneyGradient;
  final Gradient proGradient;
  final Gradient screenWash;
  final Gradient ambientGlow;

  bool get isDark => brightness == Brightness.dark;

  /// The one place the colour of money is decided.
  ///
  /// Callers must still render the sign (`+` / `−`) — colour alone is never the
  /// only signal, because red/green is indistinguishable to a red-green
  /// colour-blind user. See `docs/02-DESIGN-SYSTEM.md` §7.
  Color amountColor(AmountTone tone) => switch (tone) {
    AmountTone.income => income,
    AmountTone.expense => expense,
    AmountTone.neutral => textPrimary,
  };

  /// A pastel tint of [base] for icon chips — violet for a debit, teal for a
  /// credit, in both themes.
  Color tintOf(Color base) =>
      Color.alphaBlend(base.withValues(alpha: isDark ? 0.22 : 0.14), surface);

  static const SsColors light = SsColors(
    brightness: Brightness.light,
    bg: Color(0xFFF7F6FC),
    surface: Color(0xFFFFFFFF),
    surfaceElev: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFFAF9FF),
    textPrimary: Color(0xFF14102E),
    textSecondary: Color(0xFF6B6690),
    textTertiary: Color(0xFF9E99BE),
    violet600: Color(0xFF6C4CF1),
    violet400: Color(0xFF8B6BFF),
    violet100: Color(0xFFEFEAFE),
    teal500: Color(0xFF14C8B8),
    teal100: Color(0xFFE4FBF7),
    rose500: Color(0xFFFF5A7A),
    rose100: Color(0xFFFFE8EE),
    gold500: Color(0xFFF5B843),
    gold100: Color(0xFFFFF6E5),
    income: Color(0xFF0E9E90),
    expense: Color(0xFFE03356),
    warning: Color(0xFFB07908),
    danger: Color(0xFFC41E3A),
    border: Color(0xFFE7E2F8),
    divider: Color(0x1214102E),
    shadow: Color(0x1A4C3BD1),
    glass: Color(0xB8FFFFFF),
    glassBorder: Color(0xFFE7E2F8),
    moneyGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B6BFF), Color(0xFF6C4CF1)],
    ),
    proGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF5B843), Color(0xFFFF8A3D)],
    ),
    screenWash: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF3F0FF), Color(0xFFF7F6FC)],
      stops: [0.0, 0.32],
    ),
    ambientGlow: RadialGradient(colors: [Color(0x2214C8B8), Color(0x00F7F6FC)]),
  );

  static const SsColors dark = SsColors(
    brightness: Brightness.dark,
    bg: Color(0xFF0E0A2A),
    surface: Color(0xFF161139),
    surfaceElev: Color(0xFF1E1848),
    surfaceTint: Color(0xFF1A1450),
    textPrimary: Color(0xFFF3F1FF),
    textSecondary: Color(0xFFA9A3D0),
    textTertiary: Color(0xFF7C76A8),
    violet600: Color(0xFF8B6BFF),
    violet400: Color(0xFF9B6BFF),
    violet100: Color(0xFF2A2450),
    teal500: Color(0xFF2FD4C4),
    teal100: Color(0xFF103A36),
    rose500: Color(0xFFFF6B8A),
    rose100: Color(0xFF3A1220),
    gold500: Color(0xFFFFC662),
    gold100: Color(0xFF3A2E12),
    income: Color(0xFF2FD4C4),
    expense: Color(0xFFFF6B8A),
    warning: Color(0xFFF5B843),
    danger: Color(0xFFFF4D6D),
    border: Color(0x1AFFFFFF),
    divider: Color(0x14FFFFFF),
    shadow: Color(0x66000000),
    glass: Color(0x12FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    moneyGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B6BFF), Color(0xFF5B3FE0)],
    ),
    proGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF5B843), Color(0xFFFF8A3D)],
    ),
    screenWash: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF171043), Color(0xFF0E0A2A)],
      stops: [0.0, 0.36],
    ),
    ambientGlow: RadialGradient(colors: [Color(0x332FD4C4), Color(0x000E0A2A)]),
  );

  @override
  SsColors copyWith({Brightness? brightness}) =>
      brightness == null || brightness == this.brightness
      ? this
      : (brightness == Brightness.dark ? dark : light);

  @override
  SsColors lerp(covariant SsColors? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }

  static SsColors of(BuildContext context) =>
      Theme.of(context).extension<SsColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);
}

enum AmountTone { income, expense, neutral }

/// Spacing scale. `docs/02` §4 — the app uses these ten values and nothing else.
abstract final class SsSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x14 = 56;
  static const double x18 = 72;

  /// Screen gutter — every screen uses this for its horizontal padding.
  static const double screen = 20;

  /// Inside a card.
  static const double card = 18;
}

abstract final class SsRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;

  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rPill => BorderRadius.circular(pill);
}

abstract final class SsShadow {
  /// Floating card: soft violet-tinted in light, deep black in dark.
  static List<BoxShadow> card(SsColors c) => [
    BoxShadow(
      color: c.shadow,
      blurRadius: c.isDark ? 28 : 22,
      offset: const Offset(0, 10),
    ),
  ];

  /// Ambient glow under a hero illustration or the money card.
  static List<BoxShadow> glow(Color tint, {double blur = 40}) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.28),
      blurRadius: blur,
      offset: const Offset(0, 18),
    ),
  ];
}

/// Type scale. Every style carries the fallback chain, so a Bengali or Hindi
/// string renders in Noto and Latin text in Manrope without a per-widget
/// decision.
abstract final class SsText {
  static const String family = 'Manrope';
  static const List<String> fallback = <String>[
    'NotoSansBengali',
    'NotoSansDevanagari',
  ];

  /// Tabular figures — a balance that changes must not make the digits jump.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const TextStyle displayMoney = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 44,
    height: 52 / 44,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    fontFeatures: tabular,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  /// Amounts in a list row — tabular, semi-bold, never colour-only.
  static const TextStyle amountRow = TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    fontFeatures: tabular,
  );
}
