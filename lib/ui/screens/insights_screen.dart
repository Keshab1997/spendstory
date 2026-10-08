/// S-17 Insights (T-504).
///
/// Four answers, in the order a person asks them: where did the money go
/// (donut), what does the month look like day by day (the 30-day line), who
/// keeps taking it (top merchants), and what changed (this month vs last, the
/// biggest jump, the weekly pattern).
///
/// Everything is derived from the same `transactionsProvider` the ledger uses.
/// The period switcher changes the window, not the pipeline — week, month and
/// year all run through one `LedgerSummary.from`, and the comparison window is
/// always the equally long stretch immediately before it.
///
/// The forecast is the one Pro thing here, and the gate says so instead of
/// rendering a blurred number to squint at.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../components/ad_slot.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../format.dart';
import '../strings.dart';
import '../tokens.dart';

enum InsightsPeriod { week, month, year, custom }

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightsPeriod _period = InsightsPeriod.month;

  /// Only read when [_period] is [InsightsPeriod.custom].
  DateTime? _from;
  DateTime? _to;

  static int _msOf(DateTime d) => d.millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final isPro = ref.watch(proStatusProvider);
    final showAds = ref.watch(adsVisibleProvider);
    final txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
    final categoryById = ref.watch(categoryByIdProvider);
    final now = ref.watch(nowProvider);

    final window = _windowFor(now);
    final projected = _forecastPaise();
    final summary = LedgerSummary.from(
      txns,
      fromMs: window.$1,
      toMs: window.$2,
    );
    final previous = LedgerSummary.from(
      txns,
      fromMs: window.$3,
      toMs: window.$4,
    );

    final ranked = summary.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.take(5).toList();
    final merchants = topMerchants(txns, window.$1, window.$2);

    Future<void> openCategory(String id, int amountPaise) async {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => _CategorySheet(
          category: categoryById[id],
          amountPaise: amountPaise,
          summary: summary,
          strings: s,
          locale: locale,
        ),
      );
    }

    return SsScaffold(
      floatingNav: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),
          Text(s.insights, style: SsText.h1),
          const SizedBox(height: SsSpace.x1),
          Text(
            _windowLabel(s, locale, now),
            style: SsText.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x5),

          // ---- which window -------------------------------------------------
          SsSegmented<InsightsPeriod>(
            values: InsightsPeriod.values,
            labels: [
              s['periodWeek'],
              s['periodMonth'],
              s['periodYear'],
              s['periodCustom'],
            ],
            selected: _period,
            onChanged: _selectPeriod,
          ),
          if (_period == InsightsPeriod.custom) ...[
            const SizedBox(height: SsSpace.x3),
            _RangeRow(
              strings: s,
              from: _from,
              to: _to,
              locale: locale,
              onTap: _pickRange,
            ),
          ],
          const SizedBox(height: SsSpace.x5),

          if (summary.count == 0)
            EmptyState(
              title: s.noDataTitle,
              message: s.noDataBody,
              asset: 'assets/3d/empty-budget.jpg',
            )
          else ...[
            // ---- where it went ---------------------------------------------
            SsCard(
              child: Column(
                children: [
                  _TappableDonut(
                    slices: [
                      for (final entry in top)
                        DonutSlice(
                          value: entry.value.toDouble(),
                          color: categoryById[entry.key]?.color ?? c.violet600,
                          label: categoryById[entry.key]?.label(locale),
                        ),
                    ],
                    centre: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.expense,
                          style: SsText.micro.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        MoneyText(summary.expensePaise, style: SsText.h2),
                      ],
                    ),
                    onSlice: (i) => openCategory(top[i].key, top[i].value),
                  ),
                  const SizedBox(height: SsSpace.x2),
                  Text(
                    s['insightTapSlice'],
                    style: SsText.micro.copyWith(color: c.textTertiary),
                  ),
                  const SizedBox(height: SsSpace.x4),
                  for (final entry in top) ...[
                    _LegendRow(
                      label: categoryById[entry.key]?.label(locale) ?? '—',
                      icon: categoryById[entry.key]?.icon ?? '💳',
                      locale: locale,
                      colour: categoryById[entry.key]?.color ?? c.violet600,
                      amountPaise: entry.value,
                      share: summary.expensePaise == 0
                          ? 0
                          : entry.value / summary.expensePaise,
                      onTap: () => openCategory(entry.key, entry.value),
                    ),
                    if (entry != top.last) const SizedBox(height: SsSpace.x3),
                  ],
                ],
              ),
            ),

            // ---- the line ------------------------------------------------
            const SizedBox(height: SsSpace.x5),
            SectionHeader(title: s['trend30'], padding: EdgeInsets.zero),
            SsCard(
              child: Column(
                children: [
                  TrendLine(
                    values: dailySpend(txns, through: now),
                    height: 132,
                  ),
                  const SizedBox(height: SsSpace.x2),
                  Row(
                    children: [
                      Text(
                        shortDate(
                          DateTime(now.year, now.month, now.day)
                              .subtract(const Duration(days: 29))
                              .millisecondsSinceEpoch,
                          locale: locale,
                        ),
                        style: SsText.micro.copyWith(color: c.textTertiary),
                      ),
                      const Spacer(),
                      Text(
                        shortDate(
                          DateTime(
                            now.year,
                            now.month,
                            now.day,
                          ).millisecondsSinceEpoch,
                          locale: locale,
                        ),
                        style: SsText.micro.copyWith(color: c.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---- who keeps taking it -------------------------------------
            if (merchants.isNotEmpty) ...[
              const SizedBox(height: SsSpace.x5),
              SectionHeader(title: s['topMerchants'], padding: EdgeInsets.zero),
              SsCard(
                child: Column(
                  children: [
                    for (final m in merchants) ...[
                      _MerchantRow(
                        merchant: m.$1,
                        amountPaise: m.$2,
                        share: summary.expensePaise == 0
                            ? 0
                            : m.$2 / summary.expensePaise,
                      ),
                      if (m != merchants.last)
                        const SizedBox(height: SsSpace.x3),
                    ],
                  ],
                ),
              ),
            ],

            // ---- what changed -------------------------------------------
            const SizedBox(height: SsSpace.x5),
            SsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['monthCompare'], style: SsText.h3),
                  const SizedBox(height: SsSpace.x4),
                  _CompareRow(
                    label: s.expense,
                    currentPaise: summary.expensePaise,
                    previousPaise: previous.expensePaise,
                    locale: locale,
                    strings: s,
                  ),
                  const SizedBox(height: SsSpace.x3),
                  _CompareRow(
                    label: s.income,
                    currentPaise: summary.incomePaise,
                    previousPaise: previous.incomePaise,
                    locale: locale,
                    strings: s,
                    goodWhenDown: false,
                  ),
                  const SizedBox(height: SsSpace.x4),
                  _Findings(
                    categories: categoryById,
                    locale: locale,
                    strings: s,
                    current: summary,
                    previous: previous,
                    txns: txns,
                    fromMs: window.$1,
                    toMs: window.$2,
                  ),
                ],
              ),
            ),

            // ---- what it is heading towards ------------------------------
            const SizedBox(height: SsSpace.x5),
            if (!isPro)
              SsCard(
                color: c.tintOf(c.gold500),
                onTap: () => context.push('/pro'),
                child: Row(
                  children: [
                    Icon(Icons.auto_graph_rounded, color: c.gold500, size: 22),
                    const SizedBox(width: SsSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['insightProTitle'], style: SsText.bodyStrong),
                          const SizedBox(height: 2),
                          Text(
                            s['insightProBody'],
                            style: SsText.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: SsSpace.x3),
                          SsActionButton(
                            label: s['insightProCta'],
                            tone: SsButtonTone.gold,
                            height: 40,
                            expanded: false,
                            onPressed: () => context.push('/pro'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: SsSpace.x2),
                    SsBadge(label: 'Pro', color: c.gold500),
                  ],
                ),
              )
            else if (projected != null)
              SsCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      color: c.violet600,
                      size: 22,
                    ),
                    const SizedBox(width: SsSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['forecast'],
                            style: SsText.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          MoneyText(projected, style: SsText.h3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // Under everything, never between two numbers being compared — and
          // only for a window that has something in it.
          if (showAds && summary.count > 0)
            const AdSlot(placement: AdPlacement.sectionBanner),
          const SizedBox(height: SsSpace.x6),
        ],
      ),
    );
  }

  /// End-of-window projection, Pro's headline number. Uses the same
  /// `PeriodTotals.forecastExpense` the home screen does, so "estimated" means
  /// one thing in this app, and it stays silent in the first days of a month
  /// when a daily rate is still noise.
  int? _forecastPaise() {
    final now = ref.read(nowProvider);
    if (_period == InsightsPeriod.custom || _period == InsightsPeriod.year) {
      return null;
    }
    final txns =
        ref.read(transactionsProvider).valueOrNull ?? const <TxnView>[];
    final window = _windowFor(now);
    final summary = LedgerSummary.from(
      txns,
      fromMs: window.$1,
      toMs: window.$2,
    );
    // `monthProgress` reads the day of the month off the date it is handed, so
    // it wants today — handing it the 1st makes every forecast three days too
    // early to exist.
    final progress = _period == InsightsPeriod.week
        ? (elapsed: now.weekday, total: 7)
        : monthProgress(now.millisecondsSinceEpoch);

    return PeriodTotals(
      incomePaise: summary.incomePaise,
      expensePaise: summary.expensePaise,
    ).forecastExpense(elapsedDays: progress.elapsed, totalDays: progress.total);
  }

  void _selectPeriod(InsightsPeriod p) {
    if (p == InsightsPeriod.custom && !ref.read(proStatusProvider)) {
      // The custom range is Pro (see `insightProBody`). Sending the tap to the
      // paywall is honest; a chip that silently does nothing reads as broken.
      context.push('/pro');
      return;
    }
    setState(() => _period = p);
  }

  Future<void> _pickRange() async {
    final now = ref.read(nowProvider);
    final start = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime(now.year, now.month, now.day - 29),
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _to ?? now,
      firstDate: start,
      lastDate: now,
    );
    if (end == null || !mounted) return;
    setState(() {
      _from = start;
      _to = end;
    });
  }

  /// (from, to, previousFrom, previousTo) in epoch ms. The previous window is
  /// always the same length, ending the instant this one starts.
  (int, int, int, int) _windowFor(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = today
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    switch (_period) {
      case InsightsPeriod.week:
        final monday = today.subtract(Duration(days: now.weekday - 1));
        return (
          _msOf(monday),
          _msOf(endOfToday),
          _msOf(monday.subtract(const Duration(days: 7))),
          _msOf(monday.subtract(const Duration(milliseconds: 1))),
        );
      case InsightsPeriod.year:
        final jan1 = DateTime(now.year);
        return (
          _msOf(jan1),
          _msOf(endOfToday),
          _msOf(DateTime(now.year - 1)),
          _msOf(jan1.subtract(const Duration(milliseconds: 1))),
        );
      case InsightsPeriod.custom:
        final from = DateTime(
          (_from ?? now.subtract(const Duration(days: 29))).year,
          (_from ?? now.subtract(const Duration(days: 29))).month,
          (_from ?? now.subtract(const Duration(days: 29))).day,
        );
        final to = DateTime(
          (_to ?? now).year,
          (_to ?? now).month,
          (_to ?? now).day,
        ).add(const Duration(days: 1));
        final span = to.difference(from);
        return (
          _msOf(from),
          _msOf(to.subtract(const Duration(milliseconds: 1))),
          _msOf(from.subtract(span)),
          _msOf(from.subtract(const Duration(milliseconds: 1))),
        );
      case InsightsPeriod.month:
        final start = DateTime(now.year, now.month);
        return (
          _msOf(start),
          _msOf(endOfToday),
          _msOf(DateTime(now.year, now.month - 1)),
          _msOf(start.subtract(const Duration(milliseconds: 1))),
        );
    }
  }

  String _windowLabel(SsStrings s, String locale, DateTime now) {
    switch (_period) {
      case InsightsPeriod.week:
        return s['periodWeek'];
      case InsightsPeriod.year:
        return localizeDigits('${now.year}', locale);
      case InsightsPeriod.custom:
        if (_from == null || _to == null) return s['periodCustom'];
        return '${shortDate(_from!.millisecondsSinceEpoch, locale: locale)}'
            ' – ${shortDate(_to!.millisecondsSinceEpoch, locale: locale)}';
      case InsightsPeriod.month:
        return monthLabel(
          DateTime(now.year, now.month).millisecondsSinceEpoch,
          locale: locale,
        );
    }
  }
}

