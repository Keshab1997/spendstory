/// S-19 Recurring & reminders (T-506).
///
/// The promise of this screen is that a rule set once behaves the same every
/// month: it says plainly when the next payment is, whether it will post itself
/// or only remind, and a rule whose day has passed says so instead of showing a
/// date that has already been and gone. The tests below pin those states, the
/// strip's count, and the three things a user can do to a rule — add it, change
/// it, or delete it after being asked once more.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/recurring_math.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/screens/recurring_edit_sheet.dart';
import 'package:spendstory/ui/screens/recurring_screen.dart';
import 'package:spendstory/ui/theme.dart';

import 'ledger_harness.dart';

final _now = DateTime(2026, 10, 7, 20, 42);

int at(int y, int m, int d, [int h = 9]) =>
    DateTime(y, m, d, h).millisecondsSinceEpoch;

const List<CategoryView> _categories = <CategoryView>[
  CategoryView(
    id: 'rent',
    kind: TxnDirection.expense,
    nameEn: 'Rent',
    nameHi: 'किराया',
    nameBn: 'বাড়িভাড়া',
    icon: '🏠',
    colorHex: '#6C4CF1',
  ),
  CategoryView(
    id: 'emi',
    kind: TxnDirection.expense,
    nameEn: 'EMI',
    nameHi: 'ईएमआई',
    nameBn: 'ইএমআই',
    icon: '🏦',
    colorHex: '#F5B843',
  ),
  CategoryView(
    id: 'entertainment',
    kind: TxnDirection.expense,
    nameEn: 'Entertainment',
    nameHi: 'मनोरंजन',
    nameBn: 'বিনোদন',
    icon: '🎬',
    colorHex: '#14C8B8',
  ),
];

const List<AccountView> _accounts = <AccountView>[
  AccountView(
    id: 'acc-hdfc',
    name: 'HDFC Bank ••4521',
    type: 'bank',
    openingBalancePaise: 4820000,
  ),
  AccountView(
    id: 'acc-cash',
    name: 'Cash',
    type: 'cash',
    openingBalancePaise: 1200000,
  ),
];

/// Four shapes the strip and the cards have to keep apart: a payment still to
/// come, one that posts itself, one due today, and one that was missed.
List<RecurringRuleView> _rules() => <RecurringRuleView>[
  RecurringRuleView(
    id: 'r-rent',
    title: 'House rent',
    amountPaise: 1800000,
    categoryId: 'rent',
    accountId: 'acc-hdfc',
    dayOfMonth: 5,
    nextDueAt: at(2026, 11, 5),
    remindDaysBefore: 1,
  ),
  RecurringRuleView(
    id: 'r-emi',
    title: 'Home loan EMI',
    amountPaise: 2350000,
    categoryId: 'emi',
    accountId: 'acc-hdfc',
    dayOfMonth: 3,
    nextDueAt: at(2026, 11, 3),
    autoPost: true,
    remindDaysBefore: 1,
  ),
  RecurringRuleView(
    id: 'r-netflix',
    title: 'Netflix',
    amountPaise: 64900,
    categoryId: 'entertainment',
    accountId: 'acc-hdfc',
    dayOfMonth: 12,
    nextDueAt: at(2026, 11, 12),
    remindDaysBefore: kNoReminder,
  ),
  RecurringRuleView(
    id: 'r-gym',
    title: 'Gym',
    amountPaise: 120000,
    accountId: 'acc-cash',
    dayOfMonth: 7,
    nextDueAt: at(2026, 10, 7),
    remindDaysBefore: 0,
  ),
  RecurringRuleView(
    id: 'r-insurance',
    title: 'Term insurance',
    amountPaise: 900000,
    dayOfMonth: 20,
    nextDueAt: at(2026, 9, 20),
    remindDaysBefore: 1,
  ),
];

