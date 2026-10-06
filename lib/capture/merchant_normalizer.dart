/// Merchant normalization — turns raw SMS fragments into stable display names.
///
/// Two jobs:
///  1. canonical spelling for well-known Indian merchants (`bigbasket` → `BigBasket`)
///  2. cleanup for everyone else (title case, trim noise, drop generic words)
///
/// The parser calls [canonical]; the rule engine matches on [matchKey].
library;

/// Merchant tokens that would otherwise be captured as if they were a shop.
const Set<String> _genericTokens = <String>{
  'upi',
  'neft',
  'imps',
  'rtgs',
  'the',
  'a/c',
  'ac',
  'account',
  'acct',
  'payment',
  'transfer',
  'txn',
  'transaction',
  'your',
  'our',
  'merchant',
  'pos',
  'atm',
  'card',
  'bank',
  'ifsc',
  'ref',
  'reference',
  'vpa',
  'wallet',
  'bill',
  'biller',
  'mobile',
  'recharge',
  'india',
  'ltd',
  'limited',
  'pvt',
  'private',
  'services',
  'store',
  'shop',
  'online',
  'digital',
  'gateway',
  'debit',
  'credit',
  'withdrawn',
  'spent',
  'paid',
  'received',
  'deposited',
  'towards',
  'from',
  'via',
  'using',
  'for',
  'with',
  'and',
  'new',
  'has',
  'been',
  'branch',
  'customer',
  'dear',
  'info',
  'alert',
  'update',
  'success',
};

/// Canonical display spellings for merchants we see constantly.
///
/// Multi-word keys are listed explicitly — `amazon pay` must beat `amazon`, which
/// is why the containment scan in [canonical] walks the longest key first.
const Map<String, String> _canonical = <String, String>{
  'bigbasket': 'BigBasket',
  'blinkit': 'Blinkit',
  'grofers': 'Blinkit',
  'zepto': 'Zepto',
  'swiggy': 'Swiggy',
  'zomato': 'Zomato',
  'dunzo': 'Dunzo',
  'jiomart': 'JioMart',
  'dmart': 'DMart',
  'licious': 'Licious',
  'freshtohome': 'FreshToHome',
  'big basket': 'BigBasket',
  'amazon pay': 'Amazon Pay',
  'amazon': 'Amazon',
  'flipkart': 'Flipkart',
  'myntra': 'Myntra',
  'ajio': 'AJIO',
  'meesho': 'Meesho',
  'nykaa': 'Nykaa',
  'uber': 'Uber',
  'ola': 'Ola',
  'rapido': 'Rapido',
  'irctc': 'IRCTC',
  'redbus': 'RedBus',
  'indigo': 'IndiGo',
  'makemytrip': 'MakeMyTrip',
  'google pay': 'Google Pay',
  'phonepe': 'PhonePe',
  'phone pe': 'PhonePe',
  'paytm': 'Paytm',
  'cred': 'CRED',
  'jio': 'Jio',
  'airtel': 'Airtel',
  'vodafone': 'Vi',
  'bsnl': 'BSNL',
  'netflix': 'Netflix',
  'hotstar': 'JioHotstar',
  'spotify': 'Spotify',
  'prime video': 'Prime Video',
  'youtube': 'YouTube',
  'google play': 'Google Play',
  'apollo': 'Apollo',
  'pharmeasy': 'PharmEasy',
  '1mg': 'Tata 1mg',
  'netmeds': 'Netmeds',
  'medplus': 'MedPlus',
  'cult fit': 'cult.fit',
  'bookmyshow': 'BookMyShow',
  'pvr': 'PVR',
  'inox': 'INOX',
  'starbucks': 'Starbucks',
  'dominos': 'Domino\'s',
  'kfc': 'KFC',
  'mcdonalds': 'McDonald\'s',
  'burger king': 'Burger King',
  'chai point': 'Chai Point',
  'chai': 'Chai Point',
  'third wave': 'Third Wave Coffee',
  'third wave coffee': 'Third Wave Coffee',
  'blu tokai': 'Blue Tokai',
  'decathlon': 'Decathlon',
  'westside': 'Westside',
  'pantaloons': 'Pantaloons',
  'fabindia': 'FabIndia',
  'bata': 'Bata',
  'bajaj finserv': 'Bajaj Finserv',
  'bajaj finance': 'Bajaj Finance',
  'bajaj': 'Bajaj',
  'hdfc': 'HDFC',
  'icici': 'ICICI',
  'axis': 'Axis',
  'kotak': 'Kotak',
  'sbi': 'SBI',
  'epfo': 'EPFO',
  'lic': 'LIC',
  // income-side labels (these appear as the "merchant" in credit SMS)
  'fd interest': 'FD Interest',
  'salary': 'Salary',
  'salary transfer': 'Salary',
  'interest': 'Interest',
  'refund': 'Refund',
  'cashback': 'Cashback',
  'reversal': 'Reversal',
  'client payment': 'Client Payment',
  'house rent': 'House Rent',
  'rent': 'Rent',
};

