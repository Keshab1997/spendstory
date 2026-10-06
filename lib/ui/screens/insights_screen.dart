/// S-17 Insights.
///
/// Three questions, in this order: where did the money go, is this month normal,
/// and what is the trend. Everything on this screen is derived from the same
/// `transactionsProvider` the ledger uses — there is no second source of truth.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/view_models.dart';
import '../components/ad_slot.dart';
import '../components/lists.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../format.dart';
import '../tokens.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final summary = ref.watch(monthSummaryProvider);
    final categoryById = ref.watch(categoryByIdProvider);
    final trend = ref.watch(sixMonthTrendProvider);
    final labels = ref.watch(sixMonthLabelsProvider);
    final showAds = ref.watch(adsVisibleProvider);
    final month = ref.watch(selectedMonthProvider);

    final ranked = summary.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.take(5).toList();

    final donutSlices = <DonutSlice>[
      for (final entry in top)
        DonutSlice(
          value: entry.value.toDouble(),
          color: categoryById[entry.key]?.color ?? c.violet600,
          label: categoryById[entry.key]?.label(locale),
        ),
    ];

    final progress = monthProgress(month);
    final forecast = PeriodTotals(
      incomePaise: summary.incomePaise,
      expensePaise: summary.expensePaise,
    ).forecastExpense(elapsedDays: progress.elapsed, totalDays: progress.total);

    return SsScaffold(
      floatingNav: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),
          Text(s.insights, style: SsText.h1),
          const SizedBox(height: SsSpace.x1),
          Text(
            monthLabel(month, locale: locale),
            style: SsText.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x5),

          if (summary.count == 0)
            EmptyState(
              title: s.noDataTitle,
              message: s.noDataBody,
              asset: 'assets/3d/empty-budget.jpg',
            )
          else ...[
            // ---- the split ---------------------------------------------------
            SsCard(
              child: Column(
                children: [
                  DonutChart(
                    slices: donutSlices,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.expense,
                          style: SsText.micro.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        MoneyText(
                          summary.expensePaise,
                          showSymbol: true,
                          style: SsText.h2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SsSpace.x5),
                  for (final entry in top) ...[
                    _LegendRow(
                      label: categoryById[entry.key]?.label(locale) ?? '—',
                      icon: categoryById[entry.key]?.icon ?? '💳',
                      colour: categoryById[entry.key]?.color ?? c.violet600,
                      amountPaise: entry.value,
                      share: summary.expensePaise == 0
                          ? 0
                          : entry.value / summary.expensePaise,
                    ),
                    if (entry != top.last) const SizedBox(height: SsSpace.x3),
                  ],
                ],
              ),
            ),

            // ---- the trend ---------------------------------------------------
            const SizedBox(height: SsSpace.x5),
            SectionHeader(title: s.trend, padding: EdgeInsets.zero),
            SsCard(
              child: MiniBars(values: trend, labels: labels, height: 140),
            ),

            // ---- the forecast -------------------------------------------------
            if (forecast != null) ...[
              const SizedBox(height: SsSpace.x5),
              SsCard(
                color: c.tintOf(c.gold500),
                child: Row(
                  children: [
                    Icon(Icons.auto_graph_rounded, color: c.gold500, size: 22),
                    const SizedBox(width: SsSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'এই মাস শেষে আনুমানিক খরচ',
                            style: SsText.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          MoneyText(forecast, style: SsText.h3),
                        ],
                      ),
                    ),
                    SsBadge(label: 'Pro', color: c.gold500),
                  ],
                ),
              ),
            ],
          ],

          if (showAds) const AdSlot(placement: AdPlacement.sectionBanner),
          const SizedBox(height: SsSpace.x6),
        ],
      ),
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
  });

  final String label;
  final String icon;
  final Color colour;
  final int amountPaise;
  final double share;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Row(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MoneyText(amountPaise, style: SsText.bodyStrong),
            Text(
              '${(share * 100).toStringAsFixed(0)}%',
              style: SsText.micro.copyWith(color: c.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}
