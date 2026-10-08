/// Budget alerts (T-505).
///
/// The planner is pure, so the rules that matter — one warning per budget per
/// run, nothing for a switched-off threshold, nothing twice in a day — are
/// tested directly rather than inferred from a notification that may or may not
/// appear on a device.
///
/// The runner is tested through its seam: the sender is a provider, so a test
/// can record exactly what the app tried to post and what it decided to write
/// down as delivered.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/data/budget_alerts.dart';
import 'package:spendstory/domain/budget_math.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/strings.dart';

final _now = DateTime(2026, 10, 7, 20, 42);
int _ms(DateTime d) => d.millisecondsSinceEpoch;

BudgetView _budget({
  String id = 'b1',
  String? categoryId = 'food',
  int amountPaise = 100000, // ₹1,000
  bool alertAt80 = true,
  bool alertAt100 = true,
}) => BudgetView(
  id: id,
  categoryId: categoryId,
  period: 'monthly',
  amountPaise: amountPaise,
  startDay: 1,
  alertAt80: alertAt80,
  alertAt100: alertAt100,
);

TxnView _txn(String id, int paise, {String categoryId = 'food'}) => TxnView(
  id: id,
  amountPaise: paise,
  direction: TxnDirection.expense,
  occurredAtMs: _ms(_now),
  categoryId: categoryId,
);

/// A status for a budget whose spend is [spentPaise] out of its limit.
BudgetStatus _status({
  String id = 'b1',
  String? categoryId = 'food',
  int amountPaise = 100000,
  required int spentPaise,
  bool alertAt80 = true,
  bool alertAt100 = true,
}) => budgetStatus(
  txns: <TxnView>[_txn('s', spentPaise, categoryId: categoryId ?? 'food')],
  budget: _budget(
    id: id,
    categoryId: categoryId,
    amountPaise: amountPaise,
    alertAt80: alertAt80,
    alertAt100: alertAt100,
  ),
  nowMs: _ms(_now),
);

const _categories = <String, CategoryView>{
  'food': CategoryView(
    id: 'food',
    kind: TxnDirection.expense,
    nameEn: 'Food',
    nameHi: 'खाना',
    nameBn: 'খাবার',
    icon: '🍜',
    colorHex: '#F5B843',
  ),
};

List<BudgetAlert> _owed(
  List<BudgetStatus> statuses, {
  String locale = 'en',
  Map<String, String> sentOn = const <String, String>{},
  String today = '2026-10-07',
}) => owedBudgetAlerts(
  statuses: statuses,
  strings: SsStrings(locale),
  locale: locale,
  today: today,
  sentOn: sentOn,
  categories: _categories,
);

