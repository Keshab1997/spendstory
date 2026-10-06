# 06 — SMS Parsing Engine

**Goal:** Bank SMS → structured transaction, on-device, ≥ 95% accuracy, **zero OTP leakage**.

---

## 1. Pipeline

```
BroadcastReceiver (SMS_RECEIVED)
        │
        ▼
① OTP GUARD ──── hard reject ──► drop (never stored)
        │
        ▼
② SENDER ALLOWLIST ─── unknown ──► ignore (no false positive)
        │
        ▼
③ TRANSACTION SIGNAL CHECK ── no keyword ──► ignore
        │
        ▼
④ PARSE (per-bank parser, fallback generic)
        │
        ▼
⑤ SANITY CHECK (amount>0, date within ±72h, not duplicate)
        │
        ▼
⑥ DEDUPE (hash) ─── exists ──► ignore
        │
        ▼
⑦ CATEGORIZE (merchant_rules)
        │
        ▼
⑧ INSERT → notify UI → optional local notification
```

**Order matters:** OTP guard runs **before** anything is written to memory or disk. No raw SMS is ever persisted unless step ④ succeeded.

## 2. ① OTP GUARD — hard rules (never violate)

```dart
// lib/capture/otp_guard.dart
const _otpHard = [
  r'\botp\b', r'\bo\.t\.p\b', r'one[\s-]?time[\s-]?password',
  r'\bdo not share\b', r'\bnever share\b', r'\bconfidential\b.*\bcode\b',
  r'verification code', r'varification code', r'login code',
  r'authentication code', r'secure code', r'security code',
  r'\bCVV\b', r'\bPIN\b.*\bgenerated\b', r'valid for \d+ ?min',
];
// Length heuristic: standalone 4–8 digit code with no currency symbol/₹/Rs/INR
final _bareCode = RegExp(r'(?<![₹\d])\b\d{4,8}\b(?!\s*(?:rs|inr|₹))',
                        caseSensitive: false);
```
**If any hard pattern matches → return `null` and drop.** Never log, never store, never send.
**Test requirement:** a 40-message OTP corpus (all banks) must yield **0** parses.

## 3. ② Sender allowlist

Match against `sms_senders.senderId`, normalized: strip `VM-`, `VK-`, `AX-`, `TM-`, `BM-`, `AD-`, `CP-` prefixes, take last 6 chars, uppercase.

```dart
String normSender(String raw) => raw
    .replaceAll(RegExp(r'^(VM|VK|AX|TM|BM|AD|CP|BP|MM)-', caseSensitive: false), '')
    .trim().toUpperCase();
```

### Built-in Indian bank allowlist (v1 — 32 entries)

| Bank | Sender suffix | parserKey |
|---|---|---|
| HDFC Bank | `HDFCBK` | `hdfc` |
| ICICI Bank | `ICICIB` | `icici` |
| State Bank of India | `SBIINB`, `SBISMS`, `ATMSBI` | `sbi` |
| Axis Bank | `AXISBK` | `axis` |
| Kotak Mahindra | `KOTAKB` | `kotak` |
| Punjab National Bank | `PNBSMS` | `pnb` |
| Bank of Baroda | `BOBSMS` | `bob` |
| Canara Bank | `CANBNK` | `canara` |
| Union Bank of India | `UNIONB` | `union` |
| IDBI Bank | `IDBIBK` | `idbi` |
| Yes Bank | `YESBNK` | `yes` |
| IndusInd Bank | `INDUSB` | `indusind` |
| IDFC First | `IDFCBK` | `idfc` |
| Federal Bank | `FEDBNK` | `federal` |
| Bandhan Bank | `BANDHN` | `bandhan` |
| RBL Bank | `RBLBNK` | `rbl` |
| AU Small Finance | `AUSFBK` | `au` |
| Standard Chartered | `SCBANK` | `sc` |
| Bank of India | `BOISMS` | `boi` |
| Central Bank of India | `CENTBK` | `cbi` |
| Indian Bank | `INDBNK` | `indian` |
| UCO Bank | `UCOBNK` | `uco` |
| South Indian Bank | `SIBSMS` | `sib` |
| Karnataka Bank | `KARBNK` | `karnataka` |
| Punjab & Sind Bank | `PUNSND` | `psb` |
| Indian Overseas Bank | `IOBSMS` | `iob` |
| City Union Bank | `CUBANK` | `cub` |
| Karur Vysya Bank | `KVBSMS` | `kvb` |
| DBS Bank India | `DBSBNK` | `dbs` |
| Paytm Payments Bank | `PYTMBK` | `paytm` |
| Airtel Payments Bank | `AIRBNK` | `airtel` |
| India Post Payments | `IPPBBN` | `ippb` |

**Cards/NBFC/wallet senders (separate list, `mode: card|wallet`):** `HDFCCC`, `ICICIC`, `SBI CRD`, `AMEXIN`, `BAJAJF`, `HDBFIN`, `ZESTPAY`, `SLICEP`, `LAZYPAY`, `SIMPLE`, `CRED`, `JUPITER`, `FIBNK`, `PAYTM`, `PHONEPE`, `GPAY`, `AMAZONP`

## 4. ③ Transaction signal

