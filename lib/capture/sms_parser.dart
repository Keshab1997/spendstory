/// The SMS parser — steps ③ → ⑤ of the capture pipeline.
///
/// Pure Dart on purpose: no Flutter, no database, no plugin. That means the
/// whole rule set can be exercised by `flutter test` in milliseconds, and the
/// accuracy gates in `docs/06-SMS-PARSING.md` §10 are cheap to run on every
/// change.
library;

import '../domain/models.dart';
import 'merchant_normalizer.dart';
import 'otp_guard.dart';
import 'sender_allowlist.dart';

/// **Strong debit verbs** — a message must contain one of these to be
/// considered a completed spend. Nouns like "cashback", "offer" or "loan" are
/// deliberately absent: they appear constantly in marketing copy that mentions
/// money without moving any, and `docs/06-SMS-PARSING.md` §10 requires zero
/// false transactions from those.
const List<String> _debitSignals = <String>[
  r'\bdebit(ed)?\b',
  r'\bwithdraw(n|al)?\b',
  r'\bspent\b',
  r'\bpaid\b',
  r'\bpurchas',
  r'\bsent\b',
  r'\btransfer(red)?\b',
  r'\btrf\b',
  r'\btfr\b',
  r'\bdr\.',
  // Hindi / Bengali
  r'खर्च',
  r'काटा',
  r'भुगतान',
  r'डेबिट',
  r'ডেবিট',
  r'কাটা',
  r'পরিশোধ',
];

/// **Strong credit verbs**, same reasoning.
const List<String> _creditSignals = <String>[
  r'\bcredited?\b',
  r'\bdeposit',
  r'\breceiv',
  r'\brefund',
  r'\brevers',
  r'\bcr\.',
  r'जमा',
  r'प्राप्त',
  r'क्रेडिट',
  r'জমা',
  r'পেয়েছি',
  r'ক্রেডিট',
];

/// Markers that mean "everything after this is a balance, not a transaction".
const List<String> _balanceMarkers = <String>[
  'avl bal',
  'avl. bal',
  'avail bal',
  'available balance',
  'available bal',
  'a/c bal',
  'ac bal',
  'closing balance',
  'balance is',
  'bal is',
  'bal:',
  'balance:',
  'bal rs',
  'bal inr',
  'bal ₹',
  // card alerts quote the remaining limit instead of a balance
  'avl limit',
  'avail limit',
  'available limit',
  'avl lmt',
  'credit limit',
  'credit balance',
  'available credit',
];

/// The words "credit card" / "debit card" name a *product*, not a direction.
/// Neutralising them before signal detection is what keeps
/// "Your ICICI Bank Credit Card XX9012 has been debited with Rs 2,499" on the
/// expense side — otherwise the word "Credit" would win on position alone.
/// See `docs/06-SMS-PARSING.md` §4.
final RegExp _cardPhraseRe = RegExp(
  r'(?:credit|debit)\s*(?:card|crd)|(?:cr|db)\s*card',
  caseSensitive: false,
);

/// Marketing / informational SMS that mention money words but are not
/// transactions.
const List<String> _nonTxMarkers = <String>[
  'offer',
  'discount',
  'cashback offer',
  'apply now',
  'apply for',
  'loan offer',
  'pre-approved',
  'preapproved',
  'insurance',
  'missed call',
  'bill due',
  'statement',
  'e-mandate',
  'kyc',
  'upgrade to',
  'click here',
  't&c apply',
  'terms apply',
];

/// Future-tense notices ("Rs 999 will be debited on 15-10-26") announce a
/// payment that has *not happened yet*. Parsing them as a completed expense
/// would double-count when the real debit SMS arrives.
const List<String> _futureTenseMarkers = <String>[
  'will be debited',
  'will be credited',
  'will be deducted',
  'is scheduled',
  'scheduled for',
  'due on',
  'upcoming',
  'please ensure sufficient',
  'maintain sufficient',
];

