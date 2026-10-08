# 11 — Task List (serial order)

> **Ei serial e kaj koro.** Prottek task = choto, verifiable, ek commit. Preflight every time; test sudhu jeta change ke cover kore.

Legend: `[x]` done · `[~]` in progress · `[ ]` todo
Check per change: `python3 tool/preflight.py` · Dart edit hole: `flutter test test/<name>_test.dart`

---

## ✅ Batch 1 — Foundation (DONE)

- [x] **T-001** Repo `Keshab1997/spendstory` created + made **public** (unlimited Actions)
- [x] **T-002** Flutter scaffold — `com.keshabstudios.spendstory`, Flutter 3.47.6, analyze clean, test passing
- [x] **T-003** Agent pack installed — `tool/preflight.py`, `ci_watch.py`, `agent_loop.py`, `see_screen.py`, `AGENTS.md`
- [x] **T-004** flutter-builder v1.14.1 caller workflows (4) + whatsnew seeds
- [x] **T-005** 10 × AI 3D illustrations → `assets/3d/`
- [x] **T-006** Docs 00–11 written

---

## ✅ Batch 1.5 — Design direction + mockups (DONE)

- [x] **T-051** Home screen — 3 directions explored (light-clean / playful / minimal)
- [x] **T-052** **Direction A "Light & Clean" LOCKED** — light-first + full dark mode
- [x] **T-053** Light mockups ×9 — splash, onboarding, permission, home, tx list, add/edit, budget, insights, paywall
- [x] **T-054** Dark mockups ×2 — home, tx list
- [x] **T-055** `docs/screens-board.html` — interactive light/dark board
- [x] **T-056** `02-DESIGN-SYSTEM.md` updated — light-first tokens, dual-theme rules, addendum
- [x] **T-057** Remaining mockups — tx detail, accounts, search, settings (light) + dark set ×6 → **13 light + 8 dark = 21 screens**
- [ ] **T-058** Still missing specs' mockups: Categories (S-13), Budget detail (S-15), Recurring (S-19), About (S-21), Export (S-23), Manual-path (S-08), Language (S-05), Onboarding 2-3, Permission notif (S-07)
- [ ] **T-059** Light-mode 3D illustration variants → `assets/3d/light/*` (dark set → `assets/3d/dark/*`)


---

## 🔜 Batch 2 — Data layer + parser (no UI yet)

- [x] **T-101** Add deps: `drift`, `sqlite3_flutter_libs`, `path_provider`, `riverpod`, `uuid`, `crypto`, `intl` → `flutter pub get`
- [x] **T-102** `lib/data/tables.dart` — 8 tables per `05-DATA-MODEL.md`
- [x] **T-103** `lib/data/db.dart` — Drift database, WAL, FK on, `schemaVersion 1`
- [x] **T-104** `lib/data/seed.dart` — 12+6 categories, cash account, 120 merchant rules, 32 bank senders
- [x] **T-105** `test/data/db_test.dart` — migration + seed test
- [x] **T-106** `lib/capture/otp_guard.dart` + `test/capture/otp_guard_test.dart` → **0 parses on 40-OTP corpus**
- [x] **T-107** `lib/capture/sender_allowlist.dart` + test
- [x] **T-108** `lib/capture/sms_parser.dart` (amount/date/merchant/signals) + `test/capture/sms_parser_test.dart`
- [x] **T-109** `lib/capture/dedupe.dart` + test (25 pairs → 100% suppression)
- [x] **T-110** `lib/capture/rule_engine.dart` — merchant→category + learning + user override
- [x] **T-111** Fixtures: `test/fixtures/sms/*.json` — synthetic corpus (no real user data)
- [x] **T-112** `lib/capture/capture_service.dart` — wiring: SMS + notification → repo → stream
- [x] **T-113** `test/capture/end_to_end_test.dart` — 200-sample corpus, gate ≥95%

**Gate:** T-106 + T-109 + T-113 green. Tabе UI shuru. → 🟢 **BATCH 2 COMPLETE**

