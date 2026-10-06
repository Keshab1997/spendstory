/// S-22 Pro paywall — pushed as a fullscreen dialog (`docs/04` §3).
///
/// Prices come straight from `docs/08-MONETIZATION-ADMOB.md`: ₹99/month,
/// ₹699/year, ₹1,499 lifetime, with a 7-day trial. The **yearly plan is the
/// default selection**, because that is the one that is actually good value and
/// pretending otherwise would be a dark pattern.
///
/// The purchase itself is Batch 7 (T-601). Until the billing client exists, the
/// button flips `proStatusProvider` so the ad-free state can be reviewed end to
/// end — and says so on screen, rather than pretending to charge anyone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

enum _Plan { monthly, yearly, lifetime }

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  _Plan _plan = _Plan.yearly;

  static const Map<_Plan, ({String title, String price, String note})> _plans =
      <_Plan, ({String title, String price, String note})>{
        _Plan.monthly: (title: 'মাসিক', price: '₹৯৯', note: 'প্রতি মাসে'),
        _Plan.yearly: (
          title: 'বার্ষিক',
          price: '₹৬৯৯',
          note: 'প্রতি বছরে · ৪১% সঞ্চয়',
        ),
        _Plan.lifetime: (
          title: 'লাইফটাইম',
          price: '₹১,৪৯৯',
          note: 'একবার, চিরদিনের জন্য',
        ),
      };

  static const List<({IconData icon, String title, String body})> _features =
      <({IconData icon, String title, String body})>[
        (
          icon: Icons.block_rounded,
          title: 'বিজ্ঞাপন নেই',
          body: 'হোম, বাজেট আর ইনসাইট থেকে সব বিজ্ঞাপন সরে যাবে।',
        ),
        (
          icon: Icons.savings_outlined,
          title: 'আনলিমিটেড বাজেট',
          body: 'যত খুশি ক্যাটাগরি-বাজেট, প্রতিটার অ্যালার্ট সহ।',
        ),
        (
          icon: Icons.auto_graph_rounded,
          title: 'খরচের পূর্বাভাস',
          body: 'মাস শেষে কত খরচ হবে, আগেই জেনে নিন।',
        ),
        (
          icon: Icons.picture_as_pdf_outlined,
          title: 'এক্সপোর্ট ও রিপোর্ট',
          body: 'CSV আর PDF — রিওয়ার্ডেড অ্যাডে আনলক, Pro-তে সরাসরি।',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final isPro = ref.watch(proStatusProvider);

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
                              'SpendStory Pro',
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
                        '৭ দিন ফ্রি, তারপর যেকোনো সময় বাতিল।',
                        style: SsText.body.copyWith(
                          color: const Color(0xFF2A1B00).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SsSpace.x5),
                for (final f in _features) ...[
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
                for (final plan in _Plan.values) ...[
                  _PlanTile(
                    title: _plans[plan]!.title,
                    price: _plans[plan]!.price,
                    note: _plans[plan]!.note,
                    selected: _plan == plan,
                    badge: plan == _Plan.yearly ? 'সবচেয়ে জনপ্রিয়' : null,
                    onTap: () => setState(() => _plan = plan),
                  ),
                  const SizedBox(height: SsSpace.x3),
                ],

                const SizedBox(height: SsSpace.x3),
                SsActionButton(
                  label: isPro
                      ? 'Pro চালু আছে'
                      : '৭ দিন ফ্রি ট্রায়াল শুরু করুন',
                  tone: SsButtonTone.gold,
                  onPressed: isPro
                      ? null
                      : () {
                          ref.read(proStatusProvider.notifier).state = true;
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ডেমো: Pro চালু হয়েছে — বিজ্ঞাপনগুলো সরে গেল। '
                                'আসল বিলিং ব্যাচ ৭ (T-601)।',
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(height: SsSpace.x3),
                Center(
                  child: Text(
                    'পেমেন্ট এখনো যুক্ত হয়নি — বিলিং ব্যাচ ৭ (T-601)।',
                    style: SsText.micro.copyWith(color: c.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
