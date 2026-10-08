/// S-06 — the SMS permission explainer.
///
/// This is the highest-stakes screen in the product. Reading bank SMS is a
/// restricted Play permission whose approval depends on showing, in the app
/// itself, *why* it is needed and *what* is never touched
/// (`docs/07-PERMISSIONS-POLICY.md`). Reviewers read this screen; so does the
/// user, who is being asked to hand over something real.
///
/// So it does three things in this order: say what the app will read, say what it
/// will never read, and only then offer the button. And whatever the answer is —
/// allow, deny, or "later" — the next screen is the same, because the app works
/// without this.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../platform/permissions.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

class PermissionSmsScreen extends ConsumerStatefulWidget {
  const PermissionSmsScreen({super.key});

  @override
  ConsumerState<PermissionSmsScreen> createState() =>
      _PermissionSmsScreenState();
}

class _PermissionSmsScreenState extends ConsumerState<PermissionSmsScreen> {
  bool _asking = false;
  bool _denied = false;

  Future<void> _ask() async {
    setState(() => _asking = true);
    final result = await ref.read(permissionsProvider).requestSms();
    if (!mounted) return;

    if (result == SmsAccess.granted) {
      setState(() => _asking = false);
      await _rememberAsked();
      if (mounted) context.go('/permission/notification');
      return;
    }

    // `unknown` means the host could not be asked at all — the web preview, a
    // desktop build, or a device where the plugin is missing. That is a
    // different sentence from "the user said no", and saying the wrong one
    // would be a lie about what just happened.
    final couldNotAsk = result == SmsAccess.unknown;
    setState(() {
      _asking = false;
      // Only a real refusal flips the button to "Try again"; there is nothing
      // to try again on a platform with no prompt.
      _denied = !couldNotAsk;
    });

    // Neither outcome is a wall: the button stays, "Not now" is still there,
    // and the manual-only path is one tap below it.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(stringsProvider)[couldNotAsk ? 'permWebNote' : 'permDenied'],
        ),
      ),
    );
  }

  Future<void> _rememberAsked() async {
    final db = ref.read(appDbProvider);
    await db?.setMeta('smsPermAsked', 'true');
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);

    return SsScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x4),
          HeroIllustration(
            asset: 'assets/3d/permission-sms.jpg',
            height: 190,
            glowTint: c.violet600,
          ),
          const SizedBox(height: SsSpace.x5),
          Text(s['permTitle'], style: SsText.h1),
          const SizedBox(height: SsSpace.x3),
          Text(
            s['permWhy'],
            style: SsText.body.copyWith(color: c.textSecondary),
          ),

          const SizedBox(height: SsSpace.x5),
          SsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Point(
                  icon: Icons.check_circle_outline_rounded,
                  tint: c.teal500,
                  label: s['permReads'],
                  body: s['permReadsBody'],
                ),
                const SizedBox(height: SsSpace.x4),
                _Point(
                  icon: Icons.block_rounded,
                  tint: c.rose500,
                  label: s['permNever'],
                  body: s['permNeverBody'],
                ),
              ],
            ),
          ),

          const SizedBox(height: SsSpace.x6),
          SsActionButton(
            label: _denied ? s['permTryAgain'] : s['permAllow'],
            icon: Icons.sms_outlined,
            loading: _asking,
            onPressed: _ask,
          ),
          const SizedBox(height: SsSpace.x3),
          Center(
            child: TextButton(
              onPressed: () => context.go('/permission/notification'),
              child: Text(
                s['permNotNow'],
                style: SsText.bodyStrong.copyWith(color: c.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: SsSpace.x2),
          Center(
            child: TextButton(
              onPressed: () => context.go('/permission/manual'),
              child: Text(
                s['manualLink'],
                style: SsText.caption.copyWith(color: c.textTertiary),
              ),
            ),
          ),
          // The DPDP notice has to be one tap away at the moment the permission
          // is asked for, not only in Settings afterwards (docs/07 §5).
          Center(
            child: TextButton(
              onPressed: () => context.push('/about'),
              child: Text(
                s['privacyReadAll'],
                style: SsText.caption.copyWith(color: c.violet600),
              ),
            ),
          ),
          const SizedBox(height: SsSpace.x6),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.icon,
    required this.tint,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.tintOf(tint),
            borderRadius: SsRadius.rSm,
          ),
          child: Icon(icon, size: 18, color: tint),
        ),
        const SizedBox(width: SsSpace.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: SsText.bodyStrong),
              const SizedBox(height: 2),
              Text(
                body,
                style: SsText.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
