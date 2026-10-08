# 07 — Permissions, Play Policy & DPDP Compliance

**This is the make-or-break document.** SMS-permission apps get rejected when this is sloppy.

---

## 1. Permission inventory

| Permission | Type | Why | Deniable? |
|---|---|---|---|
| `READ_SMS` | **Restricted** (Play declaration) | Read bank transaction SMS only | ✅ app works without |
| `RECEIVE_SMS` | **Restricted** | Live capture of new bank SMS | ✅ app works without |
| `BIND_NOTIFICATION_LISTENER_SERVICE` | Special access, user-granted in Settings | Whitelisted payment apps only | ✅ |
| `POST_NOTIFICATIONS` (13+) | Runtime | Budget alerts + reminders | ✅ |
| `USE_BIOMETRIC` | Runtime | App lock | ✅ |
| `INTERNET` | Normal | **AdMob + Play billing only** — never user data | ⚠️ required for free tier |
| `VIBRATE` | Normal | Haptics | — |
| ~~`READ_CONTACTS`~~ | — | Not used | — |
| ~~`ACCESS_FINE_LOCATION`~~ | — | Not used | — |
| ~~`QUERY_ALL_PACKAGES`~~ | — | Not used (explicit whitelist instead) | — |

**Deliberately NOT requested:** Contacts, Location, Camera, Storage (SAF used for export instead), `SEND_SMS`, `CALL_LOG`.

## 2. Play Console — Permissions Declaration Form

**Where:** Play Console → App content → *Sensitive app permissions* → SMS / Call Log.

### Select this core functionality
> ☑ **SMS-based money management** — *"For example, apps that track and manage budget"*

*(Permitted permissions for this use case: `READ_SMS, RECEIVE_MMS, RECEIVE_SMS, RECEIVE_WAP_PUSH`)*