List<Override> _overrides({
  required List<RecurringRuleView> rules,
}) => <Override>[
  appDbProvider.overrideWithValue(null),
  nowProvider.overrideWithValue(_now),
  localeProvider.overrideWith((ref) => 'en'),
  bootProvider.overrideWith(
    (ref) async => BootState(onboarded: true, demoMode: true, locale: 'en'),
  ),
  // The real demo path: what the screen shows is the fixture plus whatever this
  // session saved, renamed or deleted.
  recurringProvider.overrideWith((ref) async {
    final patches = ref.watch(sessionRecurringPatchesProvider);
    final deleted = ref.watch(sessionRecurringDeletedProvider);
    final base = <RecurringRuleView>[
      ...ref.watch(sessionRecurringAddedProvider),
      ...rules,
    ];
    final known = {for (final rule in base) rule.id};
    // Same merge as the real provider: the fixture, patched by what this
    // session saved, plus anything saved that the fixture never knew about.
    return <RecurringRuleView>[
      for (final rule in base)
        if (!deleted.contains(rule.id)) patches[rule.id] ?? rule,
      for (final entry in patches.entries)
        if (!known.contains(entry.key) && !deleted.contains(entry.key))
          entry.value,
    ];
  }),
  categoriesProvider.overrideWith((ref) async => _categories),
  accountsProvider.overrideWith((ref) async => _accounts),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<RecurringRuleView>? rules,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: _overrides(rules: rules ?? _rules()),
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSsTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const RecurringScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// The screen scrolls as a whole, so everything on it is built — it only needs
/// to be brought into view before a tap lands on it.
Future<void> _tapOnScreen(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The editor sheet is a lazy list, so anything under the fold has to be
/// scrolled to before it is even in the tree.
Future<void> _revealInSheet(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    280,
    scrollable: find
        .descendant(
          of: find.byType(RecurringEditorSheet),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

/// The editor sheet is a lazy list, so the buttons under the fold (save, delete)
/// have to be scrolled to rather than merely pointed at.
Future<void> _tapInSheet(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    280,
    scrollable: find
        .descendant(
          of: find.byType(RecurringEditorSheet),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('S-19 the route', () {
    testWidgets('resolves to the real screen', (tester) async {
      final container = await pumpAt(tester, '/recurring');
      expect(pathOf(container), '/recurring');
      expect(find.byType(RecurringScreen), findsOneWidget);
    });

    testWidgets('settings has the way in, onto the real demo rules', (
      tester,
    ) async {
      await pumpAt(tester, '/settings');

      // Pushing a route leaves the shell's branch in place, so the proof is the
      // screen that arrives — with the demo ledger's three rules on it.
      await _tapOnScreen(tester, find.text('Recurring & reminders'));

      expect(find.byType(RecurringScreen), findsOneWidget);
      expect(find.text('House rent'), findsOneWidget);
      expect(find.text('Home loan EMI'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
    });
  });

  group('S-19 the list', () {
    testWidgets('every rule is on it, with what it will do', (tester) async {
      await _pump(tester);

      expect(find.text('House rent'), findsOneWidget);
      expect(find.text('Home loan EMI'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.textContaining('18,000'), findsOneWidget);

      // One rule posts itself; two ask for a reminder first.
      expect(find.text('Post it automatically'), findsOneWidget);
      expect(find.text('Remind me'), findsWidgets);
      // Netflix has no reminder set, and says so rather than nothing.
      expect(find.text('No reminder is set for this one.'), findsOneWidget);
    });

    testWidgets('the strip counts the next thirty days', (tester) async {
      await _pump(tester);

      expect(find.text('Next 30 days'), findsOneWidget);
      // Today's gym day, the 20th (insurance, caught up from September), then
      // the 3rd and the 5th of November. Netflix on the 12th is past the window.
      expect(find.text('4 due in the next 30 days'), findsOneWidget);
    });

    testWidgets('a payment due today says so, not "next on"', (tester) async {
      await _pump(tester);

      expect(find.textContaining('due today'), findsOneWidget);
    });

    testWidgets('a missed payment says it was missed', (tester) async {
      await _pump(tester);

      expect(find.textContaining('was due 20 Sep'), findsOneWidget);
    });

    testWidgets('nothing yet is an invitation, not an empty list', (
      tester,
    ) async {
      await _pump(tester, rules: const <RecurringRuleView>[]);

      expect(find.text('Nothing recurring yet'), findsOneWidget);
      expect(find.textContaining('set them once'), findsOneWidget);
      // The strip has nothing to promise, so it is not drawn at all.
      expect(find.text('Next 30 days'), findsNothing);
    });

    testWidgets('the screen still reads at a large text scale', (tester) async {
      await _pump(tester, textScale: 1.3);

      expect(find.text('House rent'), findsOneWidget);
      expect(find.text('Next 30 days'), findsOneWidget);
    });
  });

  group('S-19 editing', () {
    testWidgets('a rule opens its editor, filled in', (tester) async {
      await _pump(tester);

      await _tapOnScreen(tester, find.text('Netflix'));

      expect(find.byType(RecurringEditorSheet), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Netflix'), findsOneWidget);
      expect(find.widgetWithText(TextField, '649'), findsOneWidget);

      // An existing rule can be deleted; the confirmation is the next test.
      await _revealInSheet(tester, find.text('Delete this rule'));
      expect(find.text('Delete this rule'), findsOneWidget);
    });

    testWidgets('a rename sticks to the card', (tester) async {
      await _pump(tester);

      await _tapOnScreen(tester, find.text('Netflix'));
      await tester.enterText(find.byType(TextField).first, 'Netflix Premium');
      await _tapInSheet(tester, find.text('Save'));

      expect(find.byType(RecurringEditorSheet), findsNothing);
      expect(find.text('Netflix Premium'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);
    });

    testWidgets('the amount is saved in rupees, not paise', (tester) async {
      final container = await _pump(tester);

      await _tapOnScreen(tester, find.text('Gym'));
      await tester.enterText(find.byType(TextField).at(1), '1500');
      await _tapInSheet(tester, find.text('Save'));

      final rules = await container.read(recurringProvider.future);
      final gym = rules.firstWhere((rule) => rule.id == 'r-gym');
      expect(gym.amountPaise, 150000);
      expect(gym.nextDueAt, at(2026, 10, 7)); // untouched
    });

    testWidgets('a nameless rule is refused with a reason', (tester) async {
      await _pump(tester);

      await _tapOnScreen(tester, find.text('Add a recurring payment'));
      await _tapInSheet(tester, find.text('Save'));

      expect(find.text('Give it a name'), findsOneWidget);
      expect(find.byType(RecurringEditorSheet), findsOneWidget);
    });

    testWidgets('an amount of nothing is refused too', (tester) async {
      await _pump(tester);

      await _tapOnScreen(tester, find.text('Add a recurring payment'));
      await tester.enterText(find.byType(TextField).first, 'Gym');
      await _tapInSheet(tester, find.text('Save'));

      expect(find.text('Enter an amount'), findsOneWidget);
      expect(find.byType(RecurringEditorSheet), findsOneWidget);
    });

    testWidgets('a new rule joins the list, ready on its first due date', (
      tester,
    ) async {
      final container = await _pump(tester);

      await _tapOnScreen(tester, find.text('Add a recurring payment'));
      await tester.enterText(find.byType(TextField).first, 'Wi-Fi');
      await tester.enterText(find.byType(TextField).at(1), '999');
      await _tapInSheet(tester, find.text('Save'));

      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.textContaining('999'), findsOneWidget);

      final added = (await container.read(recurringProvider.future))
          .firstWhere((rule) => rule.title == 'Wi-Fi');
      // The date picker started on today, and that is the first payment.
      expect(added.nextDueAt, at(2026, 10, 7));
      expect(added.frequency, 'monthly');
      expect(added.amountPaise, 99900);
      expect(added.autoPost, isFalse);
    });

    testWidgets('deleting asks first, and keeping it changes nothing', (
      tester,
    ) async {
      await _pump(tester);

      await _tapOnScreen(tester, find.text('Netflix'));
      await _tapInSheet(tester, find.text('Delete this rule'));

      expect(find.text('Delete this recurring payment?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Keep it'));
      await tester.pumpAndSettle();

      expect(find.byType(RecurringEditorSheet), findsOneWidget);
      await _tapInSheet(tester, find.text('Delete this rule'));
      expect(find.byType(RecurringEditorSheet), findsOneWidget);
    });

    testWidgets('deleting for real takes the rule off the list', (
      tester,
    ) async {
      final container = await _pump(tester);

      await _tapOnScreen(tester, find.text('Netflix'));
      await _tapInSheet(tester, find.text('Delete this rule'));
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsNothing);
      expect(find.byType(RecurringEditorSheet), findsNothing);

      final rules = await container.read(recurringProvider.future);
      expect(rules.map((rule) => rule.id), isNot(contains('r-netflix')));
      expect(rules, hasLength(4));
    });
  });
}