**Delivered:**
- `lib/domain/models.dart` — pure-Dart domain types
- `lib/capture/` — `otp_guard`, `sender_allowlist` (50 senders), `merchant_normalizer` (~85 canonicals), `sms_parser`, `dedupe`, `rule_engine` (195 built-in rules), `capture_service` (the ① → ⑦ pipeline)
- `lib/data/` — `tables.dart` (9 tables + 6 indexes), `db.dart` (WAL, FK on, soft delete, purge), `seed.dart` (18 categories 3-language, cash account, rules, senders), `tx_repo.dart` (dual dedupe, computed balances), `db.g.dart` (generated)
- `test/` — **104 tests**, **319 synthetic messages** across 8 fixture files; corpus regenerable via `python3 tool/gen_sms_corpus.py`
- **Measured gates:** 0 OTP leaks · 200/200 corpus fields exact · 0 false transactions on 60 noise messages · 97.5% auto-filed · cross-channel dedupe works
- Toolchain note: `analyzer` is pinned to `13.3.0` in dev_dependencies — build_runner 2.16.1 declares analyzer <15 but does not compile against 14.x. Codegen-only pin.

**Next:** Batch 4 — onboarding + permissions (S-01 … S-08). ✅ done, see below; Batch 5 next.

---

## 🔜 Batch 3 — Design system + shell

- [x] **T-201** `lib/ui/tokens.dart` — colors, gradients, spacing, radius, typography (from `02`)
- [x] **T-202** Fonts bundled — Manrope + Noto Sans Bengali/Devanagari → `assets/fonts/`
- [x] **T-203** `SsScaffold` + `GlassCard` + `SsButton`
- [x] **T-204** `MoneyText` (tabular, sign color, 3-lang format)
- [x] **T-205** `HeroIllustration` + `EmptyState` + `AdSlot` (returns nothing for Pro)
- [x] **T-206** `BudgetBar` + `DonutChart` + `CategoryChip`
- [x] **T-207** `lib/app/router.dart` per `04-NAVIGATION.md` + `MainShell` (4-tab bottom nav)
- [x] **T-208** `test/app/router_test.dart` — first-run vs returning redirect

---

**Delivered (Batch 3):**
- `lib/ui/tokens.dart` — `SsColors` as a `ThemeExtension` (both brightnesses, verified different by test), spacing, radius, shadow, type scale with tabular figures
- `lib/ui/theme.dart` — two `ThemeData`, Material 3 base with the colour scheme, text theme, chip/sheet/input shapes all overridden
- `lib/ui/components/` — `SsScaffold`, `SsCard`, `GlassCard`, `SectionHeader`, `HeroIllustration`, `EmptyState`, `SsActionButton`, `SsIconButton`, `QuickAction`, `StatPill`, `SettingTile`, `SsSegmented`, `MoneyText`, `MoneyDelta`, `BudgetBar`, `DonutChart`, `MiniBars`, `TxRow`, `CategoryAvatar`, `CategoryChip`, `DayHeader`, `SsBadge`, `AdSlot`
- `lib/app/` — `router.dart` (guard + tabs + all 23 routes resolving), `main_shell.dart` (floating glass nav), `providers.dart` (database-or-demo seam), `app.dart`
- Screens live now: Splash, Language, Home, Transactions, Insights, Settings, Pro paywall, plus honest placeholders for S-11/13/14/16/18 with the batch that will fill them
- **Bundled fonts** — Manrope + Noto Sans Bengali + Noto Sans Devanagari in `assets/fonts/`, no network fetch
- **Web preview works**: `DemoLedger` supplies six months of deterministic trilingual demo data on platforms with no database, behind a visible "ওয়েব প্রিভিউ" banner. Nothing fake is ever presented as the user's own money.
- **Bengali/Hindi numerals** — `₹১৪,০৯০` and `৪৭%`, not `₹14,090`
- **Ad slots reserved** at the exact sizes from `docs/08`, never above the bottom nav, hidden for Pro

**Bugs found and fixed while building it (all now covered by `test/app/render_smoke_test.dart`):**
1. Six real `RenderFlex` overflows at 360×640 and at text scale 1.3 — hero header, stat pills, budget labels, plan badge, pro hero, button label
2. `MiniBars` used `1 << 62` as a clamp bound. Fine on the Dart VM, **32-bit in JavaScript**, so the widget threw at build time — visible in the web preview only as a blank rectangle where the chart should be, and invisible to `flutter test` because that runs on the VM. Found by reading the browser console on a *profile* build.

---

## ✅ Batch 4 — Onboarding + permissions (S-01 … S-08)

- [x] **T-301** S-01 Splash (boot: DB open, prefs, locale)
- [x] **T-302** S-05 Language picker (instant switch, no restart)
- [x] **T-303** S-02/03/04 Onboarding PageView + parallax
- [x] **T-304** S-06 Permission SMS explainer + `permission_handler`
- [x] **T-305** S-07 Notification access + whitelist UI + `NotificationListenerService` (Kotlin)
- [x] **T-306** S-08 Manual-only path
- [x] **T-307** `bn` locale overflow test for S-02/03/04 — see note below

