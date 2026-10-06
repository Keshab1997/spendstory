/// Routing — `docs/04-NAVIGATION.md` §1.
///
/// Four tab branches live inside a [StatefulShellRoute.indexedStack], so each
/// tab keeps its own scroll position and back stack. The onboarding and
/// permission routes are deliberately *outside* the shell: they are a linear
/// flow, not a place you can wander back into.
///
/// The guard is small and does exactly one thing: a user who has not finished
/// onboarding cannot reach a tab root. It never blocks on permissions — those
/// are optional by design, and nothing in the app is gated behind them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/screens/coming_soon_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/insights_screen.dart';
import '../ui/screens/language_screen.dart';
import '../ui/screens/pro_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/tx_list_screen.dart';
import 'main_shell.dart';
import 'providers.dart';

/// Tab roots — everything under these paths requires a finished onboarding.
const List<String> _protectedRoots = <String>[
  '/home',
  '/transactions',
  '/insights',
  '/settings',
];

final routerProvider = Provider<GoRouter>((ref) {
  // Boot resolves asynchronously (open the database, seed, read prefs). The
  // router rebuilds its redirects when it lands, rather than being recreated —
  // recreating a GoRouter would throw away the navigation stack.
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<BootState>>(bootProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final boot = ref.read(bootProvider).valueOrNull;
      final location = state.matchedLocation;

      // Still booting: hold on the splash screen.
      if (boot == null) return location == '/splash' ? null : '/splash';

      final isProtected = _protectedRoots.any(
        (root) => location == root || location.startsWith('$root/'),
      );

      if (!boot.onboarded) {
        // First run, or a user who reset their data.
        if (location == '/splash') return '/language';
        if (isProtected) return '/language';
        return null;
      }

      // Returning user who is sitting on a first-run screen.
      if (location == '/splash' || location == '/language') return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TxListScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ComingSoonScreen(
                      title: 'লেনদেনের বিস্তারিত',
                      subtitle: 'S-11 · ট্রানজ্যাকশন ডিটেইল',
                      body:
                          'SMS-এর মূল টেক্সট, ক্যাটাগরি বদল, নোট আর ডিলিট — '
                          'সব এখানে। ব্যাচ ৫ (T-403) এ বানছে।',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Outside the shell: pushed on top of the tabs, with a real back stack.
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const ComingSoonScreen(
          title: 'বাজেট',
          subtitle: 'S-14 / S-15 · বাজেট লিস্ট ও ডিটেইল',
          body: 'ক্যাটাগরি ধরে লিমিট, দৈনিক ভাতা আর ৮০% সতর্কতা — ব্যাচ ৬ (T-501)।',
        ),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const ComingSoonScreen(
          title: 'অ্যাকাউন্ট',
          subtitle: 'S-16 · অ্যাকাউন্ট লিস্ট',
          body: 'ব্যাঙ্ক, ক্যাশ, ওয়ালেট — প্রতিটার ব্যালান্স ব্যাচ ৬-এ।',
        ),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const ComingSoonScreen(
          title: 'ক্যাটাগরি',
          subtitle: 'S-13 · ক্যাটাগরি ম্যানেজার',
          body: 'নিজের ক্যাটাগরি, আইকন আর রঙ বাছা — ব্যাচ ৫ (T-405)।',
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const ComingSoonScreen(
          title: 'খুঁজুন',
          subtitle: 'S-18 · সার্চ ও ফিল্টার',
          body: 'মার্চেন্ট, টাকার অঙ্ক বা তারিখ দিয়ে খোঁজা — ব্যাচ ৫ (T-406)।',
        ),
      ),
      GoRoute(
        path: '/pro',
        pageBuilder: (context, state) =>
            MaterialPage(fullscreenDialog: true, child: const ProScreen()),
      ),

      GoRoute(
        path: '/not-found',
        builder: (context, state) => const ComingSoonScreen(
          title: 'পাতা খুঁজে পাওয়া গেল না',
          subtitle: '404',
          body: 'সেটিংস থেকে হোমে ফিরে যান।',
        ),
      ),
    ],
    errorBuilder: (context, state) => const ComingSoonScreen(
      title: 'পাতা খুঁজে পাওয়া গেল না',
      subtitle: '404',
      body: 'সেটিংস থেকে হোমে ফিরে যান।',
    ),
  );
});
