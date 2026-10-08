/// Budget arithmetic — pure Dart, no Flutter, no database.
///
/// A budget is not a calendar month, it is a **cycle**. `startDay` exists so a
/// user whose salary lands on the 7th can budget the 7th → the 6th, and the
/// daily allowance on S-15 has to know how many days are left in *that* window.
/// So the window is computed once, here, and every screen reads the same
/// numbers rather than each doing its own date arithmetic.
///
/// Tests live in `test/domain/budget_math_test.dart`; the edge cases that
/// matter are a cycle that starts mid-month, a cycle that wraps the year, and
/// the last day of a cycle (zero days left, allowance undefined rather than
/// divided by zero).
library;

import 'models.dart';
import 'view_models.dart';

/// The window a budget is measured over.
class BudgetCycle {
  const BudgetCycle({
    required this.startMs,
    required this.endMs,
    required this.elapsedDays,
    required this.totalDays,
  });

  final int startMs;

  /// Inclusive last millisecond of the cycle.
  final int endMs;

  /// Days of the cycle already lived, counting today as one. 1 on day one.
  final int elapsedDays;
  final int totalDays;

  int get daysLeft => (totalDays - elapsedDays).clamp(0, totalDays);
}

/// The cycle containing [nowMs] for a budget with the given cadence.
///
/// * `monthly` — from `startDay` to the day before the next `startDay`.
///   `startDay` is clamped to 1–28 so February always has that day
///   (`docs/05-DATA-MODEL.md`: 1–28 for exactly this reason).
/// * `weekly` — Monday to Sunday, `startDay` ignored.
/// * `custom` — the explicit `startsOn`/`endsOn` window; when either is
///   missing it degrades to the monthly window rather than throwing, because a
///   half-filled custom budget should still render.
BudgetCycle budgetCycle({
  required int nowMs,
  String period = 'monthly',
  int startDay = 1,
  int? startsOn,
  int? endsOn,
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(nowMs);

  if (period == 'custom' && startsOn != null && endsOn != null) {
    return _cycleBetween(startsOn, endsOn, nowMs);
  }

  if (period == 'weekly') {
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final next = monday.add(const Duration(days: 7));
    return _cycleBetween(
      monday.millisecondsSinceEpoch,
      next.millisecondsSinceEpoch - 1,
      nowMs,
    );
  }

  final day = startDay.clamp(1, 28);
  // The most recent occurrence of the cycle day at or before today. Written
  // with a real day-1 fallback rather than DateTime's month arithmetic, which
  // rolls 0 and 13 over for us but reads as a bug to anyone scanning it.
  DateTime start;
  if (now.day >= day) {
    start = DateTime(now.year, now.month, day);
  } else {
    start = DateTime(now.year, now.month - 1, day);
  }
  final end = DateTime(start.year, start.month + 1, day);
  return _cycleBetween(
    start.millisecondsSinceEpoch,
    end.millisecondsSinceEpoch - 1,
    nowMs,
  );
}

BudgetCycle _cycleBetween(int startMs, int endMs, int nowMs) {
  final start = DateTime.fromMillisecondsSinceEpoch(startMs);
  final end = DateTime.fromMillisecondsSinceEpoch(endMs);
  final totalDays =
      DateTime(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime(start.year, start.month, start.day)).inDays +
      1;
  final now = DateTime.fromMillisecondsSinceEpoch(nowMs);
  final elapsed =
      DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(start.year, start.month, start.day)).inDays +
      1;
  return BudgetCycle(
    startMs: startMs,
    endMs: endMs,
    elapsedDays: elapsed.clamp(1, totalDays),
    totalDays: totalDays,
  );
}

/// What a budget looks like right now: spent against it, and what is left per
/// remaining day.
class BudgetStatus {
  const BudgetStatus({
    required this.budget,
    required this.cycle,
    required this.spentPaise,
  });

  final BudgetView budget;
  final BudgetCycle cycle;
  final int spentPaise;

  int get limitPaise => budget.amountPaise;

  /// Uncapped: 1.07 really is 107%, and the screen has to say so.
  double get ratio => limitPaise <= 0 ? 0 : spentPaise / limitPaise;

  int get remainingPaise => limitPaise - spentPaise;

  /// The three thresholds the design locks in (`docs/03 §S-14`): warn at 80%,
  /// escalate at 100%, suggest a change at 120%.
  bool get at80 => ratio >= 0.8;
  bool get at100 => ratio >= 1.0;
  bool get at120 => ratio >= 1.2;

  /// The most actionable number on S-15: what the user may still spend per
  /// remaining day to finish the cycle inside the cap.
  ///
  /// Null — not zero — when the money is already gone or the cycle is over,
  /// because "spend ₹0 a day" is advice and "nothing left to spread" is a fact.
  int? get dailyAllowancePaise => remainingPaise <= 0 || cycle.daysLeft <= 0
      ? null
      : remainingPaise ~/ cycle.daysLeft;
}

/// Sums the expenses a budget covers inside its cycle.
///
/// Overall budgets count every expense; category budgets count theirs. Income
/// and transfers are never spend — counting a transfer as an expense is the
/// classic way a budget screen ends up wrong.
int spentInCycle({
  required List<TxnView> txns,
  required BudgetView budget,
  required BudgetCycle cycle,
}) {
  var sum = 0;
  for (final t in txns) {
    if (t.direction != TxnDirection.expense) continue;
    if (t.occurredAtMs < cycle.startMs || t.occurredAtMs > cycle.endMs) {
      continue;
    }
    if (budget.categoryId != null && t.categoryId != budget.categoryId) {
      continue;
    }
    sum += t.amountPaise;
  }
  return sum;
}

BudgetStatus budgetStatus({
  required List<TxnView> txns,
  required BudgetView budget,
  required int nowMs,
}) {
  final cycle = budgetCycle(
    nowMs: nowMs,
    period: budget.period,
    startDay: budget.startDay,
    startsOn: budget.startsOn,
    endsOn: budget.endsOn,
  );
  return BudgetStatus(
    budget: budget,
    cycle: cycle,
    spentPaise: spentInCycle(txns: txns, budget: budget, cycle: cycle),
  );
}

/// The list order for S-14: most-used first, so the row that needs attention is
/// the one the eye lands on. Ties fall back to the bigger cap, then the id, so
/// the order never depends on map iteration.
List<BudgetStatus> rankedBudgetStatus({
  required List<TxnView> txns,
  required List<BudgetView> budgets,
  required int nowMs,
}) {
  final list = <BudgetStatus>[
    for (final b in budgets) budgetStatus(txns: txns, budget: b, nowMs: nowMs),
  ];
  list.sort((a, b) {
    final byRatio = b.ratio.compareTo(a.ratio);
    if (byRatio != 0) return byRatio;
    final byLimit = b.limitPaise.compareTo(a.limitPaise);
    if (byLimit != 0) return byLimit;
    return a.budget.id.compareTo(b.budget.id);
  });
  return list;
}