/// Daily expense totals for the 30 days ending on [through], oldest first —
/// the line. Days with nothing spent are a real zero, not a gap: that is what
/// "no chai on Sunday" looks like, and smoothing it away would be a lie.
List<int> dailySpend(List<TxnView> txns, {required DateTime through}) {
  final start = DateTime(
    through.year,
    through.month,
    through.day,
  ).subtract(const Duration(days: 29));
  final buckets = List<int>.filled(30, 0);

  for (final t in txns) {
    if (t.direction != TxnDirection.expense) continue;
    final at = DateTime.fromMillisecondsSinceEpoch(t.occurredAtMs);
    final index = DateTime(at.year, at.month, at.day).difference(start).inDays;
    if (index < 0 || index > 29) continue;
    buckets[index] += t.amountPaise;
  }
  return buckets;
}

/// Merchant → total inside the window, biggest first, top five. Ties break on
/// name so the list never reshuffles between builds. Rows without a merchant
/// are skipped: "unknown" five times is not a merchant.
List<(String, int)> topMerchants(List<TxnView> txns, int fromMs, int toMs) {
  final totals = <String, int>{};
  for (final t in txns) {
    if (t.direction != TxnDirection.expense) continue;
    if (t.occurredAtMs < fromMs || t.occurredAtMs > toMs) continue;
    final name = (t.merchant ?? '').trim();
    if (name.isEmpty) continue;
    totals[name] = (totals[name] ?? 0) + t.amountPaise;
  }
  final ranked = totals.entries.toList()
    ..sort((a, b) {
      final byAmount = b.value.compareTo(a.value);
      return byAmount != 0 ? byAmount : a.key.compareTo(b.key);
    });
  return [for (final e in ranked.take(5)) (e.key, e.value)];
}

