/// T-307 — the first-run flow, in all three languages, at the sizes that break
/// layouts, with the platform faked.
///
/// Three things are defended here, all of which have already gone wrong once in
/// this codebase or would have:
///
///  * **No overflow.** Bengali and Hindi glyph stacks are taller than Latin ones
///    at the same font size, so a screen that fits in English can still push a
///    column past the bottom in `bn`. Every route is rendered in `bn` first, then
///    `hi`, then `en`, at 360×640 and at 1.3× text scale, and asserted after
///    *each* route — a failure has to name the screen, not say "something, in
///    one of six screens, at one of six settings".
///  * **Every answer is survivable.** Allow, deny, "not now", and "the platform
///    could not even be asked" are four different outcomes and each one has its
///    own sentence. The permission screens are the only place in the app where a
///    user can be asked for something real, so all four are tested.
///  * **Nobody is trapped.** A first-run user cannot reach the app without
///    finishing onboarding, and finishing onboarding requires no permission.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spendstory/app/app.dart';
import 'package:spendstory/app/providers.dart';
import 'package:spendstory/app/router.dart';
import 'package:spendstory/platform/permissions.dart';

const List<String> _onboardingRoutes = <String>[
  '/onboarding/1',
  '/onboarding/2',
  '/onboarding/3',
  '/permission/sms',
  '/permission/notification',
  '/permission/manual',
];

/// Answers exactly what the test tells it to, which is the one thing a widget
/// test cannot do through `permission_handler`.
class _FakePermissions extends PermissionsApi {
  _FakePermissions({
    this.smsAnswer = SmsAccess.unknown,
    this.notifications = NotificationAccess.unknown,
    this.settingsOpen = false,
  });

  /// What both reading and requesting SMS access answer with.
  final SmsAccess smsAnswer;

  final NotificationAccess notifications;

  final bool settingsOpen;

  int smsRequests = 0;

  @override
  Future<PermissionState> current() async =>
      PermissionState(sms: smsAnswer, notifications: notifications);

  @override
  Future<SmsAccess> requestSms() async {
    smsRequests++;
    return smsAnswer;
  }

  @override
  Future<bool> openNotificationSettings() async => settingsOpen;

  @override
  Future<bool> openAppSettingsPage() async => false;
}

/// The app, booted as a first-run user, with a handle on the router and a switch
/// standing in for the `onboarded` row the real flow writes to `app_meta`.
class _FirstRun {
  _FirstRun(this.tester, this.permissions);

  final WidgetTester tester;
  final _FakePermissions permissions;
  final List<String> errors = <String>[];
  final ValueNotifier<bool> onboarded = ValueNotifier<bool>(false);

  GoRouter get router =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(routerProvider);

  String get path => router.routerDelegate.currentConfiguration.uri.path;

  /// Pretends the flow just wrote `onboarded = true` to the database.
  void markOnboarded() => onboarded.value = true;

  Future<void> boot({required String locale, required double textScale}) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(onboarded.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // No database: first run is precisely the state where the database has
          // just been created, and every screen must tolerate the writes that go
          // with it when there is nowhere to write.
          appDbProvider.overrideWithValue(null),
          permissionsProvider.overrideWithValue(permissions),
          bootProvider.overrideWith(
            (ref) async => BootState(
              onboarded: onboarded.value,
              demoMode: true,
              locale: locale,
            ),
          ),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const SpendStoryApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    drain();

    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
            .read(localeProvider.notifier)
            .state =
        locale;
    await settle();
    drain();
  }

  /// Collects anything the framework raised since the last drain.
  ///
  /// `tester.takeException()` rather than an override of `FlutterError.onError`:
  /// the binding feeds its own handler into that callback, and replacing it —
  /// even restoring it before the test body ends — breaks the binding's
  /// bookkeeping for every test that follows in the same file.
  void drain() {
    final caught = tester.takeException();
    if (caught != null) errors.add(caught.toString());
  }

  /// Nothing was raised, in any frame, for the whole test.
  void assertClean() {
    drain();
    expect(
      errors,
      isEmpty,
      reason: errors
          .map((e) => '• ${e.split('\n').take(4).join(' ')}')
          .join('\n'),
    );
  }

  Future<void> goTo(String route) async {
    router.go(route);
    await settle();
    drain();
  }

  /// Taps something, scrolling it into view first.
  ///
  /// `ensureVisible` matters: these pages scroll, and at 360×640 the primary
  /// button on the permission screens sits below the fold — a bare tap would
  /// land on nothing and the test would fail for a reason that has nothing to do
  /// with what it is checking.
  Future<void> tapAndSettle(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await settle();
    drain();
  }

