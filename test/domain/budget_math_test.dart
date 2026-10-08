/// Budget arithmetic (T-501).
///
/// This file exists because the calendar is the part of a budget that is easy
/// to get subtly wrong and impossible to notice: a salary-day cycle that wraps
/// into the previous month, February when the cycle day is 28, the last day of
/// a cycle where "per day" would divide by zero. The screen can be reviewed by
/// eye; these cannot.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/domain/budget_math.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';

int _ms(int year, int month, int day, [int hour = 12]) =>
    DateTime(year, month, day, hour).millisecondsSinceEpoch;

TxnView _txn({
  required int paise,
  required int day,
  String? categoryId,
  TxnDirection direction = TxnDirection.expense,
}) => TxnView(
  id: 'txn-$day-$paise-$categoryId',
  amountPaise: paise,
  direction: direction,
  occurredAtMs: _ms(2026, 10, day),
  categoryId: categoryId,
);

void main() {
  group('the monthly cycle', () {
    test('startDay 1 is the calendar month', () {
      final cycle = budgetCycle(nowMs: _ms(2026, 10, 7));

      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.startMs),
        DateTime(2026, 10, 1),
      );
      expect(cycle.totalDays, 31);
      expect(cycle.elapsedDays, 7);
      expect(cycle.daysLeft, 24);
    });

    test('a salary-day cycle starts on that day, not on the 1st', () {
      final cycle = budgetCycle(nowMs: _ms(2026, 10, 7), startDay: 7);

      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.startMs),
        DateTime(2026, 10, 7),
      );
      expect(cycle.elapsedDays, 1, reason: 'day one of the cycle is today');
      expect(cycle.totalDays, 31, reason: '7 Oct → 6 Nov inclusive');
    });

    test('a cycle that has not started yet this month belongs to last month', () {
      final cycle = budgetCycle(nowMs: _ms(2026, 10, 3), startDay: 7);

      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.startMs),
        DateTime(2026, 9, 7),
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.endMs),
        DateTime(2026, 10, 6, 23, 59, 59, 999),
      );
      expect(cycle.daysLeft, 3);
    });

    test('the cycle wraps the year without arithmetic rolling over', () {
      final cycle = budgetCycle(nowMs: _ms(2026, 1, 3), startDay: 25);

      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.startMs),
        DateTime(2025, 12, 25),
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.endMs),
        DateTime(2026, 1, 24, 23, 59, 59, 999),
      );
    });

    test('February keeps a 28th start day', () {
      final cycle = budgetCycle(nowMs: _ms(2026, 2, 28), startDay: 28);

      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.startMs),
        DateTime(2026, 2, 28),
      );
      expect(cycle.totalDays, 28, reason: '28 Feb → 27 Mar inclusive');
    });

    test('a start day above 28 is clamped rather than trusted', () {
      // 31 clamps to 28 before any date maths happens, so on 27 February the
      // cycle is the one that began on 28 January — not a month with a 31st.
      final cycle = budgetCycle(nowMs: _ms(2026, 2, 27), startDay: 31);

      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.startMs),
        DateTime(2026, 1, 28),
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.endMs),
        DateTime(2026, 2, 27, 23, 59, 59, 999),
      );
    });

    test('a weekly cycle runs Monday to Sunday', () {
      // 7 Oct 2026 is a Wednesday.
      final cycle = budgetCycle(nowMs: _ms(2026, 10, 7), period: 'weekly');

      expect(
        DateTime.fromMillisecondsSinceEpoch(cycle.startMs),
        DateTime(2026, 10, 5),
      );
      expect(cycle.totalDays, 7);
      expect(cycle.elapsedDays, 3);
    });

    test('a custom window is used as given', () {
      final cycle = budgetCycle(
        nowMs: _ms(2026, 10, 7),
        period: 'custom',
        startsOn: _ms(2026, 9, 15),
        endsOn: _ms(2026, 10, 14),
      );

      expect(cycle.totalDays, 30);
      expect(cycle.elapsedDays, 23);
    });
  });

  group('spending inside the cycle', () {
    final txns = <TxnView>[
      _txn(paise: 100000, day: 2, categoryId: 'food'),
      _txn(paise: 50000, day: 8, categoryId: 'food'),
      _txn(paise: 200000, day: 5, categoryId: 'grocery'),
      _txn(paise: 900000, day: 3, direction: TxnDirection.income),
      _txn(paise: 30000, day: 9, categoryId: 'food'),
    ];

    test('a category budget counts only its own rows', () {
      const budget = BudgetView(
        id: 'b',
        categoryId: 'food',
        amountPaise: 500000,
      );
      final status = budgetStatus(
        txns: txns,
        budget: budget,
        nowMs: _ms(2026, 10, 7),
      );

      // The whole cycle is counted, not the part already lived: a captured row
      // dated later this month is still this month's spending.
      expect(status.spentPaise, 180000);
    });

    test('an overall budget counts every expense and no income', () {
      const budget = BudgetView(id: 'b', amountPaise: 500000);
      final status = budgetStatus(txns: txns, budget: budget, nowMs: _ms(2026, 10, 7));

      expect(status.spentPaise, 380000, reason: '₹38,000, income ignored');
    });

    test('rows outside the cycle are not counted', () {
      const budget = BudgetView(
        id: 'b',
        categoryId: 'food',
        amountPaise: 500000,
        startDay: 5,
      );
      final status = budgetStatus(txns: txns, budget: budget, nowMs: _ms(2026, 10, 7));

      expect(
        status.spentPaise,
        80000,
        reason: 'the ₹1,000 row on day 2 falls before the cycle starts',
      );
    });
  });

  group('the status', () {
    const budget = BudgetView(id: 'b', categoryId: 'food', amountPaise: 100000);

    BudgetStatus statusAt(int spent, {int day = 7}) => budgetStatus(
      txns: <TxnView>[
        TxnView(
          id: 's',
          amountPaise: spent,
          direction: TxnDirection.expense,
          occurredAtMs: _ms(2026, 10, 1),
          categoryId: 'food',
        ),
      ],
      budget: budget,
      nowMs: _ms(2026, 10, day),
    );

    test('the ratio is not clamped — 107% has to read 107%', () {
      expect(statusAt(107000).ratio, closeTo(1.07, 0.0001));
    });

    test('the thresholds fire at exactly 80, 100 and 120', () {
      expect(statusAt(79999).at80, isFalse);
      expect(statusAt(80000).at80, isTrue);
      expect(statusAt(100000).at100, isTrue);
      expect(statusAt(119999).at120, isFalse);
      expect(statusAt(120000).at120, isTrue);
    });

    test('the daily allowance spreads what is left over the days left', () {
      // ₹1,000 cap, ₹250 spent on 7 Oct → ₹750 over 24 days (8th–31st).
      final status = statusAt(25000);
      expect(status.cycle.daysLeft, 24);
      expect(status.dailyAllowancePaise, 3125);
    });

    test('there is no allowance once the money is gone', () {
      expect(statusAt(100000).dailyAllowancePaise, isNull);
      expect(statusAt(150000).dailyAllowancePaise, isNull);
    });

    test('the last day of a cycle yields no allowance rather than a divide', () {
      // 31 October: 24 days elapsed of a 31-day month, 7 left — then a custom
      // window ending today, where daysLeft is 0.
      const lastDay = BudgetView(
        id: 'b',
        categoryId: 'food',
        amountPaise: 100000,
        period: 'custom',
        startsOn: null,
        endsOn: null,
      );
      final status = budgetStatus(
        txns: const <TxnView>[],
        budget: lastDay,
        nowMs: _ms(2026, 10, 31),
      );
      // A custom budget without a window degrades to the monthly one.
      expect(status.cycle.daysLeft, 0);
      expect(status.dailyAllowancePaise, isNull);
    });
  });

  group('the list order', () {
    test('most-used first, ties by the bigger cap, then by id', () {
      final ranked = rankedBudgetStatus(
        txns: <TxnView>[
          _txn(paise: 100000, day: 2, categoryId: 'food'),
          _txn(paise: 90000, day: 2, categoryId: 'grocery'),
        ],
        budgets: const <BudgetView>[
          BudgetView(id: 'a-food', categoryId: 'food', amountPaise: 100000),
          BudgetView(id: 'b-grocery', categoryId: 'grocery', amountPaise: 90000),
          BudgetView(id: 'c-transport', categoryId: 'transport', amountPaise: 50000),
          BudgetView(id: 'd-fun', categoryId: 'fun', amountPaise: 90000),
        ],
        nowMs: _ms(2026, 10, 7),
      );

      // 100% → 100% (tie on ratio, so the bigger cap wins) → 90% → 0%.
      expect(
        ranked.map((s) => s.budget.id).toList(),
        <String>['a-food', 'b-grocery', 'd-fun', 'c-transport'],
      );
    });
  });
}
