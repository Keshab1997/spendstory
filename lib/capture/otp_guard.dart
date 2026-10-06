/// OTP and credential guard.
///
/// Runs as **step ①** of the capture pipeline — before the sender allowlist,
/// before any parsing, and before anything is written to memory or disk. If this
/// returns true the message is dropped on the floor: not logged, not stored,
/// not sent anywhere. See `docs/06-SMS-PARSING.md` §2.
library;

/// Hard patterns: any match means the message is an OTP / credential message,
/// full stop. These are deliberately generous — a false positive costs one
/// missed transaction the user can add by hand; a false negative would mean the
/// app touched an OTP, which is unacceptable.
final List<RegExp> _hardPatterns = <RegExp>[
  RegExp(r'\botp\b', caseSensitive: false),
  RegExp(r'\bo\.?\s?t\.?\s?p\.?\b', caseSensitive: false),
  RegExp(
    r'one[\s\-_]?time[\s\-_]?(password|passcode|pin|code)',
    caseSensitive: false,
  ),
  RegExp(r'do\s+not\s+share', caseSensitive: false),
  RegExp(r'never\s+share', caseSensitive: false),
  RegExp(r'donot\s*share', caseSensitive: false),
  RegExp(r'verification\s+code', caseSensitive: false),
  RegExp(r'varification\s+code', caseSensitive: false), // honest misspelling
  RegExp(r'verif(ication)?\s+(pin|otp)', caseSensitive: false),
  RegExp(r'login\s+(code|otp|pin)', caseSensitive: false),
  RegExp(r'(auth|authentication)\s+(code|pin)', caseSensitive: false),
  RegExp(r'secure\s+code', caseSensitive: false),
  RegExp(r'one[\s\-]?time\s+password', caseSensitive: false),
  RegExp(r'\bcvv\b', caseSensitive: false),
  RegExp(r'\bmpin\b', caseSensitive: false),
  RegExp(r'\bu\.?p\.?i\.?\s*pin\b', caseSensitive: false),
  RegExp(r'\batm\s*pin\b', caseSensitive: false),
  RegExp(r'card\s*pin', caseSensitive: false),
  RegExp(r'valid\s+for\s+\d+\s*(min|minute|second|sec)', caseSensitive: false),
  RegExp(r'expires?\s+in\s+\d+\s*(min|minute|second)', caseSensitive: false),
  RegExp(
    r'is\s+your\s+(login|verification|security)\s+code',
    caseSensitive: false,
  ),
  // Hindi / Bengali credential phrasing
  RegExp(r'साझा\s*न\s*करें'), // do not share
  RegExp(r'ओटीपी'),
  RegExp(r'वन\s*टाइम\s*पासवर्ड'),
  RegExp(r'সেয়ার\s*করবেন\s*না'), // do not share
  RegExp(r'শেয়ার\s*করবেন\s*না'),
  RegExp(r'ওটিপি'),
  RegExp(r'ও\s*টি\s*পি'),
];

/// A short standalone number with no currency marker next to it. This is the
/// classic OTP shape: `123456 is your code`, `Use 4321 to login`.
final RegExp _bareCode = RegExp(
  r'(?<![₹\d])\b\d{4,8}\b(?!(?:\s*(?:rs|inr|₹|rupees|only)))',
  caseSensitive: false,
);

/// Currency / amount marker — if one is present near the number, the message is
/// far more likely to be a transaction than a credential.
final RegExp _hasCurrency = RegExp(
  r'(?:₹|rs\.?|inr|rupees)\s*\d',
  caseSensitive: false,
);

/// Debit/credit verbs. Their presence outweighs a bare 6-digit number: an SMS
/// that says "Rs 1,240 debited" is a transaction even if it also contains
/// "412398" as a reference number.
final RegExp _hasMoneyVerb = RegExp(
  r'\b(debited|credited|debit|credit|withdrawn|withdrawal|spent|paid|'
  r'received|deposited|refund|purchase|sent|transferred|txn|trf|tfr)\b',
  caseSensitive: false,
);

/// Returns true when [body] is an OTP, PIN, or credential message that must be
/// dropped without being stored, logged, or parsed.
bool isOtpOrCredential(String body) {
  if (body.isEmpty) return true;

  for (final p in _hardPatterns) {
    if (p.hasMatch(body)) return true;
  }

  // A bare code with no currency and no money verb is treated as a credential.
  // This catches the short-form OTPs ("4321 is your code") that word lists miss.
  final hasBareCode = _bareCode.hasMatch(body);
  if (hasBareCode &&
      !_hasCurrency.hasMatch(body) &&
      !_hasMoneyVerb.hasMatch(body)) {
    return true;
  }

  return false;
}

/// Convenience wrapper used by the pipeline, kept as a class so call sites read
/// the same as the spec.
class OtpGuard {
  const OtpGuard._();

  static bool rejects(String body) => isOtpOrCredential(body);
}
