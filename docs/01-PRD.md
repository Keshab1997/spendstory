# 01 — Product Requirements Document (PRD)

**Product:** SpendStory
**Version:** 1.0 (MVP scope)
**Owner:** Keshab Sarkar
**Status:** Approved for build

---

## 1. Problem

India te prottek mash e koti koti UPI transaction hoy. Kintu:

- Manush **jane na taka kothay jacche** — UPI payment ek jhap e hoye jay, mone thake na.
- Bank SMS ashhe, kintu SMS inbox e hariye jay. Keu hate-hate hisab likhe na.
- Existing expense tracker gulo hoy **manual entry** (keu kore na), noy **bank login** chay (bhorsa kora jay na).
- Bengali/Hindi bhashi user der jonno **nijer bhashায়** kono premium tracker nei.

## 2. Solution

Ekta app ja **bank SMS + payment notification theke nijei kharcha dhore fele** — user ke kichu likhte hoy na. Sob data **phone e-i thake**. Bengali, Hindi, English — tinte bhashায়.

## 3. Core value proposition

> **"Taka kothay gelo — likhte hobe na, jante parbe."**

## 4. Target user

| Segment | % | Characteristic |
|---|---|---|
| Bengali-speaking salaried (WB, Assam, Tripura) | 40% | 22–40, UPI heavy, 2–4 bank account |
| Hindi-belt salaried (UP, Bihar, MP, RJ) | 35% | 20–35, first-time budgeter |
| Students | 15% | Pocket money, hostel khoroch |
| Small shopkeepers / freelancers | 10% | Business + personal mix |

**Not targeting:** B2B accounting, GST filing, investment tracking (v2).

## 5. Feature scope (MoSCoW)

### Must have — v1.0

| ID | Feature | Notes |
|---|---|---|
| F-01 | Bank SMS auto-capture | 30+ Indian bank sender ID + regex |
| F-02 | Payment notification capture | GPay/PhonePe/Paytm/BHIM/CRED |
| F-03 | OTP / spam hard filter | Never stored, never parsed |
| F-04 | Auto-categorization | Merchant→category rule engine |
| F-05 | Manual add / edit / delete | Works without any permission |
| F-06 | Home dashboard | Today / this month / balance |
| F-07 | Transaction list + search + filter | Date range, category, account |
| F-08 | Budget (overall + category) | Alert at 80% / 100% |
| F-09 | Insights | Donut, trend line, top merchants, month compare |
| F-10 | Multi-account | Cash, bank, UPI wallet, credit card |
| F-11 | 3-language UI | en, hi, bn |
| F-12 | On-device only | Zero network call for user data |
| F-13 | Backup / export | Encrypted file + CSV |
| F-14 | AdMob free tier | Banner + interstitial + rewarded |
| F-15 | Pro subscription | Ad-free + advanced insights |

### Should have — v1.1

| ID | Feature |
|---|---|
| F-20 | Recurring transactions + bill reminders |
| F-21 | Split expense tracker |
| F-22 | Widget (home screen quick-add) |
| F-23 | Salary-day budget cycle |
| F-24 | PDF statement export |

### Could have — v1.2+
Voice entry, SMS-to-split, family sharing, UPI ID auto-tag, investment tracking.

### Won't have (explicitly out)
Bank API login, Account Aggregator, cloud sync server, OTP autofill, lending/credit.

## 6. Key user stories

```
US-01  As a UPI user, I want my bank SMS to become transactions automatically,
       so that I don't have to type anything.
       ✓ Bank SMS arrives → transaction appears in list within 3s
       ✓ Sender is not a known bank → nothing happens, no false positive

US-02  As a privacy-conscious user, I want proof my data never leaves the phone,
       so that I can trust the app with my bank messages.
       ✓ Airplane mode on → app fully functional
       ✓ Data Safety section states on-device only + link to source

US-03  As a Bengali speaker, I want the whole app in Bangla,
       so that my mother can use it too.
       ✓ Language switch without restart, all 23 screens translated

US-04  As a manual-only user who denies SMS permission,
       I want to add expenses by hand and still see insights.
       ✓ App never crashes; dashboard, budget, insights all work

US-05  As a free user, I want the app to be usable without paying,
       so that I can decide to upgrade later.
       ✓ Core tracking unlimited free; ads non-intrusive; Pro optional
```

## 7. Success metrics

| Metric | Target (6 months post-launch) |
|---|---|
| Installs | 25,000 |
| D+1 retention | ≥ 35% |
| D+30 retention | ≥ 15% |
| SMS permission grant rate | ≥ 55% of onboarded users |
| Auto-captured vs manual ratio | ≥ 3:1 |
| Free→Pro conversion | ≥ 2.5% |
| Play rating | ≥ 4.3 |
| Crash-free sessions | ≥ 99.5% |

## 8. Constraints & risks

| Risk | Severity | Mitigation |
|---|---|---|
| Play rejects SMS permission declaration | 🔴 High | Notification-first architecture + full declaration pack (`07`) |
| Bank SMS format change breaks regex | 🟡 Med | Remote-safe local rule file + versioned regex + user "wrong parse" report |
| AdMob policy violation (ads near data entry) | 🔴 High | Placement map with policy annotations (`08`) |
| DPDP compliance | 🟡 Med | On-device-only = minimal exposure; privacy notice + erasure (`07`) |
| Hindi/Bengali translation quality | 🟡 Med | Human review pass before release; no raw MT |
| Pro conversion too low | 🟡 Med | Rewarded ads bridge value gap; keep core free forever |

## 9. Release plan

| Phase | Scope | Gate |
|---|---|---|
| M1 | Docs + design system + assets | This batch |
| M2 | Data layer + SMS parser + tests | Parser accuracy ≥ 95% on 200-sample corpus |
| M3 | Onboarding + permissions + Home + transaction CRUD | Manual E2E pass |
| M4 | Budget + insights + localization | All 3 languages reviewed |
| M5 | Ads + Pro + export | AdMob test IDs → live IDs |
| M6 | Play submission | Declaration + Data Safety + demo video done |