  /// A fixed handful of frames, never `pumpAndSettle`.
  ///
  /// `SsActionButton` spins a `CircularProgressIndicator` while a request is in
  /// flight, and a progress indicator animates forever by design — settling on
  /// one is settling on nothing. Twelve 60 ms frames is more than any of these
  /// transitions needs and cannot hang.
  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }
}

Future<_FirstRun> _firstRun(
  WidgetTester tester, {
  _FakePermissions? permissions,
  String locale = 'bn',
  double textScale = 1.0,
}) async {
  final run = _FirstRun(tester, permissions ?? _FakePermissions());
  await run.boot(locale: locale, textScale: textScale);
  return run;
}

void main() {
  group('layout', () {
    for (final locale in <String>['bn', 'hi', 'en']) {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets('first-run flow renders cleanly · $locale · $scale×', (
          tester,
        ) async {
          final run = await _firstRun(tester, locale: locale, textScale: scale);
          for (final route in _onboardingRoutes) {
            await run.goTo(route);
            expect(
              run.errors,
              isEmpty,
              reason:
                  '$route raised on $locale at textScale $scale:\n'
                  '${run.errors.join('\n')}',
            );
          }
          run.assertClean();
        });
      }
    }
  });

  group('paging', () {
    testWidgets('Next walks the three pages and then leaves onboarding', (
      tester,
    ) async {
      final run = await _firstRun(tester);
      await run.goTo('/onboarding/1');
      expect(find.text('প্রতিটা খরচ নিজে থেকে জমা হবে'), findsOneWidget);

      await run.tapAndSettle(find.text('পরেরটা'));
      expect(find.text('টাকা কোথায় যাচ্ছে, স্পষ্ট দেখুন'), findsOneWidget);

      await run.tapAndSettle(find.text('পরেরটা'));
      expect(find.text('আপনার ডেটা ফোনেই থাকে'), findsOneWidget);

      // The last page's primary button is the only one with a different label.
      await run.tapAndSettle(find.text('শুরু করুন'));
      expect(run.path, '/permission/sms');
      run.assertClean();
    });

    testWidgets('Back goes one page and disappears on the first page', (
      tester,
    ) async {
      final run = await _firstRun(tester);
      await run.goTo('/onboarding/2');
      expect(find.text('পিছনে'), findsOneWidget);

      await run.tapAndSettle(find.text('পিছনে'));
      expect(find.text('প্রতিটা খরচ নিজে থেকে জমা হবে'), findsOneWidget);
      expect(find.text('পিছনে'), findsNothing);
      run.assertClean();
    });

    testWidgets('a reload lands on the page the URL names', (tester) async {
      final run = await _firstRun(tester);
      await run.goTo('/onboarding/3');
      expect(find.text('আপনার ডেটা ফোনেই থাকে'), findsOneWidget);
      run.assertClean();
    });

    testWidgets('a link moves an already-open flow to the page it names', (
      tester,
    ) async {
      // The URL is the source of truth. A `PageView` keeps its own page across a
      // rebuild, so this only works if the screen actively follows the route.
      final run = await _firstRun(tester);
      await run.goTo('/onboarding/1');
      expect(find.text('প্রতিটা খরচ নিজে থেকে জমা হবে'), findsOneWidget);

      await run.goTo('/onboarding/3');
      expect(find.text('আপনার ডেটা ফোনেই থাকে'), findsOneWidget);
      expect(find.text('প্রতিটা খরচ নিজে থেকে জমা হবে'), findsNothing);
      run.assertClean();
    });
  });

  group('the SMS screen answers honestly', () {
    testWidgets('cannot ask → explains, keeps its label, does not relabel', (
      tester,
    ) async {
      // The web preview and the desktop build take this branch, so it is the one
      // that gets looked at most.
      final run = await _firstRun(
        tester,
        permissions: _FakePermissions(smsAnswer: SmsAccess.unknown),
      );
      await run.goTo('/permission/sms');

      await run.tapAndSettle(find.text('SMS পড়ার অনুমতি দিন'));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('আবার চেষ্টা করুন'), findsNothing);
      expect(find.text('SMS পড়ার অনুমতি দিন'), findsOneWidget);
      run.assertClean();
    });

    testWidgets('denied → says so and offers to try again', (tester) async {
      final run = await _firstRun(
        tester,
        permissions: _FakePermissions(smsAnswer: SmsAccess.denied),
      );
      await run.goTo('/permission/sms');

      await run.tapAndSettle(find.text('SMS পড়ার অনুমতি দিন'));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('আবার চেষ্টা করুন'), findsOneWidget);
      // Still on the same screen: a refusal is not a wall, and it is not an exit
      // either — the user chooses when to move on.
      expect(run.path, '/permission/sms');
      run.assertClean();
    });

    testWidgets('granted → carries straight on to notification access', (
      tester,
    ) async {
      final run = await _firstRun(
        tester,
        permissions: _FakePermissions(smsAnswer: SmsAccess.granted),
      );
      await run.goTo('/permission/sms');

      await run.tapAndSettle(find.text('SMS পড়ার অনুমতি দিন'));
      expect(run.path, '/permission/notification');
      expect(run.permissions.smsRequests, 1);
      run.assertClean();
    });

    testWidgets('Not now skips the ask entirely — no request is made', (
      tester,
    ) async {
      final run = await _firstRun(tester);
      await run.goTo('/permission/sms');

      await run.tapAndSettle(find.text('এখন নয়'));
      expect(run.path, '/permission/notification');
      expect(run.permissions.smsRequests, 0);
      run.assertClean();
    });
  });

  group('notification access', () {
    testWidgets('not granted → shows the six apps and the manual hint', (
      tester,
    ) async {
      final run = await _firstRun(tester);
      await run.goTo('/permission/notification');

      expect(find.text('নোটিফিকেশন অ্যাক্সেস বন্ধ আছে'), findsOneWidget);
      // Every whitelisted app is named, in human terms — a raw package name here
      // would be the explainer failing at its only job.
      for (final name in <String>[
        'Google Pay',
        'PhonePe',
        'Paytm',
        'BHIM',
        'CRED',
        'Amazon Pay',
      ]) {
        expect(find.text(name), findsOneWidget);
      }

      // The platform cannot open the list in a test, so the screen must say how
      // to do it by hand instead of leaving a dead button.
      await run.tapAndSettle(find.text('নোটিফিকেশন সেটিংস খুলুন'));
      expect(find.byType(SnackBar), findsOneWidget);
      run.assertClean();
    });

    testWidgets('when the OS does open the list, no hint is shown', (
      tester,
    ) async {
      final run = await _firstRun(
        tester,
        permissions: _FakePermissions(settingsOpen: true),
      );
      await run.goTo('/permission/notification');

      await run.tapAndSettle(find.text('নোটিফিকেশন সেটিংস খুলুন'));
      // The manual hint is a fallback for a host that cannot open the list — not
      // something to shout at a user whose settings screen just opened.
      expect(find.byType(SnackBar), findsNothing);
      run.assertClean();
    });

    testWidgets('skipping still finishes onboarding, with nothing granted', (
      tester,
    ) async {
      final run = await _firstRun(tester);
      await run.goTo('/permission/notification');

      run.markOnboarded();
      await run.tapAndSettle(find.text('এড়িয়ে যান'));
      expect(run.path, '/home');
      expect(run.permissions.smsRequests, 0);
      run.assertClean();
    });

    testWidgets('granted → the state is stated and Continue is offered', (
      tester,
    ) async {
      final run = await _firstRun(
        tester,
        permissions: _FakePermissions(
          notifications: NotificationAccess.granted,
        ),
      );
      await run.goTo('/permission/notification');

      expect(find.text('নোটিফিকেশন অ্যাক্সেস চালু আছে'), findsOneWidget);
      // With access already granted the ask is gone, not merely disabled.
      expect(find.text('নোটিফিকেশন সেটিংস খুলুন'), findsNothing);
      expect(find.text('এড়িয়ে যান'), findsNothing);

      run.markOnboarded();
      await run.tapAndSettle(find.text('এগিয়ে যান'));
      expect(run.path, '/home');
      run.assertClean();
    });
  });

  group('the manual-only path', () {
    testWidgets('is reachable from the SMS screen and finishes at Home', (
      tester,
    ) async {
      final run = await _firstRun(tester);
      await run.goTo('/permission/sms');

      await run.tapAndSettle(find.text('আমি SMS-এর অনুমতি দিতে চাই না'));
      expect(run.path, '/permission/manual');
      expect(find.text('হাতে হাতে চালান'), findsOneWidget);

      run.markOnboarded();
      await run.tapAndSettle(find.text('SpendStory শুরু করুন'));
      expect(run.path, '/home');
      // Home renders with no capture channel at all — that is the whole promise
      // of this screen.
      expect(run.permissions.smsRequests, 0);
      run.assertClean();
    });

    testWidgets('offers the way back, in case it was a mistake', (
      tester,
    ) async {
      final run = await _firstRun(tester);
      await run.goTo('/permission/manual');

      await run.tapAndSettle(find.text('না, আমাকে SMS-এর অনুমতি দিতে দিন'));
      expect(run.path, '/permission/sms');
      run.assertClean();
    });
  });

  group('the guard', () {
    testWidgets('a first-run user cannot jump straight into the app', (
      tester,
    ) async {
      final run = await _firstRun(tester);
      for (final route in <String>['/home', '/insights', '/settings']) {
        await run.goTo(route);
        expect(
          run.path,
          '/language',
          reason: '$route should not be reachable before onboarding',
        );
      }
      run.assertClean();
    });
  });
}
