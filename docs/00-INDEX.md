# SpendStory — Documentation Index

> **App:** SpendStory · UPI & bank SMS expense tracker
> **Package:** `com.keshabstudios.spendstory`
> **Stack:** Flutter 3.47.6 · Material 3 · Riverpod · Drift (SQLite) · 100% on-device
> **Languages:** English (default) · Hindi · Bengali
> **Monetization:** AdMob (free tier) + Pro subscription

---

## 📚 Dokuments (ei serial e poro — number onujayi kaj koro)

| # | File | Ki ache |
|---|---|---|
| 00 | `00-INDEX.md` | Ei file — master plan + screen inventory |
| 01 | `01-PRD.md` | Product requirements, features, user stories, scope |
| 02 | `02-DESIGN-SYSTEM.md` | Advanced 3D design language, color/type/spacing tokens, motion |
| 03 | `03-SCREEN-SPECS.md` | **Sob screen er detailed spec** (23 screens) |
| 04 | `04-NAVIGATION.md` | Routes, transition, deep links, flow diagram |
| 05 | `05-DATA-MODEL.md` | Drift schema, tables, DAOs, migrations |
| 06 | `06-SMS-PARSING.md` | Bank SMS regex rules, OTP filter, 30+ bank support |
| 07 | `07-PERMISSIONS-POLICY.md` | Play Console declaration, Data Safety, demo video script, DPDP |
| 08 | `08-MONETIZATION-ADMOB.md` | **Ad placement map**, policy rules, eCPM/revenue math, Pro tiers |
| 09 | `09-LOCALIZATION.md` | en/hi/bn strings, store listing copy, whatsnew |
| 10 | `10-CI-RELEASE.md` | Workflows, signing secrets, Play release steps |
| 11 | `11-TASKS.md` | **Serial task list** — kaj korার order |

**Assets:** `assets/3d/` — 10 ta AI-generated 3D illustration (design language er base)

---

## 🖼️ Screen Inventory — 23 screens (serial order)

| # | Screen | Route | Asset | Priority |
|---|---|---|---|---|
| 1 | Splash | `/splash` | `splash-hero.jpg` | P0 |
| 2 | Onboarding — Auto Capture | `/onboarding/1` | `onboard-auto-capture.jpg` | P0 |
| 3 | Onboarding — Privacy | `/onboarding/2` | `onboard-privacy.jpg` | P0 |
| 4 | Onboarding — Insights | `/onboarding/3` | `onboard-insights.jpg` | P0 |
| 5 | Language Picker | `/language` | — | P0 |
| 6 | Permission — SMS | `/permission/sms` | `permission-sms.jpg` | P0 |
| 7 | Permission — Notification | `/permission/notification` | `permission-notification.jpg` | P0 |
| 8 | Manual-only path | `/permission/manual` | — | P0 |
| 9 | **Home / Dashboard** | `/home` | — | P0 |
| 10 | Transactions list | `/transactions` | `empty-transactions.jpg` | P0 |
| 11 | Transaction detail | `/transactions/:id` | — | P0 |
| 12 | Add / Edit transaction | `/transactions/edit` | — | P0 |
| 13 | Categories manager | `/categories` | — | P1 |
| 14 | Budget list | `/budgets` | `empty-budget.jpg` | P1 |
| 15 | Budget detail / edit | `/budgets/:id` | — | P1 |
| 16 | Accounts | `/accounts` | — | P1 |
| 17 | Insights & Analytics | `/insights` | — | P1 |
| 18 | Search & Filter | `/search` | — | P1 |
| 19 | Recurring & Reminders | `/recurring` | — | P2 |
| 20 | Settings | `/settings` | — | P0 |
| 21 | Privacy & About | `/about` | — | P0 |
| 22 | **Pro Paywall** | `/pro` | `pro-hero.jpg` | P0 |
| 23 | Export / Backup | `/export` | — | P2 |

---

## 🎨 Design Direction (one-line brief)

> **"Premium clay-3D fintech"** — deep indigo→violet gradients, glassmorphism cards, floating 3D props, soft ambient teal glow, generous negative space, micro-animations on every state change. Material 3 base, but nothing looks like a default Flutter app.

Full tokens → `02-DESIGN-SYSTEM.md`

---

## ⚠️ Non-negotiable rules (sob doc e applicable)

1. **100% on-device.** Kono server nei. SMS/notification data kabhu device chhere na.
2. **OTP never read.** OTP messages filter out hobe — `06-SMS-PARSING.md` er hard rule.
3. **Manual entry always works.** Permission na dileo app puropuri kaj kore.
4. **Ads never near permission screens.** Play policy + user trust — `08-MONETIZATION-ADMOB.md`.
5. **CPM/Ads SDK er kache kono financial data jabe na.** AdMob ke sudhu "app open" event jabe, transaction data na.
6. **Localization from day 1.** Hardcoded English string nei — sob `.arb` file e.
