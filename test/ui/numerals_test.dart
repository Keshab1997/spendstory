/// The Bengali-digits switch (T-707, `docs/09-LOCALIZATION.md` §2).
///
/// Latin is the default — `₹1,240` is what the bank SMS, the ATM slip and every
/// UPI screen write — and a Bengali or Hindi reader who wants `₹১,২৪০` asks for
/// it once in Settings. The whole feature is one boolean
/// (`numeralsProvider`, stored as `app_meta.numerals`) and one seam
/// ([SsStrings.digits] and [SsStrings.numeralLocale]), so the tests below can
/// move every number in the app with two lines.
///
/// Two of these read the repo as text. They are the guards that keep the seam
/// from being walked around: a screen that formats a date with a bare
/// `shortDate(…, locale: 'bn')` would compile, render, and quietly ignore the
/// switch — which is the one failure a screenshot would not catch.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/data/db.dart';
import 'package:spendstory/data/seed.dart' show kNumeralsMetaKey;
import 'package:spendstory/l10n/strings_table.g.dart';
import 'package:spendstory/ui/strings.dart';

import 'ledger_harness.dart';

final SsStrings _bn = SsStrings('bn');
final int _sept12 = DateTime(2026, 9, 12).millisecondsSinceEpoch;

/// The switch in the numerals row.
///
/// Not `switchInTile`: that helper finds a switch inside a [SettingTile], and
/// this row is the lighter label + switch pair the appearance card uses for its
/// display settings.
Finder numeralsSwitch() => find.descendant(
  of: find.ancestor(
    of: find.text(_bn['settingsNumerals']),
    matching: find.byType(Row),
  ),
  matching: find.byType(Switch),
);

