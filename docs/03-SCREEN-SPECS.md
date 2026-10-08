# 03 — Screen Specifications

23 screens. Protita-r: purpose · layout · states · components · ads · motion · acceptance.

Legend: **P0** = v1.0 must ship · **P1** = v1.0 target · **P2** = v1.1

---

## S-01 · Splash — `/splash` — P0

**Purpose:** Brand moment + parallel boot (DB open, prefs, locale load).

**Layout**
```
[gradient hero background, full bleed]
        ⋮ 34% height
   splash-hero.jpg   (width 62% screen, centered)
        ⋮ space 28
   "SpendStory"       displayMoney 44 / w800, white
   "তোমার টাকার গল্প"  caption, textSecondary
        ⋮  bottom 48
   [ 3-dot loading, teal ]
```

**States:** booting → ready → route replace (no back stack).
**Motion:** illustration fade+scale 0.92→1.0 (600ms) · logo fade-up 160ms delay · Ken-Burns on hero.
**Ads:** none.
**Accept:** cold start ≤ 1.2s on mid-range device; DB migration runs here, not on Home.

---

## S-02 · Onboarding 1 — Auto Capture — `/onboarding/1` — P0

**Purpose:** Value proposition — "you don't have to type".

**Layout**
```
[3-page PageView, skip top-right]
  onboard-auto-capture.jpg   (78% width)
  h1  "খরচ লিখতে হবে না"
  body "ব্যাংকের SMS আর UPI notification থেকে
        SpendStory নিজেই হিসাব রাখে।"
  · bullet: ব্যাংক SMS → অটো এন্ট্রি
  · bullet: GPay / PhonePe / Paytm
  · bullet: ৩ সেকেন্ডে আপডেট
  [page dots]              [Next]
```
**Assets:** `onboard-auto-capture.jpg`
**Motion:** parallax 0.3× on page scroll · float loop 3s ±6px.
**Ads:** ❌ never (policy: no ads in onboarding).
**Accept:** swipe works both directions; skip → `/language`.

---

## S-03 · Onboarding 2 — Privacy — `/onboarding/2` — P0

**Layout:** same as S-02 with `onboard-privacy.jpg`.
```
  h1   "তোমার ফোনেই থাকে"
  body "ডেটা কোথাও যায় না — সার্ভার নেই,
        ক্লাউড নেই, অ্যাকাউন্ট নেই।"
  · bullet: no internet needed
  · bullet: no bank login / OTP
  · bullet: uninstall = data gone
```
**Extra:** "কেন ভরসা করব?" expandable → 4-line plain-language explanation + link to source code.
**Ads:** ❌.

---

## S-04 · Onboarding 3 — Insights — `/onboarding/3` — P0

**Layout:** `onboard-insights.jpg`
```
  h1   "টাকা কোথায় যাচ্ছে, দেখো"
  body "ক্যাটাগরি, বাজেট, ট্রেন্ড — এক নজরে।"
  · bullet: monthly donut
  · bullet: বাজেট alert at 80%
  · bullet: top merchant
  [Start]  ← primary gold CTA
```
**Ads:** ❌.

---

## S-05 · Language Picker — `/language` — P0

**Purpose:** Device locale auto-select + manual override.

**Layout**
```
  h2 "Choose your language / भाषा चुनें / ভাষা বাছুন"
  3 × LanguageCard (glass): 
     English  · English          [auto-detect tag]
     हिन्दी    · Hindi
     বাংলা     · Bengali
  caption: "पर बाद में बदल सकते हैं · Settings → Language"
```
**Behaviour:** auto-highlight device locale · tap = immediate switch (no restart) · writes `prefs.locale`.
**Ads:** ❌.

---

## S-06 · Permission — SMS — `/permission/sms` — P0

**Purpose:** Ask READ_SMS with **honest, specific** explanation. This is the Play-policy-sensitive screen.

