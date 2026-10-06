/// Sender allowlist — **step ②** of the capture pipeline.
///
/// Only messages from a known Indian bank / card / wallet sender are considered.
/// Everything else is ignored outright, which is what keeps the false-positive
/// rate at zero for spam, promotional, and personal messages.
/// See `docs/06-SMS-PARSING.md` §3.
library;

/// One allowlist entry: which sender ID maps to which bank and parser.
class SenderEntry {
  const SenderEntry({
    required this.senderId,
    required this.bankName,
    required this.parserKey,
    this.enabled = true,
  });

  /// Normalized sender suffix, e.g. `HDFCBK`.
  final String senderId;
  final String bankName;
  final String parserKey;
  final bool enabled;
}

/// The built-in allowlist. `ruleVersion` is bumped whenever this changes so the
/// database migration can re-seed `sms_senders` for existing installs.
class SenderAllowlist {
  SenderAllowlist([List<SenderEntry>? entries])
    : entries = entries ?? defaultEntries;

  /// Bump on every change to [defaultEntries]. Persisted in `app_meta`.
  static const int ruleVersion = 1;

  static const List<SenderEntry> defaultEntries = <SenderEntry>[
    // ---- banks (SMS-based transaction alerts) ----
    SenderEntry(senderId: 'HDFCBK', bankName: 'HDFC Bank', parserKey: 'hdfc'),
    SenderEntry(senderId: 'ICICIB', bankName: 'ICICI Bank', parserKey: 'icici'),
    SenderEntry(
      senderId: 'SBIINB',
      bankName: 'State Bank of India',
      parserKey: 'sbi',
    ),
    SenderEntry(
      senderId: 'SBISMS',
      bankName: 'State Bank of India',
      parserKey: 'sbi',
    ),
    SenderEntry(
      senderId: 'ATMSBI',
      bankName: 'State Bank of India',
      parserKey: 'sbi',
    ),
    SenderEntry(senderId: 'AXISBK', bankName: 'Axis Bank', parserKey: 'axis'),
    SenderEntry(
      senderId: 'KOTAKB',
      bankName: 'Kotak Mahindra Bank',
      parserKey: 'kotak',
    ),
    SenderEntry(
      senderId: 'PNBSMS',
      bankName: 'Punjab National Bank',
      parserKey: 'pnb',
    ),
    SenderEntry(
      senderId: 'BOBSMS',
      bankName: 'Bank of Baroda',
      parserKey: 'bob',
    ),
    SenderEntry(
      senderId: 'CANBNK',
      bankName: 'Canara Bank',
      parserKey: 'canara',
    ),
    SenderEntry(
      senderId: 'UNIONB',
      bankName: 'Union Bank of India',
      parserKey: 'union',
    ),
    SenderEntry(senderId: 'IDBIBK', bankName: 'IDBI Bank', parserKey: 'idbi'),
    SenderEntry(senderId: 'YESBNK', bankName: 'Yes Bank', parserKey: 'yes'),
    SenderEntry(
      senderId: 'INDUSB',
      bankName: 'IndusInd Bank',
      parserKey: 'indusind',
    ),
    SenderEntry(
      senderId: 'IDFCBK',
      bankName: 'IDFC FIRST Bank',
      parserKey: 'idfc',
    ),
    SenderEntry(
      senderId: 'FEDBNK',
      bankName: 'Federal Bank',
      parserKey: 'federal',
    ),
    SenderEntry(
      senderId: 'BANDHN',
      bankName: 'Bandhan Bank',
      parserKey: 'bandhan',
    ),
    SenderEntry(senderId: 'RBLBNK', bankName: 'RBL Bank', parserKey: 'rbl'),
    SenderEntry(
      senderId: 'AUSFBK',
      bankName: 'AU Small Finance Bank',
      parserKey: 'au',
    ),
    SenderEntry(
      senderId: 'SCBANK',
      bankName: 'Standard Chartered',
      parserKey: 'sc',
    ),
    SenderEntry(
      senderId: 'BOISMS',
      bankName: 'Bank of India',
      parserKey: 'boi',
    ),
    SenderEntry(
      senderId: 'CENTBK',
      bankName: 'Central Bank of India',
      parserKey: 'cbi',
    ),
    SenderEntry(
      senderId: 'INDBNK',
      bankName: 'Indian Bank',
      parserKey: 'indian',
    ),
    SenderEntry(senderId: 'UCOBNK', bankName: 'UCO Bank', parserKey: 'uco'),
    SenderEntry(
      senderId: 'SIBSMS',
      bankName: 'South Indian Bank',
      parserKey: 'sib',
    ),
    SenderEntry(
      senderId: 'KARBNK',
      bankName: 'Karnataka Bank',
      parserKey: 'karnataka',
    ),
    SenderEntry(
      senderId: 'PUNSND',
      bankName: 'Punjab & Sind Bank',
      parserKey: 'psb',
    ),
    SenderEntry(
      senderId: 'IOBSMS',
      bankName: 'Indian Overseas Bank',
      parserKey: 'iob',
    ),
    SenderEntry(
      senderId: 'CUBANK',
      bankName: 'City Union Bank',
      parserKey: 'cub',
    ),
    SenderEntry(
      senderId: 'KVBSMS',
      bankName: 'Karur Vysya Bank',
      parserKey: 'kvb',
    ),
    SenderEntry(
      senderId: 'DBSBNK',
      bankName: 'DBS Bank India',
      parserKey: 'dbs',
    ),
    SenderEntry(
      senderId: 'PYTMBK',
      bankName: 'Paytm Payments Bank',
      parserKey: 'paytm',
    ),
    SenderEntry(
      senderId: 'AIRBNK',
      bankName: 'Airtel Payments Bank',
      parserKey: 'airtel',
    ),
    SenderEntry(
      senderId: 'IPPBBN',
      bankName: 'India Post Payments Bank',
      parserKey: 'ippb',
    ),
    SenderEntry(
      senderId: 'JIOBNK',
      bankName: 'Jio Payments Bank',
      parserKey: 'jio',
    ),
    SenderEntry(senderId: 'FINBNK', bankName: 'Fi Money', parserKey: 'fi'),

    // ---- cards / NBFC / wallets ----
    SenderEntry(
      senderId: 'HDFCCC',
      bankName: 'HDFC Credit Card',
      parserKey: 'hdfc_card',
    ),
    SenderEntry(
      senderId: 'ICICIC',
      bankName: 'ICICI Credit Card',
      parserKey: 'icici_card',
    ),
    SenderEntry(
      senderId: 'AMEXIN',
      bankName: 'American Express',
      parserKey: 'amex',
    ),
    SenderEntry(
      senderId: 'BAJAJF',
      bankName: 'Bajaj Finserv',
      parserKey: 'bajaj',
    ),
    SenderEntry(
      senderId: 'HDBFIN',
      bankName: 'HDB Financial',
      parserKey: 'hdbf',
    ),
    SenderEntry(senderId: 'ZESTPAY', bankName: 'ZestMoney', parserKey: 'zest'),
    SenderEntry(senderId: 'SLICEP', bankName: 'Slice', parserKey: 'slice'),
    SenderEntry(senderId: 'LAZYPAY', bankName: 'LazyPay', parserKey: 'lazypay'),
    SenderEntry(senderId: 'SIMPLE', bankName: 'Simpl', parserKey: 'simpl'),
    SenderEntry(senderId: 'CRED', bankName: 'CRED', parserKey: 'cred'),
    SenderEntry(senderId: 'JUPITER', bankName: 'Jupiter', parserKey: 'jupiter'),
    SenderEntry(
      senderId: 'PAYTM',
      bankName: 'Paytm',
      parserKey: 'paytm_wallet',
    ),
    SenderEntry(senderId: 'PHONEPE', bankName: 'PhonePe', parserKey: 'phonepe'),
    SenderEntry(
      senderId: 'AMAZONP',
      bankName: 'Amazon Pay',
      parserKey: 'amazonpay',
    ),
  ];

