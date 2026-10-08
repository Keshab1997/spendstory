/// The one thing that decides whether this install is Pro (T-605).
///
/// It hears three things and nothing else:
///
/// * a purchase event from the store,
/// * a restore event from the store,
/// * the user asking for a restore.
///
/// …and it answers one question — is Pro active right now — which the ad slots,
/// the forecast and the paywall all read from the same provider. The record goes
/// to `app_meta` (`proEntitlement` and the older `proStatus` line, which the
/// paywall and the ads layer already read), so a restart keeps what Play
/// confirmed.
///
/// **What this deliberately does not do:** verify a receipt. There is no server
/// to verify against — that is the product. `docs/08 §6` accepts the trade and
/// this docstring is the record of it.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/db.dart';
import 'billing_client.dart';
import 'entitlement.dart';
import 'product_ids.dart';

class ProController {
  ProController(this._ref);

  final Ref _ref;
  StreamSubscription<BillingEvent>? _subscription;

  BillingClient get _client => _ref.read(billingClientProvider);

  /// Called once, from the shell, after the first frame. Reads what this install
  /// already owns and starts listening — the two triggers an entitlement can
  /// arrive through.
  Future<void> start() async {
    await _load();
    if (!_client.available) return;

    _subscription ??= _client.events.listen(_onEvent);
    await _client.initialize();
    // Asking Play on launch is what keeps a lapsed subscription from living
    // forever in `app_meta`, and what gives a reinstall its Pro back.
    await restore();
  }

  /// Reads the stored record. A record that has run out is cleared rather than
  /// left to expire on its own, so Settings never shows a stale plan — and a
  /// cancelled subscription really does end (the window in `product_ids.dart`
  /// is what decides that).
  Future<void> _load() async {
    final db = _ref.read(appDbProvider);
    final encoded = db == null
        ? _ref.read(sessionProEntitlementProvider)
        : await db.meta('proEntitlement');

    final stored = ProEntitlement.decode(encoded);
    if (stored == null) return;

    if (!stored.isActiveAt(_nowMs)) {
      await _clear(db);
      return;
    }
    _write(stored);
  }

  /// Back to free: the session copy, `app_meta`, and the provider the screens
  /// read. Used when the stored window has run out and on a fresh install.
  Future<void> _clear(AppDb? db) async {
    _ref.read(proEntitlementProvider.notifier).state = null;
    _ref.read(sessionProEntitlementProvider.notifier).state = null;
    if (db == null) return;
    await db.setMeta('proStatus', 'free');
    await db.setMeta('proEntitlement', '');
  }

  int get _nowMs => _ref.read(nowProvider).millisecondsSinceEpoch;

  /// The one place an event becomes access.
  void _onEvent(BillingEvent event) {
    _ref.read(lastBillingEventProvider.notifier).state = event;
    _ref.read(billingBusyProvider.notifier).state =
        event.outcome == BillingOutcome.pending;

    if (!event.grantsAccess) return;

    final plan = event.plan;
    if (plan == null) return; // a product this build does not know

    _write(
      ProEntitlement(
        plan: plan,
        confirmedAtMs: _ref.read(nowProvider).millisecondsSinceEpoch,
        source: event.outcome == BillingOutcome.restored
            ? ProSource.restore
            : ProSource.purchase,
      ),
    );
  }

  /// The user's own tap on "buy". False when there is nothing to buy on this
  /// device — the paywall says so rather than looking broken.
  Future<bool> buy(ProPlan plan) async {
    if (!_client.available) {
      // No store on this device: record it as a failure so the screen has the
      // same note to show as it would for any other refusal.
      _ref.read(lastBillingEventProvider.notifier).state = BillingEvent(
        outcome: BillingOutcome.error,
        plan: plan,
      );
      _ref.read(billingBusyProvider.notifier).state = false;
      return false;
    }

    _ref.read(billingBusyProvider.notifier).state = true;
    try {
      final started = await _client.buy(plan);
      if (!started) {
        _ref.read(billingBusyProvider.notifier).state = false;
        _ref.read(lastBillingEventProvider.notifier).state = BillingEvent(
          outcome: BillingOutcome.error,
          plan: plan,
        );
      }
      return started;
    } catch (error) {
      _ref.read(billingBusyProvider.notifier).state = false;
      _ref.read(lastBillingEventProvider.notifier).state = BillingEvent(
        outcome: BillingOutcome.error,
        plan: plan,
        message: '$error',
      );
      return false;
    }
  }

  /// Restore. Mandatory on the paywall and in Settings (`docs/08 §6`), and also
  /// what the app does by itself on every launch.
  Future<void> restore() async {
    _ref.read(billingBusyProvider.notifier).state = true;
    try {
      await _client.restore();
    } catch (error) {
      _ref.read(lastBillingEventProvider.notifier).state = BillingEvent(
        outcome: BillingOutcome.error,
        message: '$error',
      );
    } finally {
      _ref.read(billingBusyProvider.notifier).state = false;
    }
  }

  /// What the store will sell right now, with its own prices.
  Future<List<ProProduct>> products() => _client.products();

  void _write(ProEntitlement entitlement) {
    _ref.read(proEntitlementProvider.notifier).state = entitlement;

    final db = _ref.read(appDbProvider);
    if (db == null) {
      // Web preview and widget tests: the session map stands in for `app_meta`,
      // exactly like every other overlay in this app.
      _ref.read(sessionProEntitlementProvider.notifier).state = entitlement
          .encode();
      return;
    }
    unawaited(_persist(db, entitlement));
  }

  Future<void> _persist(AppDb db, ProEntitlement entitlement) async {
    await db.setMeta('proEntitlement', entitlement.encode());
    // The older key the ads layer and the paywall already speak (`isProFromMeta`
    // in `ad_slot.dart`), kept in step so there is never one reader that says
    // Free while another says Pro.
    await db.setMeta(
      'proStatus',
      entitlement.isActiveAt(_nowMs) ? 'pro' : 'free',
    );
  }
}

/// The store's prices, for the paywall. An empty list is normal on the web
/// preview and on a device with no Play services, and means "show the
/// documented prices as estimates".
final proProductsProvider = FutureProvider<List<ProProduct>>(
  (ref) => ref.watch(proControllerProvider).products(),
);

/// The controller, and the state it writes. The providers themselves live in
/// `lib/app/providers.dart` next to [proStatusProvider] so that screens can read
/// the entitlement without importing the store.
final proControllerProvider = Provider<ProController>(
  (ref) => ProController(ref),
);