/// A ₹ / Rs / INR / ৳ amount with Indian lakh grouping (`1,24,000`) or plain
/// digits. Bengali and Devanagari digits are normalized before matching.
final RegExp _amountRe = RegExp(
  r'(?:₹|৳|rs\.?|inr|rupees?|টাকা|রুপি|रुपये|रु)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
  caseSensitive: false,
);

/// VPA-style handle: `bigbasket@ybl`, `ramesh.kumar@okhdfcbank`.
final RegExp _vpaRe = RegExp(
  r'([a-z0-9][a-z0-9._\-]{2,})\s*@\s*'
  r'(okhdfcbank|okicici|okaxis|oksbi|ybl|paytm|upi|apl|ibl|axl|airtel|jio|fbl|hdfcbank|icici|sbi|kotak|yesbank)',
  caseSensitive: false,
);

/// The words that introduce a merchant: `to BigBasket on`, `at DMart,`,
/// `towards House Rent`, `from Amazon Refund`.
final RegExp _merchantKeywordRe = RegExp(
  r'\b(?:at|to|towards|for|from)\s+',
  caseSensitive: false,
);

/// How far past a keyword a merchant name may run.
const int _merchantMaxChars = 40;

final RegExp _dateDmyRe = RegExp(r'(\d{1,2})[-\/](\d{1,2})[-\/](\d{2,4})');
final RegExp _dateDmmmyRe = RegExp(
  r'(\d{1,2})[-\/\s]([A-Za-z]{3,9})[-\/\s](\d{2,4})',
);
final RegExp _dateDdMmmYyRe = RegExp(r'(\d{1,2})([A-Za-z]{3})(\d{2,4})');

const Map<String, int> _months = <String, int>{
  'jan': 1,
  'january': 1,
  'feb': 2,
  'february': 2,
  'mar': 3,
  'march': 3,
  'apr': 4,
  'april': 4,
  'may': 5,
  'jun': 6,
  'june': 6,
  'jul': 7,
  'july': 7,
  'aug': 8,
  'august': 8,
  'sep': 9,
  'sept': 9,
  'september': 9,
  'oct': 10,
  'october': 10,
  'nov': 11,
  'november': 11,
  'dec': 12,
  'december': 12,
};

/// Phrases after which a captured merchant name should stop.
const List<String> _merchantStops = <String>[
  ' on ',
  ' from ',
  ' ref ',
  ' via ',
  ' using ',
  ' towards ',
  ' at ',
  ' to ',
  ' a/c',
  ' upi',
  ' UPI',
  ' neft',
  ' imps',
  ' rtgs',
  ' (',
  ',',
  '.',
  ';',
];

/// Bengali (০-৯) and Devanagari (०-९) digits → ASCII, so the rest of the
/// pipeline only ever deals with one numeral system.
String normalizeDigits(String input) {
  const bn = '০১২৩৪৫৬৭৮৯';
  const hi = '०१२३४५६७८९';
  final buf = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final bi = bn.indexOf(ch);
    if (bi >= 0) {
      buf.write(bi);
      continue;
    }
    final hiIdx = hi.indexOf(ch);
    if (hiIdx >= 0) {
      buf.write(hiIdx);
      continue;
    }
    buf.write(ch);
  }
  return buf.toString();
}

/// Parses a bank SMS into a [ParsedTxn], or explains why it did not.
class SmsParser {
  SmsParser({SenderAllowlist? allowlist})
    : allowlist = allowlist ?? SenderAllowlist();

  final SenderAllowlist allowlist;

