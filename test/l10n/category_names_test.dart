/// Category names in three languages (T-703, `docs/09-LOCALIZATION.md` §2).
///
/// The seed is where the trilingual promise is easiest to break quietly: the
/// app looks finished in English, the row renders, and only a Bengali user
/// finds out that "Groceries" is what they got. So the rule is asserted twice —
/// once on the data (every seeded category carries all three names, and neither
/// Indian name is the English one in disguise) and once on the screen (the very
/// same row reads `Grocery` / `किराना` / `বাজার` as the language changes).
///
/// The screens read the name through `CategoryView.label(locale)`; nothing in
/// the UI may pick a column itself, which is why the widget test drives the
/// real router and the real language provider instead of a hand-built chip.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/data/seed.dart';
import 'package:spendstory/domain/models.dart';
import 'package:spendstory/domain/view_models.dart';
import 'package:spendstory/ui/components/lists.dart';

import '../ui/ledger_harness.dart';

/// Every category the first run writes, in the order the seed defines them.
const List<SeedCategory> _seed = <SeedCategory>[
  ...kExpenseCategories,
  ...kIncomeCategories,
];

/// A `CategoryView` for the same category the harness ledger files a row under,
/// so the data-level and screen-level halves of this file talk about one thing.
const CategoryView _grocery = CategoryView(
  id: 'grocery',
  kind: TxnDirection.expense,
  nameEn: 'Grocery',
  nameHi: 'किराना',
  nameBn: 'বাজার',
  icon: '🛒',
  colorHex: '#14C8B8',
);

void main() {
  group('the seed carries every language', () {
    test('18 categories - 12 expense, 6 income', () {
      expect(kExpenseCategories, hasLength(12));
      expect(kIncomeCategories, hasLength(6));
      expect(kExpenseCategories.every((c) => c.kind == 'expense'), isTrue);
      expect(kIncomeCategories.every((c) => c.kind == 'income'), isTrue);
    });

    test('ids are unique, so no rule can point at the wrong category', () {
      final ids = _seed.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, everyElement(isNotEmpty));
    });

    test('every category has a name in all three languages, trimmed', () {
      for (final category in _seed) {
        for (final name in <String>[
          category.nameEn,
          category.nameHi,
          category.nameBn,
        ]) {
          expect(name, name.trim(), reason: '${category.id}: "$name"');
          expect(name, isNotEmpty, reason: '${category.id} has a blank name');
        }
      }
    });

    test('no seeded name is the English one in disguise', () {
      // Every one of the 18 has a real Hindi and Bengali name today; this is
      // the tripwire for the category someone adds on a Friday afternoon.
      for (final category in _seed) {
        expect(
          category.nameHi,
          isNot(category.nameEn),
          reason: '${category.id} ships English text as its Hindi name',
        );
        expect(
          category.nameBn,
          isNot(category.nameEn),
          reason: '${category.id} ships English text as its Bengali name',
        );
      }
    });

    test('the label follows the locale, and never returns an empty name', () {
      expect(_grocery.label('en'), 'Grocery');
      expect(_grocery.label('hi'), 'किराना');
      expect(_grocery.label('bn'), 'বাজার');
      // The default argument is the app's default language, not English.
      expect(_grocery.label(), 'বাজার');
      // An unknown language code falls back to Bengali rather than to a blank
      // label; `_ =>` is the last arm on purpose.
      expect(_grocery.label('fr'), 'বাজার');
      // And the mapping is the obvious one for every seeded category: a column
      // cannot be swapped without this failing.
      for (final category in _seed) {
        final view = CategoryView(
          id: category.id,
          kind: TxnDirection.fromWire(category.kind) ?? TxnDirection.expense,
          nameEn: category.nameEn,
          nameHi: category.nameHi,
          nameBn: category.nameBn,
          icon: category.icon,
          colorHex: category.colorHex,
        );
        expect(view.label('en'), category.nameEn);
        expect(view.label('hi'), category.nameHi);
        expect(view.label('bn'), category.nameBn);
      }
    });
  });

  group('the screens read the language, not one column', () {
    // The ledger row and the manager both show the category through
    // `CategoryView.label(locale)`; the two screens disagree about how they
    // lay it out, so both are checked. One locale per test: pumping a second
    // app into the same test would reuse the first one's router state.
    const List<(String, String, String)> cases = <(String, String, String)>[
      ('en', 'Grocery', 'বাজার'),
      ('hi', 'किराना', 'Grocery'),
      ('bn', 'বাজার', 'Grocery'),
    ];

    for (final (locale, shown, hidden) in cases) {
      testWidgets('the ledger row reads "$shown" in $locale', (tester) async {
        await pumpAt(tester, '/transactions', locale: locale);
        expect(find.text(shown), findsOneWidget);
        expect(find.text(hidden), findsNothing);
      });

      testWidgets('the categories manager reads "$shown" in $locale', (
        tester,
      ) async {
        await pumpAt(tester, '/categories', locale: locale);
        expect(find.text(shown), findsOneWidget);
        expect(find.text(hidden), findsNothing);
      });
    }
  });
}
