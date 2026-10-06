/// Core domain models for SpendStory.
///
/// Deliberately free of Flutter and Drift imports so the capture pipeline can be
/// unit-tested in plain Dart, fast, without a database or a device.
library;

/// Direction of money movement. `transfer` exists from day one so the schema and
/// the insights layer never have to be reshaped when transfers land in v1.1.
enum TxnDirection {
  expense('expense'),
  income('income'),
  transfer('transfer');

  const TxnDirection(this.wire);
  final String wire;

  static TxnDirection? fromWire(String? v) {
    if (v == null) return null;
    for (final d in TxnDirection.values) {
      if (d.wire == v) return d;
    }
    return null;
  }
}

/// How the money moved. Drives the icon on a row and the account default.
enum PaymentMode {
  cash('cash'),
  upi('upi'),
  card('card'),
  netbanking('netbanking'),
  wallet('wallet'),
  other('other');

  const PaymentMode(this.wire);
  final String wire;

  static PaymentMode fromWire(String? v) {
    if (v == null) return PaymentMode.other;
    for (final m in PaymentMode.values) {
      if (m.wire == v) return m;
    }
    return PaymentMode.other;
  }
}

/// Where a transaction came from. Shown to the user on the detail screen — the
/// "source traceability" feature that earns trust for an SMS-reading app.
enum TxSource {
  autoSms('auto_sms'),
  autoNotif('auto_notif'),
  manual('manual'),
  recurring('recurring');

  const TxSource(this.wire);
  final String wire;
}

/// A transaction as the capture pipeline produces it, before persistence.
///
/// Money is always an integer number of paise — never a double. See
/// `docs/05-DATA-MODEL.md` §1.
class ParsedTxn {
  const ParsedTxn({
    required this.amountPaise,
    required this.direction,
    required this.occurredAtMs,
    required this.source,
    required this.parserKey,
    this.merchant,
    this.accountLast4,
    this.mode = PaymentMode.other,
    this.senderId,
    this.sourceRef,
    this.rawText,
  });

  /// Always > 0. The sign lives in [direction].
  final int amountPaise;
  final TxnDirection direction;

  /// Transaction time (epoch ms) — from the SMS body when parseable, otherwise
  /// the SMS timestamp.
  final int occurredAtMs;

  final TxSource source;

  /// Which parser handled it, e.g. `hdfc`, `generic`. Diagnostic field.
  final String parserKey;

  final String? merchant;
  final String? accountLast4;
  final PaymentMode mode;

  /// Normalized sender id, e.g. `HDFCBK`.
  final String? senderId;

  /// Notification package name, when the source is a notification.
  final String? sourceRef;

  /// The original message body. Kept on-device only, shown in the detail
  /// screen's raw-message viewer, and never transmitted anywhere.
  final String? rawText;

  ParsedTxn copyWith({
    int? amountPaise,
    TxnDirection? direction,
    int? occurredAtMs,
    String? merchant,
    String? accountLast4,
    PaymentMode? mode,
    TxSource? source,
  }) => ParsedTxn(
    amountPaise: amountPaise ?? this.amountPaise,
    direction: direction ?? this.direction,
    occurredAtMs: occurredAtMs ?? this.occurredAtMs,
    source: source ?? this.source,
    parserKey: parserKey,
    merchant: merchant ?? this.merchant,
    accountLast4: accountLast4 ?? this.accountLast4,
    mode: mode ?? this.mode,
    senderId: senderId,
    sourceRef: sourceRef,
    rawText: rawText,
  );

  @override
  String toString() =>
      'ParsedTxn(${direction.name} $amountPaise paise'
      '${merchant != null ? ' · $merchant' : ''}'
      '${accountLast4 != null ? ' · …$accountLast4' : ''}'
      ' · ${mode.name} · $parserKey)';
}

/// Why a message was rejected. Surfaced in the local `parse_log` so the user can
/// report a bad parse without ever uploading a message.
enum ParseRejection {
  otp('otp'),
  unknownSender('unknown_sender'),
  noSignal('no_signal'),
  balanceOnly('balance_only'),
  nonTransaction('non_transaction'),
  noAmount('no_amount'),
  outOfRange('out_of_range');

  const ParseRejection(this.wire);
  final String wire;
}

/// Result of one parse attempt. Exactly one of [txn] / [rejection] is non-null.
class ParseOutcome {
  const ParseOutcome.parsed(this.txn) : rejection = null;
  const ParseOutcome.rejected(this.rejection) : txn = null;

  final ParsedTxn? txn;
  final ParseRejection? rejection;

  bool get isParsed => txn != null;
}

/// A user profile / account bucket. Balance is always computed, never stored.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.openingBalancePaise = 0,
    this.last4,
    this.colorHex,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String type; // bank | cash | wallet | card
  final int openingBalancePaise;
  final String? last4;
  final String? colorHex;
  final bool isDefault;
}

/// A spending/income category with its three localized names.
class Category {
  const Category({
    required this.id,
    required this.kind,
    required this.nameEn,
    required this.nameHi,
    required this.nameBn,
    required this.icon,
    required this.colorHex,
    this.monthlyCapPaise,
    this.isSystem = false,
  });

  final String id;
  final TxnDirection kind; // expense | income
  final String nameEn;
  final String nameHi;
  final String nameBn;
  final String icon;
  final String colorHex;
  final int? monthlyCapPaise;
  final bool isSystem;
}
