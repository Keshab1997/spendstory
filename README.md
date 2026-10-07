# SpendStory

> **Taka kothay gelo — likhte hobe na, jante parbe.**
> UPI & bank SMS expense tracker · English · हिन्दी · বাংলা · 100% on-device

---

## What it is

SpendStory reads your **bank transaction SMS alerts** and **UPI payment notifications** and turns them into a clean, categorised expense list — automatically. No manual typing, no bank login, no signup, no server.

Everything stays on your phone.

## Status

| | |
|---|---|
| **Phase** | Batches 1–5 complete — parser, design system, onboarding, and the core ledger screens |
| **Package** | `com.keshabstudios.spendstory` |
| **Flutter** | 3.47.6 stable · Dart 3.13.5 |
| **Next** | Batch 6 — budgets, insights, accounts → `docs/11-TASKS.md` |

## Documentation

Read in order — the docs are numbered deliberately.

| # | Doc | What's inside |
|---|---|---|
| 00 | [Index](docs/00-INDEX.md) | Master plan + 23-screen inventory |
| 01 | [PRD](docs/01-PRD.md) | Features, user stories, metrics, risks |
| 02 | [Design System](docs/02-DESIGN-SYSTEM.md) | 3D design language, tokens, motion |
| 03 | [Screen Specs](docs/03-SCREEN-SPECS.md) | All 23 screens, layout + states + ads |
| 04 | [Navigation](docs/04-NAVIGATION.md) | Routes, flows, deep links |
| 05 | [Data Model](docs/05-DATA-MODEL.md) | Drift schema, repos, retention |
| 06 | [SMS Parsing](docs/06-SMS-PARSING.md) | Pipeline, 32 banks, OTP hard-guard |
| 07 | [Permissions & Policy](docs/07-PERMISSIONS-POLICY.md) | Play declaration, Data Safety, DPDP |
| 08 | [Monetization / AdMob](docs/08-MONETIZATION-ADMOB.md) | Ad placement map, eCPM math, Pro tiers |
| 09 | [Localization](docs/09-LOCALIZATION.md) | en/hi/bn strings + store copy |
| 10 | [CI & Release](docs/10-CI-RELEASE.md) | Workflows, signing, Play runbook |
| 11 | [Tasks](docs/11-TASKS.md) | Serial task list — work in this order |

## Design assets

`assets/3d/` — 10 AI-generated clay-3D illustrations (indigo → violet → teal):

`app-icon` · `splash-hero` · `onboard-auto-capture` · `onboard-privacy` · `onboard-insights` · `permission-sms` · `permission-notification` · `empty-transactions` · `empty-budget` · `pro-hero`

## Privacy contract

1. No server. No cloud. No account.
2. OTP messages are **never** read, stored, or parsed.
3. Financial data is **never** sent to any SDK — including AdMob.
4. Deny the SMS permission and the app still fully works (manual entry).
5. Uninstall removes everything, because nothing ever left the device.

## Working in this repo

See [`AGENTS.md`](AGENTS.md) — the rules are enforced:

```bash
python3 tool/preflight.py                                  # before every push (~1s)
python3 tool/agent_loop.py -m "feat(scope): what changed"   # preflight + commit + push
python3 tool/ci_watch.py                                    # read CI results
```

CI is **manual** — nothing runs on push. Batch changes, then dispatch
*Actions → Flutter CI → Run workflow*.

Never run `flutter build apk|aab|web` locally. Never commit a secret.