---

**Delivered (Batch 4):**
- `lib/ui/screens/onboarding_screen.dart` — three pages (captures by itself → see where the money goes → your data stays on the phone), one `PageController` driving both the pager and a two-rate parallax (artwork 42 px/page, text 20 px/page). The page number lives in the URL (`/onboarding/N`), so a reload during first run lands where the user left off.
- `lib/ui/screens/permission_sms_screen.dart` — reads / never-reads, then the button. Four distinct answers, four different sentences: allow, deny, "not now", and *the platform could not be asked at all* (the web preview) — which is finally **not** reported to the user as a refusal.
- `lib/ui/screens/permission_notification_screen.dart` — names all six whitelisted apps as apps, in `Wrap` chips, and re-checks the moment the user returns from the system list (`WidgetsBindingObserver` → `AppLifecycleState.resumed`).
- `lib/ui/screens/manual_path_screen.dart` — the no-permission route, phrased as a legitimate choice, ending at Home with capture off.
- `lib/platform/native_bridge.dart` + `lib/platform/permissions.dart` — one `MethodChannel` (`spendstory/native`) and a `PermissionsApi` seam the tests override.
- Android: `READ_SMS` + `RECEIVE_SMS` declared, `telephony` marked optional; `SpendStoryNotificationListener` filters to the six payment packages **at the door** (nothing outside the whitelist is ever buffered) and stores raw `(pkg, title, text, postedAt)` tuples for Batch 5 to parse — there is exactly one parser in this project and it is the one with tests, in Dart.
- 27 new strings × 3 languages (98 keys each, all three complete — asserted by test).
- `test/ui/onboarding_flow_test.dart` (20) + `test/platform/native_bridge_test.dart` (10).

**T-307, deliberately not image goldens:** the task asked for a `bn`-locale golden with an overflow check. Goldens were tried in Batch 3 and deleted: they fail on any font-hinting or Skia difference between machines, which makes them noise in CI rather than a gate. The overflow half of the requirement is the part that was actually catching bugs, so it is tested directly — every first-run route, three languages, two text scales, asserted after *each* route so the failure names the screen. It found two real overflows on the first run:
1. The onboarding page column overflowed by **216 px** in Bengali at 360×640 — a `PageView` gives its child a fixed height and a `Column` that does not fit overflows rather than spilling. Fixed by scrolling inside the page.
2. The **language picker** — the first screen a user ever sees — overflowed by 12 px at 1.3× text scale in all three languages. `Spacer` in a fixed-height `Column` hid it. Fixed by pinning the button and scrolling the three cards.

**Still open for Batch 5:** nothing drains `SpendStoryNotificationListener.drainPending()` yet — that is the capture pipeline's first job (T-401). Until then the buffer simply accumulates, bounded at 200 entries, so a payment made between granting access and the pipeline landing is not lost.

---

## 🔜 Batch 5 — Core app (S-09 … S-13)

- [x] **T-401** S-09 Home — hero money card, count-up, banner ad slot, quick actions
- [x] **T-402** S-10 Transactions list — grouped, month strip, summary chips, filter chips, swipe → delete (undo) / re-categorise
- [x] **T-403** S-11 Transaction detail — incl. **raw-SMS viewer** (trust feature)
- [x] **T-404** S-12 Add/Edit sheet — custom keypad, 3-tap save
- [x] **T-405** S-13 Categories manager + editor
- [x] **T-406** S-18 Search & filter
- [x] **T-407** Widget tests: add-tx flow, filter results, detail renders source

**Gate:** every S-09 … S-13 + S-18 route resolves to a real screen, 229 tests
green, `flutter analyze` clean. → 🟢 **BATCH 5 COMPLETE**

**Delivered (T-403 … T-407):**
- `lib/ui/screens/tx_detail_screen.dart` — S-11. The source row and the
  raw-message viewer are the screen, not a footnote: the exact SMS the row was
  parsed from, collapsed by default and **built only when opened**, so a
  collapsed viewer is genuinely collapsed rather than merely invisible to the
  eye and fully present to the accessibility tree. A typed row says it has no
  message instead of showing an empty box.
- `lib/ui/screens/tx_edit_sheet.dart` — S-12. A custom keypad: digits are
  entered in paise and shifted up like a cash register, so there is no decimal
  separator to get wrong in three languages and no half-typed `12.` state.
  Switching direction clears a category that belongs to the other side.
