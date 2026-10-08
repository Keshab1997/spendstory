/// S-19 Recurring & reminders (T-506).
///
/// The screen answers "what is about to be taken out of my account?" — which is
/// a question about the next few weeks, not about a list of rules. So the strip
/// of the next thirty days comes first, and the rules sit under it with their
/// next date, whether they post themselves, and whether a reminder is set.
///
/// Every date on this screen comes from `recurring_math.dart`, the same
/// arithmetic the auto-post and reminder pipelines use. A screen that computes
/// its own idea of "next month" would eventually disagree with the payments.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/recurring_math.dart';
import '../../domain/view_models.dart';
import '../components/ad_slot.dart';
import '../components/controls.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../format.dart';
import '../strings.dart';
import '../tokens.dart';
import 'recurring_edit_sheet.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final showAds = ref.watch(adsVisibleProvider);
    final rules =
        ref.watch(recurringProvider).valueOrNull ?? const <RecurringRuleView>[];
    final categoryById = ref.watch(categoryByIdProvider);
    final now = ref.watch(nowProvider);
    final nowMs = now.millisecondsSinceEpoch;
    final today = dayStartMs(nowMs);

    final strip = _strip(rules, today);

    return SsScaffold(
      title: s['recurringTitle'],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),

          if (rules.isEmpty)
            EmptyState(
              title: s['recurringEmptyTitle'],
              message: s['recurringEmptyBody'],
              asset: 'assets/3d/empty-budget.jpg',
            )
          else ...[
            // ---- the next thirty days --------------------------------------
            // Title and count stack instead of sharing a row: at large text
            // scales the two-up line has nowhere left to shrink.
            Text(s['recurringStripTitle'], style: SsText.h3),
            const SizedBox(height: SsSpace.x1),
            Text(
              s.fill('recurringDueCountTemplate', {
                'n': s.digits(
                  '${strip.fold<int>(0, (sum, day) => sum + day.rules.length)}',
                ),
              }),
              style: SsText.micro.copyWith(color: c.textTertiary),
            ),
            const SizedBox(height: SsSpace.x3),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: strip.length,
                separatorBuilder: (_, _) => const SizedBox(width: SsSpace.x2),
                itemBuilder: (_, index) =>
                    _DayTile(day: strip[index], isToday: index == 0, s: s),
              ),
            ),
            const SizedBox(height: SsSpace.x5),

            // ---- the rules --------------------------------------------------
            for (final rule in rules) ...[
              _RuleCard(
                rule: rule,
                category: rule.categoryId == null
                    ? null
                    : categoryById[rule.categoryId],
                strings: s,
                todayMs: today,
                onTap: () async {
                  await showRecurringEditor(context, existing: rule);
                },
              ),
              const SizedBox(height: SsSpace.x3),
            ],
          ],

          // One ad, above the last thing on the screen — never between the
          // strip and the rule it belongs to.
          if (showAds) const AdSlot(placement: AdPlacement.recurringNative),

          const SizedBox(height: SsSpace.x4),
          SsActionButton(
            label: s['recurringAdd'],
            icon: Icons.add_rounded,
            onPressed: () async {
              await showRecurringEditor(context);
            },
          ),
          const SizedBox(height: SsSpace.x6),
        ],
      ),
    );
  }

  /// The next thirty days, each with whatever falls due on it.
  static List<({int dayMs, List<RecurringRuleView> rules})> _strip(
    List<RecurringRuleView> rules,
    int todayMs,
  ) {
    // Midnight after the thirtieth day, minus a millisecond: the window has to
    // take in the whole of its last day, or a payment due at 9 am on day thirty
    // is counted out of a strip that is showing that very day.
    final start = DateTime.fromMillisecondsSinceEpoch(todayMs);
    final lastMs =
        DateTime(
          start.year,
          start.month,
          start.day + 30,
        ).millisecondsSinceEpoch -
        1;

    final byDay = <int, List<RecurringRuleView>>{};
    for (final rule in rules) {
      for (final due in duesBetween(
        frequency: rule.frequencyEnum,
        interval: rule.interval,
        dayOfMonth: rule.dayOfMonth,
        dueMs: rule.nextDueAt,
        fromMs: todayMs,
        toMs: lastMs,
      )) {
        (byDay[dayStartMs(due)] ??= <RecurringRuleView>[]).add(rule);
      }
    }

    return <({int dayMs, List<RecurringRuleView> rules})>[
      for (var i = 0; i < 30; i++)
        () {
          final dayMs = DateTime.fromMillisecondsSinceEpoch(todayMs)
              .add(Duration(days: i))
              .millisecondsSinceEpoch;
          return (dayMs: dayMs, rules: byDay[dayMs] ?? const []);
        }(),
    ];
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.isToday, required this.s});

  final ({int dayMs, List<RecurringRuleView> rules}) day;
  final bool isToday;
  final SsStrings s;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final hasDue = day.rules.isNotEmpty;
    final total = day.rules.fold<int>(0, (sum, r) => sum + r.amountPaise);

    final tile = Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: SsSpace.x2),
      decoration: BoxDecoration(
        color: hasDue ? c.tintOf(c.violet600) : c.surfaceTint,
        borderRadius: SsRadius.rMd,
        border: Border.all(
          color: isToday ? c.violet600 : c.divider,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekdayShort(day.dayMs, locale: s.locale).characters.first,
            style: SsText.micro.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: 2),
          Text(
            s.digits('${DateTime.fromMillisecondsSinceEpoch(day.dayMs).day}'),
            style: SsText.bodyStrong,
          ),
          const SizedBox(height: 2),
          if (hasDue)
            Text(
              formatInrCompact(total, localize: s.numeralLocale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SsText.micro.copyWith(
                color: c.violet600,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );

    // A date tile is a fixed chip: cap the text scale inside it so a very large
    // system font cannot push the day, the amount and the dot out of it.
    return MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: tile);
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.category,
    required this.strings,
    required this.todayMs,
    required this.onTap,
  });

  final RecurringRuleView rule;
  final CategoryView? category;
  final SsStrings strings;
  final int todayMs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dueDay = dayStartMs(rule.nextDueAt);
    final dueToday = dueDay == todayMs;
    // A rule whose day came and went while nobody was looking is not "next on
    // <a date in the past>" — say plainly that it was missed.
    final overdue = dueDay < todayMs;

    final frequency = rule.interval <= 1
        ? strings[switch (rule.frequencyEnum) {
            RecurringFrequency.daily => 'freqDaily',
            RecurringFrequency.weekly => 'freqWeekly',
            RecurringFrequency.monthly => 'freqMonthly',
            RecurringFrequency.yearly => 'freqYearly',
          }]
        : strings.fill('recurringEveryTemplate', {
            'n': strings.digits('${rule.interval}'),
            'unit':
                strings[switch (rule.frequencyEnum) {
                  RecurringFrequency.daily => 'unitDays',
                  RecurringFrequency.weekly => 'unitWeeks',
                  RecurringFrequency.monthly => 'unitMonths',
                  RecurringFrequency.yearly => 'unitYears',
                }],
          });

    final date = strings.shortDate(rule.nextDueAt);
    final when = overdue
        ? '${strings['recurringOverdue']} $date'
        : dueToday
        ? strings['recurringDueToday']
        : strings.fill('recurringNextDueTemplate', <String, String>{
            'date': date,
          });

    return SsCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.tintOf(category?.color ?? c.violet600),
                  borderRadius: SsRadius.rSm,
                ),
                child: category != null
                    ? Text(category!.icon, style: const TextStyle(fontSize: 18))
                    : Icon(
                        Icons.autorenew_rounded,
                        size: 18,
                        color: c.violet600,
                      ),
              ),
              const SizedBox(width: SsSpace.x3),
              Expanded(
                child: Text(
                  rule.title,
                  style: SsText.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: SsSpace.x2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: MoneyText(
                    rule.amountPaise,
                    showSign: true,
                    tone: rule.direction == TxnDirection.income
                        ? AmountTone.income
                        : AmountTone.expense,
                    style: SsText.bodyStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SsSpace.x2),
          Row(
            children: [
              Icon(
                overdue
                    ? Icons.error_outline_rounded
                    : (dueToday
                          ? Icons.notifications_active_rounded
                          : Icons.event_rounded),
                size: 16,
                color: overdue
                    ? c.rose500
                    : (dueToday ? c.gold500 : c.textTertiary),
              ),
              const SizedBox(width: SsSpace.x2),
              Expanded(
                child: Text(
                  '$when · $frequency',
                  style: SsText.caption.copyWith(
                    color: overdue
                        ? c.rose500
                        : (dueToday ? c.gold500 : c.textSecondary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: SsSpace.x1),
          Row(
            children: [
              Icon(
                rule.autoPost
                    ? Icons.bolt_rounded
                    : (rule.reminds
                          ? Icons.notifications_none_rounded
                          : Icons.do_not_disturb_on_outlined),
                size: 16,
                color: rule.autoPost ? c.teal500 : c.textTertiary,
              ),
              const SizedBox(width: SsSpace.x2),
              Expanded(
                child: Text(
                  rule.autoPost
                      ? strings['recurringAutoPost']
                      : (rule.reminds
                            ? strings['recurringRemindLabel']
                            : strings['recurringRemindNote']),
                  style: SsText.micro.copyWith(color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
