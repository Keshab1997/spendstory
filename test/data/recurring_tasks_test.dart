/// What the recurring pipeline owes (T-506, `docs/03 §S-19`).
///
/// The planner is pure, so the rules that matter — one payment per due date,
/// one reminder per payment, nothing for a switch that is off, nothing for a
/// schedule that the phone slept through — are tested directly rather than
/// inferred from a row that may or may not appear in a ledger.
///
/// The runner is tested through its seam: the notification poster is a
/// provider, so a test can record exactly what the app tried to send and what
/// it decided to write down as done.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/recurring_tasks.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/recurring_math.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/strings.dart';

final _now = DateTime(2026, 10, 7, 20, 42);
int _ms(DateTime d) => d.millisecondsSinceEpoch;
int at(int y, int m, int d, [int h = 9]) =>
    DateTime(y, m, d, h).millisecondsSinceEpoch;

RecurringRuleView _rule({
  String id = 'r1',
  String title = 'House rent',
  int amountPaise = 1800000, // ₹18,000
  TxnDirection direction = TxnDirection.expense,
  String? categoryId = 'rent',
  String? accountId = 'acc-hdfc',
  String frequency = 'monthly',
  int interval = 1,
  int? dayOfMonth = 7,
  required int nextDueAt,
  bool autoPost = false,
  int remindDaysBefore = kNoReminder,
}) => RecurringRuleView(
  id: id,
  title: title,
  amountPaise: amountPaise,
  direction: direction,
  categoryId: categoryId,
  accountId: accountId,
  frequency: frequency,
  interval: interval,
  dayOfMonth: dayOfMonth,
  nextDueAt: nextDueAt,
  autoPost: autoPost,
  remindDaysBefore: remindDaysBefore,
);

