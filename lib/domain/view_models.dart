/// UI-facing view models.
///
/// The widgets never touch Drift rows or `ParsedTxn` directly. They read these,
/// which means the same screen renders identically whether the data came from
/// the on-device database (mobile) or the bundled demo ledger (the web preview,
/// until a web database is wired up).
library;

import 'recurring_math.dart';

import 'dart:ui' show Color;

import '../capture/rule_engine.dart';
import '../data/db.dart';
import '../ui/strings.dart';
import 'models.dart';

/// One row of the ledger, as the UI needs it.
class TxnView {
  const TxnView({
    required this.id,
    required this.amountPaise,
    required this.direction,
    required this.occurredAtMs,
    this.merchant,
    this.categoryId,
    this.mode = PaymentMode.other,
    this.source = 'manual',
    this.note,
    this.rawText,
    this.accountId,
  });

  final String id;
  final int amountPaise;
  final TxnDirection direction;
  final int occurredAtMs;
  final String? merchant;
  final String? categoryId;
  final PaymentMode mode;
  final String source;
  final String? note;
  final String? rawText;

  /// Which account the money moved through, when known. Shown on the detail
  /// screen; null for a cash entry the user typed without picking one.
  final String? accountId;

  factory TxnView.fromRow(TxnRow row) => TxnView(
    id: row.id,
    amountPaise: row.amountPaise,
    direction: TxnDirection.fromWire(row.direction) ?? TxnDirection.expense,
    occurredAtMs: row.occurredAt,
    merchant: row.merchant,
    categoryId: row.categoryId,
    mode: PaymentMode.fromWire(row.mode),
    source: row.source,
    note: row.note,
    rawText: row.rawText,
    accountId: row.accountId,
  );

  bool get isIncome => direction == TxnDirection.income;

  /// Only the fields the UI is allowed to change without going through the
  /// capture pipeline. Used by the session overlay that backs a re-categorise
  /// in the web preview, where there is no database to write to.
  TxnView copyWith({String? categoryId, String? merchant, String? note}) =>
      TxnView(
        id: id,
        amountPaise: amountPaise,
        direction: direction,
        occurredAtMs: occurredAtMs,
        merchant: merchant ?? this.merchant,
        categoryId: categoryId ?? this.categoryId,
        mode: mode,
        source: source,
        note: note ?? this.note,
        rawText: rawText,
        accountId: accountId,
      );

  /// Where the row came from, in words the user understands. Shown on the detail
  /// screen — the trust-building "this is not a mystery number" line.
  String sourceLabel([String locale = 'bn']) =>
      SsStrings(locale)[switch (source) {
        'auto_sms' => 'sourceAutoSms',
        'auto_notif' => 'sourceAutoNotification',
        'recurring' => 'sourceRecurring',
        _ => 'sourceManual',
      }];
}

/// A category with its three localized names already resolved.
class CategoryView {
  const CategoryView({
    required this.id,
    required this.kind,
    required this.nameEn,
    required this.nameHi,
    required this.nameBn,
    required this.icon,
    required this.colorHex,
    this.monthlyCapPaise,
  });

  final String id;
  final TxnDirection kind;
  final String nameEn;
  final String nameHi;
  final String nameBn;
  final String icon;
  final String colorHex;
  final int? monthlyCapPaise;

  /// The display name for the active language code (`en` | `hi` | `bn`).
  String label([String locale = 'bn']) => switch (locale) {
    'en' => nameEn,
    'hi' => nameHi,
    _ => nameBn,
  };

  Color get color => colorFromHex(colorHex);

  factory CategoryView.fromRow(CategoryRow row) => CategoryView(
    id: row.id,
    kind: TxnDirection.fromWire(row.kind) ?? TxnDirection.expense,
    nameEn: row.nameEn,
    nameHi: row.nameHi,
    nameBn: row.nameBn,
    icon: row.icon,
    colorHex: row.colorHex,
    monthlyCapPaise: row.monthlyCapPaise,
  );
}

/// `#RRGGBB` → a `Color`, without importing Flutter into the domain layer's
/// callers. Kept here because view models are already UI-facing.
Color colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '').trim();
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return const Color(0xFF6C4CF1);
  return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
}

