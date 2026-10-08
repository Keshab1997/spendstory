/// Budget alerts (T-505) — the 80% and 100% warnings from `docs/03 §S-14`.
///
/// The planner here is pure: no clock, no platform, no database. The caller
/// supplies today and the record of what has already gone out, which is what
/// makes the three rules that are easy to get wrong actually testable.
///
/// 1. A budget that has crossed gets the crossed alert, not the 80% one. One
///    notification per budget per run — crossing must never arrive as two.
/// 2. Nothing is sent for a threshold the user switched off in the editor.
/// 3. Nothing is sent twice on the same day, however often the ledger changes.
library;

import '../domain/budget_math.dart';
import '../domain/view_models.dart';
import '../ui/components/money.dart' show formatInr;
import '../ui/strings.dart';

enum BudgetAlertLevel { at80, at100 }

class BudgetAlert {
  const BudgetAlert({
    required this.budgetId,
    required this.level,
    required this.title,
    required this.body,
  });

  final String budgetId;
  final BudgetAlertLevel level;
  final String title;
  final String body;

  /// `budget:<id>:80` — the identity the once-a-day cap is kept against.
  String get key =>
      'budget:$budgetId:${level == BudgetAlertLevel.at80 ? '80' : '100'}';

  /// Android needs an int. Derived from the key, so the same alert replaces
  /// yesterday's instead of stacking a second notification on the shade.
  int get notificationId => key.hashCode & 0x7fffffff;
}

/// `2026-10-08`. Local date, because "once a day" means the user's day.
String alertDay(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

/// The alerts that are owed right now, given what has already gone out today.
///
/// [sentOn] maps an alert key to the day it was last delivered.
List<BudgetAlert> owedBudgetAlerts({
  required List<BudgetStatus> statuses,
  required SsStrings strings,
  required String locale,
  required String today,
  required Map<String, String> sentOn,
  Map<String, CategoryView> categories = const <String, CategoryView>{},
}) {
  final owed = <BudgetAlert>[];

  for (final status in statuses) {
    final level = _levelFor(status);
    if (level == null) continue;

    final alert = _build(
      status: status,
      level: level,
      strings: strings,
      locale: locale,
      categories: categories,
    );
    if (sentOn[alert.key] == today) continue;
    owed.add(alert);
  }

  return owed;
}

/// Which warning this budget has earned — or none.
///
/// Crossing takes precedence over 80%, and a switched-off threshold means the
/// next one up is the only thing that can fire.
BudgetAlertLevel? _levelFor(BudgetStatus status) {
  // A budget with nothing spent against it is not a warning, whatever the
  // arithmetic says about a cap of zero.
  if (status.spentPaise <= 0) return null;

  if (status.at100) {
    return status.budget.alertAt100 ? BudgetAlertLevel.at100 : null;
  }
  if (status.at80) {
    return status.budget.alertAt80 ? BudgetAlertLevel.at80 : null;
  }
  return null;
}

BudgetAlert _build({
  required BudgetStatus status,
  required BudgetAlertLevel level,
  required SsStrings strings,
  required String locale,
  required Map<String, CategoryView> categories,
}) {
  final categoryId = status.budget.categoryId;
  final name = categoryId == null
      ? strings['budgetOverallCap']
      : (categories[categoryId]?.label(locale) ?? strings['budgetCategoryCap']);

  final crossed = level == BudgetAlertLevel.at100;
  final amount = formatInr(
    crossed ? -status.remainingPaise : status.remainingPaise,
    showSymbol: true,
    localize: locale,
  );

  return BudgetAlert(
    budgetId: status.budget.id,
    level: level,
    title: strings[crossed ? 'alert100Title' : 'alert80Title'],
    body: strings.fill(
      crossed ? 'alert100BodyTemplate' : 'alert80BodyTemplate',
      {'cat': name, 'amt': amount},
    ),
  );
}
