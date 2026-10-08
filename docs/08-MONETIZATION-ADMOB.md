# 08 — Monetization & AdMob

**Model:** Free with ads → Pro subscription (hybrid).
**Reality check:** India e CPC/eCPM kom. Tai **volume + retention + Pro conversion** — tin-tai lagbe. Ads ke user experience nষ্ট korte debe na, karon retention gelе revenue o gelo.

---

## 1. Revenue model

| Stream | Share of revenue (target) | Notes |
|---|---|---|
| AdMob banner + native | 55% | Steady, low value per user |
| AdMob interstitial | 15% | Max 1/session |
| AdMob rewarded | 10% | High eCPM, user-initiated |
| Pro subscription | 20% (grows with retention) | Highest LTV |

**Target after 6 months (25k installs, ~8k MAU, ~2.5k DAU):**

```
Banner/native : 2500 DAU × 2.2 imp × ₹18 eCPM ÷ 1000  ≈ ₹99/day
Interstitial  : 2500 × 0.45 imp × ₹55 eCPM ÷ 1000     ≈ ₹62/day
Rewarded      : 2500 × 0.20 imp × ₹95 eCPM ÷ 1000     ≈ ₹48/day
                                                       ─────────
Ads subtotal                                           ≈ ₹209/day  (₹6.3k/mo)
Pro (2.5% of 8k MAU = 200 subs × ₹99 blended ARPU)     ≈ ₹19,800/mo
                                                       ─────────
Total                                                  ≈ ₹26k/month
```
**Takeaway:** Pro is worth ~3× the ads. Ads keep free tier alive; Pro pays the bills. Don't over-optimize banner placement at the cost of retention.

> eCPM numbers are indicative India ranges — measure in AdMob, don't plan on them.

## 2. Ad unit inventory

| Ad unit name (AdMob) | Format | Placement | Screen |
|---|---|---|---|
| `ss_home_banner` | Anchored adaptive banner | Below hero money card | S-09 |
| `ss_budget_native` | Native (medium) | In-feed after 3rd budget row | S-14 |
| `ss_accounts_banner` | Anchored adaptive banner | Bottom | S-16 |
| `ss_insights_banner` | Anchored adaptive banner | Very bottom, after all charts | S-17 |
| `ss_recurring_native` | Native (small) | In-feed | S-19 |
| `ss_session_interstitial` | Interstitial | Home→Insights nav, max 1/session | global |
| `ss_rewarded_export` | Rewarded | "Watch ad → 1 free PDF export" | S-23 |
| `ss_rewarded_pro_trial` | Rewarded | "Watch ad → 24h Pro features" | S-17 Pro-locked block |

## 3. Placement rules (policy + UX contract)

### ❌ NEVER
| Rule | Why |
|---|---|
| No ads on onboarding, language, permission screens (S-02…S-08) | Play policy + it kills permission grant rate |
| No ads on Add/Edit transaction (S-12) | Accidental clicks → invalid traffic → account strike |
| No ads on transaction list/detail (S-10, S-11) | Same + destroys the core UX |
| No ads inside the paywall (S-22) | Policy: no ads on a screen selling ad-removal |
| No ad docked above bottom nav | Misclick zone |
| No interstitial on app open / on cold start | Policy + instant uninstall |
| No interstitial before a data-entry screen | User intent destruction |
| No ad refresh faster than 60s | Policy |
| No custom targeting from financial data | Hard policy violation |

### ✅ ALWAYS
- Reserved height container (`AdSlot`) → **zero layout shift**
- Label "Sponsored" / "বিজ্ঞাপন" on every native unit
- `AdSlot` renders a graceful `SizedBox.shrink()` if ad fails to load — **never a red box or a gap**
- Pro users: `AdSlot` returns `SizedBox.shrink()` at the provider level (one switch, no per-screen code)
- Test with AdMob **test IDs** until release; live IDs only in release build flavor

## 4. Interstitial frequency governor

```dart
// lib/ads/ad_gate.dart
class AdGate {
  static const _minSessionsBetween = 1;      // max 1 per session
  static const _minSecondsBetween  = 240;    // 4 min floor
  static const _allowedTriggers = {AdTrigger.homeToInsights};

  bool canShow(AdTrigger t) =>
      !pro &&
      _allowedTriggers.contains(t) &&
      _shownThisSession == 0 &&
      now.difference(_lastShownAt).inSeconds > _minSecondsBetween;
}
```
**Show only after the destination screen is built** (never mid-transition).

## 5. Rewarded ads — the India sweet spot

Indian users won't pay ₹99 easily, but they *will* watch a 30s ad for value. Two offers:

