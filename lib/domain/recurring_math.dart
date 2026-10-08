/// Recurring-rule arithmetic (T-506, `docs/03 §S-19`).
///
/// A rule is a promise about dates, and dates are where this stops being
/// trivial: rent is due on the 5th, but the 31st does not exist in February,
/// and a yearly rule set on the 29th has to survive three years out of four.
/// Everything here is pure, so those cases are tested without a clock.
///
/// The anchor is always the rule's own due date — advancing from the 5th lands
/// on the 5th, whatever has happened since. Nothing here reads "today".
library;

/// `-1` means "do not remind me"; every other value is days before the due
/// date, and `0` is the day itself.
const int kNoReminder = -1;

enum RecurringFrequency { daily, weekly, monthly, yearly }

const Map<RecurringFrequency, String> _wires = <RecurringFrequency, String>{
  RecurringFrequency.daily: 'daily',
  RecurringFrequency.weekly: 'weekly',
  RecurringFrequency.monthly: 'monthly',
  RecurringFrequency.yearly: 'yearly',
};

String recurringFrequencyWire(RecurringFrequency frequency) =>
    _wires[frequency]!;

/// Falls back to `monthly`, which is what rent and EMIs are.
RecurringFrequency recurringFrequencyFrom(String? wire) {
  for (final entry in _wires.entries) {
    if (entry.value == wire) return entry.key;
  }
  return RecurringFrequency.monthly;
}

/// Midnight local time for the day [ms] falls on — the unit a due date is
/// compared in, so "due today" does not depend on what time it is.
int dayStartMs(int ms) {
  final at = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(at.year, at.month, at.day).millisecondsSinceEpoch;
}

int daysBetweenDays(int fromMs, int toMs) =>
    DateTime.fromMillisecondsSinceEpoch(dayStartMs(toMs))
        .difference(DateTime.fromMillisecondsSinceEpoch(dayStartMs(fromMs)))
        .inDays;

/// The same rule, one whole cycle later than [dueMs].
///
/// Monthly and yearly clamp instead of rolling over: a rule on the 31st falls
/// on the 30th in April and the 28th in February, and then returns to the 31st
/// — the alternative (March 3rd) silently moves the rent.
int advanceDueDate({
  required RecurringFrequency frequency,
  int interval = 1,
  int? dayOfMonth,
  required int dueMs,
}) {
  final at = DateTime.fromMillisecondsSinceEpoch(dueMs);
  final step = interval < 1 ? 1 : interval;

  switch (frequency) {
    case RecurringFrequency.daily:
      return DateTime(
        at.year,
        at.month,
        at.day + step,
        at.hour,
        at.minute,
      ).millisecondsSinceEpoch;
    case RecurringFrequency.weekly:
      return DateTime(
        at.year,
        at.month,
        at.day + (7 * step),
        at.hour,
        at.minute,
      ).millisecondsSinceEpoch;
    case RecurringFrequency.monthly:
      final day = dayOfMonth ?? at.day;
      final monthStart = DateTime(at.year, at.month + step);
      final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
      return DateTime(
        monthStart.year,
        monthStart.month,
        day.clamp(1, lastDay),
        at.hour,
        at.minute,
      ).millisecondsSinceEpoch;
    case RecurringFrequency.yearly:
      final day = dayOfMonth ?? at.day;
      final lastDay = DateTime(at.year + step, at.month + 1, 0).day;
      return DateTime(
        at.year + step,
        at.month,
        day.clamp(1, lastDay),
        at.hour,
        at.minute,
      ).millisecondsSinceEpoch;
  }
}

/// The first due date strictly after [fromMs], starting from [dueMs].
///
/// The loop guard is not decoration: a rule with a corrupted interval would
/// otherwise hang the screen that draws it.
int nextDueAfter({
  required RecurringFrequency frequency,
  int interval = 1,
  int? dayOfMonth,
  required int dueMs,
  required int fromMs,
}) {
  var due = dueMs;
  var guard = 0;
  while (due <= fromMs && guard < 600) {
    due = advanceDueDate(
      frequency: frequency,
      interval: interval,
      dayOfMonth: dayOfMonth,
      dueMs: due,
    );
    guard++;
  }
  return due;
}

/// Every due date inside `[fromMs, toMs]` — the calendar strip.
List<int> duesBetween({
  required RecurringFrequency frequency,
  int interval = 1,
  int? dayOfMonth,
  required int dueMs,
  required int fromMs,
  required int toMs,
}) {
  final dues = <int>[];
  var due = nextDueAfter(
    frequency: frequency,
    interval: interval,
    dayOfMonth: dayOfMonth,
    dueMs: dueMs,
    fromMs: fromMs - 1,
  );
  var guard = 0;
  while (due <= toMs && guard < 600) {
    dues.add(due);
    due = advanceDueDate(
      frequency: frequency,
      interval: interval,
      dayOfMonth: dayOfMonth,
      dueMs: due,
    );
    guard++;
  }
  return dues;
}
