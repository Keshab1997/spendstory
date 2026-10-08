/// What "Pro" means, and when it stops meaning it (T-605).
///
/// There is no server in this product, so the entitlement is a record of what
/// Play last said plus a window. The two mistakes that would hurt most are
/// tested first: locking out somebody who paid, and letting a cancelled
/// subscription live forever.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/pro/entitlement.dart';
import 'package:spendstory/pro/product_ids.dart';

int at(int y, int m, int d, [int h = 12]) =>
    DateTime(y, m, d, h).millisecondsSinceEpoch;

void main() {
  group('product ids', () {
    test('every purchasable plan has an id, and every id maps back', () {
      for (final plan in purchasablePlans) {
        expect(planForProductId(productIdFor(plan)!), plan);
      }
      expect(ProProductIds.all, hasLength(purchasablePlans.length));
      expect(purchasablePlans, hasLength(3));
    });

    test('the taste is not for sale', () {
      // T-606: it is earned by watching an ad. No id means no product to query,
      // which is what makes "buy the taste" impossible rather than merely
      // discouraged.
      expect(productIdFor(ProPlan.taste), isNull);
      expect(purchasablePlans, isNot(contains(ProPlan.taste)));
      expect(
        planForProductId('ss_pro_taste'),
        isNull,
        reason: 'an id that does not exist must never decode into a plan',
      );
    });

    test(
      'an id from another app, or a typo, is unknown rather than assumed',
      () {
        for (final id in <String>[
          '',
          'ss_pro',
          'SS_PRO_MONTHLY',
          'com.other.app.monthly',
        ]) {
          expect(planForProductId(id), isNull, reason: id);
        }
      },
    );

    test('the prices are the documented ones, and yearly is the saving', () {
      expect(fallbackPricePaise(ProPlan.monthly), 9900);
      expect(fallbackPricePaise(ProPlan.yearly), 69900);
      expect(fallbackPricePaise(ProPlan.lifetime), 149900);
      expect(
        fallbackPricePaise(ProPlan.yearly),
        lessThan(fallbackPricePaise(ProPlan.monthly) * 12),
      );
    });

    test('the trial is on the yearly plan only, and it is seven days', () {
      expect(trialFor(ProPlan.yearly), const Duration(days: 7));
      expect(trialFor(ProPlan.monthly), isNull);
      expect(trialFor(ProPlan.lifetime), isNull);
      expect(trialFor(ProPlan.taste), isNull);
    });
  });

  group('the window', () {
    test('is longer than the period it pays for, never shorter', () {
      // The whole point: a renewal that is still in flight must never lock a
      // paying user out.
      expect(
        entitlementWindow(ProPlan.monthly),
        greaterThan(const Duration(days: 30)),
      );
      expect(
        entitlementWindow(ProPlan.yearly),
        greaterThan(const Duration(days: 365)),
      );
      expect(
        entitlementWindow(ProPlan.yearly).inDays,
        greaterThanOrEqualTo(372),
      );
    });

    test('only lifetime is a forever', () {
      expect(isRenewing(ProPlan.lifetime), isFalse);
      expect(isRenewing(ProPlan.monthly), isTrue);
      expect(isRenewing(ProPlan.yearly), isTrue);
      // A taste is not a subscription: nothing will be charged for it, so the
      // paywall must never promise the user a renewal date for one.
      expect(isRenewing(ProPlan.taste), isFalse);
    });
  });

  group('a monthly subscription', () {
    final pro = ProEntitlement(
      plan: ProPlan.monthly,
      confirmedAtMs: at(2026, 10, 8),
    );

    test('is active from the moment Play confirmed it', () {
      expect(pro.isActiveAt(at(2026, 10, 8)), isTrue);
      expect(pro.isActiveAt(at(2026, 10, 8) + 1), isTrue);
    });

    test('is still active on the day the next payment is due', () {
      // Day 30 — the renewal Play has not told us about yet.
      expect(pro.isActiveAt(at(2026, 11, 6)), isTrue);
    });

    test('ends when the window does, to the millisecond', () {
      final end = pro.expiresAtMs!;
      expect(pro.isActiveAt(end - 1), isTrue);
      expect(pro.isActiveAt(end), isFalse);
      expect(pro.isActiveAt(end + 1), isFalse);
    });
  });

  group('a yearly subscription', () {
    test('covers the trial and the year it promises', () {
      final pro = ProEntitlement(
        plan: ProPlan.yearly,
        confirmedAtMs: at(2026, 10, 8),
      );
      // 372 days after 8 Oct 2026 is 15 Oct 2027 — the year, plus the trial the
      // window accounts for, plus a few days of slack for a renewal in flight.
      final end = pro.expiresAtMs!;
      expect(pro.isActiveAt(at(2027, 10, 8)), isTrue);
      expect(pro.isActiveAt(end - 1), isTrue);
      expect(pro.isActiveAt(end), isFalse);
    });
  });

  group('lifetime', () {
    test('never expires, and never counts down', () {
      final pro = ProEntitlement(
        plan: ProPlan.lifetime,
        confirmedAtMs: at(2026, 10, 8),
      );
      expect(pro.expiresAtMs, isNull);
      expect(pro.isActiveAt(at(2036, 10, 8)), isTrue);
      expect(pro.remainingAt(at(2026, 10, 8)), isNull);
    });
  });

  group('a restore on another phone', () {
    test('refreshes the window from the day Play said so', () {
      final bought = ProEntitlement(
        plan: ProPlan.yearly,
        confirmedAtMs: at(2026, 10, 8),
      );
      // The phone was in a drawer for nine months; the subscription kept being
      // paid, so the restore is what keeps it alive.
      final restored = bought.refreshedAt(
        at(2027, 7, 8),
        source: ProSource.restore,
      );

      expect(restored.source, ProSource.restore);
      expect(restored.confirmedAtMs, at(2027, 7, 8));
      expect(restored.isActiveAt(at(2028, 6, 1)), isTrue);
      expect(bought.isActiveAt(at(2028, 6, 1)), isFalse);
    });

    test('does not upgrade or downgrade the plan it restored', () {
      final restored = ProEntitlement(
        plan: ProPlan.monthly,
        confirmedAtMs: at(2026, 10, 8),
        source: ProSource.restore,
      ).refreshedAt(at(2026, 11, 8), source: ProSource.restore);
      expect(restored.plan, ProPlan.monthly);
    });
  });

  group('the stored line', () {
    test('round-trips every plan and both sources', () {
      for (final plan in ProPlan.values) {
        for (final source in ProSource.values) {
          final pro = ProEntitlement(
            plan: plan,
            confirmedAtMs: at(2026, 10, 8),
            source: source,
          );
          final back = ProEntitlement.decode(pro.encode())!;

          expect(back.plan, plan);
          expect(back.confirmedAtMs, pro.confirmedAtMs);
          expect(back.source, source);
        }
      }
    });

    test('is readable in a bug report', () {
      final pro = ProEntitlement(
        plan: ProPlan.yearly,
        confirmedAtMs: at(2026, 10, 8),
        source: ProSource.restore,
      );
      expect(pro.encode(), 'yearly|${at(2026, 10, 8)}|restore');
    });

    test('anything unreadable means free, never a crash', () {
      // A corrupt or hand-edited line must not take the ledger down with it —
      // and must never be read as "paid".
      for (final bad in <String>[
        '',
        'free',
        'monthly',
        'monthly|',
        'monthly|abc',
        'monthly|0',
        'monthly|-5',
        'platinum|1759900000000',
        '|||',
      ]) {
        expect(ProEntitlement.decode(bad), isNull, reason: bad);
      }
      expect(ProEntitlement.decode(null), isNull);
    });

    test('a missing source is a purchase, not a restore', () {
      final decoded = ProEntitlement.decode('monthly|${at(2026, 10, 8)}')!;
      expect(decoded.source, ProSource.purchase);
    });
  });
}