  /// [sender] is the raw sender ID (`VM-HDFCBK`).
  /// [smsTimestampMs] is the receiver timestamp, used when the body has no date.
  ParseOutcome parseSms({
    required String sender,
    required String body,
    required int smsTimestampMs,
  }) {
    // ① OTP / credential guard — before anything else touches the message.
    if (isOtpOrCredential(body)) {
      return const ParseOutcome.rejected(ParseRejection.otp);
    }

    // ② sender allowlist
    final entry = allowlist.lookup(sender);
    if (entry == null) {
      return const ParseOutcome.rejected(ParseRejection.unknownSender);
    }

    // Normalize numerals once; every later step sees ASCII digits.
    // The card-product phrase is neutralised here so that `credit card` never
    // reads as an incoming-credit signal.
    final text = normalizeDigits(body).replaceAll(_cardPhraseRe, 'card');
    final lower = text.toLowerCase();

    // ③ transaction verbs. Marketing copy that merely *mentions* money never
    // reaches the parser: without a strong verb there is nothing to record.
    final debitAt = _firstSignal(lower, _debitSignals);
    final creditAt = _firstSignal(lower, _creditSignals);
    final hasVerb = debitAt >= 0 || creditAt >= 0;

    // A balance-only alert ("Avl Bal Rs 12,340") is not a transaction.
    if (_isBalanceOnly(lower, debitAt, creditAt)) {
      return const ParseOutcome.rejected(ParseRejection.balanceOnly);
    }

    if (!hasVerb) {
      // The reason is diagnostic only — both mean "nothing was recorded" — but
      // it is what the user sees in the local parse log.
      final marketing = _nonTxMarkers.any(lower.contains);
      return ParseOutcome.rejected(
        marketing ? ParseRejection.nonTransaction : ParseRejection.noSignal,
      );
    }

    // Future-tense notices ("will be debited on 15-10-26") are not completed
    // transactions, and parsing them would double-count the real debit later.
    for (final marker in _futureTenseMarkers) {
      if (lower.contains(marker)) {
        return const ParseOutcome.rejected(ParseRejection.nonTransaction);
      }
    }

    // Direction: whichever verb appears first wins, which is what keeps
    // "credited ... transfer" on the income side when both match.
    final direction = (debitAt >= 0 && (creditAt < 0 || debitAt < creditAt))
        ? TxnDirection.expense
        : TxnDirection.income;

    // ④ parse the transaction clause (everything before the balance marker)
    final clause = _transactionClause(text, lower);

    final amountPaise = _extractAmount(clause);
    if (amountPaise == null || amountPaise <= 0) {
      return const ParseOutcome.rejected(ParseRejection.noAmount);
    }

    final occurredAtMs = _extractTimestamp(clause, smsTimestampMs);
    if (occurredAtMs == null) {
      return const ParseOutcome.rejected(ParseRejection.outOfRange);
    }

    return ParseOutcome.parsed(
      ParsedTxn(
        amountPaise: amountPaise,
        direction: direction,
        occurredAtMs: occurredAtMs,
        source: TxSource.autoSms,
        parserKey: entry.parserKey,
        merchant: _extractMerchant(clause),
        accountLast4: _extractAccountLast4(clause),
        mode: _extractMode(lower),
        senderId: SenderAllowlist.normalize(sender),
        rawText: body,
      ),
    );
  }