  final List<SenderEntry> entries;

  /// Sender prefixes Indian carriers put in front of the bank code. Stripping
  /// these is what lets `VM-HDFCBK` and `AD-HDFCBK` both resolve to `HDFCBK`.
  static final RegExp _carrierPrefix = RegExp(
    r'^(vm|vk|ax|tm|bm|ad|cp|bp|mm|jd|ds|gl|jk|hp|lm|hy|qk|wa|ka|tz)\s*[-_]\s*',
    caseSensitive: false,
  );

  /// Normalize a raw sender ID to its allowlist form.
  ///
  /// `VM-HDFCBK` → `HDFCBK`, `AD-ICICIB` → `ICICIB`, `AX-HDFCBK` → `HDFCBK`.
  /// Also strips trailing whitespace and any `-S` style service suffix.
  static String normalize(String raw) {
    var s = raw.trim().toUpperCase();
    s = s.replaceFirst(_carrierPrefix, '');
    // Some carriers append a service indicator: `HDFCBK-S`, `ICICIB-1`.
    s = s.replaceFirst(RegExp(r'[-_][A-Z0-9]{1,2}$'), '');
    return s.trim();
  }

  /// Look up a sender. Returns null when the sender is not on the allowlist —
  /// the caller must then ignore the message entirely.
  SenderEntry? lookup(String rawSender) {
    final key = normalize(rawSender);
    if (key.isEmpty) return null;
    for (final e in entries) {
      if (e.enabled && e.senderId == key) return e;
    }
    return null;
  }

  bool isAllowed(String rawSender) => lookup(rawSender) != null;
}