| Offer | Trigger | Cap |
|---|---|---|
| **24h Pro taste** | Tap a Pro-locked insight | 1/day |
| **1 free PDF export** | Export screen | 2/day |

Rewarded is **always opt-in** with a clear label: *"বিজ্ঞাপন দেখে ২৪ ঘণ্টার জন্য Pro ব্যবহার করুন"*. Never auto-play. Never after the user already paid.

**Implemented in T-606** (`lib/pro/rewards.dart`): the button on the locked
insight says exactly what it buys, the caps are enforced per day in `app_meta`,
and only the SDK's own `onUserEarnedReward` grants anything — a dismissed ad
costs the user nothing, not even the day's one. The PDF export is handed over as
**credits** for S-23 (T-705) to spend, so the cap is implemented once.

## 6. Pro tiers

| Plan | Price | Positioning |
|---|---|---|
| Monthly | **₹99** | default |
| Yearly | **₹699** | ⭐ anchor — "৪২% সাশ্রয়" (₹58/mo) |
| Lifetime | **₹1,499** | limited-time launch offer |

**Pro features**
- সব বিজ্ঞাপন সরান
- ভবিষ্যৎ খরচের পূর্বাভাস (forecast/projection)
- কাস্টম তারিখ রেঞ্জ + PDF statement
- সীমাহীন বাজেট ও কাস্টম ক্যাটাগরি
- এনক্রিপ্টেড Google Drive auto-backup

**Billing:** `in_app_purchase` → Play Billing · server-side verification **na** (no server!) → rely on Play's local `purchaseStream` + `restorePurchases()`. Accept the small risk; document it.
**Trial:** 7 days free on yearly. Reminder notification 1 day before charge (Play handles email; app also shows a local reminder).
**Restore:** mandatory button on paywall + in Settings.
**Never:** countdown timers, fake discounts, hidden price, blocking core features (tracking is **free forever**).

## 7. Implementation notes

```dart
// lib/ads/ad_slot.dart  — one wrapper every screen uses
class AdSlot extends ConsumerWidget {
  final AdFormat format;          // banner | native | rewarded
  final String unitId;            // from AdIds (flavor-aware)
  @override
  Widget build(context, ref) {
    if (ref.watch(proProvider)) return const SizedBox.shrink();
    return SizedBox(
      height: format == AdFormat.banner ? 56 : 120,   // reserved → no CLS
      child: MobileAdWidget(unitId: unitId),
    );
  }
}
```
**Packages:** `google_mobile_ads` (+ `flutter_native_admob`/custom platform view for native) · `in_app_purchase`.
**Consent:** Google **UMP SDK** (`ConsentForm`) shown before the first ad request for EEA/UK; India gets the standard flow — and **non-personalized ads by default** there, which is the app's own default rather than the SDK's. T-607 implements the order (consent → `canRequestAds()` → start the SDK) and the stored choice; T-610 is the Settings switch that changes it.
**App ID:** `AndroidManifest.xml` `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">`. Test ID during dev: `ca-app-pub-3940256099942544~3347511713`.
**ATT:** iOS n/a for v1 (Android-first). Keep the door open.

## 8. Ads + performance budget

| Constraint | Value |
|---|---|
| Ad SDK init | **after** first frame (`WidgetsBinding.addPostFrameCallback`) — never on splash |
| Ad load | async, non-blocking; UI never waits for an ad |
| Memory | native ads released on dispose; no preloading more than 1 unit ahead |
| Battery | no ad refresh < 60s |
| Offline | `AdSlot` shows nothing; app fully usable (offline-first by design) |

## 8b. What is implemented (T-601 … T-609)

