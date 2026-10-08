/// What the recurring pipeline owes (T-506, `docs/03 §S-19`).
///
/// Two jobs live here, and both are pure so the awkward cases are testable
/// without waiting a month:
///
/// * **auto-post** — a rule with the switch on writes its payment into the
///   ledger when the due date arrives, exactly once per due date.
/// * **reminders** — a notification before a payment is due, once per due date.
///
/// Neither reads a clock: the caller passes `nowMs` and the record of what has
/// already been done, so "the same payment twice" is a test, not a hope.
library;

import '../domain/recurring_math.dart';
import '../domain/view_models.dart';
import '../ui/components/money.dart' show formatInr;
import '../ui/format.dart' show localizeDigits;
import '../ui/strings.dart';
import 'budget_alerts.dart' show alertDay;

/// A due payment the ledger should now carry.
class RecurringPost {
  const RecurringPost({required this.rule, required this.dueMs});

  final RecurringRuleView rule;

  /// The date the payment belongs to — not the day the app noticed, which may
  /// be later: a rent posted while the phone was off is still rent.
  final int dueMs;

  /// `recurring:<id>:<due day>`. The identity that keeps one due date from
  /// being posted twice.
  String get key =>
      'recurring:${rule.id}:'
      '${alertDay(DateTime.fromMillisecondsSinceEpoch(dueMs))}';
}

/// The rules whose due date has arrived and which have not been posted yet.
///
/// [postedOn] maps a [RecurringPost.key] to the day it was posted; a key that is
/// absent means the payment is still owed.
List<RecurringPost> dueRecurringPosts({
  required List<RecurringRuleView> rules,
  required int nowMs,
  required Map<String, String> postedOn,
}) {
  final owed = <RecurringPost>[];

  for (final rule in rules) {
    if (!rule.autoPost) continue;
    if (rule.nextDueAt > nowMs) continue;

    final post = RecurringPost(rule: rule, dueMs: rule.nextDueAt);
    if (postedOn.containsKey(post.key)) continue;
    owed.add(post);
  }

  return owed;
}

/// What the rule's next due date becomes once [post] has been written.
///
/// It jumps forward from **today**, not from the missed due date: a phone that
/// was off for three months owes one rent, not three. The missed cycles were
/// paid in the real world; replaying them here would invent spending.
int nextDueAfterPost({required RecurringPost post, required int nowMs}) =>
    nextDueAfter(
      frequency: post.rule.frequencyEnum,
      interval: post.rule.interval,
      dayOfMonth: post.rule.dayOfMonth,
      dueMs: post.dueMs,
      fromMs: nowMs > post.dueMs ? nowMs : post.dueMs,
    );

/// A payment worth telling the user about.
class RecurringReminder {
  const RecurringReminder({
    required this.rule,
    required this.dueMs,
    required this.title,
    required this.body,
  });

  final RecurringRuleView rule;
  final int dueMs;
  final String title;
  final String body;

  /// `recurring-reminder:<id>:<due day>` — one reminder per due date, whatever
  /// the user's timing setting is.
  String get key =>
      'recurring-reminder:${rule.id}:'
      '${alertDay(DateTime.fromMillisecondsSinceEpoch(dueMs))}';

  int get notificationId => key.hashCode & 0x7fffffff;
}

/// The reminders that are due to be posted now.
///
/// A reminder window opens `remindDaysBefore` days before the due date and
/// closes on it: telling somebody their rent was due last week is not a
/// reminder, it is an accusation, and the app is not in the business of those.
///
/// [sentOn] is keyed by the due date, so a rule that has been reminded about
/// this payment stays quiet for the rest of the window — one nudge, not one a
/// day until the money leaves. The value is the day it went out, which is only
/// ever read back for debugging.
List<RecurringReminder> owedRecurringReminders({
  required List<RecurringRuleView> rules,
  required SsStrings strings,
  required String locale,
  required int nowMs,
  required Map<String, String> sentOn,
}) {
  final owed = <RecurringReminder>[];
  final todayStart = dayStartMs(nowMs);
  String amountOf(RecurringRuleView rule) =>
      formatInr(rule.amountPaise, showSymbol: true, localize: locale);

  for (final rule in rules) {
    if (!rule.reminds) continue;

    final due = dayStartMs(rule.nextDueAt);
    final opensOn = DateTime.fromMillisecondsSinceEpoch(due)
        .subtract(Duration(days: rule.remindDaysBefore))
        .millisecondsSinceEpoch;

    if (todayStart < opensOn || todayStart > due) continue;

    final reminder = RecurringReminder(
      rule: rule,
      dueMs: rule.nextDueAt,
      title: strings['reminderTitle'],
      body: strings.fill(
        daysBetweenDays(todayStart, due) <= 0
            ? 'reminderTodayBodyTemplate'
            : 'reminderSoonBodyTemplate',
        <String, String>{
          'title': rule.title,
          'amt': amountOf(rule),
          'n': localizeDigits('${daysBetweenDays(todayStart, due)}', locale),
        },
      ),
    );

    if (sentOn.containsKey(reminder.key)) continue;
    owed.add(reminder);
  }

  return owed;
}
