/// Money rendering and the two data-visualisation widgets.
///
/// The whole app formats currency through [MoneyText] / [formatInr], so the
/// Indian grouping (`1,24,000` rather than `124,000`) is decided once.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../format.dart';
import '../tokens.dart';

/// Formats an integer number of paise as Indian rupees.
///
/// ```
/// formatInr(124000)            → '1,240'
/// formatInr(12400050)          → '1,24,000.50'
/// formatInr(12400050, paise: false) → '1,24,000'
/// ```
///
/// Grouping is hand-rolled rather than delegated to `intl` so that the lakh /
/// crore rule is explicit and testable. Paise are only shown when they are
/// non-zero or the caller asks for them, because `₹1,240.00` on every row is
/// noise.
String formatInr(
  int paise, {
  bool showPaise = false,
  bool showSymbol = false,
  String? localize,
}) {
  final negative = paise < 0;
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final fraction = abs % 100;

  final withPaise = showPaise || fraction != 0;
  final grouped = _groupIndian(rupees.toString());
  final decimals = withPaise ? '.${fraction.toString().padLeft(2, '0')}' : '';

  final symbol = showSymbol ? '₹' : '';
  final out = '${negative ? '−' : ''}$symbol$grouped$decimals';
  return localize == null ? out : localizeDigits(out, localize);
}

/// `1234567` → `12,34,567`. Groups are 3 digits from the right, then 2.
String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;

  final tail = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$tail';
}

/// A compact form for tight spaces — `₹1.2L`, `₹12.4k`.
///
/// Deliberately *not* used for the headline figures: `₹18.1k` is not how anyone
/// reads money, and the lakh/crore suffix only makes sense to a user who already
/// knows Indian grouping. It is for axis labels and dense chips.
String formatInrCompact(int paise, {String? localize}) {
  final rupees = paise / 100;
  final String out;
  if (rupees.abs() >= 10000000) {
    out = '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
  } else if (rupees.abs() >= 100000) {
    out = '₹${(rupees / 100000).toStringAsFixed(1)}L';
  } else if (rupees.abs() >= 1000) {
    out = '₹${(rupees / 1000).toStringAsFixed(1)}k';
  } else {
    out = '₹${rupees.toStringAsFixed(0)}';
  }
  return localize == null ? out : localizeDigits(out, localize);
}

