/// Every route must render without a layout exception — at the smallest common
/// phone size and at the largest text scale the app allows.
///
/// This test exists because a real overflow hid behind a screenshot for a while:
/// the six-month bar chart on Insights pushed its own column past the bottom of a
/// card. In a release build nobody sees a warning — the numbers just look wrong,
/// or a region paints as a blank rectangle. Flutter *does* tell you, though, in
/// debug: it throws a `FlutterError` and paints the yellow-and-black stripes.
/// So the assertion here is simply "no FlutterError was raised", on every route,
/// in both themes, at 360×640 and at 1.3× text scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/ui/components/money.dart';
import 'package:spendstory/ui/theme.dart';

const List<String> _allRoutes = <String>[
  '/home',
  '/transactions',
  '/transactions/demo-row',
  '/insights',
  '/settings',
  '/pro',
  '/budgets',
  '/accounts',
  '/categories',
  '/search',
  '/recurring',
];

void main() {
  for (final locale in <String>['bn', 'hi', 'en']) {
    for (final scale in <double>[1.0, 1.3]) {
      testWidgets('every route renders cleanly · $locale · textScale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final errors = <String>[];
        var currentRoute = 'initial screen';
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add('$currentRoute: ${details.exceptionAsString()}');
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              appDbProvider.overrideWithValue(null),
              bootProvider.overrideWith(
                (ref) async =>
                    BootState(onboarded: true, demoMode: true, locale: locale),
              ),
            ],
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const SpendStoryApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        container.read(localeProvider.notifier).state = locale;
        final router = container.read(routerProvider);

        for (final route in _allRoutes) {
          currentRoute = route;
          router.go(route);
          await tester.pumpAndSettle();
          // Give any lazy image or animation a chance to complain too.
          await tester.pump(const Duration(milliseconds: 400));
        }

        FlutterError.onError = previous;

        expect(errors, isEmpty, reason: errors.join('\n---\n'));
      });
    }
  }

  testWidgets('the bar chart never overflows, at any data shape', (
    tester,
  ) async {
    // Six equal values, one dominant value, and all-zero: the three shapes that
    // break a naive bar layout.
    for (final values in <List<int>>[
      <int>[100, 100, 100, 100, 100, 100],
      <int>[1, 1, 1, 1, 1, 9999999],
      <int>[0, 0, 0, 0, 0, 0],
    ]) {
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) =>
          errors.add(details.exceptionAsString());

      await tester.pumpWidget(
        MaterialApp(
          theme: buildSsTheme(Brightness.light),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MiniBars(
                values: values,
                labels: const <String>[
                  'জানু',
                  'ফেব্রু',
                  'মার্চ',
                  'এপ্রিল',
                  'মে',
                  'জুন',
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      FlutterError.onError = previous;

      expect(errors, isEmpty, reason: 'values=$values');
    }
  });
}