### Do NOT select
❌ Default SMS handler · ❌ SMS-based financial transactions (that's for UPI/OTP apps) · ❌ Caller ID/spam · ❌ Device automation

### Free-text justification (paste this, edit to taste)

```
SpendStory is a personal expense tracker. Its core, primary function is to read
bank transaction SMS alerts sent by the user's own bank and convert them into
structured expense/income entries automatically, so the user does not have to
type each transaction. This is the "SMS-based money management" use case.

There is no alternative API for this functionality. Indian banks do not expose
per-transaction alerts through any public API to third-party developers; the
only channel banks use for real-time transaction alerts is SMS. Account
Aggregator/RBI frameworks provide periodic statement data, not the instant
per-transaction alerts that make automatic tracking possible, and they require
a licensed entity. Removing SMS access would remove the app's core function —
without it the app becomes a manual entry tracker, which is exactly the
category of app users abandon.

What we read: only SMS from an allowlist of Indian bank/NBFC sender IDs
(currently 32 bank senders + 18 card/wallet senders, matched by sender ID).
What we never read or store: OTP / one-time-password messages, any message
containing "do not share", verification codes, and all non-bank SMS. Messages
from unknown senders are dropped before any parsing.

All processing is on-device. No SMS content, parsed or raw, is transmitted off
the device. The app has no server. Transaction data is stored in a local SQLite
database in the app's private storage. Raw SMS text is never shared with any
third party, never used for advertising, and never used for user profiling.

The app is fully functional without SMS permission: the user can add, edit and
categorise transactions manually, set budgets and view insights. SMS permission
is requested only after an in-app explanation screen, and denial is respected
with no repeated prompting.
```

### Mandatory attachments / evidence

| Requirement | How we satisfy it |
|---|---|
| **Demo video** (screen recording) | Script in §3 below — record on a real device, 60–90 s |
| Store listing **prominently features** the SMS feature | Long description's first paragraph + first screenshot caption |
| Privacy policy URL | Host `docs/privacy-policy.md` (GitHub Pages) |
| Data Safety form | §4 below |
| Manual entry fallback exists | S-08 screen shipped |

## 3. Demo video script (60–90 s, no voiceover needed)

| # | Shot | On-screen |
|---|---|---|
| 1 | Home screen with several transactions | "SpendStory — automatic expense tracking" |
| 2 | Open Messages app, show a **real bank debit SMS** arriving (blur account digits) | "A bank SMS arrives" |
| 3 | Switch to SpendStory → new transaction **already there**, with category | "Captured automatically. Nothing typed." |
| 4 | Tap it → Detail screen → expand "raw SMS" row | "You can see exactly which SMS it came from" |
| 5 | Show an **OTP SMS** arriving, then SpendStory → nothing added | "OTP and personal messages are never read or stored" |
| 6 | Airplane-mode toggle ON, app still fully works | "No internet. No server. Data stays on your phone." |
| 7 | Settings → permission OFF → app still usable, manual add works | "Deny permission? Everything else still works." |

**Upload as unlisted YouTube + link in the declaration form.** Keep the raw file in the repo? **No** — link only.

## 4. Data Safety form — exact answers

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | N/A (no collection) — but state: *"No user data is transmitted"* |
| Do you provide a way for users to request that their data be deleted? | **Yes** — in-app "সব ডেটা মুছুন" + uninstall |
| Data types — Financial info | **Not collected, not shared** (stored on-device only) |
| Data types — Messages (SMS) | **Not collected, not shared.** Note in description: *"Bank SMS is processed entirely on-device and never transmitted."* |
| Data types — Personal info / Location / Contacts | **Not collected** |
| Data types — App activity / Device ID | ⚠️ **AdMob collects Advertising ID** → declare **Device or other IDs → Collected, Shared, for Advertising**. See §6. |
| Data used for advertising/marketing | **Yes** — limited to the AdMob SDK's own identifiers (see §6) |

> ⚠️ **The AdMob answer changes the Data Safety section.** A "collects nothing" claim while shipping AdMob is a **policy violation**. Be precise: declare the ad SDK's identifier collection and state clearly that *no financial, SMS, or transaction data* is shared with any SDK.

## 5. DPDP Act 2023 + Rules 2025 (India)

Rules notified **13 Nov 2025** (G.S.R. 846(E)); substantive obligations enforceable **13 May 2027**. Applies to any entity processing digital personal data of people in India — **no size exemption**.

| Obligation | How SpendStory satisfies it |
|---|---|
| **Notice** (plain language, itemised purposes) | S-21 About/Privacy screen, 3 languages, shown before first permission ask |
| **Consent** (free, specific, informed, unambiguous) | Dedicated explainer screen → then OS dialog. No pre-ticked boxes. |
| **Purpose limitation** | SMS read only for transaction capture; no secondary use |
| **Data minimisation** | Only amount/date/merchant/account-last4 stored; raw SMS optional and user-deletable; OTP never stored |
| **Storage limitation** | Local only; inactive 12-month prompt to erase |
| **Right to access** | CSV/JSON export from Settings |
| **Right to correction** | Edit any transaction; re-categorise |
| **Right to erasure** | "সব ডেটা মুছুন" → immediate purge |
| **Consent withdrawal** | Revoke SMS/notification access anytime in Settings; app degrades gracefully |
| **Grievance contact** | Named email in About screen (respond ≤ 30 days) |
| **Security safeguards** | App-private storage, SQLite WAL, optional biometric app lock, encrypted backups (AES-256-GCM, user password) |
| **Breach notification** | N/A structurally — no server, so no breach surface for user data. Still document the process. |
| **Children's data** | App targets 18+; no child-directed content |
| **Consent Manager** | Not applicable (not a Consent Manager; storing locally without a fiduciary transfer) |

**Positioning:** because processing is 100% on-device and no personal data is transmitted, SpendStory's DPDP exposure is minimal — but the **notice + consent + erasure triad must still exist in-app** (they do).

## 6. AdMob & policy interaction (summary — full detail in `08`)

- AdMob SDK is the **only** component making network calls.
- **Never** pass SMS, transaction, category, merchant, or amount data into any ad request. No custom targeting keys from financial data.
- **No ads** on permission screens, onboarding, transaction edit, or paywall.
- Families/child-directed: **not** child-directed (`setTagForChildDirectedTreatment(false)`), content rating Everyone.
- User consent: for EEA/UK users the SDK shows a UMP consent form; for India, add an in-app "ব্যক্তিগতকৃত বিজ্ঞাপন বন্ধ করুন" toggle in Settings (respects the spirit of DPDP even before enforcement). **Implemented (T-607/T-610):** the form runs before the SDK is ever started and a declined user gets no ads at all; the Settings row is `Personalized ads`, off by default in India, stored in `app_meta` and handed to every request; where UMP requires a privacy-options entry point, Settings carries that door — for Pro users too, because consent can be withdrawn whatever plan you are on.
- **Ad-free is a Pro benefit** and must remain a genuine, working upgrade.

## 7. Store listing policy alignment

The listing must **prominently promote** the SMS feature (this is a policy requirement, not a marketing preference):

- **Title:** `SpendStory: Expense Tracker`
- **Short description:** include "Bank SMS ও UPI notification থেকে অটো খরচের হিসাব"
- **Screenshot 1 caption:** "ব্যাংকের SMS → অটো খরচ এন্ট্রি"
- **Long description paragraph 1:** must describe SMS auto-capture

A listing that buries the SMS feature risks the declaration.

## 8. Pre-submission checklist

```
[ ] Permissions Declaration submitted — "SMS-based money management"
[ ] Demo video recorded (7 shots) + link pasted
[ ] Privacy policy live at a public URL
[ ] Data Safety: ads identifier declared, financial/SMS declared as not-collected
[ ] About screen (S-21) text matches the privacy policy
[ ] Listing copy prominently features SMS tracking
[ ] Manual-entry fallback (S-08) shipped and testable
[ ] Manifest has NO extra restricted permissions
[ ] OTP corpus test passing with 0 parses
[ ] Content rating questionnaire done (Everyone)
[ ] Target API level = current Play requirement
[ ] 20-tester closed test completed (new-personal-account requirement)
```

> **Note on new developer accounts:** personal accounts created recently must run a **closed test with ≥ 12 testers for 14 continuous days** before production access. Budget for this in the release timeline. (`10-CI-RELEASE.md`)
