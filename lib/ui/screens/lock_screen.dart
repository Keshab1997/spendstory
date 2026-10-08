/// S-20's app lock screen — the one screen the guard can send a user to.
///
/// It is a screen rather than a dialog on purpose: a dialog can be dismissed by
/// the system back gesture, and a lock that a back gesture removes is a screen
/// lock, not an app lock. Here, back exits the app — which is exactly what a
/// user who does not want to unlock should get.
///
/// It asks the moment it appears. Nothing behind it is built: the router
/// redirects *before* a protected route resolves, so the ledger is never
/// rendered under a translucent scrim.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/lock.dart';
import '../../app/providers.dart';
import '../../platform/app_lock.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, this.returnTo = '/home'});

  /// Where to go once the user is in: the location the guard intercepted, so a
  /// deep link (or a lock that fired while the user was on Insights) resumes
  /// instead of dumping them on Home.
  final String returnTo;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _busy = false;

  /// Set when the phone has nothing to ask with. Then — and only then — the
  /// screen offers the way out described on [LockActions.disableFromLockScreen].
  bool _cannotCheck = false;

  @override
  void initState() {
    super.initState();
    // Ask as soon as the screen is up. `addPostFrameCallback` rather than a
    // call in `initState` because the prompt is a platform call and the first
    // frame should already be on screen behind it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || !mounted) return;
    final s = ref.read(stringsProvider);

    setState(() => _busy = true);
    final outcome = await ref
        .read(lockActionsProvider)
        .unlock(reason: s['appLockPromptReason']);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _cannotCheck = outcome == LockOutcome.unavailable;
    });

    if (outcome == LockOutcome.unlocked) context.go(widget.returnTo);
  }

  Future<void> _turnOff() async {
    await ref.read(lockActionsProvider).disableFromLockScreen();
    if (mounted) context.go(widget.returnTo);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);

    return SsScaffold(
      // No `PopScope` trickery and no dismiss button: back leaves the app.
      scrollable: false,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: c.violet100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_rounded, size: 38, color: c.violet600),
              ),
              const SizedBox(height: SsSpace.x5),
              Text(
                s['lockTitle'],
                textAlign: TextAlign.center,
                style: SsText.h2,
              ),
              const SizedBox(height: SsSpace.x2),
              Text(
                _cannotCheck ? s['lockUnavailableBody'] : s['lockBody'],
                textAlign: TextAlign.center,
                style: SsText.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: SsSpace.x6),
              SsActionButton(
                label: s['lockUnlock'],
                icon: Icons.fingerprint_rounded,
                loading: _busy,
                onPressed: _unlock,
              ),
              if (_cannotCheck) ...[
                const SizedBox(height: SsSpace.x3),
                // The honest way out. A phone with no fingerprint, face or PIN
                // cannot be asked, and an unopenable app is not a security
                // feature — it is a data-loss bug waiting for the uninstall.
                SsActionButton(
                  label: s['lockTurnOff'],
                  tone: SsButtonTone.ghost,
                  height: 44,
                  onPressed: _turnOff,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