void main() {
  final strings = SsStrings('en');

  group('the identity of one payment', () {
    test('a post is remembered against its due date, not against today', () {
      final post = RecurringPost(
        rule: _rule(nextDueAt: at(2026, 10, 7)),
        dueMs: at(2026, 10, 7),
      );
      expect(post.key, 'recurring:r1:2026-10-07');
    });

    test('a reminder gets a stable, positive notification id', () {
      RecurringReminder reminder(int dueDay) => RecurringReminder(
        rule: _rule(nextDueAt: at(2026, 10, dueDay)),
        dueMs: at(2026, 10, dueDay),
        title: 'Upcoming payment',
        body: 'House rent',
      );

      final id = reminder(7).notificationId;
      expect(id, greaterThan(0));
      expect(reminder(7).notificationId, id); // same payment, same id
      expect(reminder(8).notificationId, isNot(id));
    });
  });

  group('payments that should be posted', () {
    test('a rule that posts itself is owed on its due date', () {
      final owed = dueRecurringPosts(
        rules: <RecurringRuleView>[
          _rule(nextDueAt: at(2026, 10, 7), autoPost: true),
        ],
        nowMs: _ms(_now),
        postedOn: const <String, String>{},
      );
      expect(owed, hasLength(1));
      expect(owed.single.dueMs, at(2026, 10, 7)); // the due date, not today
      expect(owed.single.rule.title, 'House rent');
    });

    test('a rule with the switch off is never posted, however due it is', () {
      final owed = dueRecurringPosts(
        rules: <RecurringRuleView>[_rule(nextDueAt: at(2026, 1, 7))],
        nowMs: _ms(_now),
        postedOn: const <String, String>{},
      );
      expect(owed, isEmpty);
    });

    test('nothing is owed before the day arrives', () {
      final owed = dueRecurringPosts(
        rules: <RecurringRuleView>[
          _rule(nextDueAt: at(2026, 10, 8), autoPost: true),
        ],
        nowMs: _ms(_now),
        postedOn: const <String, String>{},
      );
      expect(owed, isEmpty);
    });

    test('a payment already posted is not owed again', () {
      final owed = dueRecurringPosts(
        rules: <RecurringRuleView>[
          _rule(nextDueAt: at(2026, 10, 7), autoPost: true),
        ],
        nowMs: _ms(_now),
        postedOn: const <String, String>{
          'recurring:r1:2026-10-07': '2026-10-07',
        },
      );
      expect(owed, isEmpty);
    });

    test('next month is a different payment, even for the same rule', () {
      final owed = dueRecurringPosts(
        rules: <RecurringRuleView>[
          _rule(nextDueAt: at(2026, 11, 7), autoPost: true),
        ],
        nowMs: _ms(_now),
        postedOn: const <String, String>{
          'recurring:r1:2026-10-07': '2026-10-07',
        },
      );
      expect(owed, isEmpty, reason: 'November is not due yet');

      final later = dueRecurringPosts(
        rules: <RecurringRuleView>[
          _rule(nextDueAt: at(2026, 11, 7), autoPost: true),
        ],
        nowMs: _ms(DateTime(2026, 11, 7, 20, 42)),
        postedOn: const <String, String>{
          'recurring:r1:2026-10-07': '2026-10-07',
        },
      );
      expect(later, hasLength(1));
      expect(later.single.key, 'recurring:r1:2026-11-07');
    });

    test('a phone that slept through three months owes one rent, not three', () {
      final stale = _rule(
        nextDueAt: at(2026, 7, 7),
        dayOfMonth: 7,
        autoPost: true,
      );
      final owed = dueRecurringPosts(
        rules: <RecurringRuleView>[stale],
        nowMs: _ms(_now),
        postedOn: const <String, String>{},
      );
      expect(owed, hasLength(1));
      expect(owed.single.dueMs, at(2026, 7, 7));

      // …and the rule moves on from today, so tomorrow is not another backlog.
      final next = nextDueAfterPost(post: owed.single, nowMs: _ms(_now));
      expect(next, at(2026, 11, 7));
    });
  });

  group('what the next due date becomes after posting', () {
    test('it advances from today, never from the missed date', () {
      final post = RecurringPost(
        rule: _rule(nextDueAt: at(2026, 7, 7), dayOfMonth: 7),
        dueMs: at(2026, 7, 7),
      );
      expect(nextDueAfterPost(post: post, nowMs: _ms(_now)), at(2026, 11, 7));
    });

    test('a payment posted exactly on its due date moves one cycle on', () {
      final post = RecurringPost(
        rule: _rule(nextDueAt: at(2026, 10, 7), dayOfMonth: 7),
        dueMs: at(2026, 10, 7),
      );
      expect(nextDueAfterPost(post: post, nowMs: _ms(_now)), at(2026, 11, 7));
    });
  });

  group('reminders', () {
    test('the window opens on the chosen day and closes on the due date', () {
      final rule = _rule(nextDueAt: at(2026, 10, 10), remindDaysBefore: 3);

      // Three days before: the first day inside the window.
      expect(
        owedRecurringReminders(
          rules: <RecurringRuleView>[rule],
          strings: strings,
          locale: 'en',
          nowMs: at(2026, 10, 7, 9),
          sentOn: const <String, String>{},
        ),
        hasLength(1),
      );

      // One day earlier: nothing yet.
      expect(
        owedRecurringReminders(
          rules: <RecurringRuleView>[rule],
          strings: strings,
          locale: 'en',
          nowMs: at(2026, 10, 6, 9),
          sentOn: const <String, String>{},
        ),
        isEmpty,
      );

      // After the date: no accusation.
      expect(
        owedRecurringReminders(
          rules: <RecurringRuleView>[rule],
          strings: strings,
          locale: 'en',
          nowMs: at(2026, 10, 11, 9),
          sentOn: const <String, String>{},
        ),
        isEmpty,
      );
    });

    test('the body counts down, and says so on the day itself', () {
      String bodyFor(int nowMs) => owedRecurringReminders(
        rules: <RecurringRuleView>[
          _rule(nextDueAt: at(2026, 10, 10), remindDaysBefore: 3),
        ],
        strings: strings,
        locale: 'en',
        nowMs: nowMs,
        sentOn: const <String, String>{},
      ).single.body;

      expect(bodyFor(at(2026, 10, 8, 9)), 'House rent: ₹18,000 in 2 days');
      expect(bodyFor(at(2026, 10, 10, 22)), 'House rent: ₹18,000 due today');
    });

    test('no reminder means no reminder', () {
      expect(
        owedRecurringReminders(
          rules: <RecurringRuleView>[_rule(nextDueAt: at(2026, 10, 10))],
          strings: strings,
          locale: 'en',
          nowMs: at(2026, 10, 10, 9),
          sentOn: const <String, String>{},
        ),
        isEmpty,
      );
    });

    test('one nudge per payment: the rest of the window stays quiet', () {
      final rule = _rule(nextDueAt: at(2026, 10, 10), remindDaysBefore: 3);

      final first = owedRecurringReminders(
        rules: <RecurringRuleView>[rule],
        strings: strings,
        locale: 'en',
        nowMs: at(2026, 10, 8, 9),
        sentOn: const <String, String>{},
      ).single;

      // Sent yesterday, so today is quiet — even though the window is open.
      expect(
        owedRecurringReminders(
          rules: <RecurringRuleView>[rule],
          strings: strings,
          locale: 'en',
          nowMs: at(2026, 10, 9, 9),
          sentOn: <String, String>{first.key: '2026-10-08'},
        ),
        isEmpty,
      );

      // A record from a *different* payment does not silence this one.
      expect(
        owedRecurringReminders(
          rules: <RecurringRuleView>[rule],
          strings: strings,
          locale: 'en',
          nowMs: at(2026, 10, 9, 9),
          sentOn: const <String, String>{
            'recurring-reminder:r1:2026-09-10': '2026-09-08',
          },
        ),
        hasLength(1),
      );
    });
  });

  group('the runner', () {
    late List<(int, String, String)> sent;

    ProviderContainer containerWith({
      required List<RecurringRuleView> rules,

      /// [refuseFirst] models a device that says no once — a permission the
      /// user has to grant, or a notification the system dropped.
      bool refuseFirst = false,
      DateTime? now,
    }) {
      sent = <(int, String, String)>[];
      final container = ProviderContainer(
        overrides: <Override>[
          appDbProvider.overrideWithValue(null),
          nowProvider.overrideWithValue(now ?? _now),
          localeProvider.overrideWith((ref) => 'en'),
          bootProvider.overrideWith(
            (ref) async =>
                BootState(onboarded: true, demoMode: true, locale: 'en'),
          ),
          recurringProvider.overrideWith((ref) async => rules),
          // The ledger the app would show: whatever this session added.
          transactionsProvider.overrideWith(
            (ref) async => ref.watch(sessionAddedProvider),
          ),
          notificationPosterProvider.overrideWith(
            (ref) => (id, title, body) async {
              sent.add((id, title, body));
              return !(refuseFirst && sent.length == 1);
            },
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('a due payment reaches the ledger once, and the rule moves on', () async {
      final container = containerWith(
        rules: <RecurringRuleView>[
          _rule(nextDueAt: at(2026, 10, 6), autoPost: true),
        ],
      );

      final first = await container.read(recurringRunnerProvider)();
      expect(first.posted, hasLength(1));
      expect(first.reminded, isEmpty);

      final ledger = await container.read(transactionsProvider.future);
      expect(ledger, hasLength(1));
      expect(ledger.single.merchant, 'House rent');
      expect(ledger.single.amountPaise, 1800000);
      expect(ledger.single.accountId, 'acc-hdfc');
      expect(ledger.single.categoryId, 'rent');
      expect(ledger.single.source, TxSource.recurring.wire);
      // The row belongs to the day the money was due, not the day the app woke.
      expect(ledger.single.occurredAtMs, at(2026, 10, 6));

      // The check runs again on every ledger change — and stays quiet.
      final second = await container.read(recurringRunnerProvider)();
      expect(second.posted, isEmpty);
      expect(await container.read(transactionsProvider.future), hasLength(1));

      expect(container.read(sessionRecurringPostedProvider), {
        'recurring:r1:2026-10-06': '2026-10-07',
      });
      expect(
        container.read(sessionRecurringPatchesProvider)['r1']!.nextDueAt,
        at(2026, 11, 7),
      );
    });

    test('a reminder goes out once, and a refusal is not recorded', () async {
      final container = containerWith(
        rules: <RecurringRuleView>[
          _rule(nextDueAt: at(2026, 10, 10), remindDaysBefore: 3),
        ],
        refuseFirst: true,
      );

      // The device said no, so nothing is written down as delivered…
      final refused = await container.read(recurringRunnerProvider)();
      expect(refused.reminded, isEmpty);
      expect(sent, hasLength(1));
      expect(container.read(sessionRecurringRemindedProvider), isEmpty);

      // …and the next pass tries again.
      final again = await container.read(recurringRunnerProvider)();
      expect(again.reminded, hasLength(1));
      expect(sent, hasLength(2));
      expect(again.reminded.single.title, 'Upcoming payment');
      expect(again.reminded.single.body, 'House rent: ₹18,000 in 3 days');
      expect(container.read(sessionRecurringRemindedProvider), {
        'recurring-reminder:r1:2026-10-10': '2026-10-07',
      });
    });

    test('a rule that posted itself is not also reminded about', () async {
      final container = containerWith(
        rules: <RecurringRuleView>[
          _rule(
            nextDueAt: at(2026, 10, 7),
            autoPost: true,
            remindDaysBefore: 0,
          ),
        ],
      );

      final run = await container.read(recurringRunnerProvider)();
      expect(run.posted, hasLength(1));
      expect(run.reminded, isEmpty);
      expect(sent, isEmpty);
      expect(container.read(sessionRecurringRemindedProvider), isEmpty);
    });

    test(
      'next month\'s rent posts even though last month\'s is recorded',
      () async {
        final container = containerWith(
          rules: <RecurringRuleView>[
            // The rule was moved on by the October run, which is written down.
            _rule(nextDueAt: at(2026, 11, 7), autoPost: true),
          ],
          now: DateTime(2026, 11, 7, 9, 30),
        );
        container.read(sessionRecurringPostedProvider.notifier).state =
            <String, String>{'recurring:r1:2026-10-07': '2026-10-07'};

        final run = await container.read(recurringRunnerProvider)();
        expect(run.posted, hasLength(1));
        expect(run.posted.single.key, 'recurring:r1:2026-11-07');
      },
    );

    test('nothing to do is not an error', () async {
      final container = containerWith(rules: const <RecurringRuleView>[]);
      final run = await container.read(recurringRunnerProvider)();
      expect(run.posted, isEmpty);
      expect(run.reminded, isEmpty);
      expect(sent, isEmpty);
    });
  });
}
