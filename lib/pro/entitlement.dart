/// What the app believes the user has paid for (T-605).
///
/// There is no server, so there is no receipt to verify against: the app's
/// record is **what Play last told it**. That makes two things matter more than
/// usual, and both are pure functions here so the tests can hold them:
///
/// * **A paying user is never locked out.** The window is longer than the
///   billing period (see `entitlementWindow`), and any word from Play — a
///   purchase, a restore, a re-delivery of a purchase made on another device —
///   refreshes it.
/// * **A cancelled subscription does end.** The window is finite, and every
///   launch asks the store to restore, which is what stops a lapsed
///   subscription from living forever in `app_meta`.
///
/// The encoded form is one line in `app_meta`, so it survives a reinstall only
/// as far as Play's restore does — which is exactly the guarantee the product
/// makes, and `docs/08 §6` says so out loud.
library;

import 'product_ids.dart';

/// Where this record came from. Kept because "I paid" and "the store handed it
/// back to me" are different stories to tell a user on the paywall.
enum ProSource { purchase, restore }

const Map<ProSource, String> _sourceWires = <ProSource, String>{
  ProSource.purchase: 'purchase',
  ProSource.restore: 'restore',
};

ProSource proSourceFrom(String? wire) => _sourceWires[ProSource.restore] == wire
    ? ProSource.restore
    : ProSource.purchase;

class ProEntitlement {
  const ProEntitlement({
    required this.plan,
    required this.confirmedAtMs,
    this.source = ProSource.purchase,
  });

  final ProPlan plan;

  /// When Play last confirmed this. Not "when the user tapped buy" — a restore
  /// on a new phone is just as much a confirmation.
  final int confirmedAtMs;

  final ProSource source;

  /// When this record stops being trusted, or null for a lifetime unlock.
  int? get expiresAtMs {
    if (!isRenewing(plan)) return null;
    return confirmedAtMs + entitlementWindow(plan).inMilliseconds;
  }

  bool isActiveAt(int nowMs) {
    final end = expiresAtMs;
    return end == null || nowMs < end;
  }

  /// How long the user has left, or null when there is no end to count down to.
  ///
  /// Shown in Settings as "renews on…" rather than as a countdown on the
  /// paywall: a timer over a price is a dark pattern (`docs/08 §6`), an honest
  /// "valid until" next to the user's own subscription is not.
  Duration? remainingAt(int nowMs) {
    final end = expiresAtMs;
    if (end == null) return null;
    final left = end - nowMs;
    return left <= 0 ? Duration.zero : Duration(milliseconds: left);
  }

  ProEntitlement refreshedAt(int nowMs, {required ProSource source}) =>
      ProEntitlement(plan: plan, confirmedAtMs: nowMs, source: source);

  /// `plan|confirmedAt|source` — one line, easy to read back in a bug report,
  /// and impossible to confuse with a receipt.
  String encode() =>
      '${plan.name}|$confirmedAtMs|${_sourceWires[source] ?? 'purchase'}';

  /// Returns null for anything that is not a record this build understands —
  /// an empty value, a plan that no longer exists, a corrupt line. A record the
  /// app cannot read must mean "free", never a crash on the way to the ledger.
  static ProEntitlement? decode(String? encoded) {
    if (encoded == null) return null;
    final parts = encoded.split('|');
    if (parts.length < 2) return null;

    final plan = ProPlan.values.where((p) => p.name == parts[0]).firstOrNull;
    if (plan == null) return null;

    final confirmedAt = int.tryParse(parts[1]);
    if (confirmedAt == null || confirmedAt <= 0) return null;

    return ProEntitlement(
      plan: plan,
      confirmedAtMs: confirmedAt,
      source: parts.length > 2 ? proSourceFrom(parts[2]) : ProSource.purchase,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