**Layout**
```
  permission-sms.jpg   (68% width)
  h2  "ব্যাংকের SMS পড়ার অনুমতি দিন"
  body (plain language):
    "আমরা শুধু ব্যাংকের লেনদেনের SMS দেখি —
     OTP বা ব্যক্তিগত message কখনো পড়ি না।"
  □ (checked, disabled) "OTP message কখনো সংরক্ষণ হবে না"
  □ (checked, disabled) "কোনো ডেটা ইন্টারনেটে যাবে না"
  [ অনুমতি দিন ]        ← primary
  [ নিজে নিজে লিখব ]    ← ghost → /permission/manual
  link: "কীভাবে কাজ করে?" → detail sheet
```
**Rules (must follow):**
1. Ads **never** on this screen (Play policy + trust).
2. Explain *what* is read, *what* is not, *why*.
3. Deny path always visible — equal weight.
4. If denied: no re-prompt; show soft banner on Home once.
5. Never show the OS dialog before this explainer screen.
**Motion:** glow pulse on illustration (2.4s loop, subtle).
**Accept:** denial → app fully usable; no crash, no nag loop.

---

## S-07 · Permission — Notification Access — `/permission/notification` — P0

**Purpose:** NotificationListener access for GPay/PhonePe/Paytm capture.

**Layout:** `permission-notification.jpg`
```
  h2  "পেমেন্ট notification ধরার অনুমতি"
  body "শুধু বেছে নেওয়া অ্যাপের পেমেন্ট alert —
        চ্যাট, OTP, ব্যক্তিগত notification নয়।"
  ▶ App whitelist list (GPay, PhonePe, Paytm, BHIM, CRED)
    sob default checked · user toggle korte parbe
  [ সেটিংসে যান ]  → opens Special App Access screen
  [ বাদ দিন ]
```
**Behaviour:** after return, verify with `NotificationManagerCompat` → tick animation.
**Monetization:** ❌ no ads.
**Accept:** only whitelisted packages parsed; verified by test.

---

## S-08 · Manual-only Path — `/permission/manual` — P0

**Purpose:** Respect the "no" — and convert it into a good experience.

**Layout**
```
  h2 "ঠিক আছে — নিজে লিখেই চলবে"
  body "সব feature কাজ করবে, শুধু অটো এন্ট্রি থাকবে না।
        পরে Settings থেকে চালু করতে পারবেন।"
  · What works: add/edit, budget, insights, export
  · What's missing: auto-capture
  [ শুরু করি ]  → /home
```
**Ads:** ❌.
**Accept:** user lands on Home with empty state + quick-add CTA.

---

## S-09 · Home / Dashboard — `/home` — P0

**Purpose:** The daily glance. 3-second answer: "ekhon obostha ki?"

**Layout**
```
[Header row: greeting + month picker + bell]
[HERO MONEY CARD  — moneyGradient, radius xl]
   এই মাসে খরচ
   ₹ 12,480          displayMoney, count-up
   ↑ 8% গত মাসের চেয়ে        (rose/teal)
   ───────────────
   আয় ₹45,000   বাকি ₹32,520
[AdSlot — anchored adaptive banner, 50dp reserved]   ← only ad on this screen
[Quick actions row: + খরচ · + আয় · স্ক্যান]
[আজকের হিসাব — date-wise mini list, top 3 + "সব দেখুন"]
[বাজেট কার্ড — BudgetBar 1-2 ta]
[Insights teaser — small donut + "বিস্তারিত"]
[Bottom nav: Home · Transactions · Insights · Settings]
```
**States:** loading (skeleton, no spinner) · empty (→ `empty-transactions.jpg` + CTA) · normal · error (never — offline only).
**Ads:** ✅ **1 banner only**, below hero money card, reserved height (no layout shift). **Never** inside the transaction list, never between list rows.
**Motion:** money count-up on mount + on data change · budget bar fill · card press scale.
**Accept:** first paint ≤ 800ms from cache; pull-to-refresh recompute ≤ 300ms.

---

## S-10 · Transactions List — `/transactions` — P0

**Purpose:** Full history, fast scan, fast filter.