| Piece | Where | Note |
|---|---|---|
| Placements + shapes | `lib/ads/ad_placement.dart` | six placements, one per `docs/08 §2` unit; heights reserved here |
| Ids + flavor switch | `lib/ads/ad_ids.dart` | debug → Google test ids only; release → live ids only, **empty until Keshab fills them in** |
| SDK seam | `lib/ads/ad_client.dart` (+ `_mobile` / `_web`) | screens name a placement; nothing else may build an `AdRequest` |
| Slot | `lib/ui/components/ad_slot.dart` | Pro → `SizedBox.shrink()`; failed load collapses; label painted over the creative |
| Governor | `lib/ads/ad_gate.dart` | 1 trigger · 1/session · 240 s floor · never Pro · shown after the screen is built |
| Manifest app id | `android/app/src/main/AndroidManifest.xml` + `build.gradle.kts` | debug = test id; release = `admob.appId` from `local.properties` or `-P` |
| Tests | `test/ads/*` | ids both directions, gate, slot, web stub, and a source audit of every request site |
| Billing seam | `lib/pro/billing_client.dart` (+ `_mobile` / `_web`) | the paywall and the controller never see the plugin |
| Three products | `lib/pro/product_ids.dart` | `ss_pro_monthly` · `ss_pro_yearly` · `ss_pro_lifetime`, prices and entitlement windows |
| Entitlement | `lib/pro/entitlement.dart` | one readable line in `app_meta`; a window, not a boolean; lifetime never expires |
| Controller | `lib/pro/pro_controller.dart` | `purchaseStream` + one restore per launch; only `purchased`/`restored` grant |
| Paywall | `lib/ui/screens/pro_screen.dart` | store prices or a labelled estimate, restore, terms + privacy, **no counter, no fake discount** |
| Placement gate | `lib/pro/paywall_gate.dart` | Settings · 3rd locked tap · 10th session · **max 1 a session** · never Pro |
| Tests | `test/pro/*`, `test/ui/paywall_test.dart` | entitlement round-trip, all five store outcomes, the gate's arithmetic, the screen's rules |
| Rewarded offers | `lib/pro/rewards.dart` | §5's two offers: 1 taste a day, 2 PDF credits a day, counters per kind **and per day** in `app_meta` |
| The 24-hour taste | `ProPlan.taste` + `ProController.grantTaste` | an entitlement like any other — same window, same expiry, and **not for sale** |
| Consent | `lib/ads/ad_consent.dart` + `AdClient.ensureConsent` | UMP form **before** the SDK starts; the client opens only on Google's `canRequestAds()` |
| Tests | `test/ads/ad_rewards_test.dart`, `test/ads/ad_consent_test.dart`, `test/ui/rewarded_offer_test.dart` | the caps, the three outcomes, the launch order, and the labelled offer on screen |
| Settings control | `lib/ui/screens/settings_screen.dart` | personalized ads (off by default in India) + the privacy-options door **only when UMP requires it** |

**Five things Keshab owns, and none of them is in the repo:**
1. Create the six units in the AdMob console and paste their ids into
   `AdLiveIds` (`lib/ads/ad_ids.dart`), plus the app id.
2. Put the live app id in `android/local.properties` (`admob.appId=…`) — machine
   local and gitignored, like `sdk.dir` — or pass `-Padmob.appId=…` on a release
   build.
3. Create the three Play Console products with the ids above, the prices in §6,
   and the 7-day trial **on the yearly plan only**. Until they exist,
   `queryProductDetails` returns nothing and the paywall shows the documented
   prices as *estimates* — which is honest, but it is not a working paywall.
4. In AdMob → **Privacy & messaging**, publish the consent message (the UMP
   form `ensureConsent()` shows), and paste the rewarded unit id into
   `AdLiveIds.rewarded`. Until the form exists, `isConsentFormAvailable()` is
   false and the app simply requests no ads in the regions that need one; until
   the unit id exists, the 24-hour taste offer is not shown at all.
5. The **grievance address** for `AppInfo.grievanceEmail` (`lib/app/app_info.dart`),
   plus the hosted copy of the policy the Play console asks for
   (`docs/07 §4`, `docs/10 §7`). DPDP wants a named contact that answers within
   30 days, and Play wants a policy URL. Until the address is set, S-21 says the
   address is being set up and points at the repository instead — it never shows
   an invented mailbox.

Until these are done the app ships **ad-free**, which is the safe direction: an
empty id requests nothing, and a live id is never reached in debug. The paywall
is the same way — a store that cannot answer changes nothing about what the app
promises, and no purchase can be granted by anything except Play's own word.

## 9. Policy-risk watchlist (review before each release)

- [ ] No ad on any screen that also has a permission CTA
- [ ] No ad inside paywall
- [ ] All native ads labelled
- [ ] No financial data in any `AdRequest` — audit every call site
- [ ] `AdSlot` returns nothing for Pro — verified by test
- [ ] Interstitial governor unit-tested (max 1/session)
- [ ] Data Safety declares advertising ID collection
- [ ] Test IDs never shipped to production (flavor check in CI)

## 10. Metrics to instrument (local counter, no analytics SDK for v1)

`ads_shown_total` · `ads_shown_by_unit` · `interstitial_gate_blocks` · `rewarded_completed` · `paywall_views` · `paywall_conversions` · `pro_active_days`.
**Do not** add Firebase Analytics in v1 — it complicates the "no data leaves the phone" promise. Local counters + Play Console stats are enough until v2, when an explicit opt-in analytics toggle can be added.
