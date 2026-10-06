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

**Next:** Batch 3 — design system + shell (`lib/ui/tokens.dart` from `docs/02-DESIGN-SYSTEM.md`).

---

## 🔜 Batch 3 — Design system + shell

- [ ] **T-201** `lib/ui/tokens.dart` — colors, gradients, spacing, radius, typography (from `02`)
- [ ] **T-202** Fonts bundled — Manrope + Noto Sans Bengali/Devanagari → `assets/fonts/`
- [ ] **T-203** `SsScaffold` + `GlassCard` + `SsButton`
- [ ] **T-204** `MoneyText` (tabular, sign color, 3-lang format)
- [ ] **T-205** `HeroIllustration` + `EmptyState` + `AdSlot` (returns nothing for Pro)
- [ ] **T-206** `BudgetBar` + `DonutChart` + `CategoryChip`
- [ ] **T-207** `lib/app/router.dart` per `04-NAVIGATION.md` + `MainShell` (4-tab bottom nav)
- [ ] **T-208** `test/app/router_test.dart` — first-run vs returning redirect

---

## 🔜 Batch 4 — Onboarding + permissions (S-01 … S-08)

- [ ] **T-301** S-01 Splash (boot: DB open, prefs, locale)
- [ ] **T-302** S-05 Language picker (instant switch, no restart)
- [ ] **T-303** S-02/03/04 Onboarding PageView + parallax
- [ ] **T-304** S-06 Permission SMS explainer + `permission_handler`
- [ ] **T-305** S-07 Notification access + whitelist UI + `NotificationListenerService` (Kotlin)
- [ ] **T-306** S-08 Manual-only path
- [ ] **T-307** Golden test at `bn` locale for S-02/03/04 (overflow check)

---

## 🔜 Batch 5 — Core app (S-09 … S-13)

- [ ] **T-401** S-09 Home — hero money card, count-up, banner ad slot, quick actions
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
