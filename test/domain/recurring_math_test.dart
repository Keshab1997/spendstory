/// Recurring-rule arithmetic (T-506, `docs/03 §S-19`).
///
/// Dates are where this stops being trivial, so the awkward ones are here on
/// purpose: the 31st in February, a leap-day rent in three ordinary years, and
/// an interval that a bad edit could have set to zero. Nothing in this file
/// reads a clock — the functions take the dates they work on.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/domain/recurring_math.dart';

int at(int y, int m, int d, [int h = 9]) =>
    DateTime(y, m, d, h).millisecondsSinceEpoch;

void main() {
  group('frequency wires', () {
    test('every frequency round-trips through its stored string', () {
      for (final frequency in RecurringFrequency.values) {
        expect(
          recurringFrequencyFrom(recurringFrequencyWire(frequency)),
          frequency,
        );
      }
    });

    test('an unknown or missing string is monthly, not a crash', () {
      // Rent and EMIs are what a rule almost always is, and a row written by a
      // future version must still open on this one.
      expect(recurringFrequencyFrom(null), RecurringFrequency.monthly);
      expect(recurringFrequencyFrom(''), RecurringFrequency.monthly);
      expect(recurringFrequencyFrom('fortnightly'), RecurringFrequency.monthly);
      expect(recurringFrequencyFrom('Weekly'), RecurringFrequency.monthly);
    });
  });

  group('the day a due date is compared in', () {
    test('dayStartMs floors to local midnight', () {
      final late = DateTime(2026, 10, 7, 23, 59).millisecondsSinceEpoch;
      final start = DateTime.fromMillisecondsSinceEpoch(dayStartMs(late));
      expect(start, DateTime(2026, 10, 7));
      expect(start.hour, 0);
    });

    test('daysBetweenDays counts whole days across a month end', () {
      expect(daysBetweenDays(at(2026, 10, 7, 1), at(2026, 10, 7, 23)), 0);
      expect(daysBetweenDays(at(2026, 10, 7), at(2026, 10, 8)), 1);
      expect(daysBetweenDays(at(2026, 10, 31), at(2026, 11, 3)), 3);
      expect(daysBetweenDays(at(2026, 12, 31), at(2027, 1, 1)), 1);
    });
  });

  group('advancing one cycle', () {
    test('daily and weekly move in whole days, many at a time if asked', () {
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.daily,
          dueMs: at(2026, 10, 7),
        ),
        at(2026, 10, 8),
      );
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.weekly,
          interval: 2,
          dueMs: at(2026, 10, 7),
        ),
        at(2026, 10, 21),
      );
    });

    test('quarterly is monthly with an interval', () {
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.monthly,
          interval: 3,
          dayOfMonth: 7,
          dueMs: at(2026, 10, 7),
        ),
        at(2027, 1, 7),
      );
    });

    test('rent on the 31st clamps to the short month and then comes back', () {
      final february = advanceDueDate(
        frequency: RecurringFrequency.monthly,
        dayOfMonth: 31,
        dueMs: at(2026, 1, 31),
      );
      expect(february, at(2026, 2, 28));

      // The anchor is the rule's own day, not the clamped one: March is the
      // 31st again, so the rent never drifts earlier and earlier.
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 31,
          dueMs: february,
        ),
        at(2026, 3, 31),
      );

      final april = advanceDueDate(
        frequency: RecurringFrequency.monthly,
        dayOfMonth: 31,
        dueMs: at(2026, 3, 31),
      );
      expect(april, at(2026, 4, 30));
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 31,
          dueMs: april,
        ),
        at(2026, 5, 31),
      );
    });

    test('a leap-day yearly rule lands on the 28th and returns in 2032', () {
      final ordinary = advanceDueDate(
        frequency: RecurringFrequency.yearly,
        dayOfMonth: 29,
        dueMs: at(2028, 2, 29),
      );
      expect(ordinary, at(2029, 2, 28));

      final back = advanceDueDate(
        frequency: RecurringFrequency.yearly,
        dayOfMonth: 29,
        dueMs: at(2031, 2, 28),
      );
      expect(back, at(2032, 2, 29)); // 2032 is a leap year
    });

    test('without a day of the month, the due date keeps its own day', () {
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.monthly,
          dueMs: at(2026, 2, 28),
        ),
        at(2026, 3, 28),
      );
    });

    test('an interval below one is one — a rule can never stall', () {
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.daily,
          interval: 0,
          dueMs: at(2026, 10, 7),
        ),
        at(2026, 10, 8),
      );
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.monthly,
          interval: -3,
          dayOfMonth: 5,
          dueMs: at(2026, 10, 5),
        ),
        at(2026, 11, 5),
      );
    });

    test('the time of day is carried, so a 9 am rule stays a 9 am rule', () {
      expect(
        advanceDueDate(
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 7,
          dueMs: at(2026, 10, 7, 9),
        ),
        at(2026, 11, 7, 9),
      );
    });
  });

  group('the next due date', () {
    test('is strictly after the day it is asked about', () {
      final due = at(2026, 10, 7);

      // Today is still owed — the next one is a month out.
      expect(
        nextDueAfter(
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 7,
          dueMs: due,
          fromMs: due,
        ),
        at(2026, 11, 7),
      );

      // One millisecond earlier, today is the next due date.
      expect(
        nextDueAfter(
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 7,
          dueMs: due,
          fromMs: due - 1,
        ),
        due,
      );
    });

    test('catches up a decade of skipped months without losing the anchor', () {
      expect(
        nextDueAfter(
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 5,
          dueMs: at(2016, 1, 5),
          fromMs: at(2026, 10, 8),
        ),
        at(2026, 11, 5),
      );
    });

    test('the shortest window that misses a due date finds nothing', () {
      expect(
        nextDueAfter(
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 5,
          dueMs: at(2026, 1, 5),
          fromMs: at(2026, 12, 6),
        ),
        at(2027, 1, 5),
      );
    });
  });

  group('the next thirty days', () {
    test('is inclusive at both ends', () {
      final dues = duesBetween(
        frequency: RecurringFrequency.monthly,
        dayOfMonth: 5,
        dueMs: at(2026, 1, 5),
        fromMs: at(2026, 10, 5),
        toMs: at(2026, 12, 5),
      );
      expect(dues, [at(2026, 10, 5), at(2026, 11, 5), at(2026, 12, 5)]);
    });

    test('carries the whole window when the rule started inside it', () {
      final dues = duesBetween(
        frequency: RecurringFrequency.monthly,
        dayOfMonth: 20,
        dueMs: at(2026, 10, 20), // first payment is later this month
        fromMs: at(2026, 10, 1),
        toMs: at(2027, 1, 31),
      );
      expect(dues, [
        at(2026, 10, 20),
        at(2026, 11, 20),
        at(2026, 12, 20),
        at(2027, 1, 20),
      ]);
    });

    test('a window with nothing in it is empty, not an error', () {
      expect(
        duesBetween(
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 5,
          dueMs: at(2026, 1, 5),
          fromMs: at(2026, 10, 6),
          toMs: at(2026, 11, 3),
        ),
        isEmpty,
      );
    });

    test('a daily rule fills the window and stops at the end of it', () {
      final dues = duesBetween(
        frequency: RecurringFrequency.daily,
        dueMs: at(2026, 10, 1),
        fromMs: at(2026, 10, 1),
        toMs: at(2026, 10, 30),
      );
      expect(dues, hasLength(30));
      expect(dues.first, at(2026, 10, 1));
      expect(dues.last, at(2026, 10, 30));
    });

    test(
      'a yearly rule inside a month-long window appears once, if at all',
      () {
        expect(
          duesBetween(
            frequency: RecurringFrequency.yearly,
            dayOfMonth: 12,
            dueMs: at(2022, 11, 12),
            fromMs: at(2026, 10, 8),
            toMs: at(2026, 11, 6),
          ),
          isEmpty,
        );
        expect(
          duesBetween(
            frequency: RecurringFrequency.yearly,
            dayOfMonth: 12,
            dueMs: at(2022, 11, 12),
            fromMs: at(2026, 10, 8),
            toMs: at(2026, 11, 30),
          ),
          [at(2026, 11, 12)],
        );
      },
    );
  });

  test('no reminder is spelled -1, and 0 means the due day itself', () {
    expect(kNoReminder, -1);
  });
}
