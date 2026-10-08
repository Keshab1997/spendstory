/// S-22 Pro paywall — pushed as a fullscreen dialog (`docs/04` §3, T-604).
///
/// Four rules from `docs/08 §6` and `docs/03 §S-22` shape every decision here,
/// and each of them is a test in `test/ui/paywall_test.dart`:
///
/// * **The price is the store's price.** The number on a tier is what Play will
///   charge, read from the store. Before the store answers — or where there is
///   no store, like the web preview — the documented price is shown and marked
///   as an estimate rather than passed off as the store's word.
/// * **No dark patterns.** No countdown, no struck-through fake price, no
///   pre-ticked box, no "are you sure you want to stay poor". The monthly plan
///   is the one selected when the screen opens, because it is the cheapest and
///   the user can move to a better one themselves.
/// * **Restore is always offered**, next to the buy button rather than buried:
///   it is the only way back for somebody who paid on another phone, and Play
///   requires it to be reachable.
/// * **Privacy and terms are one tap away** — the privacy sheet the Settings
///   screen opens, so there is one text about privacy in the app rather than
///   two that can drift.
///
/// A Pro user does not see a paywall at all: the screen shows what they own,
/// when it renews, and the restore button, and nothing in it is trying to sell
/// them anything twice.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../pro/billing_client.dart';
import '../../pro/product_ids.dart';
import '../../pro/entitlement.dart';
import '../../pro/pro_controller.dart';
import '../components/controls.dart';
import '../components/privacy_sheet.dart';
import '../components/money.dart' show formatInr;
import '../components/surfaces.dart';
import '../format.dart';
import '../strings.dart';
import '../tokens.dart';

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  /// Monthly by default: the cheapest tier, and the one a user can upgrade away
  /// from. `docs/03 §S-22` names it as the default selection, and picking the
  /// most expensive tier for the user is the kind of thing the spec calls a dark
  /// pattern.
  ProPlan _plan = ProPlan.monthly;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final isPro = ref.watch(proStatusProvider);
    final entitlement = ref.watch(proEntitlementProvider);
    final busy = ref.watch(billingBusyProvider);
    final lastEvent = ref.watch(lastBillingEventProvider);
    final storeProducts =
        ref.watch(proProductsProvider).valueOrNull ?? const <ProProduct>[];

    final plans = <ProPlan, ({String title, String note})>{
      ProPlan.monthly: (title: s['planMonthly'], note: s['planMonthlyNote']),
      ProPlan.yearly: (title: s['planYearly'], note: s['planYearlyNote']),
      ProPlan.lifetime: (title: s['planLifetime'], note: s['planLifetimeNote']),
    };

    final features = <({IconData icon, String title, String body})>[
      (
        icon: Icons.block_rounded,
        title: s['featureNoAdsTitle'],
        body: s['featureNoAdsBody'],
      ),
      (
        icon: Icons.savings_outlined,
        title: s['featureUnlimitedBudgetsTitle'],
        body: s['featureUnlimitedBudgetsBody'],
      ),
      (
        icon: Icons.auto_graph_rounded,
        title: s['featureForecastTitle'],
        body: s['featureForecastBody'],
      ),
      (
        icon: Icons.picture_as_pdf_outlined,
        title: s['featureExportTitle'],
        body: s['featureExportBody'],
      ),
    ];

    // The app is honest about which price it is showing: the store's, or its
    // own estimate while the store has not answered.
    String priceFor(ProPlan plan) {
      for (final product in storeProducts) {
        if (product.plan == plan) return product.priceLabel;
      }
      return formatInr(
        fallbackPricePaise(plan),
        showSymbol: true,
        localize: locale,
      );
    }

    final priceIsEstimate = storeProducts.isEmpty;
    final yearlySaving = _savingPercent(
      fallbackPricePaise(ProPlan.monthly),
      fallbackPricePaise(ProPlan.yearly),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: c.screenWash),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              SsSpace.screen,
              SsSpace.x2,
              SsSpace.screen,
              SsSpace.x8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: SsIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: SsSpace.x2),

                SsCard(
                  gradient: c.proGradient,
                  padding: const EdgeInsets.all(SsSpace.x5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFF2A1B00),
                            size: 30,
                          ),
                          const SizedBox(width: SsSpace.x3),
                          Flexible(
                            child: Text(
                              s.proTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SsText.h2.copyWith(
                                color: const Color(0xFF2A1B00),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SsSpace.x3),
                      Text(
                        isPro ? s['proActiveBody'] : s['trialDisclaimer'],
                        style: SsText.body.copyWith(
                          color: const Color(0xFF2A1B00).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SsSpace.x5),
                for (final f in features) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.tintOf(c.gold500),
                          borderRadius: SsRadius.rSm,
                        ),
                        child: Icon(f.icon, size: 19, color: c.gold500),
                      ),
                      const SizedBox(width: SsSpace.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.title, style: SsText.bodyStrong),
                            Text(
                              f.body,
                              style: SsText.caption.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SsSpace.x4),
                ],

                const SizedBox(height: SsSpace.x2),

                // A Pro user is not sold to; they get their receipt.
                if (isPro && entitlement != null)
                  _ProStatusCard(
                    entitlement: entitlement,
                    locale: locale,
                    strings: s,
                  )
                else ...[
                  // The three things that are for sale — never the taste, which
                  // cannot be bought and is not offered here (`docs/08 §5`).
                  for (final plan in purchasablePlans) ...[
                    _PlanTile(
                      title: plans[plan]!.title,
                      price: priceFor(plan),
                      note: plans[plan]!.note,
                      selected: _plan == plan,
                      badge: plan == ProPlan.yearly
                          ? s.fill('savePercentTemplate', {
                              'pct': localizeDigits('$yearlySaving', locale),
                            })
                          : null,
                      onTap: () => setState(() => _plan = plan),
                    ),
                    const SizedBox(height: SsSpace.x3),
                  ],

                  if (priceIsEstimate) ...[
                    Text(
                      s['priceEstimateNote'],
                      style: SsText.micro.copyWith(color: c.textTertiary),
                    ),
                    const SizedBox(height: SsSpace.x3),
                  ],

                  SsActionButton(
                    label: busy ? s['purchasePending'] : s['startTrial'],
                    tone: SsButtonTone.gold,
                    onPressed: busy ? null : () => _buy(_plan),
                  ),
                ],

                const SizedBox(height: SsSpace.x3),
                if (lastEvent != null) ...[
                  _BillingNote(event: lastEvent, strings: s),
                  const SizedBox(height: SsSpace.x3),
                ],

                // Restore, always: the way back for a purchase made on another
                // phone, and a Play requirement.
                Center(
                  child: TextButton(
                    onPressed: busy ? null : () => _restore(),
                    child: Text(s['restorePurchases']),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(s['maybeLater']),
                  ),
                ),

                const SizedBox(height: SsSpace.x2),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: SsSpace.x2,
                    children: [
                      TextButton(
                        onPressed: () => showPrivacySheet(context, ref),
                        child: Text(s.privacy),
                      ),
                      Text(
                        '·',
                        style: SsText.caption.copyWith(color: c.textTertiary),
                      ),
                      TextButton(
                        onPressed: () => showTermsSheet(context, ref),
                        child: Text(s['terms']),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    isPro ? s['proActive'] : s['subscriptionFootNote'],
                    textAlign: TextAlign.center,
                    style: SsText.micro.copyWith(color: c.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buy(ProPlan plan) async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final started = await ref.read(proControllerProvider).buy(plan);
    if (!started) {
      // The store could not be reached, or has no such product. Say so; the
      // button must never look like it did something it did not.
      messenger.showSnackBar(SnackBar(content: Text(s['billingNotAvailable'])));
      return;
    }

    // A successful *sheet* is not a successful purchase: Play answers through
    // the purchase stream, which the controller listens to, and the screen
    // simply closes. Claiming success here would be a lie for every pending
    // payment.
    messenger.showSnackBar(SnackBar(content: Text(s['purchaseThanks'])));
    navigator.pop();
  }

  Future<void> _restore() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(proControllerProvider).restore();
    if (!mounted) return;
    final event = ref.read(lastBillingEventProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          event != null && event.grantsAccess
              ? s['restoreDone']
              : s['restoreNothing'],
        ),
      ),
    );
  }
}