/// Every `.dart` file under `lib/`, keyed by its path.
Map<String, String> _libSources() {
  final files = <String, String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    files[entity.path.replaceAll(r'\', '/')] = entity.readAsStringSync();
  }
  return files;
}

/// Files allowed to name the raw numeral table, and why.
const Map<String, String> _mayCallLocalizeDigits = <String, String>{
  'lib/ui/format.dart': 'the table itself, and the date helpers it feeds',
  'lib/ui/strings.dart': 'the seam: digits() and numeralLocale decide here',
  'lib/ui/components/money.dart': 'formatInr/formatInrCompact take the code',
};

/// Files allowed to call a date helper straight, and why.
const Map<String, String> _mayCallDateHelpers = <String, String>{
  'lib/ui/format.dart': 'the definitions themselves',
  'lib/ui/strings.dart': 'the preference-aware wrappers the screens call',
  'lib/ui/screens/export_screen.dart':
      'the PDF period is English and Latin on purpose: the renderer has no '
      'Indic shaping, so there is no digit choice to make (T-705)',
};

void main() {
  group('the seam', () {
    test('Latin digits are the default, in all three languages', () {
      for (final locale in SsStrings.supportedLocales) {
        expect(SsStrings(locale).digits('1240'), '1240');
        expect(SsStrings(locale).numeralLocale, 'en');
      }
      expect(_bn.shortDate(_sept12), '12 সেপ্ট');
    });

    test('the switch moves the digits, and only the digits', () {
      final on = SsStrings('bn', nativeDigits: true);
      expect(on.digits('1240'), '১২৪০');
      expect(on.numeralLocale, 'bn');
      expect(on.shortDate(_sept12), '১২ সেপ্ট');
      // The words did not move, only the digits inside them: the ARB holds
      // `আগামী 30 দিন`, and the same sentence reads `আগামী ৩০ দিন` when the
      // switch is on. That is why the translations had to stop baking digits.
      expect(_bn['recurringStripTitle'], 'আগামী 30 দিন');
      expect(on['recurringStripTitle'], 'আগামী ৩০ দিন');
    });

    test('Hindi gets Devanagari digits, not Bengali ones', () {
      expect(SsStrings('hi', nativeDigits: true).digits('1240'), '१२४०');
      expect(SsStrings('hi', nativeDigits: true).shortDate(_sept12), '१२ सित');
    });

    test('English has one numeral system, so the switch cannot change it', () {
      expect(SsStrings('en', nativeDigits: true).digits('1240'), '1240');
      expect(SsStrings('en', nativeDigits: true).numeralLocale, 'en');
    });

    test('no ARB sentence bakes a numeral in, so the switch owns them all', () {
      // A `২০২৬` written into a translation cannot be switched *off*, so the
      // three ARB files hold ASCII digits and `operator []` writes them the way
      // the user asked for. This is the rule that keeps the switch honest, and
      // it is why T-707 had to rewrite 29 approved translations.
      final native = RegExp(r'[\u09E6-\u09EF\u0966-\u096F]');
      for (final entry in ssStringsTable.entries) {
        for (final copy in entry.value.entries) {
          expect(
            native.hasMatch(copy.value),
            isFalse,
            reason:
                'app_${entry.key}.arb "$copy": write the digits as ASCII and '
                'let the numerals switch localize them',
          );
        }
      }
    });
  });

  group('the guards', () {
    test('no file formats a numeral without going through the switch', () {
      for (final entry in _libSources().entries) {
        if (_mayCallLocalizeDigits.containsKey(entry.key)) continue;
        expect(
          entry.value.contains('localizeDigits('),
          isFalse,
          reason:
              '${entry.key} formats digits itself; use SsStrings.digits() or '
              'SsStrings.numeralLocale so the S-20 switch reaches it',
        );
      }
    });

    test('no file calls a date helper with a bare locale', () {
      // `shortDate(ms, locale: 'bn')` compiles and renders — and ignores the
      // switch, because the helper cannot see it. The wrappers on SsStrings are
      // the only ones that know.
      // `s.monthLabel(…)` is the seam and passes; `monthLabel(…)` on its own
      // is the mistake this looks for.
      final call = RegExp(
        r'(?<![.\w])(shortDate|dayLabel|monthLabel|timeOfDay)\(',
      );
      for (final entry in _libSources().entries) {
        if (_mayCallDateHelpers.containsKey(entry.key)) continue;
        final found = call
            .allMatches(entry.value)
            .map((m) => m.group(1))
            .toSet()
            .toList();
        expect(
          found,
          isEmpty,
          reason: '${entry.key} calls ${found.join(', ')}',
        );
      }
    });
  });

  group('on screen', () {
    testWidgets('the appearance card offers the switch in Bengali', (
      tester,
    ) async {
      final db = AppDb.memory();
      addTearDown(db.close);

      await pumpAt(
        tester,
        '/settings',
        locale: 'bn',
        extra: <Override>[appDbProvider.overrideWithValue(db)],
      );

      expect(find.text(_bn['settingsNumerals']), findsOneWidget);
      expect(find.text(_bn['settingsNumeralsBody']), findsOneWidget);
      expect(tester.widget<Switch>(numeralsSwitch()).value, isFalse);
    });

    testWidgets('and does not draw it for English', (tester) async {
      final db = AppDb.memory();
      addTearDown(db.close);

      await pumpAt(
        tester,
        '/settings',
        locale: 'en',
        extra: <Override>[appDbProvider.overrideWithValue(db)],
      );

      // No second way to write `1,240` exists in English, and a switch that
      // cannot change anything is a switch that lies.
      expect(find.text(SsStrings('en')['settingsNumerals']), findsNothing);
    });

    testWidgets('flipping it turns the ledger over, and is remembered', (
      tester,
    ) async {
      final db = AppDb.memory();
      addTearDown(db.close);

      final container = await pumpAt(
        tester,
        '/home',
        locale: 'bn',
        extra: <Override>[appDbProvider.overrideWithValue(db)],
      );

      // The harness's first row is ₹1,240 — written the way the bank wrote it.
      expect(find.textContaining('1,240'), findsWidgets);
      expect(find.textContaining('১,২৪০'), findsNothing);

      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      await tester.tap(numeralsSwitch());
      await tester.pumpAndSettle();

      expect(await db.meta(kNumeralsMetaKey), 'true');

      container.read(routerProvider).go('/home');
      await tester.pumpAndSettle();
      expect(find.textContaining('১,২৪০'), findsWidgets);
      expect(find.textContaining('1,240'), findsNothing);
    });

    testWidgets('a stored "on" is applied before the first frame', (
      tester,
    ) async {
      await pumpAt(
        tester,
        '/home',
        locale: 'bn',
        extra: <Override>[
          bootProvider.overrideWith(
            (ref) async => const BootState(
              onboarded: true,
              demoMode: true,
              locale: 'bn',
              numerals: true,
            ),
          ),
        ],
      );

      expect(find.textContaining('১,২৪০'), findsWidgets);
    });
  });
}
