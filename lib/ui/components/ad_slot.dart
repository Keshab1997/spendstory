/// The one place an ad can appear (T-601 … T-603).
///
/// Every screen in the app that is allowed to carry an ad uses this widget, and
/// no screen decides for itself whether the ad exists. What it does, in order:
///
/// * **Pro, or not yet onboarded** → nothing at all. One switch
///   (`adsVisibleProvider`), no per-screen code, and a test that holds it.
/// * **A build with no ads** (the web preview, widget tests, a release with the
///   live ids not filled in yet) → nothing on a device, and a labelled
///   placeholder in debug, because the person looking at that build is the one
///   deciding where ads go.
/// * **A real ad** → a box of the reserved height while it loads, the ad when it
///   lands, and nothing at all if it never lands. A failed ad must leave a
///   finished-looking page, never a hole and never a red box (`docs/08 §3`).
///
/// `AdPlacement` is re-exported so that screens keep importing this one file.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ads/ad_client.dart';
import '../../ads/ad_placement.dart';
import '../../app/providers.dart';
import '../strings.dart';
import '../tokens.dart';

export '../../ads/ad_placement.dart'
    show AdFormat, AdPlacement, formatOf, reservedHeightOf, unitNameOf;

class AdSlot extends ConsumerStatefulWidget {
  const AdSlot({super.key, required this.placement});

  final AdPlacement placement;

  /// The height this slot reserves. Banners fill it exactly; native units take
  /// at least this much and grow if their template is taller.
  static double heightFor(AdPlacement placement) => reservedHeightOf(placement);

  @override
  ConsumerState<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends ConsumerState<AdSlot> {
  AdOutcome? _outcome;

  /// The creative, created once. `build` runs again on every setState and on
  /// every provider the page listens to; asking the client for a new ad each
  /// time would restart the request, and on a real device the second request
  /// arrives after the first one was already paid for.
  Widget? _view;

  @override
  Widget build(BuildContext context) {
    final showAds = ref.watch(adsVisibleProvider);
    if (!showAds) return const SizedBox.shrink();

    final client = ref.watch(adClientProvider);
    final unitId = client.unitIdFor(widget.placement);
    final height = AdSlot.heightFor(widget.placement);

    // No ad is coming for this build/platform. On a device that means an empty
    // space; in debug it means the labelled placeholder, so the layout can be
    // reviewed before there is an AdMob account to review it with.
    if (unitId == null) {
      return kDebugMode
          ? _placeholder(context, height)
          : const SizedBox.shrink();
    }

    _view ??= client.adView(
      placement: widget.placement,
      nonPersonalized: ref.watch(nonPersonalizedAdsProvider),
      onOutcome: (outcome) {
        if (!mounted) return;
        setState(() => _outcome = outcome);
      },
    );
    final view = _view;

    // A failed load collapses the slot: the page closes up rather than leaving
    // a gap where an ad should have been.
    if (view == null || _outcome == AdOutcome.failed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: SsSpace.x4),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Stack(
          children: [
            view,
            // The label sits above the creative on purpose: "Sponsored" is not
            // decoration, it is the policy.
            Positioned(
              top: 0,
              left: 0,
              child: _label(context, ref.watch(stringsProvider)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, double height) {
    final c = SsColors.of(context);
    final strings = ref.watch(stringsProvider);

    return Container(
      height: height,
      margin: const EdgeInsets.only(top: SsSpace.x4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: SsRadius.rMd,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 16, color: c.textTertiary),
          const SizedBox(width: SsSpace.x2),
          Flexible(
            child: Text(
              '${strings['adLabel']} — ${unitNameOf(widget.placement)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SsText.micro.copyWith(color: c.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, SsStrings strings) {
    final c = SsColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SsSpace.x2, vertical: 2),
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: BorderRadius.only(
          topLeft: SsRadius.rSm.topLeft,
          topRight: SsRadius.rSm.topRight,
        ),
      ),
      child: Text(
        strings['adLabel'],
        style: SsText.micro.copyWith(color: c.textTertiary),
      ),
    );
  }
}

/// Whether ads should be shown at all. Pro is ad-free, and a user who has not
/// finished onboarding must never see an ad.
bool shouldShowAds({required bool isPro, required bool onboarded}) =>
    !isPro && onboarded;

/// Kept next to the slot so the paywall and the ad gate can never disagree about
/// what "free" means.
bool isProFromMeta(String? proStatus) => proStatus == 'pro';