/// The category with the largest percentage increase — but only a real one.
/// Returns (categoryId, percentIncrease), or null.
///
/// The 20% floor is deliberate: telling somebody "Health went up 3%" is how an
/// insights screen teaches people to stop reading it.
(String, double)? biggestJump({
  required Map<String, int> current,
  required Map<String, int> previous,
}) {
  (String, double)? best;
  for (final entry in current.entries) {
    final was = previous[entry.key] ?? 0;
    if (was <= 0) continue;
    final delta = (entry.value - was) / was * 100;
    if (delta < 20) continue;
    if (best == null || delta > best.$2) best = (entry.key, delta);
  }
  return best;
}

/// True when the average weekend day in the window costs meaningfully more
/// than the average weekday — 25%, so a single big Saturday does not qualify.
bool weekendsCostMore(List<TxnView> txns, int fromMs, int toMs) {
  final weekendDays = <int>{};
  final weekdayDays = <int>{};
  for (var ms = fromMs; ms <= toMs; ms += Duration.millisecondsPerDay) {
    final at = DateTime.fromMillisecondsSinceEpoch(ms);
    if (at.weekday == DateTime.saturday || at.weekday == DateTime.sunday) {
      weekendDays.add((at.year * 1000) + at.day);
    } else {
      weekdayDays.add((at.year * 1000) + at.day);
    }
  }

  var weekend = 0, weekday = 0;
  for (final t in txns) {
    if (t.direction != TxnDirection.expense) continue;
    if (t.occurredAtMs < fromMs || t.occurredAtMs > toMs) continue;
    final at = DateTime.fromMillisecondsSinceEpoch(t.occurredAtMs);
    if (at.weekday == DateTime.saturday || at.weekday == DateTime.sunday) {
      weekend += t.amountPaise;
    } else {
      weekday += t.amountPaise;
    }
  }

  if (weekendDays.isEmpty || weekdayDays.isEmpty) return false;
  return weekend / weekendDays.length > weekday / weekdayDays.length * 1.25;
}

