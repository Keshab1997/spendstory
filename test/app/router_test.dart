/// Router smoke + guard tests — `docs/04-NAVIGATION.md` §7.
///
/// The guard is the only thing standing between a first-run user and a Home
/// screen full of numbers that are not theirs, so it is tested from both
/// directions: a returning user must not get stuck on the splash, and a first-run
/// user must not reach a tab root.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';

/// The database is null and boot is pre-resolved, so these tests never touch the
/// file system and never race the real boot sequence.
List<Override> _overrides({required bool onboarded}) => <Override>[
  appDbProvider.overrideWithValue(null),
  bootProvider.overrideWith(
    (ref) async =>
        BootState(onboarded: onboarded, demoMode: true, locale: 'bn'),
  ),
];

Future<void> _pump(WidgetTester tester, {required bool onboarded}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(onboarded: onboarded),
      child: const SpendStoryApp(),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(routerProvider);

String _pathOf(WidgetTester tester) =>
    _routerOf(tester).routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('first run: cold start lands on the language picker', (
    tester,
  ) async {
    await _pump(tester, onboarded: false);

    expect(_pathOf(tester), '/language');
    expect(find.text('শুরু করুন'), findsOneWidget);
    // Every supported language is offered, in its own script.
    expect(find.text('বাংলা'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('returning user: cold start lands on Home', (tester) async {
    await _pump(tester, onboarded: true);

    expect(_pathOf(tester), '/home');
    expect(find.text('এই মাসের খরচ'), findsOneWidget);
  });

  testWidgets('guard: a first-run user cannot reach a tab root', (
    tester,
  ) async {
    await _pump(tester, onboarded: false);

    for (final path in <String>[
      '/home',
      '/transactions',
      '/insights',
      '/settings',
    ]) {
      _routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(
        _pathOf(tester),
        '/language',
        reason: '$path must bounce back to the language screen',
      );
    }
  });

  testWidgets('returning user is moved off the first-run screens', (
    tester,
  ) async {
    await _pump(tester, onboarded: true);

    _routerOf(tester).go('/language');
    await tester.pumpAndSettle();
    expect(_pathOf(tester), '/home');

    _routerOf(tester).go('/splash');
    await tester.pumpAndSettle();
    expect(_pathOf(tester), '/home');
  });

  testWidgets('the four tabs are reachable and keep their own stacks', (
    tester,
  ) async {
    await _pump(tester, onboarded: true);
    expect(_pathOf(tester), '/home');

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(_pathOf(tester), '/transactions');

    await tester.tap(find.byIcon(Icons.insights_outlined));
    await tester.pumpAndSettle();
    expect(_pathOf(tester), '/insights');

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(_pathOf(tester), '/settings');

    // Back to Home — tapping the active tab returns to its root.
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(_pathOf(tester), '/home');
  });

  testWidgets('an unknown route resolves instead of crashing', (tester) async {
    await _pump(tester, onboarded: true);

    _routerOf(tester).go('/there-is-no-such-screen');
    await tester.pumpAndSettle();

    expect(find.text('পাতা খুঁজে পাওয়া গেল না'), findsOneWidget);
  });

  testWidgets('the paywall opens on top of the shell', (tester) async {
    await _pump(tester, onboarded: true);

    _routerOf(tester).go('/pro');
    await tester.pumpAndSettle();

    expect(_pathOf(tester), '/pro');
    expect(find.text('SpendStory Pro'), findsWidgets);
    expect(find.text('₹৬৯৯'), findsOneWidget);
  });
}
