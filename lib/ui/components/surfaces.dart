/// Structural widgets: the page, the card, the section header, the empty state.
///
/// Everything visual in the app is built from these five, plus the controls in
/// `controls.dart`. No screen reaches for a raw `Container` with a decoration.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'controls.dart';

/// A page. Handles the three things every screen would otherwise repeat:
///
/// * the gutter (`SsSpace.screen`) and the safe area
/// * the screen wash — a subtle tint at the top in light, a gradient in dark
/// * the top padding the floating nav needs so content is never hidden behind it
class SsScaffold extends StatelessWidget {
  const SsScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.leading,
    this.wash = true,
    this.floatingNav = false,
    this.padding,
    this.scrollable = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool wash;

  /// Leaves room at the bottom for the floating navigation bar.
  final bool floatingNav;

  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final media = MediaQuery.of(context);

    final content = Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: SsSpace.screen),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        gradient: wash ? c.screenWash : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: floatingNav,
        appBar: title == null && actions == null && leading == null
            ? null
            : AppBar(
                title: title == null ? null : Text(title!),
                actions: actions,
                leading: leading,
                scrolledUnderElevation: 0,
              ),
        body: SafeArea(
          bottom: false,
          child: scrollable
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: floatingNav
                        ? 96 + media.padding.bottom
                        : SsSpace.x8 + media.padding.bottom,
                  ),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}

/// The workhorse surface: a floating card.
///
/// Always a fill plus a soft shadow — never a hairline border on its own, which
/// is the rule that keeps the app from looking like stock Material
/// (`docs/02-DESIGN-SYSTEM.md` §1.1).
class SsCard extends StatelessWidget {
  const SsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SsSpace.card),
    this.radius = SsRadius.lg,
    this.onTap,
    this.gradient,
    this.color,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated ? SsShadow.card(c) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A translucent card for hero areas — onboarding, paywall, the home money card.
/// Blur is deliberately rare: it costs a save-layer, and using it everywhere
/// makes nothing feel special (`docs/02-DESIGN-SYSTEM.md` §5).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SsSpace.card),
    this.radius = SsRadius.lg,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: c.glass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: c.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// "সাম্প্রতিক লেনদেন" + an optional trailing action ("সব দেখুন").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(top: SsSpace.x6, bottom: SsSpace.x3),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: SsText.h3)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: c.violet600,
                padding: const EdgeInsets.symmetric(horizontal: SsSpace.x2),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: SsText.bodyStrong.copyWith(color: c.violet600),
              ),
            ),
        ],
      ),
    );
  }
}

/// A 3D illustration with its ambient glow. The images ship in the bundle, so
/// this is instant on a cold start and works offline.
class HeroIllustration extends StatelessWidget {
  const HeroIllustration({
    super.key,
    required this.asset,
    this.height = 180,
    this.semanticLabel,
    this.glowTint,
    this.clip = true,
  });

  final String asset;
  final double height;
  final String? semanticLabel;
  final Color? glowTint;

  /// The current illustration set is drawn on a dark indigo ground (the light
  /// variants are T-059). On a light screen a bare dark rectangle reads as a
  /// mistake, so by default it is presented as a deliberate rounded panel with a
  /// soft shadow. The splash screen — which is already violet — passes
  /// `clip: false` and lets the artwork blend into the gradient.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  (glowTint ?? c.teal500).withValues(
                    alpha: c.isDark ? 0.20 : 0.14,
                  ),
                  c.bg.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          if (!clip)
            Image.asset(
              asset,
              height: height * 0.86,
              fit: BoxFit.contain,
              semanticLabel: semanticLabel,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stack) => _fallback(c, height),
            )
          else
            ClipRRect(
              borderRadius: SsRadius.rLg,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: SsRadius.rLg,
                  boxShadow: SsShadow.card(c),
                ),
                child: Image.asset(
                  asset,
                  height: height * 0.9,
                  fit: BoxFit.cover,
                  semanticLabel: semanticLabel,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stack) => _fallback(c, height),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // A missing illustration must never take the screen down with it.
  Widget _fallback(SsColors c, double height) =>
      Icon(Icons.image_outlined, size: height * 0.4, color: c.textTertiary);
}

/// The "nothing here yet" state. Always pairs an illustration with one action —
/// an empty state without a next step is a dead end.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.asset = 'assets/3d/empty-transactions.jpg',
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String asset;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SsSpace.x6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SsSpace.x4),
            child: HeroIllustration(asset: asset, height: 168),
          ),
          const SizedBox(height: SsSpace.x4),
          Text(title, style: SsText.h3, textAlign: TextAlign.center),
          const SizedBox(height: SsSpace.x2),
          Text(
            message,
            style: SsText.body.copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: SsSpace.x5),
            SsActionButton(
              label: actionLabel!,
              onPressed: onAction,
              expanded: false,
            ),
          ],
        ],
      ),
    );
  }
}
