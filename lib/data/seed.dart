/// First-run seed data — `docs/05-DATA-MODEL.md` §6.
///
/// Everything here is derived from code, not from a bundled SQL dump, so the
/// built-in categories, merchant patterns and sender allowlist can never drift
/// out of sync with the parser that consumes them. The rule engine's own list is
/// the single source of truth for `merchant_rules`; the allowlist is the single
/// source of truth for `sms_senders`.
///
/// Seeding is **idempotent**: it checks for existing categories first, so a
/// restore-from-backup or a hot restart never duplicates a row.
library;

import 'package:drift/drift.dart';

import '../capture/rule_engine.dart';
import '../capture/sender_allowlist.dart';
import 'db.dart';

/// What the last [seedDatabase] run did. Returned for tests and for the
/// first-run debug log — never shown to the user.
class SeedReport {
  const SeedReport({
    required this.categories,
    required this.accounts,
    required this.merchantRules,
    required this.senders,
    required this.ruleVersion,
    required this.alreadySeeded,
  });

  final int categories;
  final int accounts;
  final int merchantRules;
  final int senders;
  final int ruleVersion;
  final bool alreadySeeded;

  @override
  String toString() =>
      'SeedReport(categories: $categories, accounts: $accounts, '
      'rules: $merchantRules, senders: $senders, ruleVersion: $ruleVersion, '
      'alreadySeeded: $alreadySeeded)';
}

/// The 12 expense categories. Ids match the keys in [Cat], which is what lets a
/// merchant rule point straight at a category without a lookup table.
const List<_SeedCategory> _expenseCategories = <_SeedCategory>[
  _SeedCategory(
    id: Cat.food,
    nameEn: 'Food & Dining',
    nameHi: 'खाना-पीना',
    nameBn: 'খাবার ও রেস্তোরাঁ',
    icon: '🍽️',
    colorHex: '#FF7A59',
  ),
  _SeedCategory(
    id: Cat.grocery,
    nameEn: 'Groceries',
    nameHi: 'किराना',
    nameBn: 'মুদি ও বাজার',
    icon: '🛒',
    colorHex: '#14C8B8',
  ),
  _SeedCategory(
    id: Cat.transport,
    nameEn: 'Transport',
    nameHi: 'यातायात',
    nameBn: 'যাতায়াত',
    icon: '🚌',
    colorHex: '#6C4CF1',
  ),
  _SeedCategory(
    id: Cat.bills,
    nameEn: 'Bills & Utilities',
    nameHi: 'बिल और यूटिलिटी',
    nameBn: 'বিল ও ইউটিলিটি',
    icon: '💡',
    colorHex: '#F5B843',
  ),
  _SeedCategory(
    id: Cat.rent,
    nameEn: 'Rent & Housing',
    nameHi: 'किराया और मकान',
    nameBn: 'বাড়ি ভাড়া',
    icon: '🏠',
    colorHex: '#8B6BFF',
  ),
  _SeedCategory(
    id: Cat.health,
    nameEn: 'Health',
    nameHi: 'स्वास्थ्य',
    nameBn: 'স্বাস্থ্য',
    icon: '💊',
    colorHex: '#FF5A7A',
  ),
  _SeedCategory(
    id: Cat.education,
    nameEn: 'Education',
    nameHi: 'शिक्षा',
    nameBn: 'শিক্ষা',
    icon: '📚',
    colorHex: '#4C9AFF',
  ),
  _SeedCategory(
    id: Cat.clothing,
    nameEn: 'Clothing',
    nameHi: 'कपड़े',
    nameBn: 'পোশাক',
    icon: '👕',
    colorHex: '#FF6FB5',
  ),
  _SeedCategory(
    id: Cat.entertainment,
    nameEn: 'Entertainment',
    nameHi: 'मनोरंजन',
    nameBn: 'বিনোদন',
    icon: '🎬',
    colorHex: '#A855F7',
  ),
  _SeedCategory(
    id: Cat.recharge,
    nameEn: 'Recharge',
    nameHi: 'रिचार्ज',
    nameBn: 'রিচার্জ',
    icon: '📱',
    colorHex: '#22C55E',
  ),
  _SeedCategory(
    id: Cat.emi,
    nameEn: 'EMI & Loans',
    nameHi: 'ईएमआई और ऋण',
    nameBn: 'ইএমআই ও ঋণ',
    icon: '🏦',
    colorHex: '#F97316',
  ),
  _SeedCategory(
    id: Cat.otherExpense,
    nameEn: 'Other',
    nameHi: 'अन्य',
    nameBn: 'অন্যান্য',
    icon: '💳',
    colorHex: '#94A3B8',
  ),
];

