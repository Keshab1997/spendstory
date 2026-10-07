/// S-07 — notification access.
///
/// Android gives no dialog for this one: the user has to be sent to a system list
/// and toggle SpendStory on by hand. That is a worse experience than an SMS
/// prompt, so this screen does everything it can to compensate — it says exactly
/// which apps will be watched, it re-checks the moment the user comes back, and
/// it never pretends the permission is required.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../platform/native_bridge.dart';
import '../../platform/permissions.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

class PermissionNotificationScreen extends ConsumerStatefulWidget {
  const PermissionNotificationScreen({super.key});

  @override
  ConsumerState<PermissionNotificationScreen> createState() =>
      _PermissionNotificationScreenState();
}

class _PermissionNotificationScreenState
    extends ConsumerState<PermissionNotificationScreen>
    with WidgetsBindingObserver {
  NotificationAccess _state = NotificationAccess.unknown;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system settings list is the whole moment this screen
    // exists for — re-check immediately rather than asking the user to tap again.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final result = await ref.read(permissionsProvider).current();
    if (!mounted) return;
    setState(() => _state = result.notifications);
  }

  Future<void> _openSettings() async {
    setState(() => _busy = true);
    final opened = await ref
        .read(permissionsProvider)
        .openNotificationSettings();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!opened) {
      // Web preview, desktop, or a host that cannot open the list: be honest and
      // tell the user how to do it by hand instead of leaving a dead button.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(stringsProvider)['notifManualHint'])),
      );
    }
  }

  Future<void> _finish() async {
    final db = ref.read(appDbProvider);
    await db?.setMeta('notifPermAsked', 'true');
    await db?.setMeta('onboarded', 'true');
    if (mounted) {
      ref.invalidate(bootProvider);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final granted = _state == NotificationAccess.granted;

    return SsScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x4),
          HeroIllustration(
            asset: 'assets/3d/permission-notification.jpg',
            height: 190,
            glowTint: c.teal500,
          ),
          const SizedBox(height: SsSpace.x5),
          Text(s['notifTitle'], style: SsText.h1),
          const SizedBox(height: SsSpace.x3),
          Text(
            s['notifWhy'],
            style: SsText.body.copyWith(color: c.textSecondary),
          ),

          const SizedBox(height: SsSpace.x5),
          SsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      granted
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: granted ? c.teal500 : c.textTertiary,
                    ),
                    const SizedBox(width: SsSpace.x2),
                    Expanded(
                      child: Text(
                        granted ? s['notifOn'] : s['notifOff'],
                        style: SsText.bodyStrong.copyWith(
                          color: granted ? c.teal500 : c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SsSpace.x4),
                Text(
                  s['notifApps'],
                  style: SsText.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: SsSpace.x3),
                Wrap(
                  spacing: SsSpace.x2,
                  runSpacing: SsSpace.x2,
                  children: [
                    for (final pkg in kNotificationWhitelist)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SsSpace.x3,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.surfaceTint,
                          borderRadius: SsRadius.rPill,
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          kNotificationAppNames[pkg] ?? pkg,
                          style: SsText.caption.copyWith(color: c.textPrimary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: SsSpace.x4),
                Text(
                  s['notifOnlyThese'],
                  style: SsText.micro.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),

          const SizedBox(height: SsSpace.x6),
          if (granted)
            SsActionButton(
              label: s['notifContinue'],
              icon: Icons.check_rounded,
              onPressed: _finish,
            )
          else ...[
            SsActionButton(
              label: s['notifOpen'],
              icon: Icons.settings_outlined,
              loading: _busy,
              onPressed: _openSettings,
            ),
            const SizedBox(height: SsSpace.x3),
            SsActionButton(
              label: s['notifSkip'],
              tone: SsButtonTone.secondary,
              onPressed: _finish,
            ),
          ],
          const SizedBox(height: SsSpace.x6),
        ],
      ),
    );
  }
}
