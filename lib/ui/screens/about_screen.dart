/// S-21 About & privacy (T-704) — `docs/03 §S-21`, `docs/07 §5`.
///
/// This screen is the app's DPDP notice, and it is the one screen a Play
/// reviewer will read line by line against the data-safety declaration. So every
/// obligation in `docs/07 §5` has a section here and nowhere else:
///
///   * **notice** — plain language, three languages, reachable before the first
///     permission ask (the onboarding privacy page links here);
///   * **purpose limitation + minimisation** — what we read, and why, one
///     permission at a time, including the ones we deliberately do *not* ask for;
///   * **storage limitation** — on this phone only, and how to delete all of it;
///   * **the rights triad** — see all of it (export), correct anything (edit),
///     erase everything (Settings), plus withdrawing a permission;
///   * **grievance contact** — a named address, with the source repository as
///     the fallback while the address is not live yet ([AppInfo]).
///
/// Two deliberate omissions. There is no ad slot anywhere on this screen
/// (`docs/03 §S-21`, and `test/ads/slot_screens_test.dart` keeps the list
/// honest), and there is no network call: the two contact values are copied to
/// the clipboard rather than opened in a browser, because "we never phone home"
/// is the claim being made, and opening a link is not something a user should
/// have to trust us about while reading it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_info.dart';
import '../../app/providers.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);

    return SsScaffold(
      title: s['aboutScreenTitle'],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: SsSpace.x2),

          // ---- who this is ------------------------------------------------
          SsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(s.appName, style: SsText.h2)),
                    SsBadge(
                      label: s['privacyOnDevice'],
                      color: c.teal500,
                      icon: Icons.shield_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: SsSpace.x2),
                Text(
                  s['appTagline'],
                  style: SsText.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: SsSpace.x1),
                Text(
                  s.digits('${s['version']} ${AppInfo.version}'),
                  style: SsText.micro.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),

          // ---- what we collect: nothing -----------------------------------
          SectionHeader(title: s['aboutCollectTitle']),
          SsCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.lock_outline_rounded, color: c.teal500, size: 22),
                const SizedBox(width: SsSpace.x3),
                Expanded(
                  child: Text(
                    s['aboutCollectBody'],
                    style: SsText.body.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // ---- what we read, and why --------------------------------------
          SectionHeader(title: s['aboutReadTitle']),
          _Paragraph(text: s['aboutReadBody']),
          const SizedBox(height: SsSpace.x3),
          _TileCard(
            tiles: <Widget>[
              SettingTile(
                icon: Icons.sms_outlined,
                tint: c.violet600,
                title: s['aboutPermSmsTitle'],
                subtitle: s['aboutPermSmsBody'],
              ),
              SettingTile(
                icon: Icons.notifications_active_outlined,
                tint: c.teal500,
                title: s['aboutPermNotifyTitle'],
                subtitle: s['aboutPermNotifyBody'],
              ),
              SettingTile(
                icon: Icons.notifications_none_rounded,
                tint: c.gold500,
                title: s['aboutPermAlertsTitle'],
                subtitle: s['aboutPermAlertsBody'],
              ),
              SettingTile(
                icon: Icons.fingerprint_rounded,
                tint: c.textSecondary,
                title: s['aboutPermLockTitle'],
                subtitle: s['aboutPermLockBody'],
              ),
              SettingTile(
                icon: Icons.public_rounded,
                tint: c.textSecondary,
                title: s['aboutPermInternetTitle'],
                subtitle: s['aboutPermInternetBody'],
              ),
            ],
            divider: c.divider,
          ),

          // ---- the rights triad -------------------------------------------
          SectionHeader(title: s['aboutRightsTitle']),
          _TileCard(
            tiles: <Widget>[
              SettingTile(
                icon: Icons.download_outlined,
                tint: c.teal500,
                title: s['aboutRightAccessTitle'],
                subtitle: s['aboutRightAccessBody'],
              ),
              SettingTile(
                icon: Icons.edit_outlined,
                tint: c.violet600,
                title: s['aboutRightCorrectTitle'],
                subtitle: s['aboutRightCorrectBody'],
              ),
              SettingTile(
                icon: Icons.delete_outline_rounded,
                tint: c.danger,
                title: s['aboutRightEraseTitle'],
                subtitle: s['aboutRightEraseBody'],
              ),
              SettingTile(
                icon: Icons.lock_open_rounded,
                tint: c.gold500,
                title: s['aboutRightWithdrawTitle'],
                subtitle: s['aboutRightWithdrawBody'],
              ),
            ],
            divider: c.divider,
          ),

          // ---- the same thing as three steps -------------------------------
          SectionHeader(title: s['aboutEraseTitle']),
          SsCard(
            child: Column(
              children: <Widget>[
                _Step(
                  n: s.digits('1'),
                  text: s['aboutEraseStep1'],
                  color: c.violet600,
                ),
                const SizedBox(height: SsSpace.x3),
                _Step(
                  n: s.digits('2'),
                  text: s['aboutEraseStep2'],
                  color: c.violet600,
                ),
                const SizedBox(height: SsSpace.x3),
                _Step(
                  n: s.digits('3'),
                  text: s['aboutEraseStep3'],
                  color: c.violet600,
                ),
              ],
            ),
          ),

          // ---- how to reach a human ----------------------------------------
          SectionHeader(title: s['aboutContactTitle']),
          _Paragraph(text: s['aboutContactBody']),
          const SizedBox(height: SsSpace.x2),
          // Said once, above both copyable rows. As a per-tile trailing label
          // it overflowed at 1.3x in Hindi - "कॉपी करने के लिए टैप करें" is far
          // longer than "Tap to copy", and a trailing widget cannot shrink.
          Text(
            s['aboutTapToCopy'],
            style: SsText.micro.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: SsSpace.x3),
          _TileCard(
            tiles: <Widget>[
              if (AppInfo.hasGrievanceEmail)
                SettingTile(
                  icon: Icons.mail_outline_rounded,
                  tint: c.violet600,
                  title: s['aboutGrievanceEmail'],
                  subtitle: AppInfo.grievanceEmail,
                  trailing: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: c.textTertiary,
                  ),
                  onTap: () => _copy(context, ref, AppInfo.grievanceEmail),
                )
              else
                SettingTile(
                  icon: Icons.mail_outline_rounded,
                  tint: c.textSecondary,
                  title: s['aboutGrievanceEmail'],
                  subtitle: s['aboutEmailMissing'],
                ),
              SettingTile(
                icon: Icons.code_rounded,
                tint: c.teal500,
                title: s['aboutSourceTitle'],
                subtitle: '${s['aboutSourceBody']}\n${AppInfo.sourceRepo}',
                trailing: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: c.textTertiary,
                ),
                onTap: () => _copy(context, ref, AppInfo.sourceRepo),
              ),
            ],
            divider: c.divider,
          ),

          const SizedBox(height: SsSpace.x8),
        ],
      ),
    );
  }

  /// Copies [value] and says so. Used for the two contact rows: a link would
  /// need a browser, and this screen's whole point is that nothing is opened
  /// behind the user's back.
  Future<void> _copy(BuildContext context, WidgetRef ref, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = ref.read(stringsProvider);
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(s['aboutCopied'])));
  }
}

/// A tile stack in a card, the same shape Settings uses.
class _TileCard extends StatelessWidget {
  const _TileCard({required this.tiles, required this.divider});

  final List<Widget> tiles;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    return SsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SsSpace.x2,
        vertical: SsSpace.x1,
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < tiles.length; i++) ...<Widget>[
            if (i > 0) Divider(color: divider, height: 1),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

/// Body copy with breathing room, for the paragraph between two sections.
class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: SsSpace.x1),
      child: Text(text, style: SsText.body.copyWith(color: c.textSecondary)),
    );
  }
}

/// One numbered step, with the number in the locale's own digits.
class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text, required this.color});

  final String n;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text(
            n,
            style: SsText.micro.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: SsSpace.x3),
        Expanded(
          child: Text(
            text,
            style: SsText.body.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}