**Layout**
```
[Search bar (tap → S-18)  ][filter icon → sheet]
[Month strip: ‹ অক্টো ২০২৬ ›]
[Summary chips: খরচ ₹12,480 · আয় ₹45,000]
[Grouped by date:]
   আজ · ৭ অক্টোবর
     🛒 BigBasket          -₹1,240   UPI
     💰 বেতন               +₹45,000  HDFC
   গতকাল · ৬ অক্টোবর
     ...
[Swipe row → Edit / Delete / Re-categorize]
[Empty: empty-transactions.jpg + "প্রথম খরচ যোগ করুন"]
```
**Row anatomy:** category icon (40dp circle, tinted) · merchant (bodyStrong) · category + account + mode (caption) · amount (MoneyText, tabular).
**Ads:** ❌ **not on this screen** — list + ads = accidental clicks + policy risk.
**Motion:** list item stagger fade-in (30ms) · swipe action reveal.
**Accept:** 1,000 rows scroll 60fps (use `ListView.builder` + index).

---

## S-11 · Transaction Detail — `/transactions/:id` — P0

**Layout**
```
[big category icon + glow]
  ₹1,240              displayMoney, expense color
  BigBasket           h2
  ─────────
  তারিখ    ৭ অক্টো ২০২৬, ৮:৪২ PM
  ক্যাটাগরি খাবার        [change]
  অ্যাকাউন্ট HDFC Savings
  মোড      UPI
  সোর্স    ✓ অটো (SMS)   ← traceability! "এই SMS থেকে"
  নোট      ...
  ─────────
  [raw SMS viewer — collapsed, tap to expand]  ← trust feature
  [এডিট] [মুছুন]
```
**"Source" row is a differentiator:** user dekhte pare kon SMS theke ki parse holo. Bhorsa build kore.
**Ads:** ❌.
**Motion:** hero icon scale-in · expand smooth.

---

## S-12 · Add / Edit Transaction — `/transactions/edit` — P0

**Purpose:** The single most-used action. Must be ≤ 5 seconds.

**Layout (bottom sheet, 88% height)**
```
[Amount keypad — custom, large, thumb-reachable]
   ₹ [  1,240 ]        displayMoney
[খরচ | আয়] segmented
[Category — horizontal chips, most-used first]
[Account picker]  [Date picker]  [Mode: Cash/UPI/Card]
[নোট — optional, one line]
[সেভ]  ← full width primary, sticky bottom
```
**Rules:** keypad opens by default · last-used account/category preselected · save = haptic + tick animation + sheet close.
**Ads:** ❌ **never** — data entry e ad = misclick + Play policy risk.
**Accept:** 3 taps → saved. No scroll needed on a 6" screen.

---

## S-13 · Categories Manager — `/categories` — P1

**Layout:** two tabs (খরচ / আয়) · grid 3-col of CategoryCard · FAB `+`.
**Category editor sheet:** emoji/icon picker · name (3 langs) · color chip picker · monthly cap (optional) · delete (with reassign warning).
**Ads:** ❌.
**Default categories (expense):** খাবার · বাজার · যাতায়াত · বিল · ভাড়া · স্বাস্থ্য · শিক্ষা · কাপড় · বিনোদন · রিচার্জ · EMI · অন্যান্য
**Default (income):** বেতন · ব্যবসা · ফ্রিল্যান্স · সুদ · উপহার · অন্যান্য

---

## S-14 · Budget List — `/budgets` — P1

**Layout**
```
[Headline: এই মাসের বাজেট ₹25,000 — ৫০% ব্যবহৃত]
[overall BudgetBar — big, gradient fill]
[Category budgets, sorted by % used desc:]
   খাবার      ₹4,000/₹6,000   [████░] 67%   teal
   যাতায়াত    ₹2,900/₹3,000   [█████] 97%   gold ⚠
   বিনোদন      ₹3,200/₹3,000  [█████] 107%  rose 🚨
[Empty: empty-budget.jpg + "বাজেট সেট করুন"]
[+ নতুন বাজেট]
```
**Alert logic:** 80% → local notification (once/day max) · 100% → different notification · 120% → suggestion card.
**Ads:** ✅ **1 native ad** after the 3rd budget row (in-feed), never above the fold. Marked "Sponsored".
**Motion:** bar fill stagger 80ms · threshold color cross-fade.