- `lib/ui/screens/tx_edit_screen.dart` — the same form hosted as a page, so
  `/transactions/edit` is a real, reloadable route. The host says how to leave;
  a page reached with `go()` has nothing to pop.
- `lib/ui/screens/categories_screen.dart` — S-13. Two tabs, 3-col grid, editor
  with icon/colour/3-language name/monthly cap. One name is enough to save; the
  others fall back to it rather than rendering a blank label. Delete **hides**:
  rows already filed keep their history.
- `lib/ui/screens/search_screen.dart` — S-18. Matches merchant, note, category
  and **amount the way a human remembers it** (`1240` and `1,240` both find
  ₹1,240.00). Direction, source and multi-category filters, live result count.
- `lib/app/providers.dart` — `TxActions` / `CategoryActions`: one write seam,
  `TxRepo` when a database exists and session overlays when it does not, so the
  web preview responds to every write instead of ignoring it.
- `test/ui/` — 35 new tests driving the **real app and router**, because half of
  this batch is route wiring and a perfect screen at an unreachable path is not
  done. Includes no-overflow checks for each new screen in 3 languages at 1.3×
  on 360×640.

**Three real bugs this work surfaced (all now covered):**
1. `Dismissible` asserts the row leaves the tree in the same frame; both
   backends are asynchronous. Fixed with a local pending-delete set.
2. The add sheet `await`ed `HapticFeedback.mediumImpact()` before closing. On a
   device that resolves instantly; in a widget test nothing answers the channel,
   so the form span forever. A vibration is feedback, not a step — it is no
   longer awaited.
3. `monthLabel()` selected the Bengali month list for `'en'` and then ignored it
   via a second branch. Harmless, but one edit away from shipping Bengali month
   names to English users. Rewritten as a single switch.

**Deliberately not done here:** budgets/insights/accounts (Batch 6), ads and
purchases (Batch 7), ARB localization (Batch 8), release prep (Batch 9).

**T-402 notes:**
- The month strip is the list's scope, not decoration: rows are filtered to the
  selected month and the forward arrow is disabled in the current one, because a
  future month is always empty and an empty screen the user cannot explain is
  worse than a dead arrow.
- The two summary chips describe the **month**, not the active filter — hiding
  income should not make the month's income vanish from the header.
- Swipe covers the two corrections an auto-captured ledger actually needs: left
  deletes (soft delete + a 6s Undo, so the id, the raw SMS and the capture
  history survive), right opens a category sheet offering only the categories
  matching the row's direction. Amount and note stay a detail-screen job (T-403).
- `TxActions` (`lib/app/providers.dart`) is the one write seam: `TxRepo` when a
  database exists, in-session overlays when it does not — so the web preview
  responds to a delete instead of silently ignoring it.
- `_justDeleted` in the screen exists because `Dismissible` asserts the row
  leaves the tree in the same frame, while both backends are asynchronous.
- `test/ui/tx_list_test.dart` — 13 tests, including no-overflow across 3
  languages × 2 text scales at 360×640.

---

## 🔜 Batch 6 — Budget, insights, accounts

- [x] **T-501** S-14 Budget list + native ad after 3rd row
- [x] **T-502** S-15 Budget detail — circular gauge + **daily allowance**
- [x] **T-503** S-16 Accounts + computed balances
- [x] **T-504** S-17 Insights — donut, trend, top merchants, deltas
- [x] **T-505** Budget alert notifications (80%/100%), once-per-day cap
- [x] **T-506** S-19 Recurring & reminders (v1.1)

**What landed (T-501 … T-506):**
- `lib/domain/budget_math.dart` — the cycle and the status, pure and shared.
  A cycle starts on `startDay` (salary day), not on the 1st; 80/100/120 and the
  daily allowance (left ÷ days remaining) are defined here once.
- `lib/ui/screens/budgets_screen.dart` — S-14. Headline overall cap, rows sorted
  by % used, 80/100/120 colours, the 120% suggestion card, and **one native ad
  after the third row** — never above the fold, and the list is never padded to
  reach it.
- `lib/ui/screens/budget_detail_screen.dart` + `CircularGauge` (`money.dart`) —
  S-15. Ring, spent/left/limit, the daily allowance card, the category's recent
  rows, one banner at the bottom.
- `lib/ui/screens/accounts_screen.dart` + `account_edit_sheet.dart` — S-16.
  Balances are **computed from the ledger every time, never stored**; the
  opening balance is the only number the user owns. Deleting an account hides
  it without taking its transactions out of the totals.
