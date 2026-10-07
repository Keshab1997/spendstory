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
- [ ] **T-402** S-10 Transactions list — grouped, swipe actions, filter chips
- [ ] **T-403** S-11 Transaction detail — incl. **raw-SMS viewer** (trust feature)
- [ ] **T-404** S-12 Add/Edit sheet — custom keypad, 3-tap save
- [ ] **T-405** S-13 Categories manager + editor
- [ ] **T-406** S-18 Search & filter
- [ ] **T-407** Widget tests: add-tx flow, filter results, detail renders source

---

## 🔜 Batch 6 — Budget, insights, accounts

- [ ] **T-501** S-14 Budget list + native ad after 3rd row
- [ ] **T-502** S-15 Budget detail — circular gauge + **daily allowance**
- [ ] **T-503** S-16 Accounts + computed balances
- [ ] **T-504** S-17 Insights — donut, trend, top merchants, deltas
- [ ] **T-505** Budget alert notifications (80%/100%), once-per-day cap
- [ ] **T-506** S-19 Recurring & reminders (v1.1)

---

## 🔜 Batch 7 — Monetization

- [ ] **T-601** AdMob SDK init **after first frame**, test IDs in debug flavor
- [ ] **T-602** `AdGate` interstitial governor (max 1/session) + unit test
- [ ] **T-603** Native ad units (budget list, recurring)
- [ ] **T-604** S-22 Paywall — 3 tiers, restore button, no dark patterns
- [ ] **T-605** `in_app_purchase` — 3 products + `purchaseStream` + restore
- [ ] **T-606** Rewarded: 24h Pro taste + free PDF export + daily caps
- [ ] **T-607** UMP consent form (first ad request) + India personalized-ads toggle
- [ ] **T-608** `test/ads/ad_slot_test.dart` — Pro user → `SizedBox.shrink()`
- [ ] **T-609** Audit: grep every `AdRequest` site → **zero** financial data passed

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
