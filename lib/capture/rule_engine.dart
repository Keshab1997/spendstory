/// Merchant → category intelligence.
///
/// Three layers of decision, in priority order:
///  1. **user-defined rule** — always wins. If the user re-categorised
///     "Swiggy" once, every future Swiggy lands where they put it.
///  2. **learned rule** — a built-in rule whose [MerchantRule.hits] the user has
///     confirmed by accepting an auto-categorisation.
///  3. **built-in rule** — the shipped India merchant table below.
///
/// Longest pattern wins, so `bigbasket` beats a generic `basket`-ish token and
/// `amazon pay` beats `amazon`.
///
/// Category keys match the seed rows in `lib/data/seed.dart`.
library;

import 'merchant_normalizer.dart';

/// Category keys used across the app. Kept as constants so a typo is a compile
/// error rather than a silently uncategorised transaction.
abstract final class Cat {
  // expense
  static const food = 'food';
  static const grocery = 'grocery';
  static const transport = 'transport';
  static const bills = 'bills';
  static const rent = 'rent';
  static const health = 'health';
  static const education = 'education';
  static const clothing = 'clothing';
  static const entertainment = 'entertainment';
  static const recharge = 'recharge';
  static const emi = 'emi';
  static const otherExpense = 'other_expense';
  // income
  static const salary = 'salary';
  static const business = 'business';
  static const freelance = 'freelance';
  static const interest = 'interest';
  static const gift = 'gift';
  static const otherIncome = 'other_income';
}

class MerchantRule {
  const MerchantRule({
    required this.pattern,
    required this.categoryKey,
    this.hits = 0,
    this.isUserDefined = false,
  });

  /// Lowercase match key, e.g. `bigbasket`.
  final String pattern;
  final String categoryKey;

  /// How many times this rule has been used and accepted.
  final int hits;

  /// User rules are never overridden by anything.
  final bool isUserDefined;

  MerchantRule bump() => MerchantRule(
    pattern: pattern,
    categoryKey: categoryKey,
    hits: hits + 1,
    isUserDefined: isUserDefined,
  );
}

class RuleResult {
  const RuleResult({
    this.categoryKey,
    this.confidence = 0,
    this.matchedPattern,
  });

  final String? categoryKey;

  /// 0 = no idea, 1 = certain. Below ~0.5 the UI should ask rather than assume.
  final double confidence;

  final String? matchedPattern;

  bool get isConfident => categoryKey != null && confidence >= 0.5;

  @override
  String toString() =>
      'RuleResult(${categoryKey ?? 'none'} · ${confidence.toStringAsFixed(2)}'
      '${matchedPattern != null ? ' · $matchedPattern' : ''})';
}

class RuleEngine {
  RuleEngine({List<MerchantRule>? userRules, List<MerchantRule>? builtIns})
    : userRules = List<MerchantRule>.from(userRules ?? const []),
      builtIns = List<MerchantRule>.from(builtIns ?? defaultRules);

  final List<MerchantRule> userRules;
  final List<MerchantRule> builtIns;

  /// Classify a parsed transaction. [rawText] is used only as a fallback when no
  /// merchant could be extracted — it lets a distinctive token elsewhere in the
  /// SMS still earn a category.
  RuleResult classify({String? merchant, String? rawText}) {
    final fromMerchant = _match(merchant);
    if (fromMerchant != null) return fromMerchant;

    if (rawText != null && rawText.isNotEmpty) {
      return _match(rawText) ?? const RuleResult();
    }
    return const RuleResult();
  }

