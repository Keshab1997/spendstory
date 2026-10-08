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
import '../strings.dart';
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
    final strings = ref.watch(stringsProvider);
    final base = style ?? SsText.amountRow;
    final sign = switch (tone) {
      AmountTone.income => showSign ? '+' : '',
      AmountTone.expense => showSign ? '−' : '',
      AmountTone.neutral => '',
    };

    // Bengali and Hindi render their own numerals: ₹১,২৪০ reads as money to a
    // Bengali speaker in a way ₹1,240 never quite does.
    final body = compact
        ? formatInrCompact(paise, localize: strings.numeralLocale)
        : formatInr(
            paise,
            showPaise: showPaise,
            showSymbol: showSymbol,
            localize: strings.numeralLocale,
          );

    return Text(
      '$sign$body',
      style: base.copyWith(color: color ?? c.amountColor(tone)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Counts the headline amount up on first paint and smoothly to each new value.
///
/// The tween keeps the last displayed value as its starting point when data
/// changes, so a refresh never flashes back to zero. This is used on the Home
/// hero; list rows stay static for scanability.
class CountUpMoney extends StatelessWidget {
  const CountUpMoney(
    this.paise, {
    super.key,
    this.style,
    this.color,
    this.duration = const Duration(milliseconds: 600),
  });

  final int paise;
  final TextStyle? style;
  final Color? color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: paise),
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : duration,
      curve: Curves.easeOutExpo,
      builder: (context, value, _) =>
          MoneyText(value, style: style, color: color),
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
    required this.strings,
  });

  final double deltaPercent;
  final bool onDark;
  final SsStrings strings;

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
          strings.digits('${deltaPercent.abs().toStringAsFixed(0)}%'),
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
    final strings = ref.watch(stringsProvider);
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
                  formatInr(
                    spentPaise,
                    showSymbol: true,
                    localize: strings.numeralLocale,
                  ),
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
                  ' / ${formatInr(limitPaise, showSymbol: true, localize: strings.numeralLocale)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SsText.caption.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(width: SsSpace.x2),
              Flexible(
                child: Text(
                  remaining >= 0
                      ? '${strings['budgetLeft']} ${formatInr(remaining, showSymbol: true, localize: strings.numeralLocale)}'
                      : '${formatInr(-remaining, showSymbol: true, localize: strings.numeralLocale)} ${strings['over']}',
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

/// A ring showing how much of a cap is gone, with the number in the middle.
///
/// The ring and the number must never disagree, so both are driven from one
/// `ratio`: the arc is clamped to a full circle (an arc cannot be 107% of a
/// circle) while the number is not, which is exactly the pair a user needs —
/// the ring says "full", the centre says "and then some".
class CircularGauge extends StatelessWidget {
  const CircularGauge({
    super.key,
    required this.ratio,
    required this.child,
    this.size = 176,
    this.thickness = 14,
    this.color,
  });

  /// Uncapped on purpose: 1.07 draws a full ring and reads 107%.
  final double ratio;

  final Widget child;
  final double size;
  final double thickness;

  /// Overrides the threshold colour. Used where the surrounding card already
  /// carries the state and a second colour would fight it.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    // The same thresholds as [BudgetBar]: violet under 80%, gold to 100%,
    // danger once the cap is gone.
    final arcColour =
        color ??
        (ratio >= 1.0 ? c.danger : (ratio >= 0.8 ? c.gold500 : c.violet600));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: Size.square(size),
              painter: _GaugePainter(
                progress: value,
                thickness: thickness,
                track: c.surfaceTint,
                color: arcColour,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(thickness + SsSpace.x3),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.thickness,
    required this.track,
    required this.color,
  });

  final double progress;
  final double thickness;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(thickness / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;

    final barPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.color != color;
}

/// A 30-day spending line with a gradient fill, drawn left to right.
///
/// Hand-painted for the same reason the donut is: it is a polyline and a fill,
/// and it has to match the token ramp exactly. The "draw" is a path metric —
/// the line is painted up to a moving point rather than fading in, which is
/// what makes it read as the month being written out.
class TrendLine extends StatelessWidget {
  const TrendLine({
    super.key,
    required this.values,
    this.height = 132,
    this.color,
  });

  /// One point per day, oldest first. Daily totals in paise.
  final List<int> values;

  final double height;

  /// Defaults to the money gradient's violet.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final line = color ?? c.violet600;

    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '—',
            style: SsText.caption.copyWith(color: c.textTertiary),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
        builder: (context, progress, _) => CustomPaint(
          size: Size.infinite,
          painter: _TrendPainter(
            values: values,
            progress: progress,
            line: line,
            fill: line.withValues(alpha: c.isDark ? 0.28 : 0.18),
            baseline: c.surfaceTint,
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.progress,
    required this.line,
    required this.fill,
    required this.baseline,
  });

  final List<int> values;
  final double progress;
  final Color line;
  final Color fill;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    var maxValue = 1;
    for (final v in values) {
      if (v > maxValue) maxValue = v;
    }

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          size.width * i / (values.length - 1),
          size.height -
              (size.height * 0.88) * (values[i] / maxValue).clamp(0.0, 1.0) -
              4,
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final metric = path.computeMetrics().first;
    // The fill is the line's own path closed down to the baseline, so it
    // arrives with the drawing instead of revealing the shape in advance.
    canvas.drawPath(
      Path.from(metric.extractPath(0, metric.length * progress))
        ..lineTo(points.first.dx, size.height)
        ..lineTo(
          points.first.dx + (points.last.dx - points.first.dx) * progress,
          size.height,
        )
        ..close(),
      Paint()..color = fill,
    );

    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = line,
    );

    // The tip: a dot where the drawing has reached.
    canvas.drawCircle(
      Offset(
        points.first.dx + (points.last.dx - points.first.dx) * progress,
        _yAt(points, progress),
      ),
      3.6,
      Paint()..color = line,
    );
  }

  double _yAt(List<Offset> points, double t) {
    final x = points.first.dx + (points.last.dx - points.first.dx) * t;
    for (var i = 1; i < points.length; i++) {
      if (x <= points[i].dx) {
        final a = points[i - 1];
        final b = points[i];
        final span = (b.dx - a.dx).abs();
        final local = span == 0 ? 0.0 : ((x - a.dx) / span).clamp(0.0, 1.0);
        return a.dy + (b.dy - a.dy) * local;
      }
    }
    return points.last.dy;
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.progress != progress || old.values.length != values.length;
}
