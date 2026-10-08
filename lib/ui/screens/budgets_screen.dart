/// S-14 Budgets (T-501).
///
/// The screen answers one question — *how much of this month's money is already
/// spoken for* — and answers it in that order: the overall cap and its bar
/// first, then the categories ranked by how much of their cap is gone, so the
/// row that needs attention is the one the eye lands on.
///
/// Two rules from `docs/03 §S-14` are enforced here rather than trusted to a
/// later batch:
///
/// * the native ad sits **after the third budget row**, never above the fold,
///   and only when there are more rows below it — an ad above the content on a
///   screen about the user's money is the fastest way to lose them;
/// * a budget at 120% is not just coloured red, it gets a sentence: raise the
///   cap, or slow the spending. A limit the user keeps missing is either a
///   wrong limit or a spending problem, and the screen should say so.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/budget_math.dart';
import '../../domain/view_models.dart';
import '../components/ad_slot.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../format.dart';
import '../strings.dart';
import '../tokens.dart';
import 'budget_edit_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final showAds = ref.watch(adsVisibleProvider);
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <BudgetView>[];
    final txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
    final categoryById = ref.watch(categoryByIdProvider);
    final nowMs = ref.watch(nowProvider).millisecondsSinceEpoch;

    final overall = <BudgetView>[
      for (final b in budgets)
        if (b.isOverall) b,
    ];
    final ranked = rankedBudgetStatus(
      txns: txns,
      budgets: [
        for (final b in budgets)
          if (!b.isOverall) b,
      ],
      nowMs: nowMs,
    );
    final overallStatus = overall.isEmpty
        ? null
        : budgetStatus(txns: txns, budget: overall.first, nowMs: nowMs);

    // The rows are capped at five on the list; the detail screen owns the rest.
    // An endless scroll of progress bars is a report, not a screen.
    final shown = ranked.take(6).toList();

    return SsScaffold(
      title: s.budget,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),

          // ---- the overall cap -----------------------------------------------
          if (overallStatus == null)
            _NoOverallCard(
              text: s['budgetEmptyBody'],
              actionLabel: s['budgetSetTitle'],
              onAction: () => showBudgetEditor(context),
            )
          else
            SsCard(
              gradient: c.moneyGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['budgetThisMonth'],
                    style: SsText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: SsSpace.x1),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: MoneyText(
                          overallStatus.limitPaise,
                          style: SsText.displayMoney,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: SsSpace.x2),
                      Flexible(
                        child: Text(
                          '— ${_pctLabel(overallStatus.ratio, locale)} '
                          '${s['budgetUsed']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SsText.bodyStrong.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SsSpace.x4),
                  // The bar sits on the gradient here, so it is drawn from white
                  // rather than the threshold colours: the overall number is
                  // context, and the alarms belong to the categories below.
                  ClipRRect(
                    borderRadius: SsRadius.rPill,
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                        FractionallySizedBox(
                          widthFactor: overallStatus.ratio.clamp(0.0, 1.0),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: SsRadius.rPill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SsSpace.x2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${s['budgetSpentLabel']} '
                          '${formatInr(overallStatus.spentPaise, showSymbol: true, localize: locale)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SsText.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      Text(
                        _budgetBarTail(overallStatus, s, locale),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SsText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SsSpace.x3),
                  SsActionButton(
                    label: s['budgetEdit'],
                    tone: SsButtonTone.secondary,
                    height: 40,
                    onPressed: () => showBudgetEditor(
                      context,
                      existing: overall.first,
                    ),
                  ),
                ],
              ),
            ),

          // ---- the categories -------------------------------------------------
          SectionHeader(
            title: s['budgetCategoryCap'],
            actionLabel: s['budgetNew'],
            onAction: () => showBudgetEditor(context),
          ),

          if (shown.isEmpty)
            EmptyState(
              title: s['budgetEmptyTitle'],
              message: s['budgetEmptyBody'],
              asset: 'assets/3d/empty-budget.jpg',
              actionLabel: s['budgetSetTitle'],
              onAction: () => showBudgetEditor(context),
            )
          else
            for (var i = 0; i < shown.length; i++) ...[
              _BudgetRow(
                status: shown[i],
                category: categoryById[shown[i].budget.categoryId],
                locale: locale,
                strings: s,
                onTap: () => context.push('/budgets/${shown[i].budget.id}'),
              ),
              // After the third row, and only when rows follow it.
              if (i == 2 && shown.length > 3 && showAds)
                const AdSlot(placement: AdPlacement.budgetNative),
            ],

          // ---- a cap that keeps being missed ----------------------------------
          for (final status in shown)
            if (status.at120) _SuggestionCard(status: status, locale: locale, s: s),

          if (shown.isNotEmpty) ...[
            const SizedBox(height: SsSpace.x4),
            SsActionButton(
              label: s['budgetNew'],
              icon: Icons.add_rounded,
              tone: SsButtonTone.secondary,
              onPressed: () => showBudgetEditor(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// `৫০%` — the percentage as the user reads it, uncapped, because a budget at
/// 107% has to say 107%.
String _pctLabel(double ratio, String locale) =>
    localizeDigits('${(ratio * 100).round()}%', locale);

String _budgetBarTail(BudgetStatus status, SsStrings s, String locale) {
  final remaining = status.remainingPaise;
  if (remaining >= 0) {
    return '${s['budgetRemainingLabel']} '
        '${formatInr(remaining, showSymbol: true, localize: locale)}';
  }
  return '${formatInr(-remaining, showSymbol: true, localize: locale)} '
      '${s['over']}';
}

class _NoOverallCard extends StatelessWidget {
  const _NoOverallCard({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return SsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: SsText.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x3),
          SsActionButton(
            label: actionLabel,
            tone: SsButtonTone.secondary,
            height: 42,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.status,
    required this.category,
    required this.locale,
    required this.strings,
    required this.onTap,
  });

  final BudgetStatus status;
  final CategoryView? category;
  final String locale;
  final SsStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final label = category?.label(locale) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: SsSpace.x3),
      child: SsCard(
        onTap: onTap,
        padding: const EdgeInsets.all(SsSpace.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (category != null) ...[
                  CategoryAvatar(
                    icon: category!.icon,
                    color: category!.color,
                    size: 34,
                  ),
                  const SizedBox(width: SsSpace.x3),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SsText.bodyStrong,
                  ),
                ),
                SsBadge(
                  label: _pctLabel(status.ratio, locale),
                  color: status.at100
                      ? c.danger
                      : (status.at80 ? c.gold500 : c.teal500),
                  icon: status.at100
                      ? Icons.error_outline_rounded
                      : (status.at80 ? Icons.warning_amber_rounded : null),
                ),
              ],
            ),
            const SizedBox(height: SsSpace.x3),
            BudgetBar(
              spentPaise: status.spentPaise,
              limitPaise: status.limitPaise,
              height: 8,
              showLabels: false,
            ),
            const SizedBox(height: SsSpace.x2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatInr(status.spentPaise, showSymbol: true, localize: locale)}'
                    ' / ${formatInr(status.limitPaise, showSymbol: true, localize: locale)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SsText.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                if (status.cycle.daysLeft > 0 &&
                    status.dailyAllowancePaise != null)
                  Text(
                    strings.daysLeft(status.cycle.daysLeft),
                    style: SsText.micro.copyWith(color: c.textTertiary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.status,
    required this.locale,
    required this.s,
  });

  final BudgetStatus status;
  final String locale;
  final SsStrings s;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: SsSpace.x3),
      child: SsCard(
        color: c.rose100,
        elevated: false,
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: c.danger, size: 20),
            const SizedBox(width: SsSpace.x3),
            Expanded(
              child: Text(
                s.fill('budgetSuggestTemplate', {
                  'pct': localizeDigits(
                    '${((status.ratio - 1) * 100).round()}',
                    locale,
                  ),
                }),
                style: SsText.caption.copyWith(color: c.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