  RuleResult? _match(String? text) {
    if (text == null) return null;
    final key = matchKey(text);
    if (key.isEmpty) return null;

    MerchantRule? best;
    for (final rule in userRules) {
      if (!_matchesRule(key, rule.pattern)) continue;
      if (best == null || rule.pattern.length > best.pattern.length) {
        best = rule;
      }
    }
    if (best != null) {
      // A user decision is definitive.
      return RuleResult(
        categoryKey: best.categoryKey,
        confidence: 1.0,
        matchedPattern: best.pattern,
      );
    }

    best = null;
    for (final rule in builtIns) {
      if (!_matchesRule(key, rule.pattern)) continue;
      if (best == null || rule.pattern.length > best.pattern.length) {
        best = rule;
      }
    }
    if (best == null) return null;

    // Confirmed hits push confidence up; a fresh guess stays moderate so the UI
    // can still ask.
    final confidence = (0.6 + best.hits * 0.05).clamp(0.0, 0.95);
    return RuleResult(
      categoryKey: best.categoryKey,
      confidence: confidence,
      matchedPattern: best.pattern,
    );
  }

  /// True when [pattern] describes [key].
  ///
  /// Whole words match directly, so "paytm wallet" still matches `paytm`. Very
  /// short patterns are *not* matched as substrings — the word `lic` must never
  /// fire on a shop called "Delicious" — but longer ones may ignore the space,
  /// which is what lets `big basket` (from "Big-Basket") match the built-in
  /// `bigbasket`.
  static bool _matchesRule(String key, String pattern) {
    if (key == pattern) return true;
    if (key.startsWith('$pattern ') ||
        key.endsWith(' $pattern') ||
        key.contains(' $pattern ')) {
      return true;
    }
    final tightKey = key.replaceAll(' ', '');
    final tightPattern = pattern.replaceAll(' ', '');
    return tightPattern.length >= 5 && tightKey.contains(tightPattern);
  }

  /// Record that the user accepted (or corrected to) [categoryKey] for
  /// [merchant]. Replaces any existing user rule for the same pattern.
  RuleEngine learn({required String pattern, required String categoryKey}) {
    final key = matchKey(pattern);
    if (key.isEmpty) return this;
    final next = userRules.where((r) => r.pattern != key).toList()
      ..add(
        MerchantRule(
          pattern: key,
          categoryKey: categoryKey,
          hits: 1,
          isUserDefined: true,
        ),
      );
    return RuleEngine(userRules: next, builtIns: builtIns);
  }

  /// Account for a built-in hit being accepted unchanged.
  RuleEngine countHit(String pattern) {
    final next = builtIns
        .map((r) => r.pattern == pattern ? r.bump() : r)
        .toList(growable: false);
    return RuleEngine(userRules: userRules, builtIns: next);
  }