- `lib/ui/screens/insights_screen.dart` + `TrendLine` — S-17. Week/month/year/
  custom windows, donut with angle-accurate taps, 30-day line, top-5 merchants,
  delta chips, biggest jump (20% floor), weekend pattern (1.25× floor), Pro
  forecast. The ad sits under everything, never between two charts being read
  together.
- `lib/data/budget_alerts.dart` + `MainActivity.postNotification` +
  `POST_NOTIFICATIONS` — T-505. The planner is pure: at most one alert per
  budget per run, crossing beats 80%, switched-off thresholds stay silent, and
  nothing repeats inside the same day. The day is remembered in `app_meta` on a
  phone and in the session overlay in the demo build. A notification the OS
  refuses (no permission, no host) is **not** marked delivered — it is still
  owed tomorrow. The permission is asked at the moment a user switches a
  warning on, and nowhere else.
- `lib/domain/recurring_math.dart` + `lib/data/recurring_tasks.dart` — T-506.
  The dates are the hard part and they are pure: a rule on the 31st clamps to
  the last day of a short month **and comes back to the 31st** (never drifting
  to the 3rd), a leap-day yearly rule survives three ordinary years, and an
  interval a bad edit set to zero still moves forward. Auto-post writes the
  payment on the day it was **due**, not the day the app noticed one, so a
  phone that slept through three months owes one rent rather than three; each
  payment and each reminder is remembered against its own due date
  (`recurring:<id>:<day>` in `app_meta`, the session map in the demo build).
- `lib/ui/screens/recurring_screen.dart` + `recurring_edit_sheet.dart` — S-19
  `/recurring`. Rules with their next due date (and "was due" when it has
  passed), auto-post/reminder footer, a 30-day strip that counts what is coming,
  one native in-feed ad under the rules and nothing above them. The editor is
  one sheet for new and existing rules: name, amount, direction, category,
  account, frequency with an interval, first payment date, the auto-post switch
  and the reminder timing — with the day-of-month note said out loud instead of
  surprising the user in February. Turning a reminder on is the one moment the
  notification permission is asked for.
- `lib/data/db.dart` — **schema v2**: `recurring_rules`, with a `if (from < 2)`
  step and `test/data/migration_test.dart`, which opens a file written as v1 and
  proves the ledger survived and the new table is writable.
- `test/` — budgets 21, budget detail 17, accounts 15, insights 33, alerts 17,
  recurring math 20, recurring pipeline 19, recurring screen 16, migration 1
  (406 total), plus the render smoke pass over every route in 3 languages × 2
  text scales.

**Bugs the tests surfaced (all fixed):**
1. `monthProgress()` reads the day off the date it is given; the insights
   forecast was handing it the 1st, so it thought one day had elapsed and hid
   the card for the first days of every month.
2. The insights compare row overflowed a 360dp phone by 150px — the trailing
   amount and delta now shrink together.
3. `SectionHeader` had no ellipsis, so Bengali's "অ্যাকাউন্ট যোগ করুন"
   overflowed at 1.3×; the same class of bug bit the account card's balance.
4. Hidden lazily-loaded providers: `budgetStatusesProvider` is a Future on
   purpose — `valueOrNull` on a provider nobody has started is null, and an
   alert pipeline that sees an empty ledger decides there is nothing to warn
   about.
5. The 30-day strip ended at midnight of its thirtieth day, so a payment due at
   9 am on that very day was counted out of the strip that was showing it; the
   window now runs to the end of the day.
6. The strip header and its day tiles overflowed at 1.3× text scale — "27 due in
   the next 30 days" has nowhere to shrink in a two-up row. Title and count
   stack, and a tile caps the text scale inside its own 56 px chip.
7. A reminder was re-sent every day inside its window; "remind me three days
   before" now means one nudge, remembered against the due date.

---

## 🔜 Batch 7 — Monetization (in progress)

- [x] **T-601** AdMob SDK init **after first frame**, test IDs in debug flavor
- [x] **T-602** `AdGate` interstitial governor (max 1/session) + unit test
- [x] **T-603** Native ad units (budget list, recurring)
- [x] **T-604** S-22 Paywall — 3 tiers, restore button, no dark patterns
- [x] **T-605** `in_app_purchase` — 3 products + `purchaseStream` + restore
- [x] **T-606** Rewarded: 24h Pro taste + free PDF export + daily caps
- [x] **T-607** UMP consent form (first ad request) + India personalized-ads toggle
- [x] **T-608** `test/ads/ad_slot_test.dart` — Pro user → `SizedBox.shrink()`
- [x] **T-609** Audit: grep every `AdRequest` site → **zero** financial data passed
- [ ] **T-610** Settings toggle: "personalized ads" (off by default in India)

