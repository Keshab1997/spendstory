# 04 — Navigation

**Package:** `go_router` · declarative, deep-link ready.

---

## 1. Route table

```dart
// lib/app/router.dart
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',           builder: SplashScreen.new),
    GoRoute(path: '/language',         builder: LanguageScreen.new),

    GoRoute(path: '/onboarding/1',     builder: Onboarding1.new),
    GoRoute(path: '/onboarding/2',     builder: Onboarding2.new),
    GoRoute(path: '/onboarding/3',     builder: Onboarding3.new),

    GoRoute(path: '/permission/sms',          builder: PermissionSms.new),
    GoRoute(path: '/permission/notification', builder: PermissionNotif.new),
    GoRoute(path: '/permission/manual',       builder: ManualPath.new),

    StatefulShellRoute.indexedStack(           // bottom nav
      builder: (c, s, shell) => MainShell(shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home',         builder: HomeScreen.new)]),
        StatefulShellBranch(routes: [GoRoute(
            path: '/transactions',
            builder: TxList.new,
            routes: [
              GoRoute(path: ':id',   builder: TxDetail.new),
              GoRoute(path: 'edit',  builder: TxEdit.new),   // ?id= for edit mode
            ])]),
        StatefulShellBranch(routes: [GoRoute(path: '/insights',     builder: Insights.new)]),
        StatefulShellBranch(routes: [GoRoute(path: '/settings',     builder: Settings.new)]),
      ],
    ),

    GoRoute(path: '/categories',  builder: Categories.new),
    GoRoute(path: '/budgets',     builder: BudgetList.new,
      routes: [GoRoute(path: ':id', builder: BudgetDetail.new)]),
    GoRoute(path: '/accounts',    builder: Accounts.new),
    GoRoute(path: '/search',      builder: Search.new),
    GoRoute(path: '/recurring',   builder: Recurring.new),
    GoRoute(path: '/about',       builder: About.new),
    GoRoute(path: '/export',      builder: Export.new),

    GoRoute(                                     // paywall = fullscreen sheet
      path: '/pro',
      pageBuilder: (c, s) => MaterialPage(
        fullscreenDialog: true, child: const ProPaywall()),
    ),
  ],
  errorBuilder: (c, s) => const NotFoundScreen(),
);
```

## 2. First-run flow

```
/splash
   │  (reads prefs: onboarded? locale? permissions?)
   ├── first run ──────► /language ──► /onboarding/1 ──2──3──► /permission/sms
   │                                                                │
   │                                            granted ────────────┤
   │                                            denied  ──► /permission/notification
   │                                                              │
   │                                            granted/denied ───┤
   │                                                              ▼
   └── returning ────────────────────────────────────────────► /home
                                                                  ▲
                                     /permission/manual ──────────┘
```

**Rules**
- Splash never renders a back arrow; `context.go()` replace semantics only.
- After onboarding, `/onboarding/*` and `/permission/*` are **removed** from the stack (not push).
- Returning user with revoked permission → Home shows a **single soft banner**, never a forced redirect.

## 3. Transitions

| From → To | Transition | Duration |
|---|---|---|
| Splash → Language/Home | fade | 300ms |
| Onboarding pages | slide horizontal (PageView) | native |
| Onboarding → Permission | fadeThrough | 260ms |
| Any → Paywall | bottom-sheet slide-up | 340ms, `easeOutCubic` |
| Home → Tx detail | shared-axis Z (icon hero) | 300ms |
| List → Add/Edit | modal bottom sheet | 280ms |
| Tab switch (bottom nav) | fadeThrough | 220ms |
| Budget list → detail | shared-axis X | 280ms |

**Bottom nav:** 4 tabs — Home · Transactions · Insights · Settings. Badge on Transactions = uncategorized count.
**Back behaviour:** tab root e back → system exit; nested → pop. Paywall back = dismiss (never blocks).

## 4. Bottom navigation spec

```
┌──────────────────────────────────────────┐
│   🏠        📋        📊        ⚙️        │
│  হোম       লেনদেন     বিশ্লেষণ    সেটিংস   │
└──────────────────────────────────────────┘
```
- Height 68dp + safe area, glass background (blur 18)
- Active: teal icon + label, 600 weight, dot indicator
- Inactive: textSecondary, label visible (not icon-only)
- Ad banner: **never** docked above bottom nav (accidental-click risk + policy)

## 5. Deep links

| URL | Opens |
|---|---|
| `spendstory://tx/{id}` | S-11 detail |
| `spendstory://pro` | S-22 paywall |
| `spendstory://budget/{id}` | S-15 |
| `spendstory://home` | S-09 |

Android: `android/app/src/main/AndroidManifest.xml` e intent-filter (scheme `spendstory`). Verified App Links Play e optional — avoid `https` scheme claim until domain ready.

## 6. State & guards

- `app_meta` (onboarded, locale, theme) → `SharedPreferences` + Riverpod `AppMetaProvider`
- Guard: `redirect:` e check koro — `onboarded == false` hole `/home` ba `/transactions` e jete debe na
- Permission state **kono guard na** — permission optional, app kono screen block kore na
- Ad gate: interstitial ek session e max 1, `AdGateProvider` e counter

## 7. Testing requirements

- Router smoke test: cold-start → `/language` (first run) · cold-start → `/home` (returning)
- Deep-link test per URL above
- Redirect guard test: `onboarded=false` + `go('/home')` → resolves to `/language`
- Back-stack test: onboarding 3 → back → onboarding 2 (never to splash)