/// The donut, with taps resolved by angle.
///
/// Hit-testing inside a painted chart is the part that is easy to skip and
/// impossible not to notice: tapping the orange slice and getting the blue
/// one's detail is worse than no interaction at all.
class _TappableDonut extends StatelessWidget {
  const _TappableDonut({
    required this.slices,
    required this.centre,
    required this.onSlice,
  });

  final List<DonutSlice> slices;
  final Widget centre;
  final ValueChanged<int> onSlice;

  static const double _size = 168;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final total = slices.fold<double>(0, (sum, s) => sum + s.value);
        if (total <= 0 || slices.isEmpty) return;

        final dx = details.localPosition.dx - _size / 2;
        final dy = details.localPosition.dy - _size / 2;
        // The hole in the middle is not a slice.
        if (math.sqrt(dx * dx + dy * dy) < _size * 0.28) return;

        // The painter starts at twelve o'clock and sweeps clockwise.
        var angle = math.atan2(dy, dx) + math.pi / 2;
        if (angle < 0) angle += math.pi * 2;

        var swept = 0.0;
        for (var i = 0; i < slices.length; i++) {
          swept += slices[i].value / total * math.pi * 2;
          if (angle < swept) {
            onSlice(i);
            return;
          }
        }
        onSlice(slices.length - 1);
      },
      child: DonutChart(slices: slices, size: _size, center: centre),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.icon,
    required this.colour,
    required this.amountPaise,
    required this.share,
    required this.locale,
    required this.onTap,
  });

  final String label;
  final String icon;
  final Color colour;
  final int amountPaise;
  final double share;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: SsRadius.rSm,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.tintOf(colour),
              borderRadius: SsRadius.rSm,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: SsSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SsText.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: SsRadius.rPill,
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: c.surfaceTint,
                    valueColor: AlwaysStoppedAnimation<Color>(colour),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SsSpace.x3),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(amountPaise, style: SsText.bodyStrong),
                Text(
                  localizeDigits(
                    '${(share * 100).toStringAsFixed(0)}%',
                    locale,
                  ),
                  style: SsText.micro.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({
    required this.merchant,
    required this.amountPaise,
    required this.share,
  });

  final String merchant;
  final int amountPaise;
  final double share;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                merchant,
                style: SsText.bodyStrong,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: SsRadius.rPill,
                child: LinearProgressIndicator(
                  value: share.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: c.surfaceTint,
                  valueColor: AlwaysStoppedAnimation<Color>(c.teal500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: SsSpace.x3),
        Flexible(child: MoneyText(amountPaise, style: SsText.bodyStrong)),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.currentPaise,
    required this.previousPaise,
    required this.locale,
    required this.strings,
    this.goodWhenDown = true,
  });

  final String label;
  final int currentPaise;
  final int previousPaise;
  final String locale;
  final SsStrings strings;
  final bool goodWhenDown;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final delta = previousPaise <= 0
        ? null
        : (currentPaise - previousPaise) / previousPaise * 100;

    // "About the same as last month" next to a five-figure amount is wider than
    // a 360dp phone: the trailing cluster shrinks together rather than the row
    // overflowing at the one text scale that matters most.
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: SsText.body.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(width: SsSpace.x2),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                MoneyText(currentPaise, style: SsText.bodyStrong),
                const SizedBox(width: SsSpace.x2),
                if (delta == null)
                  const SizedBox.shrink()
                else if (delta.abs() < 5)
                  Text(
                    strings['deltaSame'],
                    style: SsText.micro.copyWith(color: c.textTertiary),
                  )
                else
                  MoneyDelta(
                    deltaPercent: delta,
                    locale: locale,
                    goodWhenDown: goodWhenDown,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The two sentences that turn numbers into something to act on: the biggest
/// jump and the weekly pattern. Both appear only when they are true — an
/// "insight" that fires every month regardless is decoration.
class _Findings extends StatelessWidget {
  const _Findings({
    required this.categories,
    required this.locale,
    required this.strings,
    required this.current,
    required this.previous,
    required this.txns,
    required this.fromMs,
    required this.toMs,
  });

  final Map<String, CategoryView> categories;
  final String locale;
  final SsStrings strings;
  final LedgerSummary current;
  final LedgerSummary previous;
  final List<TxnView> txns;
  final int fromMs;
  final int toMs;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final jump = biggestJump(
      current: current.byCategory,
      previous: previous.byCategory,
    );
    final weekendHeavy = weekendsCostMore(txns, fromMs, toMs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (jump != null) ...[
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: c.rose500),
              const SizedBox(width: SsSpace.x2),
              Text(
                strings['biggestJump'],
                style: SsText.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: SsSpace.x1),
          Text(
            '${categories[jump.$1]?.label(locale) ?? '—'} · '
            '${strings.fill('deltaMoreTemplate', {'pct': localizeDigits('${jump.$2.round()}', locale)})}',
            style: SsText.bodyStrong,
          ),
          const SizedBox(height: SsSpace.x4),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              weekendHeavy ? Icons.weekend_outlined : Icons.show_chart_rounded,
              size: 18,
              color: c.violet600,
            ),
            const SizedBox(width: SsSpace.x2),
            Expanded(
              child: Text(
                weekendHeavy
                    ? strings['patternWeekend']
                    : strings['patternSteady'],
                style: SsText.body,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.strings,
    required this.from,
    required this.to,
    required this.locale,
    required this.onTap,
  });

  final SsStrings strings;
  final DateTime? from;
  final DateTime? to;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    String show(DateTime? d) => d == null
        ? '—'
        : shortDate(
            DateTime(d.year, d.month, d.day).millisecondsSinceEpoch,
            locale: locale,
          );

    return SsCard(
      elevated: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: SsSpace.card,
        vertical: SsSpace.x4,
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 20, color: c.violet600),
          const SizedBox(width: SsSpace.x3),
          Expanded(
            child: Text(
              '${show(from)} – ${show(to)}',
              style: SsText.bodyStrong,
            ),
          ),
          Text(
            strings['periodCustom'],
            style: SsText.micro.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// What a tapped slice says: the category, how much, what share of the window,
/// and how many times. The count is the part that changes behaviour — "₹4,200
/// in 31 transactions" is a habit; "₹4,200" is just a number.
class _CategorySheet extends StatelessWidget {
  const _CategorySheet({
    required this.category,
    required this.amountPaise,
    required this.summary,
    required this.strings,
    required this.locale,
  });

  final CategoryView? category;
  final int amountPaise;
  final LedgerSummary summary;
  final SsStrings strings;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final share = summary.expensePaise == 0
        ? 0
        : (amountPaise / summary.expensePaise * 100).round();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SsSpace.x5,
          0,
          SsSpace.x5,
          SsSpace.x5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category?.icon ?? '💳',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: SsSpace.x2),
                Expanded(
                  child: Text(
                    category?.label(locale) ?? strings['unknownCategory'],
                    style: SsText.h3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SsSpace.x3),
            MoneyText(amountPaise, style: SsText.h2),
            const SizedBox(height: SsSpace.x1),
            Text(
              strings.fill('shareOfSpendingTemplate', {
                'pct': localizeDigits('$share', locale),
              }),
              style: SsText.body.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
