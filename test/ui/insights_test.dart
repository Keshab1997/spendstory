/// S-17 Insights (T-504).
///
/// The promise of this screen is that its numbers agree with the rest of the
/// app: the same ledger, the same rupees, one window at a time. So the tests
/// check the arithmetic (each period totals what it should), the part a person
/// actually touches (the donut answers for the slice they aimed at), and the
/// two things that would be easy to fake — the comparison and the "pattern"
/// sentence, which must change when the data changes and stay quiet when it
/// does not.
///
/// The period maths sits behind `nowProvider`, so a fixed Wednesday is dropped
/// in and the week/month/year windows stop being a moving target.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/components/money.dart';
import 'package:spendstory/ui/screens/insights_screen.dart';
import 'package:spendstory/ui/screens/pro_screen.dart';
import 'package:spendstory/ui/theme.dart';

/// Wednesday, 7 October 2026. The month window is Oct 1–7, the week window runs
/// Mon Oct 5 → Wed Oct 7, and the comparison window is September.
final _now = DateTime(2026, 10, 7, 20, 42);
int _ms(DateTime d) => d.millisecondsSinceEpoch;

TxnView _txn({
  required String id,
  required int paise,
  required DateTime at,
  String? merchant,
  String? categoryId,
  TxnDirection direction = TxnDirection.expense,
}) => TxnView(
  id: id,
  amountPaise: paise,
  direction: direction,
  occurredAtMs: _ms(at),
  merchant: merchant,
  categoryId: categoryId,
);

/// October so far: grocery ₹1,500 (Mon ₹1,000 BigBasket + Tue ₹500 More),
/// food ₹600 (Sat ₹300 + today ₹300, both Chaiwala), salary ₹50,000.
/// September: grocery ₹900, food ₹600, salary ₹50,000.
///
/// Picked so every finding has one definite answer: expenses are up 40%, income
/// is flat, grocery is the biggest jump (+67%), the three merchants rank
/// ₹1,000 → ₹600 → ₹500, and the weekday/weekend averages are close enough that
/// the screen must *not* claim weekends cost more.
final _ledger = <TxnView>[
  _txn(
    id: 'g-mon',
    paise: 100000,
    at: DateTime(2026, 10, 5, 13),
    merchant: 'BigBasket',
    categoryId: 'grocery',
  ),
  _txn(
    id: 'g-tue',
    paise: 50000,
    at: DateTime(2026, 10, 6, 19),
    merchant: 'More Supermarket',
    categoryId: 'grocery',
  ),
  _txn(
    id: 'f-sat',
    paise: 30000,
    at: DateTime(2026, 10, 3, 9),
    merchant: 'Chaiwala',
    categoryId: 'food',
  ),
  _txn(
    id: 'f-today',
    paise: 30000,
    at: DateTime(2026, 10, 7, 8),
    merchant: 'Chaiwala',
    categoryId: 'food',
  ),
  _txn(
    id: 'in-oct',
    paise: 5000000,
    at: DateTime(2026, 10, 2, 10),
    merchant: 'Payroll',
    categoryId: 'salary',
    direction: TxnDirection.income,
  ),
  _txn(
    id: 'g-sep',
    paise: 90000,
    at: DateTime(2026, 9, 10, 12),
    merchant: 'BigBasket',
    categoryId: 'grocery',
  ),
  _txn(
    id: 'f-sep',
    paise: 60000,
    at: DateTime(2026, 9, 12, 20),
    merchant: 'Chaiwala',
    categoryId: 'food',
  ),
  _txn(
    id: 'in-sep',
    paise: 5000000,
    at: DateTime(2026, 9, 2, 10),
    merchant: 'Payroll',
    categoryId: 'salary',
    direction: TxnDirection.income,
  ),
];

