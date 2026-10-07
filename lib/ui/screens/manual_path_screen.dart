/// S-08 — the manual-only path.
///
/// Reached from the SMS screen by anyone who does not want to hand over SMS
/// access, and it has to feel like a legitimate choice rather than a consolation
/// prize. It is: the ledger, budgets, categories, insights and export all work
/// with hand-entered transactions, and capture can be switched on later from
/// Settings without losing a thing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

class ManualPathScreen extends ConsumerStatefulWidget {
  const ManualPathScreen({super.key});

  @override
  ConsumerState<ManualPathScreen> createState() => _ManualPathScreenState();
}

class _ManualPathScreenState extends ConsumerState<ManualPathScreen> {
  bool _saving = false;

  Future<void> _finish() async {
    setState(() => _saving = true);
    final db = ref.read(appDbProvider);
    await db?.setMeta('onboarded', 'true');
    if (!mounted) return;
    ref.invalidate(bootProvider);
    context.go('/home');
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
            asset: 'assets/3d/empty-transactions.jpg',
            height: 176,
            glowTint: c.violet600,
          ),
          const SizedBox(height: SsSpace.x5),
          Text(s['manualTitle'], style: SsText.h1),
          const SizedBox(height: SsSpace.x3),
          Text(
            s['manualBody'],
            style: SsText.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x5),
          SsCard(
            padding: const EdgeInsets.symmetric(
              horizontal: SsSpace.x2,
              vertical: SsSpace.x1,
            ),
            child: Column(
              children: [
                SettingTile(
                  icon: Icons.edit_note_rounded,
                  title: s['manualP1'],
                  subtitle: s['manualP1Body'],
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.pie_chart_outline_rounded,
                  tint: c.teal500,
                  title: s['manualP2'],
                  subtitle: s['manualP2Body'],
                ),
                Divider(color: c.divider, height: 1),
                SettingTile(
                  icon: Icons.toggle_on_outlined,
                  tint: c.gold500,
                  title: s['manualP3'],
                  subtitle: s['manualP3Body'],
                ),
              ],
            ),
          ),
          const SizedBox(height: SsSpace.x6),
          SsActionButton(
            label: s['manualStart'],
            loading: _saving,
            onPressed: _finish,
          ),
          const SizedBox(height: SsSpace.x3),
          Center(
            child: TextButton(
              onPressed: () => context.go('/permission/sms'),
              child: Text(
                s['manualBack'],
                style: SsText.bodyStrong.copyWith(color: c.violet600),
              ),
            ),
          ),
          const SizedBox(height: SsSpace.x6),
        ],
      ),
    );
  }
}
