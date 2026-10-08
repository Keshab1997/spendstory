/// The ad-request audit (T-609, `docs/08 §3`, §9).
///
/// The checklist item is *"grep every `AdRequest` site → zero financial data
/// passed"*, and a checklist item that lives only in a doc rots. So the grep is
/// a test: it reads `lib/` as text and fails if the app ever grows a second
/// place that talks to the SDK, or a spec that could carry an amount, a
/// merchant or a category.
///
/// This is deliberately a source scan rather than a runtime assertion — the
/// question is *what the code can ever do*, not what one test run happened to
/// do, and the answer to that is visible only in the source.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `.dart` file under `lib/`, keyed by path relative to the repo root.
Map<String, String> _libSources() {
  final files = <String, String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    files[entity.path] = entity.readAsStringSync();
  }
  return files;
}

/// The path as the repo writes it, so failure messages read like a code review.
String _rel(String path) => path.replaceAll(r'\', '/');

/// The text between the parentheses of `name(` starting at [start], or null.
String? _argsAfter(String source, int start) {
  final open = source.indexOf('(', start);
  if (open < 0) return null;
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    final ch = source[i];
    if (ch == '(') depth++;
    if (ch == ')') {
      depth--;
      if (depth == 0) return source.substring(open + 1, i);
    }
  }
  return null;
}

void main() {
  final sources = _libSources();

  group('nothing but the client may build an ad request', () {
    test('AdRequest appears in exactly one file, and it is the SDK client', () {
      final sites = <String>[
        for (final entry in sources.entries)
          if (entry.value.contains('AdRequest(')) _rel(entry.key),
      ];

      expect(
        sites,
        <String>['lib/ads/ad_client_mobile.dart'],
        reason:
            'an ad request built anywhere else is a request nobody audited; '
            'route it through AdClient instead',
      );
    });

    test('that one request carries no targeting beyond the consent flag', () {
      final source = sources['lib/ads/ad_client_mobile.dart']!;
      final index = source.indexOf('AdRequest(');

      final args = _argsAfter(source, index)!;

      // `nonPersonalizedAds` is a consent answer. `keywords`, `contentUrl` and
      // `neighboringContentUrls` are the targeting fields — and passing any of
      // them from a ledger is exactly the policy violation this test exists to
      // prevent, so they are asserted absent rather than merely unused.
      for (final banned in <String>[
        'keywords',
        'contentUrl',
        'neighboringContentUrls',
        'extras',
      ]) {
        expect(args, isNot(contains(banned)), reason: banned);
      }
    });

    test('the SDK client never reads a financial field', () {
      final source = sources['lib/ads/ad_client_mobile.dart']!;

      for (final word in <String>[
        'amountPaise',
        'merchant',
        'categoryId',
        'balance',
        'occurredAt',
        'budgetsProvider',
        'transactionsProvider',
      ]) {
        expect(
          source,
          isNot(contains(word)),
          reason:
              '$word in the ad client: an ad request must never learn what the '
              'user spent, where, or on what',
        );
      }
    });

    test('AdSpec can only hold four things, none of them financial', () {
      final source = sources['lib/ads/ad_client.dart']!;
      // The class body only — the doc comment above it talks about money, which
      // is the point of the comment. The class ends at the first `}` that starts
      // a line, which is how the formatter writes it.
      final start = source.indexOf('class AdSpec');
      final end = source.indexOf('\n}', start);
      final body = source.substring(start, end);

      final fields = RegExp(
        r'^\s*final\s+[\w<>?, ]+\s+(\w+);',
        multiLine: true,
      ).allMatches(body).map((m) => m.group(1)).toSet();

      expect(fields, <String>{
        'unitId',
        'format',
        'reservedHeight',
        'nonPersonalized',
      });
    });

    test('only the SDK client builds a spec — not a screen, not the gate', () {
      final builders = <String>{
        for (final entry in sources.entries)
          if (entry.value.contains('AdSpec(')) _rel(entry.key),
      };

      // The definition, and the one file that constructs one.
      expect(builders, <String>{
        'lib/ads/ad_client.dart',
        'lib/ads/ad_client_mobile.dart',
      });
    });
  });

  group('the screens an ad is allowed on (docs/03)', () {
    // Every screen spec that says "Ads: ✅", and nothing else. Onboarding,
    // permission screens, add/edit, the ledger and its rows, search, settings,
    // the paywall and About are all "❌" — and each of those ❌ is a line here.
    const allowed = <String>{
      'lib/ui/screens/home_screen.dart', // S-09
      'lib/ui/screens/budgets_screen.dart', // S-14
      'lib/ui/screens/budget_detail_screen.dart', // S-15
      'lib/ui/screens/accounts_screen.dart', // S-16
      'lib/ui/screens/insights_screen.dart', // S-17
      'lib/ui/screens/recurring_screen.dart', // S-19
    };

    test('a slot exists only on the screens that may carry one', () {
      final withSlots = <String>{
        for (final entry in sources.entries)
          if (_rel(entry.key).startsWith('lib/ui/screens/') &&
              entry.value.contains('AdSlot('))
            _rel(entry.key),
      };

      expect(withSlots, allowed);
    });

    test('the "never" screens have no slot, and no import of one either', () {
      const never = <String>[
        'lib/ui/screens/pro_screen.dart', // S-22: no ads on a screen selling
        'lib/ui/screens/settings_screen.dart', // S-20: policy irritant
        'lib/ui/screens/search_screen.dart', // S-18
        'lib/ui/screens/categories_screen.dart', // S-13
        'lib/ui/screens/tx_list_screen.dart', // S-10
        'lib/ui/screens/tx_detail_screen.dart', // S-11
        'lib/ui/screens/tx_edit_screen.dart', // S-12
        'lib/ui/screens/budget_edit_sheet.dart',
        'lib/ui/screens/account_edit_sheet.dart',
        'lib/ui/screens/recurring_edit_sheet.dart',
      ];

      for (final path in never) {
        final source = sources[path];
        expect(source, isNotNull, reason: '$path has been renamed or removed');
        expect(source, isNot(contains('AdSlot')), reason: path);
        expect(source, isNot(contains('AdClient')), reason: path);
      }
    });

    test('the onboarding and permission screens are ad-free too', () {
      final onboarding = sources.entries.where(
        (entry) =>
            _rel(entry.key).contains('onboarding') ||
            _rel(entry.key).contains('permission_screen'),
      );
      expect(onboarding, isNotEmpty, reason: 'the scan found nothing to check');
      for (final entry in onboarding) {
        expect(entry.value, isNot(contains('AdSlot')), reason: _rel(entry.key));
      }
    });
  });

  test('the manifest carries the AdMob app id, from Gradle', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('com.google.android.gms.ads.APPLICATION_ID'));
    expect(manifest, contains(r'${admobAppId}'));

    // …and Gradle is where the flavor decides which one that is.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('manifestPlaceholders["admobAppId"]'));
    expect(gradle, contains('ca-app-pub-3940256099942544~3347511713'));
  });
}