const List<CategoryView> _categories = <CategoryView>[
  CategoryView(
    id: 'grocery',
    kind: TxnDirection.expense,
    nameEn: 'Grocery',
    nameHi: 'किराना',
    nameBn: 'বাজার',
    icon: '🛒',
    colorHex: '#14C8B8',
  ),
  CategoryView(
    id: 'food',
    kind: TxnDirection.expense,
    nameEn: 'Food',
    nameHi: 'खाना',
    nameBn: 'খাবার',
    icon: '🍜',
    colorHex: '#F5B843',
  ),
  CategoryView(
    id: 'salary',
    kind: TxnDirection.income,
    nameEn: 'Salary',
    nameHi: 'वेतन',
    nameBn: 'বেতন',
    icon: '💰',
    colorHex: '#6C4CF1',
  ),
];

List<Override> _overrides({
  String locale = 'en',
  List<TxnView> ledger = const <TxnView>[],
  bool isPro = false,
}) => <Override>[
  appDbProvider.overrideWithValue(null),
  bootProvider.overrideWith(
    (ref) async => BootState(onboarded: true, demoMode: true, locale: locale),
  ),
  localeProvider.overrideWith((ref) => locale),
  nowProvider.overrideWithValue(_now),
  proStatusProvider.overrideWith((ref) => isPro),
  categoriesProvider.overrideWith((ref) async => _categories),
  transactionsProvider.overrideWith((ref) async => ledger),
];

/// The screen on its own — fast, and enough for everything that lives inside it.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String locale = 'en',
  Size size = const Size(390, 844),
  double textScale = 1.0,
  List<TxnView>? ledger,
  bool isPro = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: _overrides(
      locale: locale,
      ledger: ledger ?? _ledger,
      isPro: isPro,
    ),
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSsTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const InsightsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// The real app and the real router — for the route itself and for the taps
/// that leave the screen.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  bool isPro = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: _overrides(ledger: _ledger, isPro: isPro),
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SpendStoryApp(),
    ),
  );
  await tester.pumpAndSettle();
  container.read(routerProvider).go('/insights');
  await tester.pumpAndSettle();
  return container;
}

/// Scrolls [finder] into view. Everything in the screen's column is built even
/// when it is below the fold, so this is enough to make it tappable.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// The number in the middle of the donut. The window total also appears in the
/// "this month vs last" card, so the centre has to be matched where it lives.
Finder _donutTotal(String text) =>
    find.descendant(of: find.byType(DonutChart), matching: find.text(text));

/// A point on the donut ring, [degrees] clockwise from twelve o'clock.
Offset _ringPoint(WidgetTester tester, double degrees) {
  final centre = tester.getCenter(find.byType(DonutChart));
  final radians = degrees * math.pi / 180;
  const radius = 70.0; // between the 66px inner edge and the 84px outer edge
  return centre +
      Offset(radius * math.sin(radians), -radius * math.cos(radians));
}

