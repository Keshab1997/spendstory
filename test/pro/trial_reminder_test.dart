/// The trial reminder (`docs/03 §S-22`: "trial reminder 1 day before").
///
/// Play charges on the eighth day of a yearly trial. The app says so once, on
/// the last day, the next time it is opened — and this is the test that keeps it
/// to *once*, on the *last day*, and about money only where money is due.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/db.dart';
import 'package:spendstory/pro/entitlement.dart';
import 'package:spendstory/pro/product_ids.dart';
import 'package:spendstory/pro/trial_reminder.dart';
import 'package:spendstory/ui/strings.dart';

final _bought = DateTime(2026, 10, 8, 9);

ProEntitlement _entitlement({
  ProPlan plan = ProPlan.yearly,
  ProSource source = ProSource.purchase,
  DateTime? at,
}) => ProEntitlement(
  plan: plan,
  confirmedAtMs: (at ?? _bought).millisecondsSinceEpoch,
  source: source,
);

/// The reminder, as a phone would see it: the title and body come from the real
/// string table, so a translation that is missing or empty fails here rather
/// than reaching somebody as a blank notification.
TrialReminder? _at(
  DateTime now, {
  ProEntitlement? entitlement,
  bool sent = false,
  String locale = 'en',
}) {
  final strings = SsStrings(locale);
  return trialReminderFor(
    entitlement: entitlement ?? _entitlement(),
    now: now,
    alreadySent: sent,
    strings: {
      'trialEndsTitle': strings['trialEndsTitle'],
      'trialEndsBody': strings['trialEndsBody'],
    },
  );
}

