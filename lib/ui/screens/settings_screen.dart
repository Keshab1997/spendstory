/// S-20 Settings.
///
/// This is where the two promises the product is sold on become visible
/// switches: someone can see, in one screen, that SpendStory is ad-free on Pro,
/// works in three languages, and never sends data anywhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../components/ad_slot.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isPro = ref.watch(proStatusProvider);
    final showAds = ref.watch(adsVisibleProvider);

    return SsScaffold(
      floatingNav: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),
          Text(s.settings, style: SsText.h1),
          const SizedBox(height: SsSpace.x5),

          // ---- pro -----------------------------------------------------------
          if (isPro)
            SsCard(
              gradient: c.proGradient,
              onTap: () => context.push('/pro'),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF2A1B00),
                    size: 26,
                  ),
                  const SizedBox(width: SsSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['proTitle'],
                          style: SsText.h3.copyWith(
                            color: const Color(0xFF2A1B00),
                          ),
                        ),
                        Text(
                          'সক্রিয় · বিজ্ঞাপন নেই',
                          style: SsText.caption.copyWith(
                            color: const Color(0xFF2A1B00)
                                .withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF2A1B00).withValues(alpha: 0.8),
                  ),
                ],
              ),
            )
          else
            SsCard(
              gradient: c.proGradient,
              onTap: () => context.push('/pro'),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['proTitle'],
                          style: SsText.h3.copyWith(
                            color: const Color(0xFF2A1B00),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['proBody'],
                          style: SsText.caption.copyWith(
                            color: const Color(0xFF2A1B00)
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF2A1B00),
                  ),
                ],
              ),
            ),

          // ---- appearance ----------------------------------------------------
          const SizedBox(height: SsSpace.x6),
          SectionHeader(title: s['appearance'], padding: EdgeInsets.zero),
          SsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['theme'],
                  style: SsText.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: SsSpace.x2),
                SsSegmented<ThemeMode>(
                  values: const [
                    ThemeMode.system,
                    ThemeMode.light,
                    ThemeMode.dark,
                  ],
                  labels: [s['themeSystem'], s['themeLight'], s['themeDark']],
                  selected: themeMode,
                  onChanged: (mode) =>
                      ref.read(themeModeProvider.notifier).state = mode,
                ),
                const SizedBox(height: SsSpace.x4),
                Text(
                  s['language'],
                  style: SsText.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: SsSpace.x2),
                SsSegmented<String>(
                  values: const ['bn', 'hi', 'en'],
                  labels: const ['বাংলা', 'हिन्दी', 'English'],
                  selected: locale,
                  onChanged: (code) {
                    ref.read(localeProvider.notifier).state = code;
                    ref.read(appDbProvider)?.setMeta('locale', code);
                  },
                ),
              ],
            ),
          ),

          // ---- the rest ------------------------------------------------------
          const SizedBox(height: SsSpace.x5),
          SsCard(
            padding: const EdgeInsets.symmetric(
              horizontal: SsSpace.x2,
              vertical: SsSpace.x1,
            ),
            child: Column(
              children: [
                SettingTile(
                  icon: Icons.savings_outlined,
                  tint: c.gold500,
                  title: s.budget,
                  subtitle: 'ক্যাটাগরি ধরে মাসিক লিমিট',
                  onTap: () => context.push('/budgets'),
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.category_outlined,
                  tint: c.teal500,
                  title: s.categories,
                  subtitle: 'নিজের ক্যাটাগরি বানান',
                  onTap: () => context.push('/categories'),
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.account_balance_outlined,
                  title: s.accounts,
                  subtitle: 'ব্যাঙ্ক · ক্যাশ · ওয়ালেট',
                  onTap: () => context.push('/accounts'),
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.lock_outline_rounded,
                  tint: c.violet600,
                  title: s['privacy'],
                  subtitle: s['privacyBody'],
                  onTap: () => _showPrivacy(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: SsSpace.x5),
          SsCard(
            padding: const EdgeInsets.symmetric(
              horizontal: SsSpace.x2,
              vertical: SsSpace.x1,
            ),
            child: SettingTile(
              icon: Icons.delete_outline_rounded,
              title: 'সব ডেটা মুছুন',
              subtitle: 'ডাবল-কনফার্মের পর সম্পূর্ণ মুছে যাবে',
              danger: true,
              onTap: () => _confirmErase(context, ref),
            ),
          ),

          if (showAds) const AdSlot(placement: AdPlacement.sectionBanner),

          const SizedBox(height: SsSpace.x6),
          Center(
            child: Column(
              children: [
                Text(
                  'SpendStory · ${s['version']} 1.0.0 (1)',
                  style: SsText.micro.copyWith(color: c.textTertiary),
                ),
                const SizedBox(height: SsSpace.x1),
                Text(
                  s['aboutBody'],
                  style: SsText.micro.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: SsSpace.x4),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    final c = SsColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          SsSpace.x5,
          SsSpace.x2,
          SsSpace.x5,
          SsSpace.x8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('প্রাইভেসি', style: SsText.h2),
            const SizedBox(height: SsSpace.x3),
            Text(
              'SpendStory শুধু ব্যাঙ্কের লেনদেন SMS পড়ে — OTP কখনো পড়ে না। '
              'কোনো ডেটা সার্ভারে যায় না, কোনো অ্যাকাউন্ট লাগে না। '
              'অ্যাপটা আনইনস্টল করলে সব ডেটা ফোন থেকেই চলে যায়।',
              style: SsText.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: SsSpace.x4),
            SsBadge(
              label: '100% অন-ডিভাইস',
              color: c.teal500,
              icon: Icons.shield_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmErase(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDbProvider);
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('সব ডেটা মুছবেন?'),
        content: const Text(
          'সব লেনদেন, বাজেট আর ক্যাটাগরি মুছে যাবে। এটি ফেরানো যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('থাক'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );

    if (first != true || !context.mounted) return;

    // A second confirm, because this is the one irreversible action in the app.
    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নিশ্চিত?'),
        content: const Text('শেষ সুযোগ — তারপরই সব মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('হ্যাঁ, মুছে ফেলুন'),
          ),
        ],
      ),
    );

    if (second != true) return;

    if (db == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ডেমো মোডে ডেটা মুছে ফেলা নিষ্ক্রিয় — ফোনের বিল্ডে কাজ করে।',
            ),
          ),
        );
      }
      return;
    }

    await db.purgeEverything();
    await db.seedIfNeeded();
    await db.setMeta('onboarded', 'false');
    ref.invalidate(bootProvider);
    ref.invalidate(transactionsProvider);

    if (context.mounted) context.go('/language');
  }
}
