/// Drift table definitions — the eight tables of `docs/05-DATA-MODEL.md` §2.
///
/// Conventions that hold across every table:
///
/// * **Money is an integer number of paise.** Never a double, never a decimal
///   string. A ₹1,240.50 payment is stored as `124050`.
/// * **Soft delete.** Anything the user can remove carries a nullable
///   `deletedAt`; a hard `DELETE` only happens on the DPDP "erase everything"
///   path. Nothing is ever removed silently.
/// * **Timestamps are epoch milliseconds**, `occurredAt` being when the money
///   moved and `createdAt` when we heard about it. Those differ by seconds on
///   SMS capture and by days on a manual back-entry.
///
/// Data class names are pinned with `@DataClassName` so they never collide with
/// the hand-written domain models in `lib/domain/models.dart`.
library;

import 'package:drift/drift.dart';

/// Ledger. Indexed for the three queries the UI actually runs: the reverse
/// chronological list, the per-category roll-up and the per-account balance.
@DataClassName('TxnRow')
@TableIndex(name: 'idx_tx_occurred_at', columns: {#occurredAt})
@TableIndex(name: 'idx_tx_category', columns: {#categoryId})
@TableIndex(name: 'idx_tx_account', columns: {#accountId})
@TableIndex(name: 'idx_tx_source', columns: {#source})
class Transactions extends Table {
  /// uuid v4 — see `docs/05-DATA-MODEL.md` §2. Never reused, never renumbered.
  TextColumn get id => text()();

  /// Always > 0. The sign lives in [direction].
  IntColumn get amountPaise => integer()();

  TextColumn get direction => text().withLength(min: 1, max: 12)();

  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  TextColumn get mode => text().withDefault(const Constant('other'))();

  IntColumn get occurredAt => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  TextColumn get source => text()();

  /// Sender ID for SMS, package name for notifications. Shown in the detail
  /// screen as the trust-building "where did this come from" line.
  TextColumn get sourceRef => text().nullable()();

  /// The original message. On-device only, and cleared by the "delete raw
  /// messages" switch in Settings.
  TextColumn get rawText => text().nullable()();

  /// sha1(amount + direction + minute bucket + sender + account tail). UNIQUE:
  /// a redelivered SMS can never create a second row.
  TextColumn get dedupeHash => text().unique()();

  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User-editable categories. The 12 expense + 6 income rows are seeded on first
/// run with all three languages already filled in.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();

  /// `expense` | `income`
  TextColumn get kind => text()();

  TextColumn get nameEn => text()();
  TextColumn get nameHi => text()();
  TextColumn get nameBn => text()();

  /// Emoji for now; a code point once the icon set lands.
  TextColumn get icon => text()();

  /// `#RRGGBB`
  TextColumn get colorHex => text()();

  /// Optional per-category budget cap. Null = no cap.
  IntColumn get monthlyCapPaise => integer().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// System rows cannot be deleted — only hidden.
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Bank / cash / wallet / card buckets.
///
/// The balance is **never stored** — it is recomputed from [openingBalancePaise]
/// plus every non-deleted transaction, so a soft-deleted or edited row can never
/// leave a stale number behind.
@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// `bank` | `cash` | `wallet` | `card`
  TextColumn get type => text()();

  IntColumn get openingBalancePaise =>
      integer().withDefault(const Constant(0))();

  TextColumn get last4 => text().nullable()();

  TextColumn get colorHex => text().nullable()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Spending caps. `categoryId == null` is the overall monthly budget.
@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// `monthly` | `weekly` | `custom`
  TextColumn get period => text().withDefault(const Constant('monthly'))();

  IntColumn get amountPaise => integer()();

  /// 1–28, so a salary-day cycle (say the 7th) still works in February.
  IntColumn get startDay => integer().withDefault(const Constant(1))();

  BoolColumn get alertAt80 => boolean().withDefault(const Constant(true))();
  BoolColumn get alertAt100 => boolean().withDefault(const Constant(true))();

  /// Only meaningful for `custom`.
  IntColumn get startsOn => integer().nullable()();
  IntColumn get endsOn => integer().nullable()();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recurring payments — schema present from v1 so rent/EMI can ship in v1.1
/// without a migration.
@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  TextColumn get id => text()();

  TextColumn get title => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get direction => text()();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// `daily` | `weekly` | `monthly` | `yearly`
  TextColumn get frequency => text()();

  IntColumn get interval => integer().withDefault(const Constant(1))();

  IntColumn get dayOfMonth => integer().nullable()();
  IntColumn get nextDueAt => integer()();

  BoolColumn get autoPost => boolean().withDefault(const Constant(false))();
  IntColumn get remindDaysBefore => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The auto-categorisation brain. Seeded from `RuleEngine.defaultRules`;
/// `isUserDefined` rows always win over the built-ins.
@DataClassName('MerchantRuleRow')
@TableIndex(name: 'idx_rule_pattern', columns: {#pattern})
class MerchantRules extends Table {
  TextColumn get id => text()();

  /// Lowercase match token, e.g. `bigbasket`, `swiggy`.
  TextColumn get pattern => text()();

  TextColumn get categoryId => text().references(Categories, #id)();

  /// How many times this rule has matched and been accepted.
  IntColumn get hits => integer().withDefault(const Constant(0))();

  /// 1.0 when the user set the rule by hand.
  RealColumn get confidence => real().withDefault(const Constant(0.6))();

  BoolColumn get isUserDefined =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Versioned sender allowlist. `addedInRuleVersion` lets a rule-version bump
/// re-seed only what is new instead of wiping the user's own edits.
@DataClassName('SmsSenderRow')
class SmsSenders extends Table {
  TextColumn get id => text()();

  /// Normalized form, e.g. `HDFCBK` (the carrier prefix is stripped before it
  /// ever reaches this table).
  TextColumn get senderId => text()();

  TextColumn get bankName => text()();
  TextColumn get parserKey => text()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  IntColumn get addedInRuleVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local-only capture diagnostics. Powers Settings → "কিছু ভুল হয়েছে?".
/// Never uploaded — the user exports it by hand if they want to report a parse.
@DataClassName('ParseLogRow')
@TableIndex(name: 'idx_log_created', columns: {#createdAt})
class ParseLog extends Table {
  TextColumn get id => text()();

  TextColumn get senderId => text().nullable()();

  BoolColumn get matched => boolean()();

  TextColumn get parserKey => text().nullable()();

  /// `otp` | `unknown_sender` | `no_signal` | `balance_only` |
  /// `non_transaction` | `no_amount` | `out_of_range`
  TextColumn get failureReason => text().nullable()();

  /// Never stores the message body — only the reason. The body stays where it
  /// came from.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key–value settings: onboarded, locale, theme, permission flags, pro status,
/// ruleVersion, sessionCount.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
