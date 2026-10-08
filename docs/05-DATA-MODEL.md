# 05 — Data Model

**Engine:** Drift (SQLite) · **Location:** app private storage · **Sync:** none (by design)

---

## 1. Principles

1. **Zero network.** Kono table remote jay na.
2. **Soft delete** (`deleted_at`) — restore + undo support, DPDP erase e purge.
3. **Money = integer paise**, never float. `int amountPaise`. Display e ÷100.
4. **Source traceability.** Prottek tx jane se kothay theke elo (`source`, `sourceRef`).
5. **Idempotent capture.** Ek-i SMS duibar ashle duibar entry hobe na (`dedupeHash` unique).

## 2. Tables

### `transactions`
| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PK | uuid v4 |
| `amountPaise` | INTEGER | > 0 always; sign `direction` theke |
| `direction` | TEXT | `expense` \| `income` \| `transfer` |
| `merchant` | TEXT? | raw merchant / counterparty |
| `note` | TEXT? | user note |
| `categoryId` | TEXT FK | → `categories.id` |
| `accountId` | TEXT FK | → `accounts.id` |
| `mode` | TEXT | `cash`\|`upi`\|`card`\|`netbanking`\|`wallet`\|`other` |
| `occurredAt` | INTEGER | epoch ms (tx time, not capture time) |
| `createdAt` | INTEGER | epoch ms |
| `updatedAt` | INTEGER | epoch ms |
| `source` | TEXT | `auto_sms` \| `auto_notif` \| `manual` \| `recurring` |
| `sourceRef` | TEXT? | sender ID / package name |
| `rawText` | TEXT? | original SMS body (encrypted-at-rest optional) |
| `dedupeHash` | TEXT UNIQUE | sha1(amount+direction+timestamp_norm+sender+acct4) |
| `isRecurring` | BOOLEAN | default false |
| `deletedAt` | INTEGER? | soft delete |

**Indexes:** `occurredAt DESC`, `categoryId`, `accountId`, `dedupeHash UNIQUE`, `source`.

### `categories`
| Column | Type | Notes |
|---|---|---|
| `id` | TEXT PK | uuid |
| `kind` | TEXT | `expense` \| `income` |
| `nameEn` / `nameHi` / `nameBn` | TEXT | 3-language names |
| `icon` | TEXT | emoji or code point |
| `colorHex` | TEXT | `#RRGGBB` |
| `monthlyCapPaise` | INTEGER? | optional per-category budget |
| `sortOrder` | INTEGER | user-reorderable |
| `isSystem` | BOOLEAN | system rows can't be deleted |
| `deletedAt` | INTEGER? | |

### `accounts`
| Column | Type |
|---|---|
| `id` TEXT PK · `name` TEXT · `type` TEXT (`bank`\|`cash`\|`wallet`\|`card`) |
| `openingBalancePaise` INTEGER · `last4` TEXT? · `colorHex` TEXT |
| `isDefault` BOOLEAN · `sortOrder` INTEGER · `deletedAt` INTEGER? |

**Balance (computed, never stored):**
```sql
openingBalancePaise
  + SUM(income where accountId=?) − SUM(expense where accountId=?)
  ± transfers
```

### `budgets`
| Column | Type | Notes |
|---|---|---|
| `id` TEXT PK | | |
| `categoryId` TEXT? FK | | `NULL` = overall budget |
| `period` TEXT | | `monthly` \| `weekly` \| `custom` |
| `amountPaise` INTEGER | | |
| `startDay` INTEGER | | 1–28 (salary-day cycle support) |
| `alertAt80` / `alertAt100` BOOLEAN | | |
| `startsOn` / `endsOn` INTEGER? | | for custom |

### `recurring_rules` *(v1.1)*
`id` · `title` · `amountPaise` · `direction` · `categoryId` · `accountId` · `frequency` (`daily|weekly|monthly|yearly`) · `interval` · `dayOfMonth` · `nextDueAt` · `autoPost` BOOLEAN · `remindDaysBefore` INTEGER · `deletedAt`