**What landed (T-604, T-605):**
- `lib/pro/` — the billing half of Pro, and the only place that imports
  `in_app_purchase`. `product_ids.dart` holds the three ids, the documented
  prices and the entitlement window; `entitlement.dart` is the record Play last
  confirmed, encoded as one readable line (`yearly|1759939200000|restore`);
  `billing_client.dart` is the seam (`available`, `events`, `buy`, `restore`);
  `billing_client_mobile.dart` is the plugin; `billing_client_web.dart` is a
  const stub whose `available` is false.
- **The entitlement is a window, not a boolean.** Monthly is honoured for 31 days
  and yearly for 372, both longer than the period they pay for — a renewal still
  in flight must never lock a paying user out — and `proStatusProvider` is now a
  *derived* `Provider<bool>` that re-reads the clock, so a window that runs out
  reads Free immediately. Lifetime's window is null: nothing to count down.
- **The store's price is what the paywall shows.** `proProductsProvider` asks
  Play; when it cannot, the screen falls back to `fallbackPricePaise` and says
  the numbers are estimates. Nothing in this app formats a price and calls it
  the store's.
- **A purchase is granted on `purchased`/`restored`, and never on the tap.** Play
  answers after the sheet closes, so the paywall says "opening the store…" and
  the snackbar comes from the event, not from the tap. `pending` gets its own
  note ("the store is reviewing it") and grants nothing.
- **Restore is on the paywall *and* in Settings** (`docs/08 §6`), and the
  controller also restores once per launch: it is what gives a reinstall its Pro
  back and what ends a subscription that lapsed in the store.
- **The paywall gate is arithmetic** (`lib/pro/paywall_gate.dart`, §S-22): a tap
  on something that names Pro is always honoured, a Pro-locked insight earns the
  paywall on the third tap, the app offers itself from the tenth session, and
  never more than one paywall a session — counters in `app_meta`, so the tenth
  session is the tenth session of the install.
- **There are no counted-down offers, no fake discounts and no struck-through
  prices**, and the tests say so by pattern, not by eye:
  `test/ui/paywall_test.dart` searches every string on the screen for
  `\bleft\b`, `\bending\b`, `was ₹`, `hurry`, `limited time`.
- **The trial reminder** (`lib/pro/trial_reminder.dart`) is S-22's last rule:
  Play charges on the eighth day of a yearly trial, so on the *last* day of one
  — and only on that day, only for a trial bought in this app, only once — the
  next launch posts a notification that says where to cancel. It says **no
  price**: the store's price is the store's to state, and a notification is not
  a place to guess at money. A notification the host refuses stays owed, the
  same bargain T-505 makes.

**What landed (T-601 … T-603, T-608, T-609):**
- `lib/ads/` — the whole ads layer, and the only place that knows the SDK
  exists. `ad_placement.dart` names the six placements as *screens* (`ss_home_banner`,
  `ss_budget_native`, …), `ad_ids.dart` is the flavor switch, `ad_client.dart` is
  the seam, `ad_client_mobile.dart` is the SDK, `ad_client_web.dart` is the web
  preview's honest "nothing". The conditional import came across from
  `lib/data/db.dart` unchanged — the preview still builds with no SDK in it.
- **The flavor is the switch.** A debug build can only ever resolve to Google's
  test ids and a release build can only resolve to the live ones; the check is
  `test/ads/ad_ids_test.dart`, in both directions. The live ids are **empty in
  the repo** until Keshab creates the units — an unset id means that placement
  shows nothing, never a test ad in production.
- **`AdSlot` is now the only widget an ad can appear in.** Screens name a
  placement; the widget asks `adsVisibleProvider`, gets the unit from the client,
  and renders nothing for Pro, nothing before onboarding, nothing on web, and
  nothing when the load fails — a failed ad collapses the slot instead of
  leaving a 56 dp hole. A native unit's reserved height is a *floor*, never a
  ceiling, or the ad's own click target would be clipped.
- **The manifest app id comes from Gradle**, not from the XML: debug gets the
  test app id, release reads `admob.appId` from `android/local.properties` (the
  gitignored, machine-local file) or `-Padmob.appId=…`, so the live id never
  lands in the repo. A missing id falls
  back to the test one at *manifest* level only — the app still requests nothing,
  because the live unit ids are empty.