/// Renders an amount. The sign is always visible for income and expense — the
/// colour is a reinforcement, never the only signal
/// (`docs/02-DESIGN-SYSTEM.md` §7).
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.paise, {
    super.key,
    this.tone = AmountTone.neutral,
    this.showSign = false,
    this.showPaise = false,
    this.showSymbol = true,
    this.style,
    this.compact = false,
    this.color,
  });

  final int paise;
  final AmountTone tone;
  final bool showSign;
  final bool showPaise;
  final bool showSymbol;
  final TextStyle? style;
  final bool compact;

  /// Overrides the tone-derived colour. Used on the gradient hero card, where the
  /// amount sits on violet and must be white in both themes.
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final locale = ref.watch(localeProvider);
    final base = style ?? SsText.amountRow;
    final sign = switch (tone) {
      AmountTone.income => showSign ? '+' : '',
      AmountTone.expense => showSign ? '−' : '',
      AmountTone.neutral => '',
    };

    // Bengali and Hindi render their own numerals: ₹১,২৪০ reads as money to a
    // Bengali speaker in a way ₹1,240 never quite does.
    final body = compact
        ? formatInrCompact(paise, localize: locale)
        : formatInr(
            paise,
            showPaise: showPaise,
            showSymbol: showSymbol,
            localize: locale,
          );

    return Text(
      '$sign$body',
      style: base.copyWith(color: color ?? c.amountColor(tone)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// "গত মাসের চেয়ে ১২% কম" — a delta with the arrow that matches its direction.
class MoneyDelta extends StatelessWidget {
  const MoneyDelta({
    super.key,
    required this.deltaPercent,
    this.onDark = false,
    this.goodWhenDown = true,
  });

  final double deltaPercent;
  final bool onDark;

  /// For an expense, spending *less* is the good outcome.
  final bool goodWhenDown;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final up = deltaPercent > 0;
    final good = goodWhenDown ? !up : up;
    final tone = good ? c.teal500 : c.rose500;
    final colour = onDark ? Colors.white : tone;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 15,
          color: colour,
        ),
        const SizedBox(width: SsSpace.x1),
        Text(
          '${deltaPercent.abs().toStringAsFixed(0)}%',
          style: SsText.caption.copyWith(
            color: colour,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Budget progress. Colour thresholds are fixed by the design lock:
/// under 80% accent, 80–99% warning (gold), 100%+ danger (rose).
class BudgetBar extends ConsumerWidget {
  const BudgetBar({
    super.key,
    required this.spentPaise,
    required this.limitPaise,
    this.height = 10,
    this.showLabels = true,
    this.animate = true,
  });

  final int spentPaise;
  final int limitPaise;
  final double height;
  final bool showLabels;
  final bool animate;

  double get ratio =>
      limitPaise <= 0 ? 0 : (spentPaise / limitPaise).clamp(0.0, 1.0);

  /// Thresholds fixed by the design lock: accent under 80%, amber at 80%,
  /// rose once the limit is reached.
  Color _barColour(SsColors c) {
    if (limitPaise > 0 && spentPaise >= limitPaise) return c.danger;
    if (ratio >= 0.8) return c.gold500;
    return c.violet600;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final locale = ref.watch(localeProvider);
    final colour = _barColour(c);
    final remaining = limitPaise - spentPaise;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: SsRadius.rPill,
          child: Stack(
            children: [
              Container(height: height, color: c.surfaceTint),
              animate
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => FractionallySizedBox(
                        widthFactor: value.clamp(0.001, 1.0),
                        child: Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: colour,
                            borderRadius: SsRadius.rPill,
                          ),
                        ),
                      ),
                    )
                  : FractionallySizedBox(
                      widthFactor: ratio.clamp(0.001, 1.0),
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: colour,
                          borderRadius: SsRadius.rPill,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: SsSpace.x2),
          // Both halves are flexible and both ellipsize, so a long Bengali
          // amount on a narrow phone shortens the label instead of overflowing
          // the card.
          Row(
            children: [
              Flexible(
                child: Text(
                  formatInr(spentPaise, showSymbol: true, localize: locale),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SsText.caption.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  ' / ${formatInr(limitPaise, showSymbol: true, localize: locale)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SsText.caption.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(width: SsSpace.x2),
              Flexible(
                child: Text(
                  remaining >= 0
                      ? 'বাকি ${formatInr(remaining, showSymbol: true, localize: locale)}'
                      : '${formatInr(-remaining, showSymbol: true, localize: locale)} বেশি',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: SsText.caption.copyWith(
                    color: remaining >= 0 ? c.textSecondary : c.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A ring chart for the category split. Hand-painted rather than pulling in a
/// charting package: it is sixty lines and it matches the token set exactly.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 168,
    this.thickness = 18,
    this.center,
  });

  final List<DonutSlice> slices;
  final double size;
  final double thickness;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              size: Size.square(size),
              painter: _DonutPainter(
                slices: slices,
                thickness: thickness,
                track: c.surfaceTint,
                progress: t,
              ),
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class DonutSlice {
  const DonutSlice({required this.value, required this.color, this.label});

  final double value;
  final Color color;
  final String? label;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.thickness,
    required this.track,
    required this.progress,
  });

  final List<DonutSlice> slices;
  final double thickness;
  final Color track;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = thickness;
    final arcRect = rect.deflate(stroke / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);

    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    var start = -math.pi / 2;
    const gap = 0.03;

    for (final slice in slices) {
      final sweep = (slice.value / total) * math.pi * 2 * progress;
      if (sweep <= gap) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = slice.color;

      canvas.drawArc(arcRect, start + gap / 2, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress ||
      old.slices.length != slices.length ||
      old.thickness != thickness;
}

/// A small bar series — the six-month trend on Insights.
///
/// Built so it *cannot* overflow: the bar area is an [Expanded] and the label is
/// a fixed-height footer, which means an unusually tall font, a clamped-but-still
/// large text scale, or a short card can only make the bars shorter — never push
/// the column past its box. The earlier fixed-height version did overflow, and an
/// overflow inside a card is invisible in a release build until someone screenshots
/// it.
class MiniBars extends StatelessWidget {
  const MiniBars({
    super.key,
    required this.values,
    required this.labels,
    this.height = 120,
    this.highlightLast = true,
  });

  final List<int> values;
  final List<String> labels;
  final double height;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    // A plain loop, deliberately — not `reduce(math.max).clamp(1, 1 << 62)`.
    //
    // On the Dart VM `1 << 62` is a large integer. Compiled to JavaScript a
    // bit-shift is 32-bit, the upper bound collapses to below 1, and `clamp`
    // throws "Invalid argument: 1" while the widget builds. In a release web
    // build that exception surfaces only as a blank rectangle where the chart
    // should be, and no test here can catch it: `flutter test` runs on the VM.
    // So: no bit tricks in this file.
    var maxValue = 1;
    for (final v in values) {
      if (v > maxValue) maxValue = v;
    }

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: values[i] / maxValue),
                          duration: Duration(milliseconds: 500 + i * 60),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => FractionallySizedBox(
                            heightFactor: value.clamp(0.04, 1.0),
                            widthFactor: 1,
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient:
                                    highlightLast && i == values.length - 1
                                    ? c.moneyGradient
                                    : null,
                                color: highlightLast && i == values.length - 1
                                    ? null
                                    : c.violet100,
                                borderRadius: SsRadius.rSm,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: SsSpace.x2),
                    SizedBox(
                      height: 16,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          i < labels.length ? labels[i] : '',
                          style: SsText.micro.copyWith(color: c.textTertiary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