### `merchant_rules` (auto-categorization brain)
| Column | Type | Notes |
|---|---|---|
| `id` TEXT PK | | |
| `pattern` TEXT | | lowercase match token, e.g. `bigbasket`, `swiggy` |
| `categoryId` TEXT FK | | |
| `hits` INTEGER | | how many times matched (learning) |
| `confidence` REAL | | user-confirmed → 1.0 |
| `isUserDefined` BOOLEAN | | manual override always wins |

### `sms_senders` (allowlist, versioned)
`id` · `senderId` (e.g. `VM-HDFCBK`) · `bankName` · `parserKey` · `enabled` · `addedInRuleVersion`

### `parse_log` (diagnostics, local only)
`id` · `senderId` · `matched` BOOLEAN · `parserKey`? · `failureReason`? · `createdAt`
→ Settings → "কিছু ভুল হয়েছে? রিপোর্ট করুন" e JSON export (user-initiated, no auto upload)

### `app_meta` (kv)
`onboarded` · `locale` · `theme` · `smsPermAsked` · `notifPermAsked` · `lastBackupAt` · `autoBackup` · `proStatus` · `ruleVersion` · `sessionCount` · `appLock`

`BackupRepo` (T-705) reads and writes `lastBackupAt` and the weekly-reminder flag
`autoBackup`. The payload carries `locale`, `theme` and `lastBackupAt` and
nothing else from this table: entitlements, reward counters, alert markers and
the ads-consent choice belong to the phone and the store account, never to a file
the user can copy — a hand-edited backup must not be able to grant Pro.

## 3. Drift setup

```dart
// lib/data/db.dart
@DriftDatabase(tables: [
  Transactions, Categories, Accounts, Budgets,
  RecurringRules, MerchantRules, SmsSenders, ParseLog,
])
class AppDb extends _$AppDb {
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: stepByStep(/* additive migrations only */),
    beforeOpen: (d) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );
}
```

**Rules:** additive migrations only (no column drops in the wild) · every migration gets a test with a seeded v(n-1) db · `WAL` mode on.

## 4. Repositories (Riverpod providers)

| Repo | Responsibility |
|---|---|
| `TxRepo` | create/update/softDelete/query/filter/dedupe |
| `CategoryRepo` | CRUD + reorder + seed defaults |
| `AccountRepo` | CRUD + computed balances |
| `BudgetRepo` | CRUD + progress computation |
| `InsightRepo` | donut series, trend, top merchants, deltas, forecast (Pro) |
| `CaptureRepo` | receives parsed tx from SMS/notif → dedupe → insert → notify UI |
| `RuleRepo` | merchant→category resolution, learning, user override |
| `BackupRepo` | encrypted export/restore (AES-256-GCM), CSV |

## 5. Erase / retention (DPDP)

| Action | Effect |
|---|---|
| Delete single tx | soft delete → undo snackbar 5s → purge on next open |
| "সব ডেটা মুছুন" (Settings) | double-confirm → full purge + prefs reset → back to onboarding (T-706: the two dialogs and the purge are in `settings_screen.dart`, tested against a real database) |
| App lock (Settings) | not a data feature: `app_meta.appLock` is one row, and a locked app renders `/lock` instead of anything else. Nothing is encrypted by it — the database stays app-private, locked or not — so a user who forgets the lock still owns their data |
| Uninstall | OS removes everything (nothing was outside) |
| Inactive > 12 months | on open, prompt: "পুরনো ডেটা মুছে ফেলব?" (user choice, never silent) |

## 6. Seed data on first run

- 12 expense categories + 6 income categories (3-language names, icon, color)
- 1 account: "নগদ" (cash), default
- 1 overall budget: none (user sets)
- `merchant_rules`: ~120 built-in India merchant patterns (Swiggy, Zomato, BigBasket, Blinkit, Zepto, Uber, Ola, Rapido, IRCTC, Jio, Airtel, Amazon, Flipkart, Myntra, DMart, local bus…)
- `sms_senders`: 30+ bank allowlist + ruleVersion = 1