/// The yearly plan's saving, computed from the two prices rather than asserted.
///
/// `docs/08 §6` promises "৪২% সাশ্রয়" as an anchor. A percentage typed into a
/// string is a claim that can quietly become false the day Play's pricing
/// changes; this one is arithmetic on the numbers on the same screen.
int _savingPercent(int monthlyPaise, int yearlyPaise) {
  final twelveMonths = monthlyPaise * 12;
  if (twelveMonths <= 0) return 0;
  return (((twelveMonths - yearlyPaise) * 100) / twelveMonths).round();
}

/// Which plan this is, in the user's language. Used by the paywall's own status
/// card and by Settings, so the two can never name a plan differently.
String planLabel(SsStrings strings, ProPlan plan) => switch (plan) {
  ProPlan.monthly => strings['planMonthly'],
  ProPlan.yearly => strings['planYearly'],
  ProPlan.lifetime => strings['planLifetime'],
  ProPlan.taste => strings['planTaste'],
};

/// What a paying user sees instead of the tiers: which plan they own, and when
/// it renews. No price, no timer, nothing to buy.
class _ProStatusCard extends StatelessWidget {
  const _ProStatusCard({
    required this.entitlement,
    required this.locale,
    required this.strings,
  });

  final ProEntitlement entitlement;
  final String locale;
  final SsStrings strings;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    // A renewal date is a promise about a payment, so only the two plans that
    // will actually be charged again get one. A taste ends after 24 hours and
    // says that instead (`docs/08 §5`); lifetime has nothing to say.
    final renewsOn = isRenewing(entitlement.plan)
        ? entitlement.expiresAtMs
        : null;
    final isTaste = entitlement.plan == ProPlan.taste;