/// The 6 income categories.
const List<_SeedCategory> _incomeCategories = <_SeedCategory>[
  _SeedCategory(
    id: Cat.salary,
    nameEn: 'Salary',
    nameHi: 'वेतन',
    nameBn: 'বেতন',
    icon: '💰',
    colorHex: '#0E9E90',
  ),
  _SeedCategory(
    id: Cat.business,
    nameEn: 'Business',
    nameHi: 'व्यापार',
    nameBn: 'ব্যবসা',
    icon: '🏪',
    colorHex: '#2FD4C4',
  ),
  _SeedCategory(
    id: Cat.freelance,
    nameEn: 'Freelance',
    nameHi: 'फ्रीलांस',
    nameBn: 'ফ্রিল্যান্স',
    icon: '💻',
    colorHex: '#4CC9F0',
  ),
  _SeedCategory(
    id: Cat.interest,
    nameEn: 'Interest',
    nameHi: 'ब्याज',
    nameBn: 'সুদ',
    icon: '📈',
    colorHex: '#10B981',
  ),
  _SeedCategory(
    id: Cat.gift,
    nameEn: 'Gift',
    nameHi: 'उपहार',
    nameBn: 'উপহার',
    icon: '🎁',
    colorHex: '#E879F9',
  ),
  _SeedCategory(
    id: Cat.otherIncome,
    nameEn: 'Other Income',
    nameHi: 'अन्य आय',
    nameBn: 'অন্যান্য আয়',
    icon: '✨',
    colorHex: '#A9A3D0',
  ),
];

const String kCashAccountId = 'acc-cash';

/// Keys written into `app_meta` on first run.
const Map<String, String> kDefaultMeta = <String, String>{
  'onboarded': 'false',
  'locale': 'en',
  'theme': 'system',
  'smsPermAsked': 'false',
  'notifPermAsked': 'false',
  'proStatus': 'free',
  'sessionCount': '0',
  'seedVersion': '1',
};

Future<SeedReport> seedDatabase(AppDb db) async {
  final existingCategories = await db.select(db.categories).get();
  final senders = SenderAllowlist.defaultEntries;
  final rules = RuleEngine.defaultRules;

  if (existingCategories.isNotEmpty) {
    return SeedReport(
      categories: existingCategories.length,
      accounts: (await db.select(db.accounts).get()).length,
      merchantRules: (await db.select(db.merchantRules).get()).length,
      senders: (await db.select(db.smsSenders).get()).length,
      ruleVersion: SenderAllowlist.ruleVersion,
      alreadySeeded: true,
    );
  }

  await db.transaction(() async {
    var sortOrder = 0;

    for (final c in <_SeedCategory>[
      ..._expenseCategories,
      ..._incomeCategories,
    ]) {
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: c.id,
              kind: c.kind,
              nameEn: c.nameEn,
              nameHi: c.nameHi,
              nameBn: c.nameBn,
              icon: c.icon,
              colorHex: c.colorHex,
              sortOrder: Value(sortOrder++),
              isSystem: const Value(true),
            ),
          );
    }

    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: kCashAccountId,
            // Stored in English; the UI renders the localized name from the id,
            // so a locale switch never leaves a half-translated account list.
            name: 'Cash',
            type: 'cash',
            openingBalancePaise: const Value(0),
            isDefault: const Value(true),
            colorHex: const Value('#14C8B8'),
            sortOrder: const Value(0),
          ),
        );

    await db.batch((b) {
      b.insertAll(
        db.merchantRules,
        rules.map(
          (r) => MerchantRulesCompanion.insert(
            id: 'rule-${_slug(r.pattern)}',
            pattern: r.pattern,
            categoryId: r.categoryKey,
            hits: Value(r.hits),
            confidence: Value(r.isUserDefined ? 1.0 : 0.6),
            isUserDefined: Value(r.isUserDefined),
          ),
        ),
      );
      b.insertAll(
        db.smsSenders,
        senders.map(
          (s) => SmsSendersCompanion.insert(
            id: 'sender-${_slug(s.senderId)}',
            senderId: s.senderId,
            bankName: s.bankName,
            parserKey: s.parserKey,
            enabled: Value(s.enabled),
            addedInRuleVersion: SenderAllowlist.ruleVersion,
          ),
        ),
      );
      b.insertAll(db.appMeta, <AppMetaCompanion>[
        for (final e in kDefaultMeta.entries)
          AppMetaCompanion.insert(key: e.key, value: e.value),
        AppMetaCompanion.insert(
          key: 'ruleVersion',
          value: '${SenderAllowlist.ruleVersion}',
        ),
      ]);
    });
  });

  return SeedReport(
    categories: _expenseCategories.length + _incomeCategories.length,
    accounts: 1,
    merchantRules: rules.length,
    senders: senders.length,
    ruleVersion: SenderAllowlist.ruleVersion,
    alreadySeeded: false,
  );
}

String _slug(String raw) =>
    raw.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');

class _SeedCategory {
  const _SeedCategory({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.nameBn,
    required this.icon,
    required this.colorHex,
  });

  final String id;
  final String nameEn;
  final String nameHi;
  final String nameBn;
  final String icon;
  final String colorHex;

  String get kind =>
      _incomeCategories.any((c) => c.id == id) ? 'income' : 'expense';
}