void main() {
  group('when it is owed', () {
    test('on the last day of the trial, not before', () {
      // Day one: the trial started this morning.
      expect(_at(_bought), isNull);
      expect(_at(_bought.add(const Duration(days: 3))), isNull);

      // The last day: six days in, with less than a day of trial left.
      final lastDay = _bought.add(const Duration(days: 6, hours: 1));
      expect(_at(lastDay), isNotNull);
    });

    test('and not after it, when the money is already Play’s business', () {
      final ended = _bought.add(const Duration(days: 7));
      expect(_at(ended), isNull);
      expect(_at(ended.add(const Duration(days: 30))), isNull);
    });

    test('exactly at the boundary, an hour early, it is still a reminder', () {
      final justUnder24h = _bought.add(
        const Duration(days: 7) - const Duration(minutes: 30),
      );
      expect(_at(justUnder24h), isNotNull);
    });
  });

  group('what it says', () {
    test('names the trial, and where to cancel — no price, no threat', () {
      final reminder = _at(_bought.add(const Duration(days: 6, hours: 12)))!;

      expect(reminder.title, 'Free trial ending');
      expect(reminder.body, contains('Play Store'));
      // The store's price is the store's to state. A notification that guesses
      // at one is a notification that can be wrong about money.
      expect(reminder.body, isNot(contains('₹')));
      expect(reminder.body, isNot(contains('699')));
    });

    test('uses one fixed id, so a second one replaces the first', () {
      expect(TrialReminder.notificationId, 6047);
    });
  });

  group('when it is not owed at all', () {
    test('once it has been sent', () {
      final when = _bought.add(const Duration(days: 6, hours: 12));
      expect(_at(when), isNotNull);
      expect(_at(when, sent: true), isNull);
    });

    test('for a monthly plan, which has no trial', () {
      final when = _bought.add(const Duration(days: 6, hours: 12));
      expect(
        _at(when, entitlement: _entitlement(plan: ProPlan.monthly)),
        isNull,
      );
    });

    test('for lifetime, which has nothing to end', () {
      final when = _bought.add(const Duration(days: 6, hours: 12));
      expect(
        _at(when, entitlement: _entitlement(plan: ProPlan.lifetime)),
        isNull,
      );
    });

    test('for a restore, which is not a fresh trial', () {
      // A reinstall during a trial restores the subscription with today's date.
      // Telling that user their trial ends tomorrow would be a lie that renews
      // itself every time they reinstall.
      final when = _bought.add(const Duration(days: 6, hours: 12));
      expect(
        _at(when, entitlement: _entitlement(source: ProSource.restore)),
        isNull,
      );
    });

    test('for somebody who owns nothing', () {
      final when = _bought.add(const Duration(days: 6, hours: 12));
      expect(
        trialReminderFor(
          entitlement: null,
          now: when,
          alreadySent: false,
          strings: const <String, String>{},
        ),
        isNull,
      );
    });
  });

  group('posting it', () {
    late AppDb db;
    late List<String> posted;

    setUp(() async {
      db = AppDb.memory();
      posted = <String>[];
    });
    tearDown(() async => db.close());

    ProviderContainer container({DateTime? now, bool canPost = true}) {
      final c = ProviderContainer(
        overrides: <Override>[
          appDbProvider.overrideWithValue(db),
          nowProvider.overrideWithValue(
            now ?? _bought.add(const Duration(days: 6, hours: 12)),
          ),
          notificationPosterProvider.overrideWithValue((id, title, body) async {
            posted.add('$id|$title|$body');
            return canPost;
          }),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('goes out once, and is written down', () async {
      final c = container();
      c.read(proEntitlementProvider.notifier).state = _entitlement();

      expect(await c.read(trialReminderRunnerProvider)(), isTrue);
      expect(posted, hasLength(1));
      expect(posted.single, startsWith('6047|'));
      expect(await db.meta(TrialReminder.key), 'sent');

      // A second run in the same launch, and after a restart.
      expect(await c.read(trialReminderRunnerProvider)(), isFalse);

      final restarted = container();
      restarted.read(proEntitlementProvider.notifier).state = _entitlement();
      expect(await restarted.read(trialReminderRunnerProvider)(), isFalse);
      expect(posted, hasLength(1));
    });

    test('a refused notification stays owed, like every other alert', () async {
      final c = container(canPost: false);
      c.read(proEntitlementProvider.notifier).state = _entitlement();

      expect(await c.read(trialReminderRunnerProvider)(), isFalse);
      expect(await db.meta(TrialReminder.key), isNull);

      // Owed, not lost: the next launch while the trial is still running
      // delivers it, and only then is it written down.
      final again = container();
      again.read(proEntitlementProvider.notifier).state = _entitlement();
      expect(await again.read(trialReminderRunnerProvider)(), isTrue);
      expect(posted, hasLength(2));
      expect(await db.meta(TrialReminder.key), 'sent');
    });

    test('nothing is posted on an ordinary day', () async {
      final c = container(now: _bought.add(const Duration(days: 2)));
      c.read(proEntitlementProvider.notifier).state = _entitlement();

      expect(await c.read(trialReminderRunnerProvider)(), isFalse);
      expect(posted, isEmpty);
      expect(await db.meta(TrialReminder.key), isNull);
    });

    test('goes out in Bengali when that is the language', () async {
      final c = ProviderContainer(
        overrides: <Override>[
          appDbProvider.overrideWithValue(db),
          localeProvider.overrideWith((ref) => 'bn'),
          nowProvider.overrideWithValue(
            _bought.add(const Duration(days: 6, hours: 12)),
          ),
          notificationPosterProvider.overrideWithValue((id, title, body) async {
            posted.add('$id|$title|$body');
            return true;
          }),
        ],
      );
      addTearDown(c.dispose);
      c.read(proEntitlementProvider.notifier).state = _entitlement();

      expect(await c.read(trialReminderRunnerProvider)(), isTrue);
      expect(posted.single, contains('ফ্রি ট্রায়াল'));
      expect(posted.single, contains('Play Store'));
      expect(
        _at(
          _bought.add(const Duration(days: 6, hours: 12)),
          locale: 'bn',
        )!.body,
        contains('Play Store'),
      );
    });
  });
}