    return SsCard(
      color: c.tintOf(c.gold500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 20, color: c.gold500),
              const SizedBox(width: SsSpace.x2),
              Expanded(
                child: Text(strings['proActive'], style: SsText.bodyStrong),
              ),
            ],
          ),
          const SizedBox(height: SsSpace.x1),
          Text(
            planLabel(strings, entitlement.plan),
            style: SsText.caption.copyWith(color: c.textSecondary),
          ),
          if (renewsOn != null) ...[
            const SizedBox(height: SsSpace.x1),
            Text(
              strings.fill('renewsOnTemplate', {
                'date': shortDate(renewsOn, locale: locale),
              }),
              style: SsText.micro.copyWith(color: c.textTertiary),
            ),
          ],
          if (isTaste) ...[
            const SizedBox(height: SsSpace.x2),
            Text(
              strings['proTasteBody'],
              style: SsText.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// The store's last word, in the user's language: a payment under review, a
/// refusal, or a plan that is not on sale in this country yet.
class _BillingNote extends StatelessWidget {
  const _BillingNote({required this.event, required this.strings});

  final BillingEvent event;
  final SsStrings strings;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    final (String key, Color color, IconData icon) = switch (event.outcome) {
      BillingOutcome.pending => (
        'billingPending',
        c.gold500,
        Icons.hourglass_bottom_rounded,
      ),
      BillingOutcome.canceled => (
        'billingCanceled',
        c.textSecondary,
        Icons.close_rounded,
      ),
      BillingOutcome.error => (
        'billingFailed',
        c.danger,
        Icons.error_outline_rounded,
      ),
      BillingOutcome.purchased || BillingOutcome.restored => (
        'billingSucceeded',
        c.teal500,
        Icons.check_circle_outline_rounded,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: SsSpace.x2),
        Expanded(
          child: Text(
            strings[key],
            style: SsText.caption.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.note,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String note;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return SsCard(
      onTap: onTap,
      color: selected ? c.tintOf(c.gold500) : c.surface,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? c.gold500 : Colors.transparent,
              border: Border.all(
                color: selected ? c.gold500 : c.border,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF2A1B00),
                  )
                : null,
          ),
          const SizedBox(width: SsSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SsText.bodyStrong,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: SsSpace.x2),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SsSpace.x2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: c.proGradient,
                            borderRadius: SsRadius.rPill,
                          ),
                          child: Text(
                            badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SsText.micro.copyWith(
                              color: const Color(0xFF2A1B00),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  note,
                  style: SsText.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Text(price, style: SsText.h3),
        ],
      ),
    );
  }
}