- **The SDK initializes after the first frame**, never on the splash, and only
  when `adsVisibleProvider` is true — a Pro user's phone never starts the SDK.
- **The interstitial governor** (`AdGateRules`) is pure: one trigger
  (`homeToInsights`), one per session, a 240-second floor, never for Pro, never
  before onboarding. The gate shows it *after* the destination screen is built,
  and an attempt that fails to load does **not** spend the session's one
  interstitial.
- **The audit is a test.** `test/ads/ad_request_audit_test.dart` reads `lib/` as
  text and fails if a second `AdRequest` site appears, if that request grows a
  targeting field, if the SDK client mentions an amount or a merchant, if
  `AdSpec` grows a fifth field, if a screen outside the `✅` list in `docs/03`
  imports `AdSlot`, or if the manifest stops taking its app id from Gradle.

**Bugs the tests surfaced (all fixed):**
1. `AdSlot` rebuilt its ad request on every `build`. Invisible in a fake, fatal
   on a device: the second request lands after the first was already paid for.
   The creative is now created once per slot.
2. The interstitial unit was being borrowed from a banner placement. The audit
   test is what caught it — a whole-screen format is not a placement, and
   `AdFormat` now says so.
3. `docs/03` and the code had drifted: budget detail and accounts both declared
   `sectionBanner`, which resolved to the insights unit. Each screen now has the
   placement its own spec names, and S-20 Settings — which has **no** unit —
   lost the slot it had grown.
4. The `240s` floor was off by a boundary (`<` where `docs/08 §4` writes `>`),
   so an interstitial could fire exactly four minutes later.

**What landed (T-606, T-607):**
- **`lib/pro/rewards.dart`** — the two offers of `docs/08 §5` as arithmetic and a
  ledger. The caps are 1 taste a day and 2 PDF credits a day; the counters live
  in `app_meta` per kind **and per day**, so yesterday's taste cannot be spent
  today and a ledger left open across midnight rolls itself. `RewardRules.offers`
  says no to a Pro user, to a build with no rewarded unit, and before onboarding
  — three ways the offer must not exist.
- **Only the store's word grants.** `RewardedOutcome.earned` comes from the SDK's
  `onUserEarnedReward`; a dismissed ad grants nothing *and does not spend the
  day's one*, because the cap is on grants, not on attempts. Three outcomes, three
  tests, and three different sentences on screen.
- **The 24-hour taste is an entitlement, not a flag.** `ProPlan.taste` goes
  through the same `ProController._write` as a purchase — same window arithmetic,
  same expiry, same clearing on the next launch — so the forecast, the ad slots
  and the paywall cannot tell a taste from a subscription and do not have to.
  What they *can* tell is when it ends, and the paywall says "24-hour taste" and
  no renewal date rather than promising a payment nobody will make.
- **The taste is not for sale**: `productIdFor` returns null for it, the store is
  never queried, and `buy()` refuses it. The paywall's tiers come from
  `purchasablePlans`, so the three prices are still the three prices.
- **The offer is opt-in and labelled**, on the locked insight it unlocks
  (Insights → the Pro card): "Watch an ad for 24 hours of Pro" — the sentence
  `docs/08 §5` asks for, in all three languages, as a *secondary* button next to
  "See Pro" and never inside the paywall (§S-22 forbids ads there, and the
  `never` list in the audit test holds it). When the day's one is spent the
  button is replaced by a sentence that says so.
- **The free PDF export is a credit S-23 spends** (`pdfExportCreditsProvider` +
  `RewardLedger.spendPdfCredit`), granted twice a day, and spending one cannot
  buy a third ad — the cap counts grants, not what is left. **T-705 consults it.**
- **`lib/ads/ad_consent.dart` + the seam (T-607)** — the consent flow runs
  *before* the SDK is initialized (`docs/08 §7`), and the mobile client starts
  with `_mayRequestAds = false`: nothing is requested until Google's own
  `canRequestAds()` says it may be. A user in the EEA who was asked and did not
  agree gets no ads at all, and the SDK is never even started on their phone.
  A failed consent call leaves the gate closed, which is the cheap direction.
- **India gets non-personalized ads by default.** The choice is stored in
  `app_meta` (`personalizedAds`), read on every launch, and handed to every
  request as `nonPersonalizedAds` — and only ever from there: the audit test
  still finds exactly one place in the app that can build a request. T-610 puts
  the switch in Settings; `ConsentController.setPersonalized` and
  `privacyOptionsRequired()` (the UMP "change your mind later" door) are already
  there for it.
