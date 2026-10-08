/// The localization contracts (T-702, `docs/09-LOCALIZATION.md` §6).
///
/// Three files hold all the copy, in three languages, and two generated files
/// are built from them. Everything that can silently drift is asserted here:
///
///   * a key that exists in English but not in Bengali — the failure mode that
///     ships an English sentence inside a Bengali screen;
///   * a generated table that was not regenerated after an ARB edit;
///   * a screen reading a key that does not exist, which renders as `⟦key⟧`
///     instead of failing the build;
///   * a translator (or an agent) pasting the English string into `app_bn.arb`
///     and calling it translated.
///
/// Like the ad-request audit, two of these read the repo as text — the question
/// is *what the files say*, not what one run happened to render.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/l10n/app_localizations.dart';
import 'package:spendstory/l10n/strings_table.g.dart';
import 'package:spendstory/ui/strings.dart';

const List<String> _locales = <String>['en', 'hi', 'bn'];

/// The ARB file for [locale], metadata entries (`@key`, `@@locale`) removed.
Map<String, String> _arb(String locale) {
  final raw = json.decode(
    File('lib/l10n/app_$locale.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  return <String, String>{
    for (final entry in raw.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

/// The full file, metadata included — the template needs its `@key` blocks.
Map<String, dynamic> _arbRaw(String locale) =>
    json.decode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Every `.dart` file under `lib/`, keyed by its path.
Map<String, String> _libSources() {
  final files = <String, String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    files[entity.path.replaceAll(r'\', '/')] = entity.readAsStringSync();
  }
  return files;
}

/// `{name}` placeholders in [value], in the order they appear.
List<String> _placeholders(String value) =>
    RegExp(r'\{(\w+)\}').allMatches(value).map((m) => m.group(1)!).toList();

/// Keys whose text is the same in all three languages on purpose: a brand name
/// and a payment method. Any *new* key that arrives identical to English is a
/// translation that did not happen, and fails the test below.
const Set<String> _sameInEveryLanguage = <String>{
  'appName',
  'proTitle',
  'notFoundSubtitle',
  'modeUpi',
  // S-23's Pro badge on the PDF card. "Pro" is the plan's name in all three
  // languages, exactly like `proTitle` above.
  'exportPdfPro',
};

void main() {
  final en = _arb('en');
  final keys = en.keys.toList();
  final sources = _libSources();

  group('the three ARB files agree', () {
    test('app_hi.arb and app_bn.arb have exactly the keys of the template', () {
      for (final locale in <String>['hi', 'bn']) {
        final other = _arb(locale);
        expect(
          other.keys.where((k) => !en.containsKey(k)),
          isEmpty,
          reason:
              'app_$locale.arb has keys the template does not: they would '
              'never be translated anywhere',
        );
        expect(
          en.keys.where((k) => !other.containsKey(k)),
          isEmpty,
          reason:
              'app_$locale.arb is missing keys - a screen would fall back to '
              '⟦key⟧ for the user, and English for nobody',
        );
      }
    });

    test('the same keys are in the same order, so the files stay diffable', () {
      for (final locale in <String>['hi', 'bn']) {
        expect(_arb(locale).keys.toList(), keys, reason: 'app_$locale.arb');
      }
    });

    test('no translation is empty or still holds the ⟦key⟧ marker', () {
      for (final locale in _locales) {
        final table = _arb(locale);
        for (final key in keys) {
          expect(
            table[key]!.trim(),
            isNotEmpty,
            reason: 'app_$locale.arb: "$key" is blank',
          );
          expect(
            table[key],
            isNot(contains('⟦')),
            reason:
                'app_$locale.arb: "$key" holds the runtime missing-key '
                'marker, which means it was pasted, not translated',
          );
        }
      }
    });

    test('a placeholder in any language is a placeholder in the template', () {
      final template = _arbRaw('en');
      for (final key in keys) {
        final meta = template['@$key'] as Map<String, dynamic>?;
        final placeholders =
            meta?['placeholders'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final declared = placeholders.keys.toSet();
        for (final locale in _locales) {
          for (final placeholder in _placeholders(_arb(locale)[key]!)) {
            expect(
              declared,
              contains(placeholder),
              reason:
                  'app_$locale.arb: "$key" uses {$placeholder}, which the '
                  'template does not declare - gen-l10n cannot type it',
            );
          }
        }
        // And the other way round: a declared placeholder nothing uses is a
        // leftover from a rewritten sentence.
        for (final placeholder in declared) {
          expect(
            _placeholders(en[key]!),
            contains(placeholder),
            reason:
                'app_en.arb: "@$key" declares {$placeholder}, which the '
                'English sentence no longer uses',
          );
        }
      }
    });
  });

  group('the generated table is the ARB files', () {
    test('every locale, every key, byte for byte', () {
      expect(ssStringsTable.keys.toSet(), _locales.toSet());
      for (final locale in _locales) {
        final table = ssStringsTable[locale]!;
        final arb = _arb(locale);
        expect(
          table.keys.toSet(),
          keys.toSet(),
          reason:
              '$locale: the table and app_$locale.arb hold different keys '
              '- run `python3 tool/l10n_gen.py`',
        );
        for (final key in keys) {
          expect(
            table[key],
            arb[key],
            reason:
                '$locale/$key is stale in strings_table.g.dart - run '
                '`python3 tool/l10n_gen.py`',
          );
        }
      }
    });

    test('the key list is the template, in template order', () {
      expect(ssStringKeys, keys);
    });

    test('SsStrings never needs its ⟦key⟧ fallback', () {
      expect(SsStrings.missingKeys, isEmpty);
      for (final locale in _locales) {
        final strings = SsStrings(locale);
        for (final key in keys) {
          expect(
            strings[key],
            isNot(startsWith('⟦')),
            reason: '$locale/$key renders as a missing key',
          );
        }
      }
    });

    test('gen-l10n emitted a member for every key', () {
      final generated = File('lib/l10n/app_localizations_en.dart')
          .readAsStringSync();
      final absent = <String>[
        for (final key in keys)
          if (!generated.contains('get $key =>') &&
              !generated.contains('$key('))
            key,
      ];
      expect(
        absent,
        isEmpty,
        reason: 'flutter gen-l10n did not emit these - run `flutter gen-l10n`',
      );
    });

    test(
      'the app offers exactly the locales Flutter was given, English first',
      () {
        final flutter = AppLocalizations.supportedLocales
            .map((locale) => locale.languageCode)
            .toList();
        expect(SsStrings.supportedLocales.toSet(), flutter.toSet());
        // A device with none of the three gets the first entry; English is the
        // language the store listing and the privacy policy are written in.
        expect(flutter.first, 'en');
      },
    );
  });

  group('the copy the screens read', () {
    test('every key read through the string accessor exists', () {
      // Deliberately narrow: `s['txTitle']`, `strings['x']`,
      // `ref.read(stringsProvider)['x']` and `SsStrings('bn')['x']` are the
      // four ways a screen reaches copy. A key that is not in the ARB files
      // renders as ⟦key⟧ to the user, and nothing else in the app would notice.
      final pattern = RegExp(
        r"(?:SsStrings\([^)]*\)|ref\.(?:read|watch)\(stringsProvider\)|"
        r"\bs)\s*\[\s*'([A-Za-z_]\w*)'\s*\]",
      );
      final unknown = <String>{};
      for (final entry in sources.entries) {
        if (entry.key == 'lib/ui/strings.dart') continue;
        for (final match in pattern.allMatches(entry.value)) {
          final key = match.group(1)!;
          if (!ssStringsTable['en']!.containsKey(key)) {
            unknown.add('${entry.key}: $key');
          }
        }
      }
      expect(
        unknown,
        isEmpty,
        reason: 'these call sites read a key no ARB file defines',
      );
    });

    test('the typed getters and the table cannot drift apart', () {
      // `lib/ui/strings.dart` keeps its getters by hand next to a generated
      // table, so the one thing that can rot is a getter whose key was renamed.
      final source = sources['lib/ui/strings.dart']!;
      final getters = RegExp(r"String get (\w+) => this\['(\w+)'\];")
          .allMatches(source);
      expect(getters, isNotEmpty);
      for (final match in getters) {
        expect(
          match.group(1),
          match.group(2),
          reason: 'getter ${match.group(1)} reads a different key',
        );
        expect(
          ssStringsTable['en'],
          contains(match.group(2)),
          reason: 'getter ${match.group(1)} reads a key no ARB file defines',
        );
      }
    });

    test('Bengali and Hindi are translations, not copies of English', () {
      for (final locale in <String>['hi', 'bn']) {
        final identical = <String>{
          for (final key in keys)
            if (_arb(locale)[key] == en[key]) key,
        };
        expect(
          identical,
          _sameInEveryLanguage,
          reason:
              'app_$locale.arb: a key is word-for-word English. Translate '
              'it, or add it to _sameInEveryLanguage with a reason.',
        );
      }
    });
  });
}