---

## S-15 · Budget Detail / Edit — `/budgets/:id` — P1

**Layout:** big circular gauge · spent/left/total · daily allowance = left ÷ days remaining · "ei gache e din-e ₹X khoroch korle budget thik thakbe" · recent tx in this category · edit sheet.
**Ads:** ✅ 1 banner at bottom.
**Differentiator:** *daily allowance number* — the single most actionable insight for a salaried Indian user.

---

## S-16 · Accounts — `/accounts` — P1

**Layout:** account cards (bank/cash/wallet/card) with balance · total net · `+ add` · account editor sheet (name, type, opening balance, color, last-4 digits).
**Ads:** ✅ 1 banner at bottom.
**Note:** balance = opening + credits − debits, computed. No bank API.

---

## S-17 · Insights & Analytics — `/insights` — P1

**Layout**
```
[Period segmented: সপ্তাহ | মাস | বছর | কাস্টম]
[Donut — category split, tap slice → detail]
[Trend line — daily spend, 30 days, gradient fill]
[Top merchants — top 5 with bars]
[Month compare — this vs last, delta chips]
[Biggest jump — "খাবার ৩২% বেশি"]
[প্রবণতা — "সপ্তাহান্তে বেশি খরচ" pattern]
[Pro-locked block: "ভবিষ্যৎ পূর্বাভাস" → /pro]
```
**Ads:** ✅ 1 banner at very bottom (below all content, never interleaved with charts).
**Motion:** donut sweep + stagger · line draw 900ms · number count-up.
**Pro gate:** basic insights free forever; forecast + custom date range + export = Pro.

---

## S-18 · Search & Filter — `/search` — P1

**Layout:** search field (merchant, note, amount) · filter sheet: date range · category multi-select · account · amount range · mode · source (auto/manual) · chip row of active filters · result count.
**Ads:** ❌.

---

## S-19 · Recurring & Reminders — `/recurring` — P2 (v1.1)

**Layout:** list of recurring rules (rent, EMI, subscriptions) · next due · auto-post toggle · reminder timing · upcoming 30-day calendar strip.
**Ads:** ✅ 1 native in-feed.

---

## S-20 · Settings — `/settings` — P0

**Sections**
```
সাধারণ
  ভাষা / Language        → /language
  থিম  (ডার্ক ডিফল্ট / লাইট / সিস্টেম)
নিরাপত্তা
  অ্যাপ লক (biometric)
  ডেটা মুছুন (destructive, double-confirm)
ক্যাপচার
  SMS ক্যাপচার status + toggle
  Notification access status + toggle
  App whitelist → /permission/notification
ব্যাকআপ
  এনক্রিপ্টেড ব্যাকআপ ফাইল তৈরি
  CSV export        (Pro: PDF)
  রিস্টোর
মনিটাইজেশন
  বিজ্ঞাপন সরান → /pro
  Pro status / restore purchase
সম্পর্কে
  Privacy Policy · Terms · Open-source licenses
  অ্যাপ ভার্সন ১.০.০ (build 1)
  "রিপোর্ট / ফিডব্যাক"
```
**Ads:** ❌ (settings e ad = policy irritant).

---

## S-21 · Privacy & About — `/about` — P0

**Layout:** plain-language privacy summary (scroll) · full policy link · what we collect (**nothing**) · permissions explained one-by-one · data deletion steps · contact email · DPDP rights (access/correct/erase) · source repo link.
**Ads:** ❌.
**Why it matters:** ei screen ta Play declaration er sathe consistent hote hobe — `07-PERMISSIONS-POLICY.md` dekho.