void main() {
  // The sender test talks to the real MethodChannel, which needs the services
  // binding; without it the failure is a `StateError` from Flutter itself
  // rather than the MissingPluginException the bridge is built to survive.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('alertDay', () {
    test('is the local date, zero-padded', () {
      expect(alertDay(DateTime(2026, 10, 7, 23, 59)), '2026-10-07');
      expect(alertDay(DateTime(2026, 1, 3, 0, 5)), '2026-01-03');
    });
  });

  group('the thresholds', () {
    test('says nothing under 80%', () {
      expect(_owed([_status(spentPaise: 79000)]), isEmpty);
    });

    test('warns once at 80%, with what is left', () {
      final owed = _owed([_status(spentPaise: 80000)]);
      expect(owed, hasLength(1));
      expect(owed.single.level, BudgetAlertLevel.at80);
      expect(owed.single.title, '80% of your budget is used');
      expect(owed.single.body, 'Food: ₹200 left');
    });

    test('crossing gets the crossed alert, never both', () {
      final owed = _owed([_status(spentPaise: 100000)]);
      expect(owed, hasLength(1));
      expect(owed.single.level, BudgetAlertLevel.at100);
      expect(owed.single.title, 'Budget crossed');
      expect(owed.single.body, 'Food: ₹0 over');

      final over = _owed([_status(spentPaise: 128000)]);
      expect(over.single.level, BudgetAlertLevel.at100);
      expect(over.single.body, 'Food: ₹280 over');
    });

    test(
      'a switched-off threshold stays silent, and the next one still fires',
      () {
        expect(
          _owed([_status(spentPaise: 85000, alertAt80: false)]),
          isEmpty,
          reason: '80% is off, and 85% has not crossed yet',
        );
        final crossed = _owed([_status(spentPaise: 110000, alertAt80: false)]);
        expect(crossed, hasLength(1));
        expect(crossed.single.level, BudgetAlertLevel.at100);

        expect(
          _owed([_status(spentPaise: 110000, alertAt100: false)]),
          isEmpty,
          reason: 'crossing is off; the 80% warning was not asked for either',
        );
      },
    );

    test('an untouched budget is not a warning', () {
      expect(_owed([_status(spentPaise: 0)]), isEmpty);
    });

    test('the overall cap is named, not categorised', () {
      final owed = _owed([_status(categoryId: null, spentPaise: 90000)]);
      expect(owed.single.body, 'Overall monthly budget: ₹100 left');
    });

    test('the copy is localised, digits and all', () {
      final owed = _owed([_status(spentPaise: 80000)], locale: 'bn');
      expect(owed.single.title, SsStrings('bn')['alert80Title']);
      expect(owed.single.body, contains('২০০'));
      expect(owed.single.body, isNot(contains('⟦')));
    });
  });

  group('the once-a-day cap', () {
    test('an alert already delivered today is not repeated', () {
      final status = _status(spentPaise: 85000);
      final key = _owed([status]).single.key;

      expect(_owed([status], sentOn: {key: '2026-10-07'}), isEmpty);
      expect(
        _owed([status], sentOn: {key: '2026-10-06'}),
        hasLength(1),
        reason: 'yesterday does not excuse today',
      );
    });

    test('80% and 100% are separate warnings on separate days', () {
      final at80 = _owed([_status(spentPaise: 85000)]).single;
      final at100 = _owed([_status(spentPaise: 110000)]).single;

      expect(at80.key, 'budget:b1:80');
      expect(at100.key, 'budget:b1:100');
      expect(
        _owed([_status(spentPaise: 110000)], sentOn: {at80.key: '2026-10-07'}),
        hasLength(1),
        reason: 'crossing is news even if the 80% warning already went out',
      );
    });

    test('each budget keeps its own record', () {
      final a = _status(id: 'a', categoryId: 'food', spentPaise: 85000);
      final b = _status(id: 'b', categoryId: 'food', spentPaise: 85000);
      final owed = _owed([a, b], sentOn: {'budget:a:80': '2026-10-07'});

      expect(owed, hasLength(1));
      expect(owed.single.budgetId, 'b');
    });

    test('the same alert always carries the same notification id', () {
      final first = _owed([_status(spentPaise: 85000)]).single;
      final second = _owed([_status(spentPaise: 85000)]).single;
      expect(first.notificationId, second.notificationId);
      expect(first.notificationId, isNonNegative);
    });
  });

  group('the sender', () {
    test('without a host nothing is reported as delivered', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ok = await container.read(budgetAlertSenderProvider)(
        const BudgetAlert(
          budgetId: 'b1',
          level: BudgetAlertLevel.at80,
          title: '80% of your budget is used',
          body: 'Food: ₹200 left',
        ),
      );

      expect(
        ok,
        isFalse,
        reason:
            'flutter test and the web have no Android host, so the alert '
            'stays owed instead of being written down as sent',
      );
    });
  });

  group('the runner', () {
    late List<BudgetAlert> posted;

    ProviderContainer containerWith({
      required List<BudgetView> budgets,
      required List<TxnView> ledger,
      bool deliver = true,
      DateTime? now,
    }) {
      posted = <BudgetAlert>[];
      final container = ProviderContainer(
        overrides: <Override>[
          appDbProvider.overrideWithValue(null),
          nowProvider.overrideWithValue(now ?? _now),
          localeProvider.overrideWith((ref) => 'en'),
          bootProvider.overrideWith(
            (ref) async =>
                BootState(onboarded: true, demoMode: true, locale: 'en'),
          ),
          categoriesProvider.overrideWith(
            (ref) async => _categories.values.toList(),
          ),
          budgetsProvider.overrideWith((ref) async => budgets),
          transactionsProvider.overrideWith((ref) async => ledger),
          budgetAlertSenderProvider.overrideWith(
            (ref) => (alert) async {
              posted.add(alert);
              return deliver;
            },
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('posts what is owed, once, and remembers the day', () async {
      final container = containerWith(
        budgets: <BudgetView>[_budget(amountPaise: 100000)],
        ledger: <TxnView>[_txn('t1', 85000)],
      );

      final first = await container.read(budgetAlertRunnerProvider)();
      expect(first, hasLength(1));
      expect(posted, hasLength(1));
      expect(posted.single.body, 'Food: ₹150 left');

      // The ledger changed, so the check runs again — and stays quiet.
      final second = await container.read(budgetAlertRunnerProvider)();
      expect(second, isEmpty);
      expect(posted, hasLength(1));

      final session = container.read(sessionAlertsSentProvider);
      expect(session, {'budget:b1:80': '2026-10-07'});
    });

    test('a fresh day sends again', () async {
      final container = containerWith(
        budgets: <BudgetView>[_budget(amountPaise: 100000)],
        ledger: <TxnView>[_txn('t1', 85000)],
        now: _now.add(const Duration(days: 1)),
      );

      await container.read(budgetAlertRunnerProvider)();
      expect(posted, hasLength(1));
    });

    test('a budget that was never touched posts nothing', () async {
      final container = containerWith(
        budgets: <BudgetView>[_budget(amountPaise: 100000)],
        ledger: <TxnView>[_txn('t1', 12000)],
      );

      expect(await container.read(budgetAlertRunnerProvider)(), isEmpty);
      expect(posted, isEmpty);
    });

    test('nothing is recorded as delivered when the host refuses it', () async {
      final container = containerWith(
        budgets: <BudgetView>[_budget(amountPaise: 100000)],
        ledger: <TxnView>[_txn('t1', 85000)],
        deliver: false,
      );

      expect(await container.read(budgetAlertRunnerProvider)(), isEmpty);
      expect(posted, hasLength(1), reason: 'it was tried');
      expect(
        container.read(sessionAlertsSentProvider),
        isEmpty,
        reason: 'a notification that did not go out is still owed',
      );
    });

    test('no budgets means no work at all', () async {
      final container = containerWith(
        budgets: const <BudgetView>[],
        ledger: <TxnView>[_txn('t1', 999000)],
      );

      expect(await container.read(budgetAlertRunnerProvider)(), isEmpty);
      expect(posted, isEmpty);
    });
  });
}
