/// Buttons and small interactive pieces.
///
/// Every button in the app comes from here, which is what keeps the touch
/// targets at 48dp and the corner radii consistent.
library;

import 'package:flutter/material.dart';

import '../tokens.dart';

enum SsButtonTone { primary, secondary, ghost, gold, danger }

/// The standard button.
///
/// [SsButtonTone.primary] is the violet gradient — one per screen, on the action
/// we want the user to take. Everything else is secondary by design, because a
/// screen with three loud buttons has no primary action.
class SsActionButton extends StatelessWidget {
  const SsActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tone = SsButtonTone.primary,
    this.expanded = true,
    this.loading = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SsButtonTone tone;
  final bool expanded;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final enabled = onPressed != null && !loading;

    final (Gradient? gradient, Color fill, Color fg) = switch (tone) {
      SsButtonTone.primary => (c.moneyGradient, c.violet600, Colors.white),
      SsButtonTone.gold => (c.proGradient, c.gold500, const Color(0xFF2A1B00)),
      SsButtonTone.secondary => (null, c.violet100, c.violet600),
      SsButtonTone.ghost => (null, Colors.transparent, c.textSecondary),
      SsButtonTone.danger => (null, c.rose100, c.danger),
    };

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: fg),
        if (loading || icon != null) const SizedBox(width: SsSpace.x2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            style: SsText.bodyStrong.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        height: height,
        constraints: const BoxConstraints(minWidth: 96),
        decoration: BoxDecoration(
          color: gradient == null ? fill : null,
          gradient: gradient,
          borderRadius: SsRadius.rPill,
        ),
        // Material sits *inside* the decorated container so the ripple is
        // clipped to the gradient rather than painted behind it.
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: SsRadius.rPill,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SsSpace.x6),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular icon button — used for the app bar and the quick actions.
class SsIconButton extends StatelessWidget {
  const SsIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.tone,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final fg = tone ?? c.textPrimary;

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: c.surfaceTint,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.45, color: fg),
          ),
        ),
      ),
    );
  }
}

/// One of the four shortcuts under the home hero card.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final base = tint ?? c.violet600;

    return InkWell(
      onTap: onTap,
      borderRadius: SsRadius.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SsSpace.x2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.tintOf(base),
                borderRadius: SsRadius.rMd,
              ),
              child: Icon(icon, size: 22, color: base),
            ),
            const SizedBox(height: SsSpace.x2),
            Text(
              label,
              style: SsText.micro.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small rounded stat — "আয় ₹45,000" beside "খরচ ₹32,400" on the hero card.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone,
    this.onDark = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? tone;

  /// Pills on the violet hero card need light-on-dark text; pills on a normal
  /// surface need the theme's text colours.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final accent = tone ?? (onDark ? Colors.white : c.textPrimary);
    final sub = onDark ? Colors.white.withValues(alpha: 0.72) : c.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SsSpace.x3,
        vertical: SsSpace.x2,
      ),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.16) : c.surfaceTint,
        borderRadius: SsRadius.rPill,
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.18))
            : Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: SsSpace.x1 + 2),
          ],
          // Flexible, because a pill holding "₹১,২৪,০০০" in a narrow hero card
          // has to shorten rather than overflow its own rounded border.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SsText.micro.copyWith(color: sub),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SsText.bodyStrong.copyWith(color: accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A settings-style row: icon, title, optional subtitle, trailing chevron or
/// switch.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.trailing,
    this.tint,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? tint;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final base = danger ? c.danger : (tint ?? c.violet600);

    return InkWell(
      onTap: onTap,
      borderRadius: SsRadius.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SsSpace.x2,
          vertical: SsSpace.x3,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.tintOf(base),
                  borderRadius: SsRadius.rSm,
                ),
                child: Icon(icon, size: 19, color: base),
              ),
              const SizedBox(width: SsSpace.x3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SsText.bodyStrong.copyWith(
                      color: danger ? c.danger : c.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// A pill-shaped segmented control. Used for the light/dark/system choice and
/// for the period selector on Insights.
class SsSegmented<T> extends StatelessWidget {
  const SsSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    assert(values.length == labels.length);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: SsRadius.rPill,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(values[i]),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: values[i] == selected
                        ? c.surface
                        : Colors.transparent,
                    borderRadius: SsRadius.rPill,
                    boxShadow: values[i] == selected ? SsShadow.card(c) : null,
                  ),
                  child: Text(
                    labels[i],
                    style: SsText.caption.copyWith(
                      color: values[i] == selected
                          ? c.textPrimary
                          : c.textSecondary,
                      fontWeight: values[i] == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
