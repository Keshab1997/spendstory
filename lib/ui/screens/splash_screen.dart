/// S-01 Splash.
///
/// Purely visual: the router holds every cold start here until [bootProvider]
/// resolves (open the database, seed it on first run, read the preferences) and
/// then sends the user to `/home` or `/language`. That is why this screen has no
/// buttons and no back arrow — see `docs/04-NAVIGATION.md` §2.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/surfaces.dart';
import '../tokens.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: SsColors.light.moneyGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              HeroIllustration(
                asset: 'assets/3d/splash-hero.jpg',
                height: 240,
                glowTint: Colors.white,
                semanticLabel: 'SpendStory',
                // The splash is already violet, so the artwork blends in
                // instead of sitting in a panel.
                clip: false,
              ),
              const Spacer(flex: 2),
              Text(
                'SpendStory',
                style: SsText.h1.copyWith(color: Colors.white, fontSize: 34),
              ),
              const SizedBox(height: SsSpace.x2),
              Text(
                'আপনার টাকার গল্প, নিজের ফোনেই',
                style: SsText.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(flex: 3),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: SsSpace.x6),
            ],
          ),
        ),
      ),
    );
  }
}