- **A debug build is treated as the EEA** (`ConsentDebugSettings`), so the form
  can actually be seen and tested from India. Release builds always get the real
  geography — the same rule the ad ids follow.

**Bugs the tests surfaced (T-606/T-607, all fixed):**
9. The paywall built its tiers from `ProPlan.values`, so adding the taste plan
   put a fourth, priceless tier on the screen and crashed on a null `plans[plan]`.
   Tiers now come from `purchasablePlans`, which is derived from the product ids.
10. `expiresAtMs` used `isRenewing(plan)` to mean "this has an end", and a taste
    is not renewing — so it would have been treated as a lifetime unlock and
    never expired. Worse, the first fix (making the taste "renewing") made the
    paywall promise "Renews on…" to somebody who was never going to be charged.
    Lifetime is now the only plan without an end, and a renewal line is only
    drawn for the two plans the store will bill again.
11. The ad offer sat in a `Row` beside "See Pro", which overflowed at 360 dp in
    Bengali (the label is a whole sentence, because that is what "clear label"
    means). It is full-width below the paid action now — and `docs/08 §5`'s
    Bengali is on the button, not in a tooltip.
12. The very first version of the offer could be tapped before the day's ledger
    had loaded, which read an empty counter as "nothing granted yet". The shell
    loads the ledger with the rest of the launch work, and the button reads what
    the ledger published rather than guessing.

**Bugs the tests surfaced (T-604/T-605, all fixed):**
5. `billingClientProvider` was read before the store had answered in tests, so a
   *cancelled* purchase still wrote `proEntitlement` — the controller now
   ignores anything that is not `purchased`/`restored`, and the fake store's five
   outcomes each have their own test.
6. The paywall's fallback prices were rendered side by side with the store's
   without saying which was which. The estimate note is now printed above the
   tiers whenever `proProductsProvider` is empty.
7. The privacy and terms sheets were a fixed `Column`, so the policy text
   overflowed on a 360 dp phone. Both sheets scroll now.
8. Tapping the Settings card opened a paywall for a user who *already pays* —
   the gate reads `proStatusProvider` first and Pro users get their own card
   (plan + renewal), with nothing to buy and restore still offered.

**Next:** T-610 — the Settings half: the "personalized ads" switch (off by
default in India, which is the default `lib/ads/ad_consent.dart` already
applies) plus the "privacy options" row when UMP says the app has to offer one.
The mechanism is in place; what is missing is the door. After that Batch 7 is
done, and Batch 8's T-705 is where the free PDF export credit gets spent.

---

## 🔜 Batch 8 — Localization + compliance screens

- [ ] **T-701** `lib/l10n/*.arb` — en/hi/bn full key set
- [ ] **T-702** `test/l10n/l10n_test.dart` — key parity across locales
- [ ] **T-703** Category names in 3 languages (seed)
- [ ] **T-704** S-21 About/Privacy — text must match `07` §5
- [ ] **T-705** S-23 Export/Backup — AES-256-GCM + CSV + rewarded PDF
- [ ] **T-706** Settings data-erase (double confirm) + biometric lock
- [ ] **T-707** Bengali digits toggle

---

## 🔜 Batch 9 — Release prep

- [ ] **T-801** App icon from `app-icon.png` → `flutter_launcher_icons` (adaptive)
- [ ] **T-802** Splash native config (`flutter_native_splash`) using brand gradient
- [ ] **T-803** Compress `assets/3d/*` → webp 2×, target < 120 KB each
- [ ] **T-804** `distribution/whatsnew/` — rename `bn-BD`→`bn-IN`, add `hi-IN`
- [ ] **T-805** Keystore + GitHub secrets (Keshab, locally — never in repo)
- [ ] **T-806** Privacy policy live URL (GitHub Pages)
- [ ] **T-807** **Demo video** recorded (7 shots per `07` §3)
- [ ] **T-808** Play listing assets: 8 screenshots × 3 languages + feature graphic
- [ ] **T-809** Permissions Declaration + Data Safety submitted
- [ ] **T-810** Internal test → 12-tester closed test (14 days) → production

---

## 📌 Standing rules while working

1. `preflight` before **every** push.
2. **Never** `flutter build apk|aab|web` locally.
3. Push straight to `main`; commit often; batch CI.
4. **Ask Keshab** for: tags/releases, workflow/secret/settings changes, anything public or irreversible.
5. Never let a secret into git.
6. Every parser rule change → fixture + test in the same commit.
7. Every new screen → its acceptance criteria from `03` must be testable.