  /// Parses a payment-app notification body (the parallel path for GPay,
  /// PhonePe, Paytm, BHIM, CRED and Amazon Pay).
  ParseOutcome parseNotification({
    required String packageName,
    required String title,
    required String body,
    required int timestampMs,
  }) {
    final combined = normalizeDigits('$title $body'.trim());
    if (isOtpOrCredential(combined)) {
      return const ParseOutcome.rejected(ParseRejection.otp);
    }

    final lower = combined.toLowerCase();
    final debitAt = _firstSignal(lower, _debitSignals);
    final creditAt = _firstSignal(lower, _creditSignals);
    if (debitAt < 0 && creditAt < 0) {
      return const ParseOutcome.rejected(ParseRejection.noSignal);
    }

    final direction = (debitAt >= 0 && (creditAt < 0 || debitAt < creditAt))
        ? TxnDirection.expense
        : TxnDirection.income;

    final amountPaise = _extractAmount(combined);
    if (amountPaise == null || amountPaise <= 0) {
      return const ParseOutcome.rejected(ParseRejection.noAmount);
    }

    final mode = _extractMode(lower);

    return ParseOutcome.parsed(
      ParsedTxn(
        amountPaise: amountPaise,
        direction: direction,
        occurredAtMs: timestampMs,
        source: TxSource.autoNotif,
        parserKey: _parserKeyForPackage(packageName),
        merchant: _extractMerchant(combined),
        mode: mode == PaymentMode.other ? PaymentMode.upi : mode,
        sourceRef: packageName,
        rawText: combined,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // internals
  // ---------------------------------------------------------------------------

  static int _firstSignal(String lower, List<String> signals) {
    var best = -1;
    for (final s in signals) {
      final m = RegExp(s, caseSensitive: false).firstMatch(lower);
      if (m == null) continue;
      if (best < 0 || m.start < best) best = m.start;
    }
    return best;
  }

  static bool _isBalanceOnly(String lower, int debitAt, int creditAt) {
    if (!_balanceMarkers.any(lower.contains)) return false;

    // "Avl Bal Rs 12,340" with no debit/credit verb → a balance-only alert.
    if (debitAt < 0 && creditAt < 0) return true;

    // A balance marker *before* any transaction verb means the only amount
    // available is the balance.
    for (final marker in _balanceMarkers) {
      final i = lower.indexOf(marker);
      if (i >= 0 && i < debitAt && i < creditAt) return true;
    }
    return false;
  }

  /// Everything before the first balance marker — this is where the transaction
  /// amount lives. Without this cut, "Avl Bal Rs.12,340" would be parsed as the
  /// transaction amount. See `docs/06-SMS-PARSING.md` §5.
  static String _transactionClause(String text, String lower) {
    var cut = text.length;
    for (final marker in _balanceMarkers) {
      final i = lower.indexOf(marker);
      if (i >= 0 && i < cut) cut = i;
    }
    return text.substring(0, cut).trim();
  }

  static int? _extractAmount(String text) {
    final m = _amountRe.firstMatch(text);
    if (m == null) return null;
    final raw = m.group(1)!.replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    // Money is stored as integer paise — see docs/05-DATA-MODEL.md §1.
    return (value * 100).round();
  }

  static String? _extractMerchant(String clause) {
    // 1. VPA handle — the most reliable merchant signal in a UPI SMS.
    final vpa = _vpaRe.firstMatch(clause);
    if (vpa != null) {
      final name = canonical(vpa.group(1));
      if (name != null) return name;
    }

    // 2. Every `at/to/towards/for/from X` candidate, in order. A credit SMS
    //    reads "credited to A/c XX3399 … towards FD Interest", and a debit can
    //    read "debited from your account 123456789 … to Bajaj Finserv", so the
    //    first candidate is often just an account number — keep looking.
    //    Each keyword gets its own bounded slice, because a single greedy
    //    pattern would swallow the keyword that follows it.
    for (final m in _merchantKeywordRe.allMatches(clause)) {
      final start = m.end;
      if (start >= clause.length) continue;
      final stop = start + _merchantMaxChars;
      var raw = clause.substring(
        start,
        stop < clause.length ? stop : clause.length,
      );
      for (final s in _merchantStops) {
        final i = raw.indexOf(s);
        if (i > 0) raw = raw.substring(0, i);
      }
      final name = canonical(raw);
      if (name != null) return name;
    }

    return null;
  }

  static String? _extractAccountLast4(String clause) {
    final patterns = <RegExp>[
      RegExp(
        r'(?:a\/c|\bac\b|\bacct\b|\baccount\b)\s*(?:no\.?)?\s*[xX*]{0,10}\s*(\d{3,})',
      ),
      RegExp(r'[xX*]{2,}\s*(\d{4})'),
      RegExp(
        r'(?:card|ending|ending with)\s*(?:no\.?)?\s*[xX*]{0,10}\s*(\d{4})',
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(clause);
      if (m != null) {
        final d = m.group(1)!;
        return d.length >= 4 ? d.substring(d.length - 4) : d.padLeft(4, '0');
      }
    }
    return null;
  }

  static PaymentMode _extractMode(String lower) {
    if (RegExp(r'\bvpa\b|\bupi\b|@ok|@ybl|@paytm|@apl|@ibl|@axl')
        .hasMatch(lower)) {
      return PaymentMode.upi;
    }
    if (RegExp(r'\bcredit card\b|\bdebit card\b|\bcard\b|\bpos\b|\bamex\b')
        .hasMatch(lower)) {
      return PaymentMode.card;
    }
    if (RegExp(r'\bwallet\b|\bpaytm wallet\b|\bamazon pay balance\b')
        .hasMatch(lower)) {
      return PaymentMode.wallet;
    }
    if (RegExp(r'\bneft\b|\bimps\b|\brtgs\b|\bnet ?bank').hasMatch(lower)) {
      return PaymentMode.netbanking;
    }
    if (RegExp(r'\batm\b|\bcash withdrawal\b|\bwdl\b').hasMatch(lower)) {
      return PaymentMode.cash;
    }
    return PaymentMode.other;
  }

  /// Returns the transaction timestamp, or null when the parsed date is
  /// nonsensical (more than 72h in the future, or older than 400 days).
  static int? _extractTimestamp(String clause, int smsTimestampMs) {
    final parsed = _parseDate(clause);
    if (parsed == null) return smsTimestampMs;

    final delta = parsed - smsTimestampMs;
    const threeDays = 72 * 60 * 60 * 1000;
    const fourHundredDays = 400 * 24 * 60 * 60 * 1000;
    if (delta > threeDays || delta < -fourHundredDays) return smsTimestampMs;
    return parsed;
  }

  static int? _parseDate(String clause) {
    // dd-MM-yy / dd/MM/yyyy
    var m = _dateDmyRe.firstMatch(clause);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final y = _expandYear(m.group(3)!);
      if (_validYmd(y, mo, d)) {
        return DateTime(y!, mo!, d!).millisecondsSinceEpoch;
      }
    }

    // dd-MMM-yy  (06-OCT-2026)
    m = _dateDmmmyRe.firstMatch(clause);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = _months[m.group(2)!.toLowerCase()];
      final y = _expandYear(m.group(3)!);
      if (mo != null && _validYmd(y, mo, d)) {
        return DateTime(y!, mo, d!).millisecondsSinceEpoch;
      }
    }

    // 07OCT26
    m = _dateDdMmmYyRe.firstMatch(clause);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = _months[m.group(2)!.toLowerCase()];
      final y = _expandYear(m.group(3)!);
      if (mo != null && _validYmd(y, mo, d)) {
        return DateTime(y!, mo, d!).millisecondsSinceEpoch;
      }
    }

    return null;
  }

  static int? _expandYear(String raw) {
    final n = int.tryParse(raw);
    if (n == null) return null;
    if (raw.length <= 2) return n < 70 ? 2000 + n : 1900 + n;
    return n;
  }

  static bool _validYmd(int? y, int? m, int? d) {
    if (y == null || m == null || d == null) return false;
    if (m < 1 || m > 12 || d < 1 || d > 31) return false;
    if (y < 2000 || y > 2100) return false;
    return true;
  }

  static String _parserKeyForPackage(String pkg) => switch (pkg) {
    'com.google.android.apps.nbu.paisa.user' => 'gpay',
    'com.phonepe.app' => 'phonepe',
    'net.one97.paytm' => 'paytm',
    'in.org.npci.upiapp' => 'bhim',
    'com.dreamplug.androidapp' => 'cred',
    'in.amazon.mShop.android.shopping' => 'amazonpay',
    _ => 'notification',
  };
}

/// Packages we listen to when notification access is granted. Nothing outside
/// this list is ever inspected — see `docs/06-SMS-PARSING.md` §9.
const Set<String> kPaymentPackages = <String>{
  'com.google.android.apps.nbu.paisa.user',
  'com.phonepe.app',
  'net.one97.paytm',
  'in.org.npci.upiapp',
  'com.dreamplug.androidapp',
  'in.amazon.mShop.android.shopping',
};
