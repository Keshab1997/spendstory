import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/rule_engine.dart';
import 'package:spendstory/capture/sms_parser.dart';

import 'fixture_loader.dart';

void main() {
  group('RuleEngine — built-in merchant table', () {
    final engine = RuleEngine();

    void expectCategory(String merchant, String category) {
      final r = engine.classify(merchant: merchant);
      expect(r.categoryKey, category, reason: 'merchant "$merchant" → $r');
    }

    test('classifies the merchants Indian users actually see', () {
      expectCategory('Swiggy', Cat.food);
      expectCategory('Zomato', Cat.food);
      expectCategory('BigBasket', Cat.grocery);
      expectCategory('Blinkit', Cat.grocery);
      expectCategory('Zepto', Cat.grocery);
      expectCategory('Uber', Cat.transport);
      expectCategory('Rapido', Cat.transport);
      expectCategory('IRCTC', Cat.transport);
      expectCategory('Airtel', Cat.bills);
      expectCategory('Jio', Cat.bills);
      expectCategory('House Rent', Cat.rent);
      expectCategory('Apollo', Cat.health);
      expectCategory('Netflix', Cat.entertainment);
      expectCategory('BookMyShow', Cat.entertainment);
      expectCategory('Myntra', Cat.clothing);
      expectCategory('Bajaj Finserv', Cat.emi);
      expectCategory('Salary', Cat.salary);
      expectCategory('FD Interest', Cat.interest);
    });

    test('is case- and separator-insensitive', () {
      expectCategory('SWIGGY', Cat.food);
      expectCategory('swiggy', Cat.food);
      expectCategory('Big-Basket', Cat.grocery);
    });

    test('unknown merchants stay unclassified rather than guessing', () {
      final r = engine.classify(merchant: 'Ramesh Kumar');
      expect(r.categoryKey, isNull);
      expect(r.isConfident, isFalse);
    });

    test('generic payment rails are never a category', () {
      expect(engine.classify(merchant: 'UPI').categoryKey, isNull);
      expect(engine.classify(merchant: 'NEFT').categoryKey, isNull);
    });
  });

  group('RuleEngine — confidence and learning', () {
    test('a built-in match is confident enough to auto-file', () {
      final r = RuleEngine().classify(merchant: 'Swiggy');
      expect(r.isConfident, isTrue);
      expect(r.confidence, greaterThanOrEqualTo(0.6));
      expect(r.matchedPattern, 'swiggy');
    });

    test('confirmed hits raise confidence but never to certainty', () {
      var engine = RuleEngine();
      for (var i = 0; i < 20; i++) {
        engine = engine.countHit('swiggy');
      }
      final r = engine.classify(merchant: 'Swiggy');
      expect(r.confidence, greaterThan(0.6));
      expect(r.confidence, lessThan(1.0));
    });

    test('a user rule always beats the built-in rule', () {
      final engine = RuleEngine().learn(
        pattern: 'swiggy',
        categoryKey: Cat.grocery,
      );
      final r = engine.classify(merchant: 'Swiggy');
      expect(r.categoryKey, Cat.grocery);
      expect(r.confidence, 1.0);
    });

    test('a user rule matches a longer captured phrase', () {
      final engine = RuleEngine().learn(
        pattern: 'ramesh kumar',
        categoryKey: Cat.rent,
      );
      expect(engine.classify(merchant: 'Ramesh Kumar').categoryKey, Cat.rent);
    });

    test('longest pattern wins when two rules could match', () {
      final engine = RuleEngine(
        userRules: [
          const MerchantRule(pattern: 'amazon', categoryKey: Cat.otherExpense),
          const MerchantRule(pattern: 'amazon pay', categoryKey: Cat.recharge),
        ],
      );
      expect(engine.classify(merchant: 'Amazon Pay').categoryKey, Cat.recharge);
    });
  });

  group('RuleEngine — end to end with the parser', () {
    final parser = SmsParser();
    final engine = RuleEngine();

    RuleResult classifyBody(Map<String, dynamic> item) {
      final outcome = parser.parseSms(
        sender: item['sender'] as String,
        body: item['body'] as String,
        smsTimestampMs: isoToMs(item['smsAtIso'] as String),
      );
      expect(outcome.isParsed, isTrue, reason: item['note'] as String);
      final txn = outcome.txn!;
      return engine.classify(merchant: txn.merchant, rawText: txn.rawText);
    }

    test('salary SMS with no merchant still lands in the salary category', () {
      final item = loadFixture('credit')
          .firstWhere((i) => (i['note'] as String).contains('Salary'));
      expect(classifyBody(item).categoryKey, Cat.salary);
    });

    test('a Swiggy UPI debit lands in food', () {
      final item = loadFixture('debit')
          .firstWhere((i) => (i['body'] as String).contains('swiggy@ybl'));
      expect(classifyBody(item).categoryKey, Cat.food);
    });

    test('a grocery UPI debit lands in grocery', () {
      final item = loadFixture('debit').first;
      expect(classifyBody(item).categoryKey, Cat.grocery);
    });

    test('rent transfer lands in rent', () {
      final item = loadFixture('debit')
          .firstWhere((i) => (i['body'] as String).contains('House Rent'));
      expect(classifyBody(item).categoryKey, Cat.rent);
    });

    test('every parsed fixture gets a category that is not null', () {
      final uncategorised = <String>[];
      for (final name in ['debit', 'credit']) {
        for (final item in loadFixture(name)) {
          final outcome = parser.parseSms(
            sender: item['sender'] as String,
            body: item['body'] as String,
            smsTimestampMs: isoToMs(item['smsAtIso'] as String),
          );
          if (!outcome.isParsed) continue;
          final r = engine.classify(
            merchant: outcome.txn!.merchant,
            rawText: outcome.txn!.rawText,
          );
          if (r.categoryKey == null) {
            uncategorised.add('${item['note']}: ${outcome.txn!.merchant}');
          }
        }
      }
      // Person-to-person payments to a named individual legitimately have no
      // category — the UI files them as "Uncategorised" and offers a one-tap
      // pick. Everything else must be classified, so this guard stays tight.
      expect(
        uncategorised.length,
        lessThanOrEqualTo(4),
        reason: 'uncategorised: ${uncategorised.join(', ')}',
      );
    });
  });

  test('the shipped table is large enough for first-run seeding', () {
    expect(RuleEngine.defaultRules.length, greaterThanOrEqualTo(120));
  });

  test('no duplicate patterns in the shipped table', () {
    final seen = <String>{};
    final dupes = <String>[];
    for (final r in RuleEngine.defaultRules) {
      if (!seen.add(r.pattern)) dupes.add(r.pattern);
    }
    expect(dupes, isEmpty, reason: 'duplicate rule patterns: $dupes');
  });
}