**Implemented (T-704):** `lib/ui/screens/about_screen.dart`, route `/about`.
Reachable from the SMS permission screen (before the first ask), Settings →
Privacy, and the paywall's privacy summary. The contact address is
`AppInfo.grievanceEmail` and is empty until Keshab sets it (`08 §8b`); until
then the screen says so and points at the repository. There is no `AdSlot` on
it, and both contact rows copy rather than open a browser.

---

## S-22 · Pro Paywall — `/pro` — P0

**Layout (full-screen sheet, hero top)**
```
[pro-hero.jpg + sparkle overlay]
  "SpendStory Pro"    h1, gold gradient text
  "বিজ্ঞাপন নেই, আরও গভীর হিসাব"
  ──────
  [ ₹99 / মাস ]   ← default-selected
  [ ₹699 / বছর ]  ← "৪২% সাশ্রয়" badge (anchor)
  [ ₹1,499 আজীবন ] ← limited
  ──────
  ✅ সব বিজ্ঞাপন নেই
  ✅ ভবিষ্যৎ খরচের পূর্বাভাস
  ✅ কাস্টম তারিখ রেঞ্জ + PDF এক্সপোর্ট
  ✅ সীমাহীন বাজেট ও ক্যাটাগরি
  ✅ Google Drive এনক্রিপ্টেড ব্যাকআপ
  [ ৭ দিন ফ্রি ট্রায়াল ]  ← gold CTA
  "ট্রায়াল শেষ হলে ₹99/মাস। যখন খুশি বাতিল।"
  [পরে দেখব]  ·  [কেনা ফিরিয়ে আনুন]
```
**Rules:** privacy + terms link mandatory · price clearly shown · no countdown-timer dark pattern · trial reminder 1 day before.
**Ads:** ❌ **never inside a paywall** (policy).
**Placement triggers:** (a) Settings tap, (b) 3rd time tapping a Pro-locked insight, (c) after 10th session — max 1 paywall/session.

---

## S-23 · Export / Backup — `/export` — P2

**Layout:** backup-now card (AES-256, password field) · file picker / Drive · restore (file picker + password) · CSV export (all free) · PDF statement (Pro) · auto-backup toggle (weekly, to chosen folder).
**Ads:** ✅ 1 rewarded ad option: "watch ad → 1 free PDF export" (India te khub kaj kore).
**Accept:** restore on fresh install returns 100% of tx, categories, budgets, accounts.

**Implemented (T-705):** `lib/ui/screens/export_screen.dart`, route `/export`,
reached from Settings. Backup writes the whole ledger encrypted with AES-256-GCM
under a password the user chooses and hands the file to the share sheet; restore
picks a file and adds it without wiping what is on the phone. CSV is free for
everyone — the Pro card's copy said otherwise and was corrected here. The PDF
statement is Pro, or one rewarded credit earned on the screen itself. Two
sentences of this spec are knowingly not built as written: the weekly
"auto-backup to a folder" is a weekly *reminder* (an unattended encrypted write
needs a stored password, which would break `07 §5`), and "Drive" is the share
sheet rather than a Drive SDK, so `08 §6`'s Drive auto-backup is still open.

---

## 🚫 Ads summary (what the policy doc will enforce)

| Screen | Ad allowed | Type |
|---|---|---|
| Splash, Onboarding 1-3, Language, Permissions (S-06,07,08) | ❌ | — |
| Home (S-09) | ✅ 1 | anchored banner, below hero |
| Transactions list (S-10), Detail (S-11), Add/Edit (S-12) | ❌ | — |
| Categories (S-13) | ❌ | — |
| Budget list (S-14) | ✅ 1 | native in-feed (after 3rd row) |
| Budget detail (S-15), Accounts (S-16) | ✅ 1 | banner, bottom |
| Insights (S-17) | ✅ 1 | banner, very bottom |
| Search (S-18) | ❌ | — |
| Recurring (S-19) | ✅ 1 | native in-feed |
| Settings (S-20), About (S-21), Paywall (S-22) | ❌ | — |
| Export (S-23) | ✅ optional | rewarded (user-initiated only) |

**Plus:** interstitial — max **1 per session**, only after Home→Insights navigation, **never** before a data-entry screen or on app open.