void main() {
  group('S-17 the route', () {
    testWidgets('resolves to the real screen', (tester) async {
      await _pumpApp(tester);
      expect(find.byType(InsightsScreen), findsOneWidget);
    });

    testWidgets('says where you are and offers all four windows', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });
  });

  group('S-17 the window', () {
    testWidgets('month is the default and totals October', (tester) async {
      await _pump(tester);
      // ₹1,500 grocery + ₹600 food. The ₹50,000 salary is income, not spending.
      expect(_donutTotal('₹2,100'), findsOneWidget);
    });

    testWidgets('week narrows to Monday onwards', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      // Saturday's ₹300 of food drops out: 1,000 + 500 + 300.
      expect(_donutTotal('₹1,800'), findsOneWidget);
      expect(_donutTotal('₹2,100'), findsNothing);
    });

    testWidgets('year reaches back through September', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      expect(_donutTotal('₹3,600'), findsOneWidget); // 2,100 + 900 + 600
    });

    testWidgets('custom is Pro: the third tap goes to the paywall', (
      tester,
    ) async {
      await _pumpApp(tester);

      // §S-22 lets the app offer the paywall on the third tap at a Pro-locked
      // insight, and not before. The first two taps still answer — with the
      // reason, in the app's own words — because a chip that does nothing
      // reads as broken.
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsNothing);
      // A snackbar, not a route: the wording is the same as the Pro card's, so
      // the finder has to say which one it means.
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('are part of Pro'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsNothing);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsOneWidget);
    });

    testWidgets('and only one paywall a session, however many taps', (
      tester,
    ) async {
      await _pumpApp(tester);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Custom'));
        await tester.pumpAndSettle();
      }
      expect(find.byType(ProScreen), findsOneWidget);

      // Back out of it; the session has had its one offer.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsNothing);
    });

    testWidgets('with Pro, custom offers a date range', (tester) async {
      await _pump(tester, isPro: true);
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      // The chip, the heading that names the window, and the row offering to
      // pick the dates.
      expect(find.text('Custom'), findsNWidgets(3));
      expect(find.text('— – —'), findsOneWidget);
    });
  });

  group('S-17 the donut', () {
    testWidgets('ranks categories and shows each share', (tester) async {
      await _pump(tester);
      expect(find.text('Grocery'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('71%'), findsOneWidget);
      expect(find.text('29%'), findsOneWidget);

      // Biggest first.
      expect(
        tester.getTopLeft(find.text('Grocery')).dy,
        lessThan(tester.getTopLeft(find.text('Food')).dy),
      );
    });

    testWidgets('tapping a slice opens that slice, not its neighbour', (
      tester,
    ) async {
      await _pump(tester);

      // Grocery sweeps ~257° clockwise from the top; 30° in is safely inside it.
      await tester.tapAt(_ringPoint(tester, 30));
      await tester.pumpAndSettle();
      expect(find.text('71% of spending'), findsOneWidget);

      await tester.tapAt(const Offset(30, 30)); // tap the barrier to dismiss
      await tester.pumpAndSettle();

      // Food owns the last 103°; 300° lands in it.
      await tester.tapAt(_ringPoint(tester, 300));
      await tester.pumpAndSettle();
      expect(find.text('29% of spending'), findsOneWidget);
    });

    testWidgets('tapping the hole in the middle does nothing', (tester) async {
      await _pump(tester);
      await tester.tapAt(tester.getCenter(find.byType(DonutChart)));
      await tester.pumpAndSettle();
      expect(find.textContaining('of spending'), findsNothing);
    });

    testWidgets('a legend row opens the same detail', (tester) async {
      await _pump(tester);
      await _reveal(tester, find.text('Food'));
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(find.text('29% of spending'), findsOneWidget);
    });
  });

  group('S-17 the line', () {
    testWidgets('is thirty days of expenses, today last', (tester) async {
      await _pump(tester);
      final line = tester.widget<TrendLine>(find.byType(TrendLine));

      expect(line.values.length, 30);
      expect(line.values.last, 30000); // today's chai
      expect(line.values[27], 100000); // Monday's grocery
      expect(line.values[26], 0); // Sunday: a real zero, not a gap
      expect(line.values[25], 30000); // Saturday's, four days back
      expect(
        line.values.reduce((a, b) => a + b),
        210000 + 90000 + 60000,
        reason: 'income must never reach the spending line',
      );
    });
  });

  group('S-17 merchants', () {
    testWidgets('lists them biggest first, with their windows totals', (
      tester,
    ) async {
      await _pump(tester);
      await _reveal(tester, find.text('More Supermarket'));

      expect(find.text('₹1,000'), findsOneWidget); // BigBasket
      expect(find.text('₹500'), findsOneWidget); // More Supermarket
      // Chaiwala's ₹600 is also the Food legend amount.
      expect(find.text('₹600'), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('BigBasket')).dy,
        lessThan(tester.getTopLeft(find.text('Chaiwala')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Chaiwala')).dy,
        lessThan(tester.getTopLeft(find.text('More Supermarket')).dy),
      );
    });

    testWidgets('is not shown when no row carries a merchant', (tester) async {
      await _pump(
        tester,
        ledger: <TxnView>[
          _txn(
            id: 'anon',
            paise: 40000,
            at: DateTime(2026, 10, 6, 12),
            categoryId: 'food',
          ),
        ],
      );
      expect(find.text('Where the money goes'), findsNothing);
      expect(find.text('Food'), findsOneWidget);
    });
  });

  group('S-17 what changed', () {
    testWidgets('shows the expense delta and calls a flat income flat', (
      tester,
    ) async {
      await _pump(tester);
      await _reveal(tester, find.text('This month vs last'));

      expect(find.text('40%'), findsOneWidget); // ₹2,100 vs ₹1,500
      expect(find.text('About the same as last month'), findsOneWidget);
    });

    testWidgets('says nothing at all when there is no last month', (
      tester,
    ) async {
      await _pump(
        tester,
        ledger: <TxnView>[
          _txn(
            id: 'only',
            paise: 40000,
            at: DateTime(2026, 10, 6, 12),
            merchant: 'Chaiwala',
            categoryId: 'food',
          ),
        ],
      );
      await _reveal(tester, find.text('This month vs last'));

      expect(find.text('About the same as last month'), findsNothing);
      expect(find.text('Biggest jump'), findsNothing);
    });

    testWidgets('names the biggest jump', (tester) async {
      await _pump(tester);
      await _reveal(tester, find.text('Biggest jump'));
      expect(find.text('Grocery · 67% more than last month'), findsOneWidget);
    });

    testWidgets('does not claim a weekend pattern that is not there', (
      tester,
    ) async {
      await _pump(tester);
      await _reveal(tester, find.text('This month vs last'));

      expect(
        find.text('Your spending is steady through the week.'),
        findsOneWidget,
      );
      expect(find.text('Weekends cost more than weekdays.'), findsNothing);
    });

    testWidgets('claims the weekend pattern when the weekends earn it', (
      tester,
    ) async {
      await _pump(
        tester,
        ledger: <TxnView>[
          _txn(
            id: 'sat',
            paise: 300000,
            at: DateTime(2026, 10, 3, 12),
            merchant: 'BigBasket',
            categoryId: 'grocery',
          ),
          _txn(
            id: 'mon',
            paise: 20000,
            at: DateTime(2026, 10, 5, 12),
            merchant: 'Chaiwala',
            categoryId: 'food',
          ),
        ],
      );
      await _reveal(tester, find.text('This month vs last'));
      expect(find.text('Weekends cost more than weekdays.'), findsOneWidget);
    });
  });

  group('S-17 the forecast', () {
    testWidgets('is offered to free users, and the offer goes somewhere', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _reveal(tester, find.text('Where this month ends'));
      expect(find.text('Estimated spending by month-end'), findsNothing);

      await tester.tap(find.text('See Pro'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsOneWidget);
    });

    testWidgets('for Pro, projects the month at the current rate', (
      tester,
    ) async {
      await _pump(tester, isPro: true);
      await _reveal(tester, find.text('Estimated spending by month-end'));
      // ₹2,100 over 7 days, across a 31-day month.
      expect(find.text('₹9,300'), findsOneWidget);
      expect(find.text('Where this month ends'), findsNothing);
    });
  });

  group('S-17 empty', () {
    testWidgets('an empty ledger says so instead of drawing a blank chart', (
      tester,
    ) async {
      await _pump(tester, ledger: const <TxnView>[]);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.byType(DonutChart), findsNothing);
      expect(find.byType(TrendLine), findsNothing);
      expect(find.text('Week'), findsOneWidget); // the window switcher stays
    });
  });

  group('S-17 layout', () {
    for (final locale in const ['bn', 'hi', 'en']) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('no overflow in $locale at ${scale}x on a 360dp phone', (
          tester,
        ) async {
          await _pump(
            tester,
            locale: locale,
            size: const Size(360, 640),
            textScale: scale,
          );
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -1200),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$locale at ${scale}x overflowed',
          );
        });
      }
    }
  });

  group('S-17 the maths behind the screen', () {
    test('dailySpend buckets by day, expenses only, oldest first', () {
      final buckets = dailySpend(_ledger, through: _now);
      expect(buckets.length, 30);
      expect(buckets.last, 30000);
      expect(buckets[29], 30000);
      expect(buckets.first, 0);
      expect(buckets.reduce((a, b) => a + b), 360000);
    });

    test('dailySpend drops anything older than thirty days', () {
      final buckets = dailySpend(_ledger, through: _now);
      // The window opens on Sep 8, so September's grocery (the 10th) and food
      // (the 12th) are both inside it — and the salary (the 2nd) is not.
      expect(buckets[2], 90000);
      expect(buckets[3], 0);
      expect(buckets[4], 60000);
    });

    test('topMerchants ranks, caps at five, skips blanks and breaks ties', () {
      final ranked = topMerchants(
        <TxnView>[
          _txn(id: 'a', paise: 100, at: _now, merchant: 'Alpha'),
          _txn(id: 'b', paise: 500, at: _now, merchant: 'Beta'),
          _txn(id: 'c', paise: 500, at: _now, merchant: 'Gamma'),
          _txn(id: 'd', paise: 900, at: _now), // no merchant
          _txn(id: 'e', paise: 900, at: _now, merchant: '   '), // all spaces
          _txn(id: 'f', paise: 700, at: _now, merchant: 'Delta'),
          _txn(id: 'g', paise: 600, at: _now, merchant: 'Epsilon'),
          _txn(id: 'h', paise: 50, at: _now, merchant: 'Zeta'),
          _txn(
            id: 'i',
            paise: 4000,
            at: _now,
            merchant: 'Payroll',
            direction: TxnDirection.income,
          ),
        ],
        _ms(_now.subtract(const Duration(days: 1))),
        _ms(_now),
      );

      expect(ranked.map((m) => m.$1).toList(), [
        'Delta',
        'Epsilon',
        'Beta',
        'Gamma',
        'Alpha',
      ]);
      expect(ranked.first.$2, 700);
    });

    test('biggestJump ignores small moves and brand-new categories', () {
      expect(
        biggestJump(current: {'a': 110}, previous: {'a': 100}),
        isNull,
        reason: '10% is noise',
      );
      expect(
        biggestJump(current: {'a': 130}, previous: {'a': 100})!.$2,
        closeTo(30, 0.01),
      );
      expect(
        biggestJump(current: const {'new': 900}, previous: const {}),
        isNull,
        reason: 'nothing to compare a first month against',
      );
      expect(
        biggestJump(
          current: const {'a': 130, 'b': 400},
          previous: const {'a': 100, 'b': 100},
        ),
        ('b', 300.0),
      );
    });

    test('weekendsCostMore needs a real gap, not one big Saturday', () {
      final steady = <TxnView>[
        _txn(id: 'w', paise: 100000, at: DateTime(2026, 10, 5, 12)),
        _txn(id: 'w2', paise: 100000, at: DateTime(2026, 10, 6, 12)),
        _txn(id: 'e', paise: 25000, at: DateTime(2026, 10, 3, 12)),
        _txn(id: 'e2', paise: 25000, at: DateTime(2026, 10, 4, 12)),
      ];
      expect(
        weekendsCostMore(steady, _ms(DateTime(2026, 10, 1)), _ms(_now)),
        isFalse,
        reason: 'the same money, spread evenly, is not a weekend habit',
      );

      final weekendHeavy = <TxnView>[
        _txn(id: 'w', paise: 20000, at: DateTime(2026, 10, 5, 12)),
        _txn(id: 'e', paise: 200000, at: DateTime(2026, 10, 4, 12)),
      ];
      expect(
        weekendsCostMore(weekendHeavy, _ms(DateTime(2026, 10, 1)), _ms(_now)),
        isTrue,
      );

      // A window with no weekend in it can never make the claim.
      expect(
        weekendsCostMore(
          weekendHeavy,
          _ms(DateTime(2026, 9, 1)),
          _ms(DateTime(2026, 9, 4)),
        ),
        isFalse,
      );
    });
  });
}
