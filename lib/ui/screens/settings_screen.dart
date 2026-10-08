/// S-20 Settings.
///
/// This is where the two promises the product is sold on become visible
/// switches: someone can see, in one screen, that SpendStory is ad-free on Pro,
/// works in three languages, and never sends data anywhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ads/ad_consent.dart';
import '../../app/app_info.dart';
import '../../app/providers.dart';
import '../../export/backup_repo.dart';
import '../../pro/pro_controller.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import '../format.dart';
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
    final personalized = !ref.watch(nonPersonalizedAdsProvider);
    final privacyOptionsRequired = ref.watch(privacyOptionsRequiredProvider);

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
                          s['activeNoAds'],
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
                  subtitle: s['budgetSettingBody'],
                  onTap: () => context.push('/budgets'),
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.category_outlined,
                  tint: c.teal500,
                  title: s.categories,
                  subtitle: s['categoriesSettingBody'],
                  onTap: () => context.push('/categories'),
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.account_balance_outlined,
                  title: s.accounts,
                  subtitle: s['accountsSettingBody'],
                  onTap: () => context.push('/accounts'),
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.ios_share_rounded,
                  tint: c.violet600,
                  title: s['featureExportTitle'],
                  // The weekly reminder has to be visible without opening S-23,
                  // or it is not a reminder — just a switch in a room nobody
                  // walks into.
                  subtitle:
                      (ref.watch(autoBackupProvider).valueOrNull ?? false) &&
                          backupDue(
                            lastBackupAt: ref
                                .watch(lastBackupAtProvider)
                                .valueOrNull,
                            now: ref.watch(nowProvider),
                          )
                      ? s['exportDue']
                      : s['exportSettingBody'],
                  onTap: () => context.push('/export'),
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.autorenew_rounded,
                  tint: c.violet600,
                  title: s['recurringTitle'],
                  subtitle: s['recurringSettingBody'],
                  onTap: () => context.push('/recurring'),
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.restore_rounded,
                  tint: c.textSecondary,
                  title: s['restorePurchases'],
                  subtitle: s['subscriptionFootNote'],
                  onTap: () async {
                    // Mandatory in Settings as well as on the paywall
                    // (`docs/08 §6`): somebody who reinstalled has to be able
                    // to get their Pro back without finding the paywall.
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(proControllerProvider).restore();
                    if (!context.mounted) return;
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
                  },
                ),
                // ---- ads (T-610) ------------------------------------------
                // Only for a free user: a Pro user sees no ads, so a control
                // about what ads know is noise on their screen (`docs/07 §6`).
                if (!isPro) ...[
                  Divider(color: c.divider, height: 1),
                  SettingTile(
                    icon: Icons.tune_rounded,
                    tint: c.textSecondary,
                    title: s['personalizedAds'],
                    subtitle: s['personalizedAdsBody'],
                    trailing: Switch(
                      value: personalized,
                      onChanged: (on) => ref
                          .read(consentControllerProvider)
                          .setPersonalized(on),
                    ),
                    onTap: () => ref
                        .read(consentControllerProvider)
                        .setPersonalized(!personalized),
                  ),
                ],
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.lock_outline_rounded,
                  tint: c.violet600,
                  title: s['privacy'],
                  subtitle: s['privacyBody'],
                  // S-21 is the full notice and the DPDP page; the sheet stays
                  // as the two-line summary the paywall needs inline.
                  onTap: () => context.push('/about'),
                ),
              ],
            ),
          ),

          // The door Google's consent rules require when they require it: shown
          // for everybody, Pro included, because consent can be withdrawn
          // whatever plan you are on.
          if (privacyOptionsRequired) ...[
            const SizedBox(height: SsSpace.x5),
            SsCard(
              padding: const EdgeInsets.symmetric(
                horizontal: SsSpace.x2,
                vertical: SsSpace.x1,
              ),
              child: SettingTile(
                icon: Icons.privacy_tip_outlined,
                tint: c.teal500,
                title: s['privacyOptions'],
                subtitle: s['privacyOptionsBody'],
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final shown = await ref
                      .read(consentControllerProvider)
                      .showPrivacyOptions();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        shown
                            ? s['privacyOptionsShown']
                            : s['privacyOptionsMissing'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: SsSpace.x5),
          SsCard(
            padding: const EdgeInsets.symmetric(
              horizontal: SsSpace.x2,
              vertical: SsSpace.x1,
            ),
            child: SettingTile(
              icon: Icons.delete_outline_rounded,
              title: s['deleteAllData'],
              subtitle: s['deleteAllDataSubtitle'],
              danger: true,
              onTap: () => _confirmErase(context, ref),
            ),
          ),

          const SizedBox(height: SsSpace.x6),
          Center(
            child: InkWell(
              borderRadius: SsRadius.rMd,
              onTap: () => context.push('/about'),
              child: Padding(
                padding: const EdgeInsets.all(SsSpace.x2),
                child: Column(
                  children: [
                    Text(
                      localizeDigits(
                        '${s.appName} · ${s['version']} ${AppInfo.version}',
                        locale,
                      ),
                      style: SsText.micro.copyWith(color: c.textTertiary),
                    ),
                    const SizedBox(height: SsSpace.x1),
                    Text(
                      s['aboutBody'],
                      style: SsText.micro.copyWith(color: c.textTertiary),
                    ),
                    const SizedBox(height: SsSpace.x1),
                    Text(
                      s['about'],
                      style: SsText.micro.copyWith(color: c.violet600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: SsSpace.x4),
        ],
      ),
    );
  }

  Future<void> _confirmErase(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDbProvider);
    final s = ref.read(stringsProvider);
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s['eraseTitle']),
        content: Text(s['eraseBody']),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s['keep']),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s['erase']),
          ),
        ],
      ),
    );

    if (first != true || !context.mounted) return;

    // A second confirm, because this is the one irreversible action in the app.
    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s['confirm']),
        content: Text(s['lastChance']),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s['no']),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s['yesErase']),
          ),
        ],
      ),
    );

    if (second != true) return;

    if (db == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s['demoEraseUnavailable'])));
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
