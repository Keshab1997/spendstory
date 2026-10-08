/// S-09 Home — the screen the whole product is judged by.
///
/// Layout, top to bottom, and why:
///
/// 1. **Greeting + month** — tells the user *which* month the number below is.
/// 2. **The hero money card** — one big number. Nothing else on the screen is
///    allowed to be loud.
/// 3. **Ad banner** (free users only) — below the hero, never above it, and
///    never docked to the bottom nav (`docs/03-SCREEN-SPECS.md`).
/// 4. **Four quick actions** — the four things a user actually does.
/// 5. **Budget progress** — the number that changes behaviour.
/// 6. **Recent transactions** — proof the capture pipeline is working.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ads/ad_gate.dart';
import '../../app/providers.dart';
import '../../domain/view_models.dart';
import '../components/ad_slot.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../tokens.dart';
import 'tx_edit_sheet.dart';

/// Insights, and — at most once a session — the interstitial that may follow it.
///
/// The order is the whole point (`docs/08 §4`): navigate first, let the screen
/// build, and only then ask the gate. An interstitial that appears mid-transition
/// is the one users remember, and an interstitial over a screen that never
/// arrived is worse.
void _openInsights(BuildContext context, WidgetRef ref) {
  context.go('/insights');
  final gate = ref.read(adGateProvider);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(gate.maybeShow(AdTrigger.homeToInsights));
  });
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);

    final summary = ref.watch(monthSummaryProvider);
    final previous = ref.watch(previousMonthSummaryProvider);
    final budget = ref.watch(overallBudgetProvider).valueOrNull;
    final categoryById = ref.watch(categoryByIdProvider);
    final showAds = ref.watch(adsVisibleProvider);
    final demo = ref.watch(demoModeProvider);
    final month = ref.watch(selectedMonthProvider);

    final recent =
        (ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[])
            .take(5)
            .toList();

    final delta = previous.expensePaise == 0
        ? 0.0
        : ((summary.expensePaise - previous.expensePaise) /
                  previous.expensePaise *
                  100)
              .clamp(-999.0, 999.0);

    return SsScaffold(
      floatingNav: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.greeting,
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                    Text(s.monthLabel(month), style: SsText.h1),
                  ],
                ),
              ),
              SsIconButton(
                icon: Icons.search_rounded,
                tooltip: s['search'],
                onPressed: () => context.push('/search'),
              ),
              const SizedBox(width: SsSpace.x2),
              SsIconButton(
                icon: Icons.account_balance_wallet_outlined,
                tooltip: s['accounts'],
                onPressed: () => context.push('/accounts'),
              ),
            ],
          ),

          if (demo) ...[
            const SizedBox(height: SsSpace.x4),
            _DemoBanner(label: s['demoBanner'], body: s['demoBannerBody']),
          ],

          const SizedBox(height: SsSpace.x5),

          // ---- hero ----------------------------------------------------------
          SsCard(
            gradient: c.moneyGradient,
            padding: const EdgeInsets.all(SsSpace.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.heroLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SsText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    if (previous.expensePaise > 0) ...[
                      const SizedBox(width: SsSpace.x2),
                      MoneyDelta(deltaPercent: delta, onDark: true, strings: s),
                      const SizedBox(width: SsSpace.x1),
                      Flexible(
                        child: Text(
                          s['vsLastMonth'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SsText.micro.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: SsSpace.x1),
                CountUpMoney(
                  summary.expensePaise,
                  color: Colors.white,
                  style: SsText.displayMoney,
                ),
                const SizedBox(height: SsSpace.x4),
                Row(
                  children: [
                    Flexible(
                      child: StatPill(
                        label: s.income,
                        value: formatInr(
                          summary.incomePaise,
                          showSymbol: true,
                          localize: locale,
                        ),
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                    const SizedBox(width: SsSpace.x3),
                    Flexible(
                      child: StatPill(
                        label: s.savings,
                        value: formatInr(
                          summary.netPaise,
                          showSymbol: true,
                          localize: locale,
                        ),
                        icon: Icons.savings_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (showAds) const AdSlot(placement: AdPlacement.homeBanner),

          // ---- quick actions -------------------------------------------------
          const SizedBox(height: SsSpace.x5),
          Row(
            children: [
              Expanded(
                child: QuickAction(
                  icon: Icons.add_rounded,
                  label: s.addTx,
                  onTap: () => TxEditSheet.show(context),
                ),
              ),
              Expanded(
                child: QuickAction(
                  icon: Icons.savings_outlined,
                  label: s.budget,
                  tint: c.gold500,
                  onTap: () => context.push('/budgets'),
                ),
              ),
              Expanded(
                child: QuickAction(
                  icon: Icons.category_outlined,
                  label: s.categories,
                  tint: c.teal500,
                  onTap: () => context.push('/categories'),
                ),
              ),
              Expanded(
                child: QuickAction(
                  icon: Icons.insights_outlined,
                  label: s.reports,
                  tint: c.rose500,
                  onTap: () => _openInsights(context, ref),
                ),
              ),
            ],
          ),

          // ---- budget --------------------------------------------------------
          if (budget != null && budget > 0) ...[
            const SizedBox(height: SsSpace.x3),
            SectionHeader(title: s['monthlyBudget']),
            SsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BudgetBar(
                    spentPaise: summary.expensePaise,
                    limitPaise: budget,
                  ),
                  if (summary.expensePaise >= budget) ...[
                    const SizedBox(height: SsSpace.x3),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: c.danger,
                        ),
                        const SizedBox(width: SsSpace.x1 + 2),
                        Expanded(
                          child: Text(
                            s['budgetExceeded'],
                            style: SsText.caption.copyWith(color: c.danger),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ---- recent --------------------------------------------------------
          SectionHeader(
            title: s.recentTx,
            actionLabel: s.seeAll,
            onAction: () => context.go('/transactions'),
          ),
          if (recent.isEmpty)
            EmptyState(
              title: s.emptyTxTitle,
              message: s.emptyTxBody,
              actionLabel: s.addFirst,
              onAction: () {},
            )
          else
            SsCard(
              padding: const EdgeInsets.symmetric(
                horizontal: SsSpace.x3,
                vertical: SsSpace.x1,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i > 0) Divider(color: c.divider, height: 1),
                    TxRow(
                      txn: recent[i],
                      category: categoryById[recent[i].categoryId],
                      strings: s,
                      dense: true,
                      onTap: () =>
                          context.push('/transactions/${recent[i].id}'),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: SsSpace.x4),
        ],
      ),
    );
  }
}

/// The one piece of chrome that exists only in the web preview: it says, in
/// plain language, that the numbers below are not this user's money.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SsSpace.x3,
        vertical: SsSpace.x2 + 2,
      ),
      decoration: BoxDecoration(
        color: c.tintOf(c.gold500),
        borderRadius: SsRadius.rMd,
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 16, color: c.gold500),
          const SizedBox(width: SsSpace.x2),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: SsText.micro.copyWith(color: c.textSecondary),
                children: [
                  TextSpan(
                    text: '$label — ',
                    style: SsText.micro.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