/// Money in and out for a period, plus the budget it is measured against.
class PeriodTotals {
  const PeriodTotals({
    required this.incomePaise,
    required this.expensePaise,
    this.budgetPaise,
  });

  final int incomePaise;
  final int expensePaise;
  final int? budgetPaise;

  int get netPaise => incomePaise - expensePaise;

  double get spentRatio => budgetPaise == null || budgetPaise == 0
      ? 0
      : (expensePaise / budgetPaise!).clamp(0.0, 2.0);

  /// The forecast for the end of the period, at the current daily burn rate.
  /// Null when there is not enough of the period elapsed to be meaningful.
  int? forecastExpense({required int elapsedDays, required int totalDays}) {
    if (elapsedDays < 3 || totalDays <= 0) return null;
    final perDay = expensePaise / elapsedDays;
    return (perDay * totalDays).round();
  }
}

/// Aggregates a list of transactions for the home hero card and Insights.
class LedgerSummary {
  const LedgerSummary({
    required this.incomePaise,
    required this.expensePaise,
    required this.byCategory,
    required this.count,
  });

  final int incomePaise;
  final int expensePaise;

  /// categoryId → total expense paise, largest first when iterated.
  final Map<String, int> byCategory;

  final int count;

  int get netPaise => incomePaise - expensePaise;

  static LedgerSummary from(List<TxnView> txns, {int? fromMs, int? toMs}) {
    var income = 0;
    var expense = 0;
    var count = 0;
    final byCategory = <String, int>{};

    for (final t in txns) {
      if (fromMs != null && t.occurredAtMs < fromMs) continue;
      if (toMs != null && t.occurredAtMs > toMs) continue;
      count++;
      if (t.direction == TxnDirection.income) {
        income += t.amountPaise;
      } else {
        expense += t.amountPaise;
        if (t.categoryId != null) {
          byCategory[t.categoryId!] =
              (byCategory[t.categoryId!] ?? 0) + t.amountPaise;
        }
      }
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LedgerSummary(
      incomePaise: income,
      expensePaise: expense,
      byCategory: Map.fromEntries(sorted),
      count: count,
    );
  }
}

/// A bank / cash / wallet account, as the UI needs it.
///
/// The Drift `AccountRow` cannot exist without a database, and the accounts
/// screen has to render in demo mode too, so the UI reads this instead.
class AccountView {
  const AccountView({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalancePaise,
    this.last4,
    this.colorHex,
  });

  final String id;
  final String name;
  final String type; // bank | cash | wallet | card
  final int openingBalancePaise;
  final String? last4;

  /// Optional per-account tint, set by the user in the account editor.
  final String? colorHex;

  String get label => last4 == null ? name : '$name ••$last4';
}

/// A spending cap, as the UI needs it.
///
/// `categoryId == null` is the overall monthly budget — one per ledger, which
/// is why the whole-app cap and the per-category caps can live in one list and
/// one screen (`docs/05-DATA-MODEL.md`, `budgets` table).
class BudgetView {
  const BudgetView({
    required this.id,
    this.categoryId,
    required this.amountPaise,
    this.period = 'monthly',
    this.startDay = 1,
    this.alertAt80 = true,
    this.alertAt100 = true,
    this.startsOn,
    this.endsOn,
  });

  final String id;

  /// Null = the overall budget.
  final String? categoryId;

  final int amountPaise;

  /// `monthly` | `weekly` | `custom`.
  final String period;

  /// 1–28: the day the cycle starts, for a salary-day budget.
  final int startDay;

  final bool alertAt80;
  final bool alertAt100;

  /// Only meaningful for `period: 'custom'`.
  final int? startsOn;
  final int? endsOn;

  bool get isOverall => categoryId == null;

  BudgetView copyWith({
    String? categoryId,
    bool clearCategory = false,
    int? amountPaise,
    String? period,
    int? startDay,
    bool? alertAt80,
    bool? alertAt100,
  }) => BudgetView(
    id: id,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    amountPaise: amountPaise ?? this.amountPaise,
    period: period ?? this.period,
    startDay: startDay ?? this.startDay,
    alertAt80: alertAt80 ?? this.alertAt80,
    alertAt100: alertAt100 ?? this.alertAt100,
    startsOn: startsOn,
    endsOn: endsOn,
  );

