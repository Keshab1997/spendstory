/// S-15 Budget detail (T-502).
///
/// The differentiator of this whole feature sits in one sentence at the top:
/// **what is left, divided by the days left**. "₹750 left" is a fact the user
/// can do nothing with on the 8th of the month; "spend about ₹31 a day" is a
/// decision they can act on today. Everything else on the screen — the ring,
/// the three totals, the recent rows — exists to justify that number.
///
/// Over-budget is handled by *not* dividing: the allowance disappears and the
/// card says the cap is used up, because "spend ₹0 a day" reads as advice when
/// it is really a boundary.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/budget_math.dart';
import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../components/ad_slot.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../format.dart';
import '../tokens.dart';
import 'budget_edit_sheet.dart';

class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({super.key, required this.id});

  final String id;

  /// Opens the editor, and leaves the screen if the budget did not survive it.
  /// Staying would mean showing "no budget set" for the row the user is looking
  /// at, which reads as a bug rather than a consequence.
  static Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    BudgetView budget,
  ) async {
    final changed = await showBudgetEditor(context, existing: budget);
    if (!context.mounted || !changed) return;
    final budgets = await ref.read(budgetsProvider.future);
    if (!context.mounted) return;
    if (!budgets.any((b) => b.id == budget.id)) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final showAds = ref.watch(adsVisibleProvider);
    final budgets =
        ref.watch(budgetsProvider).valueOrNull ?? const <BudgetView>[];
    final txns =
        ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
    final categoryById = ref.watch(categoryByIdProvider);

    final budget = _find(budgets, id);

    if (budget == null) {
      return SsScaffold(
        title: s.budget,
        leading: BackButton(onPressed: () => _leave(context)),
        child: EmptyState(
          title: s['budgetEmptyTitle'],
          message: s['budgetEmptyBody'],
          asset: 'assets/3d/empty-budget.jpg',
        ),
      );
    }

    final status = budgetStatus(
      txns: txns,
      budget: budget,
      nowMs: ref.watch(nowProvider).millisecondsSinceEpoch,
    );
    final category = budget.categoryId == null
        ? null
        : categoryById[budget.categoryId];
    final title = category?.label(locale) ?? s['budgetOverallName'];

    // The rows this cap actually counts, newest first — the evidence behind the
    // number above, so nobody has to take the total on faith.
    final recent = <TxnView>[
      for (final t in txns)
        if (t.direction == TxnDirection.expense &&
            t.occurredAtMs >= status.cycle.startMs &&
            t.occurredAtMs <= status.cycle.endMs &&
            (budget.categoryId == null || t.categoryId == budget.categoryId))
          t,
    ].take(6).toList();

    return SsScaffold(
      title: title,
      leading: BackButton(onPressed: () => _leave(context)),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: s['budgetEdit'],
          onPressed: () => _edit(context, ref, budget),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),

          // ---- the ring -------------------------------------------------------
          Center(
            child: CircularGauge(
              ratio: status.ratio,
              size: 184,
              thickness: 15,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizeDigits('${(status.ratio * 100).round()}%', locale),
                    style: SsText.h1.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: SsSpace.x1),
                  Text(
                    s['budgetUsed'],
                    style: SsText.micro.copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SsSpace.x3),
          Center(
            child: Text(
              category == null
                  ? s['budgetOverallName']
                  : '${category.icon}  $title',
              style: SsText.bodyStrong.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: SsSpace.x4),

          // ---- the three totals ----------------------------------------------
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: s['budgetSpentLabel'],
                  value: status.spentPaise,
                  tone: AmountTone.expense,
                ),
              ),
              const SizedBox(width: SsSpace.x2),
              Expanded(
                child: _Stat(
                  label: s['budgetRemainingLabel'],
                  value: status.remainingPaise,
                  tone: status.remainingPaise >= 0
                      ? AmountTone.income
                      : AmountTone.expense,
                ),
              ),
              const SizedBox(width: SsSpace.x2),
              Expanded(
                child: _Stat(
                  label: s['budgetTotalLabel'],
                  value: status.limitPaise,
                ),
              ),
            ],
          ),
          const SizedBox(height: SsSpace.x4),

          // ---- the number the screen exists for --------------------------------
          SsCard(
            gradient: c.moneyGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s['budgetDailyTitle'],
                        style: SsText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    Text(
                      s.daysLeft(status.cycle.daysLeft),
                      style: SsText.micro.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SsSpace.x2),
                Text(
                  status.dailyAllowancePaise == null
                      ? s['budgetAllSpent']
                      : s.fill('budgetDailyTemplate', {
                          'amt': formatInr(
                            _wholeRupees(status.dailyAllowancePaise!),
                            showSymbol: true,
                            localize: locale,
                          ),
                        }),
                  style: SsText.h3.copyWith(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),

          // ---- what the cap is counting ---------------------------------------
          SectionHeader(title: s['budgetRecentTx']),
          if (recent.isEmpty)
            Text(
              s['budgetNoTx'],
              style: SsText.caption.copyWith(color: c.textSecondary),
            )
          else
            for (final t in recent)
              TxRow(
                txn: t,
                locale: locale,
                category: category,
                showDate: true,
                onTap: () => context.push('/transactions/${t.id}'),
              ),

          // One native unit, below everything it could interrupt: a chart or a
          // list of someone's spending is not an ad break.
          if (showAds) const AdSlot(placement: AdPlacement.detailNative),

          const SizedBox(height: SsSpace.x4),
          SsActionButton(
            label: s['budgetEdit'],
            icon: Icons.tune_rounded,
            tone: SsButtonTone.secondary,
            onPressed: () => _edit(context, ref, budget),
          ),
          const SizedBox(height: SsSpace.x3),
        ],
      ),
    );
  }

  static BudgetView? _find(List<BudgetView> budgets, String id) {
    for (final b in budgets) {
      if (b.id == id) return b;
    }
    return null;
  }

  static void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/budgets');

  /// A daily allowance is advice, and advice in paise is noise — ₹31.25 a day
  /// reads as false precision for a number that is already an average.
  static int _wholeRupees(int paise) => (paise ~/ 100) * 100;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.tone});

  final String label;
  final int value;
  final AmountTone? tone;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return SsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SsSpace.x3,
        vertical: SsSpace.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SsText.micro.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: SsSpace.x1),
          MoneyText(value, tone: tone ?? AmountTone.neutral, style: SsText.h3),
        ],
      ),
    );
  }
}