/// Key used for rule matching: lowercase, separators collapsed, punctuation gone.
String matchKey(String raw) {
  var s = raw.toLowerCase().trim();
  s = s.replaceAll(RegExp(r'[._\-*#/]'), ' ');
  s = s.replaceAll(RegExp(r'[^a-z0-9\u0900-\u097F\u0980-\u09FF ]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// A token that is an account fragment (`xx4521`) or a bare reference number
/// rather than a merchant name.
final RegExp _looksLikeReference = RegExp(r'^[a-z]{0,3}\d{3,}$');

/// True when the token is a payment-rail word rather than a merchant.
bool isGeneric(String raw) {
  final k = matchKey(raw);
  if (k.isEmpty) return true;
  if (k.length < 3) return true;
  if (_genericTokens.contains(k)) return true;
  if (RegExp(r'^\d+$').hasMatch(k)) return true;
  if (_looksLikeReference.hasMatch(k)) return true;
  // A phrase made only of rail words and one-letter fragments ("a c") carries
  // no merchant either.
  final words = k.split(' ');
  if (words.every((w) => w.length < 3 || _genericTokens.contains(w))) {
    return true;
  }
  return false;
}

/// Produce a clean display name. Returns null when [raw] carries no merchant.
String? canonical(String? raw) {
  if (raw == null) return null;
  final key = matchKey(raw);
  if (key.isEmpty) return null;

  // 1. exact canonical hit
  final exact = _canonical[key];
  if (exact != null) return exact;

  // 2. a known merchant appearing inside a longer captured phrase.
  //    The leftmost merchant wins, with the longest key breaking a tie — so
  //    "Amazon Refund" reads as Amazon (not "Refund") and "Amazon Pay" beats
  //    "Amazon".
  final contained = _leftmostKnown(key);
  if (contained != null) return _canonical[contained];

  // 3. free text — keep meaningful words only
  final words = key
      .split(' ')
      .where((w) => w.isNotEmpty && !isGeneric(w))
      .toList();
  if (words.isEmpty) return null;

  return words.map(_titleCase).join(' ');
}

/// Finds the known merchant appearing earliest in [key]; ties go to the longer
/// key. Matching is on whole words, so `lic` never fires inside `delicious`.
String? _leftmostKnown(String key) {
  String? best;
  var bestAt = -1;
  for (final k in _canonical.keys) {
    if (k.length < 4) continue;
    final at = _wordIndexOf(key, k);
    if (at < 0) continue;
    if (best == null ||
        at < bestAt ||
        (at == bestAt && k.length > best.length)) {
      best = k;
      bestAt = at;
    }
  }
  return best;
}

int _wordIndexOf(String haystack, String needle) {
  var from = 0;
  while (true) {
    final i = haystack.indexOf(needle, from);
    if (i < 0) return -1;
    final beforeOk = i == 0 || haystack[i - 1] == ' ';
    final end = i + needle.length;
    final afterOk = end == haystack.length || haystack[end] == ' ';
    if (beforeOk && afterOk) return i;
    from = i + 1;
  }
}

String _titleCase(String w) {
  if (w.isEmpty) return w;
  return w[0].toUpperCase() + w.substring(1);
}