  factory BudgetView.fromRow(BudgetRow row) => BudgetView(
    id: row.id,
    categoryId: row.categoryId,
    amountPaise: row.amountPaise,
    period: row.period,
    startDay: row.startDay,
    alertAt80: row.alertAt80,
    alertAt100: row.alertAt100,
    startsOn: row.startsOn,
    endsOn: row.endsOn,
  );
}

/// One recurring rule — rent, an EMI, a subscription (S-19, T-506).
///
/// `nextDueAt` is stored, not derived on every read: it is the one field that
/// changes as the rule is acted on (posting advances it), and re-deriving it
/// from `dayOfMonth` would forget that February clamped a 31st.
class RecurringRuleView {
  const RecurringRuleView({
    required this.id,
    required this.title,
    required this.amountPaise,
    this.direction = TxnDirection.expense,
    this.categoryId,
    this.accountId,
    this.frequency = 'monthly',
    this.interval = 1,
    this.dayOfMonth,
    required this.nextDueAt,
    this.autoPost = false,
    this.remindDaysBefore = 1,
  });

  final String id;
  final String title;
  final int amountPaise;
  final TxnDirection direction;
  final String? categoryId;
  final String? accountId;

  /// `daily` | `weekly` | `monthly` | `yearly`.
  final String frequency;

  /// Every N days/weeks/months/years. 1 for most rules.
  final int interval;

  /// 1–31, for monthly and yearly rules. See `advanceDueDate`: a 31st clamps
  /// to the last day of a shorter month rather than rolling into the next one.
  final int? dayOfMonth;

  final int nextDueAt;

  /// When on, the due payment is written into the ledger by itself.
  final bool autoPost;

  /// `-1` = no reminder; otherwise days before the due date, `0` = that day.
  final int remindDaysBefore;

  bool get reminds => remindDaysBefore >= 0;

  RecurringFrequency get frequencyEnum => recurringFrequencyFrom(frequency);

  RecurringRuleView copyWith({
    String? title,
    int? amountPaise,
    TxnDirection? direction,
    String? categoryId,
    bool clearCategory = false,
    String? accountId,
    bool clearAccount = false,
    String? frequency,
    int? interval,
    int? dayOfMonth,
    bool clearDayOfMonth = false,
    int? nextDueAt,
    bool? autoPost,
    int? remindDaysBefore,
  }) => RecurringRuleView(
    id: id,
    title: title ?? this.title,
    amountPaise: amountPaise ?? this.amountPaise,
    direction: direction ?? this.direction,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    accountId: clearAccount ? null : (accountId ?? this.accountId),
    frequency: frequency ?? this.frequency,
    interval: interval ?? this.interval,
    dayOfMonth: clearDayOfMonth ? null : (dayOfMonth ?? this.dayOfMonth),
    nextDueAt: nextDueAt ?? this.nextDueAt,
    autoPost: autoPost ?? this.autoPost,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
  );

  factory RecurringRuleView.fromRow(RecurringRuleRow row) => RecurringRuleView(
    id: row.id,
    title: row.title,
    amountPaise: row.amountPaise,
    direction: TxnDirection.fromWire(row.direction) ?? TxnDirection.expense,
    categoryId: row.categoryId,
    accountId: row.accountId,
    frequency: row.frequency,
    interval: row.interval,
    dayOfMonth: row.dayOfMonth,
    nextDueAt: row.nextDueAt,
    autoPost: row.autoPost,
    remindDaysBefore: row.remindDaysBefore,
  );
}

/// The category ids the rule engine can emit, in the order they should be
/// offered to the user when asking "which category was this?".
const List<String> kCategoryPickerOrder = <String>[
  Cat.food,
  Cat.grocery,
  Cat.transport,
  Cat.bills,
  Cat.rent,
  Cat.health,
  Cat.education,
  Cat.clothing,
  Cat.entertainment,
  Cat.recharge,
  Cat.emi,
  Cat.otherExpense,
  Cat.salary,
  Cat.business,
  Cat.freelance,
  Cat.interest,
  Cat.gift,
  Cat.otherIncome,
];
