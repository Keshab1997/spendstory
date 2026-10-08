/// The bundled demo ledger.
///
/// Used by the web preview (`https://keshab1997.github.io/spendstory/`), where
/// there is no SQLite and therefore no bank SMS to read. It is **generated
/// deterministically** from a fixed seed, so the same build always shows the
/// same numbers — a preview that reshuffles itself on every refresh is
/// impossible to review.
///
/// Nothing here ever runs on a phone: `providers.dart` only reaches for it when
/// no database is available.
library;

import '../capture/rule_engine.dart';
import '../domain/models.dart';
import '../domain/recurring_math.dart';
import '../domain/view_models.dart';
import 'seed.dart';

/// A tiny linear congruential generator. Deterministic, no dependency, and
/// obviously not cryptography.
class _Rand {
  _Rand(this._state);

  int _state;

  int next(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7FFFFFFF;
    return _state % max;
  }

  int range(int min, int max) => min + next(max - min + 1);
}

class DemoLedger {
  DemoLedger({DateTime? now})
    : now =
          now ??
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            20,
          ) {
    _build();
  }

  final DateTime now;
  final List<TxnView> transactions = <TxnView>[];
  final Map<String, int> budgetCaps = <String, int>{};
  int? overallBudgetPaise;

  static const String accountCash = 'acc-cash';
  static const String accountHdfc = 'acc-hdfc';
  static const String accountSbi = 'acc-sbi';

  List<AccountView> get accounts => const <AccountView>[
    AccountView(
      id: accountCash,
      name: 'Cash',
      type: 'cash',
      last4: null,
      // A month's float: six months of chai, petrol and the odd restaurant
      // table adds up, and a demo that drifts negative teaches the wrong thing.
      openingBalancePaise: 1200000,
    ),
    AccountView(
      id: accountHdfc,
      name: 'HDFC Bank',
      type: 'bank',
      last4: '4521',
      openingBalancePaise: 4820000,
    ),
    AccountView(
      id: accountSbi,
      name: 'State Bank of India',
      type: 'bank',
      last4: '1234',
      openingBalancePaise: 1265000,
    ),
  ];

  List<CategoryView> get categories => <CategoryView>[
    for (final c in allSeedCategories)
      CategoryView(
        id: c.id,
        kind: TxnDirection.fromWire(c.kind) ?? TxnDirection.expense,
        nameEn: c.nameEn,
        nameHi: c.nameHi,
        nameBn: c.nameBn,
        icon: c.icon,
        colorHex: c.colorHex,
        monthlyCapPaise: budgetCaps[c.id],
      ),
  ];

  /// The caps as rows, with the same ids every reload — a budget detail route
  /// the user can reach from the preview has to stay reachable.
  List<BudgetView> get budgets => <BudgetView>[
    if (overallBudgetPaise != null)
      BudgetView(id: 'demo-budget-overall', amountPaise: overallBudgetPaise!),
    for (final entry in budgetCaps.entries)
      BudgetView(
        id: 'demo-budget-${entry.key}',
        categoryId: entry.key,
        amountPaise: entry.value,
      ),
  ];

  /// Three shapes the recurring screen has to handle: rent that is only
  /// reminded, an EMI that posts itself, and a subscription due later in the
  /// month. Their due dates are computed from today, so the preview is never
  /// showing a rent that was due two months ago.
  List<RecurringRuleView> get recurring => <RecurringRuleView>[
    RecurringRuleView(
      id: 'demo-recurring-rent',
      title: 'House rent',
      amountPaise: 1800000,
      categoryId: Cat.rent,
      accountId: 'acc-hdfc',
      dayOfMonth: 5,
      nextDueAt: _nextDueOn(5),
      remindDaysBefore: 1,
    ),
    RecurringRuleView(
      id: 'demo-recurring-emi',
      title: 'Home loan EMI',
      amountPaise: 2350000,
      categoryId: Cat.emi,
      accountId: 'acc-hdfc',
      dayOfMonth: 3,
      nextDueAt: _nextDueOn(3),
      autoPost: true,
      remindDaysBefore: 1,
    ),
    RecurringRuleView(
      id: 'demo-recurring-netflix',
      title: 'Netflix',
      amountPaise: 64900,
      categoryId: Cat.entertainment,
      accountId: 'acc-hdfc',
      dayOfMonth: 12,
      nextDueAt: _nextDueOn(12),
      remindDaysBefore: 0,
    ),
  ];

  /// The next time this day-of-month comes round, from today.
  int _nextDueOn(int day) => nextDueAfter(
    frequency: RecurringFrequency.monthly,
    dayOfMonth: day,
    dueMs: DateTime(now.year, now.month, day, 9).millisecondsSinceEpoch,
    fromMs: now.millisecondsSinceEpoch,
  );

  /// Categories that have a cap, for the budget screen.
  List<({CategoryView category, int spentPaise, int capPaise})> get budgeted {
    final summary = LedgerSummary.from(
      transactions,
      fromMs: startOfCurrentMonth,
    );
    final byId = {for (final c in categories) c.id: c};

    return budgetCaps.entries
        .where((e) => byId.containsKey(e.key))
        .map(
          (e) => (
            category: byId[e.key]!,
            spentPaise: summary.byCategory[e.key] ?? 0,
            capPaise: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.spentPaise.compareTo(a.spentPaise));
  }

  int get startOfCurrentMonth =>
      DateTime(now.year, now.month).millisecondsSinceEpoch;

  // ---------------------------------------------------------------------------
  // generation
  // ---------------------------------------------------------------------------

  void _build() {
    // A per-month seed keeps every month's shape stable across reloads while
    // still differing from its neighbours.
    for (var monthsAgo = 5; monthsAgo >= 0; monthsAgo--) {
      _buildMonth(monthsAgo);
    }

    overallBudgetPaise = 4000000; // ₹40,000
    budgetCaps
      ..[Cat.grocery] =
          800000 // ₹8,000
      ..[Cat.food] =
          500000 // ₹5,000
      ..[Cat.transport] =
          300000 // ₹3,000
      ..[Cat.bills] =
          200000 // ₹2,000 — the cap that usually sits near the 80% line
      ..[Cat.entertainment] = 150000; // ₹1,500
  }

  void _buildMonth(int monthsAgo) {
    final monthStart = DateTime(now.year, now.month - monthsAgo);
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final isCurrentMonth = monthsAgo == 0;
    final lastDay = isCurrentMonth ? now.day : daysInMonth;

    // Every month has the same skeleton — salary, rent, EMI, the streaming
    // subscriptions — plus a varying tail of everyday spending.
    final rnd = _Rand(0x5EED + monthsAgo * 7919);

    void add(
      int day,
      int amountPaise,
      String merchant,
      String categoryId, {
      TxnDirection direction = TxnDirection.expense,
      String? note,
      String? accountId,
    }) {
      if (day < 1 || day > lastDay) {
        return;
      }
      final mode = modeFor(merchant);
      transactions.add(
        TxnView(
          id: 'demo-${monthStart.year}-${monthStart.month}-${merchant.hashCode}-$day',
          amountPaise: amountPaise,
          direction: direction,
          occurredAtMs: DateTime(
            monthStart.year,
            monthStart.month,
            day,
            9 + (day % 10),
            (day * 7) % 60,
          ).millisecondsSinceEpoch,
          merchant: merchant,
          categoryId: categoryId,
          mode: mode,
          source: direction == TxnDirection.income ? 'auto_sms' : 'auto_sms',
          note: note,
          accountId: accountId ?? _accountFor(mode),
        ),
      );
    }

    add(
      1,
      4500000,
      'Salary',
      Cat.salary,
      direction: TxnDirection.income,
      note: 'বেতন',
    );

    if (monthsAgo == 0) {
      add(
        2,
        125000,
        'FD Interest',
        Cat.interest,
        direction: TxnDirection.income,
        note: 'এফডি সুদ',
        accountId: accountSbi,
      );
    }

    add(3, 1200000, 'House Rent', Cat.rent);

    final variable = <({int day, int amount, String merchant, String cat})>[
      (day: 2, amount: 124000, merchant: 'BigBasket', cat: Cat.grocery),
      (day: 4, amount: 45000, merchant: 'Blinkit', cat: Cat.grocery),
      (day: 5, amount: 38000, merchant: 'Swiggy', cat: Cat.food),
      (day: 6, amount: 18000, merchant: 'Uber', cat: Cat.transport),
      (day: 7, amount: 29900, merchant: 'Jio', cat: Cat.bills),
      (day: 8, amount: 24000, merchant: 'Zomato', cat: Cat.food),
      (day: 9, amount: 64000, merchant: 'Apollo', cat: Cat.health),
      (day: 10, amount: 14900, merchant: 'Netflix', cat: Cat.entertainment),
      (day: 11, amount: 4000, merchant: 'Metro', cat: Cat.transport),
      (day: 12, amount: 231000, merchant: 'DMart', cat: Cat.grocery),
      (day: 13, amount: 89000, merchant: 'Restaurant', cat: Cat.food),
      (day: 14, amount: 19900, merchant: 'Airtel', cat: Cat.bills),
      (day: 15, amount: 23900, merchant: 'Mobile Recharge', cat: Cat.recharge),
      (day: 16, amount: 50000, merchant: 'Petrol', cat: Cat.transport),
      (day: 17, amount: 149900, merchant: 'Myntra', cat: Cat.clothing),
      (day: 18, amount: 240000, merchant: 'Bajaj Finserv', cat: Cat.emi),
      (day: 19, amount: 30000, merchant: 'BookMyShow', cat: Cat.entertainment),
      (day: 20, amount: 118000, merchant: 'Electricity', cat: Cat.bills),
      (day: 21, amount: 6500, merchant: 'Rapido', cat: Cat.transport),
      (day: 22, amount: 32000, merchant: 'Sharma Provision', cat: Cat.grocery),
      (day: 23, amount: 4000, merchant: 'Chai Point', cat: Cat.food),
      (day: 24, amount: 44000, merchant: 'Zepto', cat: Cat.grocery),
      (day: 25, amount: 12000, merchant: 'Bus Fare', cat: Cat.transport),
      (day: 26, amount: 76000, merchant: 'Swiggy', cat: Cat.food),
    ];

    for (final item in variable) {
      // ±18% jitter, so the month has a texture rather than a fixed pattern.
      final jitter = rnd.range(82, 118) / 100;
      add(item.day, (item.amount * jitter).round(), item.merchant, item.cat);
    }

    if (monthsAgo > 0) {
      add(
        27,
        7500,
        'Cashback',
        Cat.otherIncome,
        direction: TxnDirection.income,
        accountId: accountSbi,
      );
    }

    transactions.sort((a, b) => b.occurredAtMs.compareTo(a.occurredAtMs));
  }

  /// Where the money moved. Cash is cash, everything else runs through the
  /// salary account — and the two income rows that are interest or cashback
  /// land in the savings account, which is exactly where those arrive.
  static String _accountFor(PaymentMode mode) =>
      mode == PaymentMode.cash ? accountCash : accountHdfc;

  static PaymentMode modeFor(String merchant) {
    const upiMerchants = <String>{
      'Swiggy',
      'Zomato',
      'BigBasket',
      'Blinkit',
      'Zepto',
      'Rapido',
      'Sharma Provision',
      'Chai Point',
      'Netflix',
      'Metro',
      'Bus Fare',
    };
    if (upiMerchants.contains(merchant)) return PaymentMode.upi;
    if (merchant == 'Salary' ||
        merchant == 'FD Interest' ||
        merchant == 'Cashback') {
      return PaymentMode.netbanking;
    }
    if (merchant == 'Petrol' || merchant == 'Restaurant') {
      return PaymentMode.cash;
    }
    return PaymentMode.card;
  }
}