```dart
const _debitSignals = [
  'debited','debit','withdrawn','withdrawal','spent','paid','purchase',
  'sent','transferred to','txn of','txn of','tfr to','trf to','dr.',
  'काटा','भुगतान','खर्च','ডেবিট','কাটা','পরিশোধ',
];
const _creditSignals = [
  'credited','credit','deposited','received','refund','cashback',
  'reversed','salary','जमा','प्राप्त','ক্রেডিট','জমা','পেয়েছি',
];
const _balanceOnlySignals = ['avl bal','available balance','bal:']; // balance SMS, not a tx
const _nonTx = [
  'offer','discount','cashback offer','apply now','loan offer','insurance',
  'missed call','bill due','statement','e-mandate','kyc','kyc update',
];
```
**Decision:** debit keyword + amount → expense · credit keyword + amount → income · balance-only → **ignore** · non-tx → ignore.

## 5. ④ Amount extraction (Indian number formats)

```dart
// Handles: Rs.1,240 · INR 1240 · ₹ 1,240.50 · Rs 1,240/- · 1,24,000 · 12.5 Lakh? (no)
final _amount = RegExp(
  r'(?:Rs\.?|INR|₹)\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
  caseSensitive: false);

int toPaise(String s) {
  final clean = s.replaceAll(',', '');
  return (double.parse(clean) * 100).round();   // never float store
}
```
**Indian grouping:** `1,24,000` (lakh format) must parse — test case mandatory.
**Ignore** amounts with "bal" proximity unless a debit/credit signal also exists.

## 6. Date extraction

| Pattern | Example |
|---|---|
| `dd-MM-yy` / `dd-MM-yyyy` | `07-10-26` |
| `dd-MMM-yy` | `07-Oct-26` |
| `ddMMMyy` | `07OCT26` |
| `dd/mm/yyyy` | `07/10/2026` |
| relative | `today`, `yesterday`, `আজ`, `গতকাল` |

**No date found → use SMS `timestamp`** (the receiver's own millis).
**Reject** if parsed date is > 72h in the future or > 400 days in the past → fall back to SMS timestamp.

## 7. Merchant extraction

Order:
1. Known merchant token from `merchant_rules` (longest match wins)
2. `(?:at|to|towards|for)\s+([A-Za-z0-9 .&_-]{3,28})` before "on"/"from"/date
3. VPA pattern: `([a-z0-9._-]{3,})@(?:okhdfcbank|okicici|okaxis|ybl|paytm|upi|apl)` → take handle
4. Fallback: bank name + mode (`"HDFC UPI"`)

**Normalize:** uppercase→Title Case · strip trailing `PVT LTD`, `INDIA`, `*`, digits-only tokens.

## 8. Example end-to-end

```
INPUT : "VM-HDFCBK"
        "Rs.1,240.00 debited from A/c XX4521 on 07-10-26 to
         VPA bigbasket@ybl (UPI Ref 412398765432). Avl Bal Rs.12,340.50"

① OTP guard      → no match
② sender         → HDFCBK → parserKey hdfc
③ signal         → 'debited' → expense
④ amount         → 1240.00 → 124000 paise
   account last4 → 4521
   date          → 2026-10-07 (from SMS timestamp if absent)
   merchant      → VPA handle 'bigbasket' → merchant_rules → Groceries/বাজার
   mode          → UPI
⑤ sanity         → ok
⑥ dedupe hash    → sha1("124000|expense|2026-10-07T14:42|HDFCBK|4521") → new
⑦ categorize     → বাজার (confidence from rule hits)
⑧ insert         → UI stream emits → Home updates

RESULT: { amount: 124000, direction: expense, merchant: "BigBasket",
          category: বাজার, account: HDFC •4521, mode: upi,
          source: auto_sms, sourceRef: "VM-HDFCBK" }
```

## 9. Notification parsing (parallel path)

`NotificationListenerService` → filter `packages` ∈ whitelist → extract `EXTRA_TEXT`.

| App | Package | Extract |
|---|---|---|
| Google Pay | `com.google.android.apps.nbu.paisa.user` | amount, payee, "Paid ₹X to Y" |
| PhonePe | `com.phonepe.app` | amount, payee |
| Paytm | `net.one97.paytm` | amount, payee |
| BHIM | `in.org.npci.upiapp` | amount, payee |
| CRED | `com.dreamplug.androidapp` | amount, merchant |
| Amazon Pay | `in.amazon.mShop.android.shopping` | amount |

**Same OTP guard + dedupe applies** — a payment may arrive via both SMS and notification → dedupe keeps one (within a 10-min window, same amount+direction → merge, prefer the one with better merchant).

## 10. Accuracy & testing

| Test | Corpus | Gate |
|---|---|---|
| OTP false-positive | 40 real OTP SMS (all banks) | **0 parses** |
| Debit parse | 60 samples, 20 banks | ≥ 95% |
| Credit parse | 40 samples | ≥ 95% |
| Indian lakh grouping | 15 samples | 100% |
| Multi-language (hi/bn keywords) | 20 samples | ≥ 90% |
| Non-tx (offers/statements) | 30 samples | 0 false tx |
| Duplicate suppression | 25 pairs | 100% |
| Notification parse | 6 apps × 5 samples | ≥ 92% |

Corpus lives in `test/fixtures/sms/*.json` (synthetic, no real user data). Parser versioned: `ruleVersion` bump → migration writes new `sms_senders` rows.

## 11. Failure handling

- Parse fails → **nothing inserted**, row written to `parse_log` (local only)
- Settings → "ভুল হয়েছে? জানান" → shows last 20 failures (sender + reason, **never** full text unless user opts in) → "রিপোর্ট কপি করুন" → JSON to clipboard (user pastes wherever)
- **No auto-upload. Ever.** This is the trust contract.
