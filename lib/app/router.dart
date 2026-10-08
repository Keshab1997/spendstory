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

import '../ui/screens/budgets_screen.dart';
import '../ui/screens/categories_screen.dart';
import '../ui/screens/coming_soon_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/insights_screen.dart';
import '../ui/screens/language_screen.dart';
import '../ui/screens/manual_path_screen.dart';
import '../ui/screens/onboarding_screen.dart';
import '../ui/screens/permission_notification_screen.dart';
import '../ui/screens/permission_sms_screen.dart';
import '../ui/screens/pro_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/search_screen.dart';
import '../ui/screens/tx_detail_screen.dart';
import '../ui/screens/tx_edit_screen.dart';
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

      // A returning user sitting on the splash or the language picker is sent
      // home. The onboarding and permission screens are deliberately *not*
      // redirected away: they are harmless to open again, and keeping them
      // reachable is what lets the web preview be reviewed screen by screen
      // without first wiping the app's preferences.
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

      // One route, three pages — the page number lives in the URL so a reload
      // during onboarding lands where the user left off.
      GoRoute(
        path: '/onboarding/:page',
        builder: (context, state) {
          final raw = int.tryParse(state.pathParameters['page'] ?? '1') ?? 1;
          return OnboardingScreen(
            page: raw.clamp(1, OnboardingScreen.pageCount),
          );
        },
      ),
      GoRoute(
        path: '/permission/sms',
        builder: (context, state) => const PermissionSmsScreen(),
      ),
      GoRoute(
        path: '/permission/notification',
        builder: (context, state) => const PermissionNotificationScreen(),
      ),
      GoRoute(
        path: '/permission/manual',
        builder: (context, state) => const ManualPathScreen(),
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
                  // Static before dynamic: otherwise ':id' swallows 'edit'
                  // and the add screen becomes a transaction called "edit".
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const TxEditScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        TxDetailScreen(id: state.pathParameters['id']!),
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
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const ComingSoonScreen(
          titleKey: 'accounts',
          subtitleKey: 'accountPageSubtitle',
          bodyKey: 'accountPageBody',
        ),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/pro',
        pageBuilder: (context, state) =>
            MaterialPage(fullscreenDialog: true, child: const ProScreen()),
      ),

      GoRoute(
        path: '/not-found',
        builder: (context, state) => const ComingSoonScreen(
          titleKey: 'notFoundTitle',
          subtitleKey: 'notFoundSubtitle',
          bodyKey: 'notFoundBody',
        ),
      ),
    ],
    errorBuilder: (context, state) => const ComingSoonScreen(
      titleKey: 'notFoundTitle',
      subtitleKey: 'notFoundSubtitle',
      bodyKey: 'notFoundBody',
    ),
  );
});