  /// The shipped India merchant table — `docs/05-DATA-MODEL.md` §6 requires ~120
  /// built-in patterns on first run.
  static const List<MerchantRule> defaultRules = <MerchantRule>[
    // ---- food delivery & eating out ----
    MerchantRule(pattern: 'swiggy', categoryKey: Cat.food),
    MerchantRule(pattern: 'zomato', categoryKey: Cat.food),
    MerchantRule(pattern: 'eatsure', categoryKey: Cat.food),
    MerchantRule(pattern: 'faasos', categoryKey: Cat.food),
    MerchantRule(pattern: 'behrouz', categoryKey: Cat.food),
    MerchantRule(pattern: 'ovenstory', categoryKey: Cat.food),
    MerchantRule(pattern: 'domin', categoryKey: Cat.food),
    MerchantRule(pattern: 'kfc', categoryKey: Cat.food),
    MerchantRule(pattern: 'mcdonald', categoryKey: Cat.food),
    MerchantRule(pattern: 'burger king', categoryKey: Cat.food),
    MerchantRule(pattern: 'pizza hut', categoryKey: Cat.food),
    MerchantRule(pattern: 'subway', categoryKey: Cat.food),
    MerchantRule(pattern: 'starbucks', categoryKey: Cat.food),
    MerchantRule(pattern: 'chaayos', categoryKey: Cat.food),
    MerchantRule(pattern: 'chai point', categoryKey: Cat.food),
    MerchantRule(pattern: 'third wave', categoryKey: Cat.food),
    MerchantRule(pattern: 'blue tokai', categoryKey: Cat.food),
    MerchantRule(pattern: 'cafe', categoryKey: Cat.food),
    MerchantRule(pattern: 'restaurant', categoryKey: Cat.food),
    MerchantRule(pattern: 'hotel', categoryKey: Cat.food),
    MerchantRule(pattern: 'bakery', categoryKey: Cat.food),
    MerchantRule(pattern: 'sweets', categoryKey: Cat.food),
    MerchantRule(pattern: 'biryani', categoryKey: Cat.food),
    MerchantRule(pattern: 'dhaba', categoryKey: Cat.food),
    MerchantRule(pattern: 'juice', categoryKey: Cat.food),
    MerchantRule(pattern: 'tea stall', categoryKey: Cat.food),

    // ---- groceries & daily needs ----
    MerchantRule(pattern: 'bigbasket', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'blinkit', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'grofers', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'zepto', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'jiomart', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'dmart', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'reliance fresh', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'reliance smart', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'more retail', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'spencers', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'licious', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'freshtohome', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'milkbasket', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'country delight', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'amul', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'bazar', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'kirana', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'provision', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'vegetable', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'sabzi', categoryKey: Cat.grocery),
    MerchantRule(pattern: 'fish market', categoryKey: Cat.grocery),

    // ---- transport ----
    MerchantRule(pattern: 'uber', categoryKey: Cat.transport),
    MerchantRule(pattern: 'ola', categoryKey: Cat.transport),
    MerchantRule(pattern: 'rapido', categoryKey: Cat.transport),
    MerchantRule(pattern: 'blusmart', categoryKey: Cat.transport),
    MerchantRule(pattern: 'namma yatri', categoryKey: Cat.transport),
    MerchantRule(pattern: 'irctc', categoryKey: Cat.transport),
    MerchantRule(pattern: 'redbus', categoryKey: Cat.transport),
    MerchantRule(pattern: 'abhibus', categoryKey: Cat.transport),
    MerchantRule(pattern: 'indigo', categoryKey: Cat.transport),
    MerchantRule(pattern: 'air india', categoryKey: Cat.transport),
    MerchantRule(pattern: 'makemytrip', categoryKey: Cat.transport),
    MerchantRule(pattern: 'goibibo', categoryKey: Cat.transport),
    MerchantRule(pattern: 'yatra', categoryKey: Cat.transport),
    MerchantRule(pattern: 'metro', categoryKey: Cat.transport),
    MerchantRule(pattern: 'petrol', categoryKey: Cat.transport),
    MerchantRule(pattern: 'fuel', categoryKey: Cat.transport),
    MerchantRule(pattern: 'diesel', categoryKey: Cat.transport),
    MerchantRule(pattern: 'fastag', categoryKey: Cat.transport),
    MerchantRule(pattern: 'parking', categoryKey: Cat.transport),
    MerchantRule(pattern: 'auto fare', categoryKey: Cat.transport),
    MerchantRule(pattern: 'cab', categoryKey: Cat.transport),
    MerchantRule(pattern: 'toll', categoryKey: Cat.transport),

    // ---- bills & utilities ----
    MerchantRule(pattern: 'jio', categoryKey: Cat.bills),
    MerchantRule(pattern: 'airtel', categoryKey: Cat.bills),
    MerchantRule(pattern: 'vodafone', categoryKey: Cat.bills),
    MerchantRule(pattern: 'bsnl', categoryKey: Cat.bills),
    MerchantRule(pattern: 'electricity', categoryKey: Cat.bills),
    MerchantRule(pattern: 'wbsedcl', categoryKey: Cat.bills),
    MerchantRule(pattern: 'cesc', categoryKey: Cat.bills),
    MerchantRule(pattern: 'bescom', categoryKey: Cat.bills),
    MerchantRule(pattern: 'adani electricity', categoryKey: Cat.bills),
    MerchantRule(pattern: 'tata power', categoryKey: Cat.bills),
    MerchantRule(pattern: 'gas', categoryKey: Cat.bills),
    MerchantRule(pattern: 'indane', categoryKey: Cat.bills),
    MerchantRule(pattern: 'hp gas', categoryKey: Cat.bills),
    MerchantRule(pattern: 'bharat gas', categoryKey: Cat.bills),
    MerchantRule(pattern: 'water bill', categoryKey: Cat.bills),
    MerchantRule(pattern: 'broadband', categoryKey: Cat.bills),
    MerchantRule(pattern: 'act fibernet', categoryKey: Cat.bills),
    MerchantRule(pattern: 'jiofiber', categoryKey: Cat.bills),
    MerchantRule(pattern: 'dth', categoryKey: Cat.bills),
    MerchantRule(pattern: 'tata sky', categoryKey: Cat.bills),
    MerchantRule(pattern: 'dish tv', categoryKey: Cat.bills),
    MerchantRule(pattern: 'municipal', categoryKey: Cat.bills),
    MerchantRule(pattern: 'maintenance', categoryKey: Cat.bills),

    // ---- rent & housing ----
    MerchantRule(pattern: 'rent', categoryKey: Cat.rent),
    MerchantRule(pattern: 'landlord', categoryKey: Cat.rent),
    MerchantRule(pattern: 'house rent', categoryKey: Cat.rent),
    MerchantRule(pattern: 'nobroker', categoryKey: Cat.rent),
    MerchantRule(pattern: 'housing society', categoryKey: Cat.rent),

    // ---- health ----
    MerchantRule(pattern: 'apollo', categoryKey: Cat.health),
    MerchantRule(pattern: 'pharmeasy', categoryKey: Cat.health),
    MerchantRule(pattern: '1mg', categoryKey: Cat.health),
    MerchantRule(pattern: 'netmeds', categoryKey: Cat.health),
    MerchantRule(pattern: 'medplus', categoryKey: Cat.health),
    MerchantRule(pattern: 'wellness forever', categoryKey: Cat.health),
    MerchantRule(pattern: 'pharmacy', categoryKey: Cat.health),
    MerchantRule(pattern: 'medical', categoryKey: Cat.health),
    MerchantRule(pattern: 'hospital', categoryKey: Cat.health),
    MerchantRule(pattern: 'clinic', categoryKey: Cat.health),
    MerchantRule(pattern: 'diagnostic', categoryKey: Cat.health),
    MerchantRule(pattern: 'pathlab', categoryKey: Cat.health),
    MerchantRule(pattern: 'dr lal', categoryKey: Cat.health),
    MerchantRule(pattern: 'thyrocare', categoryKey: Cat.health),
    MerchantRule(pattern: 'dental', categoryKey: Cat.health),
    MerchantRule(pattern: 'cult fit', categoryKey: Cat.health),
    MerchantRule(pattern: 'cultfit', categoryKey: Cat.health),
    MerchantRule(pattern: 'gym', categoryKey: Cat.health),

    // ---- education ----
    MerchantRule(pattern: 'byju', categoryKey: Cat.education),
    MerchantRule(pattern: 'unacademy', categoryKey: Cat.education),
    MerchantRule(pattern: 'vedantu', categoryKey: Cat.education),
    MerchantRule(pattern: 'coursera', categoryKey: Cat.education),
    MerchantRule(pattern: 'udemy', categoryKey: Cat.education),
    MerchantRule(pattern: 'school fee', categoryKey: Cat.education),
    MerchantRule(pattern: 'college fee', categoryKey: Cat.education),
    MerchantRule(pattern: 'tuition', categoryKey: Cat.education),
    MerchantRule(pattern: 'coaching', categoryKey: Cat.education),
    MerchantRule(pattern: 'library', categoryKey: Cat.education),
    MerchantRule(pattern: 'exam fee', categoryKey: Cat.education),

    // ---- clothing ----
    MerchantRule(pattern: 'myntra', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'ajio', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'meesho', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'nykaa', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'pantaloons', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'westside', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'max fashion', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'decathlon', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'zara', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'h&m', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'lifestyle', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'fabindia', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'bata', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'footwear', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'garment', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'boutique', categoryKey: Cat.clothing),
    MerchantRule(pattern: 'tailor', categoryKey: Cat.clothing),

    // ---- shopping / marketplace (defaults to clothing only when apparel-ish) ----
    MerchantRule(pattern: 'amazon', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'flipkart', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'snapdeal', categoryKey: Cat.otherExpense),

    // ---- entertainment ----
    MerchantRule(pattern: 'netflix', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'hotstar', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'prime video', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'spotify', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'gaana', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'sonyliv', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'zee5', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'bookmyshow', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'pvr', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'inox', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'cinepolis', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'youtube', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'google play', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'playstore', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'steam', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'dream11', categoryKey: Cat.entertainment),
    MerchantRule(pattern: 'mpl', categoryKey: Cat.entertainment),

    // ---- recharge ----
    MerchantRule(pattern: 'recharge', categoryKey: Cat.recharge),
    MerchantRule(pattern: 'mobile recharge', categoryKey: Cat.recharge),
    MerchantRule(pattern: 'prepaid', categoryKey: Cat.recharge),
    MerchantRule(pattern: 'top up', categoryKey: Cat.recharge),
    MerchantRule(pattern: 'topup', categoryKey: Cat.recharge),

    // ---- EMI / loans / insurance ----
    MerchantRule(pattern: 'emi', categoryKey: Cat.emi),
    MerchantRule(pattern: 'loan', categoryKey: Cat.emi),
    MerchantRule(pattern: 'bajaj finance', categoryKey: Cat.emi),
    MerchantRule(pattern: 'bajaj finserv', categoryKey: Cat.emi),
    MerchantRule(pattern: 'hdb financial', categoryKey: Cat.emi),
    MerchantRule(pattern: 'insurance', categoryKey: Cat.emi),
    MerchantRule(pattern: 'lic', categoryKey: Cat.emi),
    MerchantRule(pattern: 'policybazaar', categoryKey: Cat.emi),
    MerchantRule(pattern: 'credit card payment', categoryKey: Cat.emi),

    // ---- wallets and payment rails ----
    // These arrive as the *merchant* when a wallet is the counterparty. They
    // carry no spending intent, so they land in "Other" rather than being
    // guessed into a real category.
    MerchantRule(pattern: 'paytm', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'phonepe', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'google pay', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'gpay', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'cred', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'mobikwik', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'freecharge', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'amazon pay', categoryKey: Cat.otherExpense),

    // ---- ATM & cash ----
    MerchantRule(pattern: 'withdrawn', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'cash withdrawal', categoryKey: Cat.otherExpense),
    MerchantRule(pattern: 'atm wdl', categoryKey: Cat.otherExpense),

    // ---- income ----
    MerchantRule(pattern: 'salary', categoryKey: Cat.salary),
    MerchantRule(pattern: 'sal cr', categoryKey: Cat.salary),
    MerchantRule(pattern: 'wages', categoryKey: Cat.salary),
    MerchantRule(pattern: 'payroll', categoryKey: Cat.salary),
    MerchantRule(pattern: 'freelance', categoryKey: Cat.freelance),
    MerchantRule(pattern: 'upwork', categoryKey: Cat.freelance),
    MerchantRule(pattern: 'fiverr', categoryKey: Cat.freelance),
    MerchantRule(pattern: 'client payment', categoryKey: Cat.freelance),
    MerchantRule(pattern: 'interest', categoryKey: Cat.interest),
    MerchantRule(pattern: 'int cr', categoryKey: Cat.interest),
    MerchantRule(pattern: 'fd interest', categoryKey: Cat.interest),
    MerchantRule(pattern: 'dividend', categoryKey: Cat.interest),
    MerchantRule(pattern: 'refund', categoryKey: Cat.otherIncome),
    MerchantRule(pattern: 'cashback', categoryKey: Cat.otherIncome),
    MerchantRule(pattern: 'reversal', categoryKey: Cat.otherIncome),
  ];
}
