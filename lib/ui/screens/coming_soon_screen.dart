/// An honest placeholder for a screen that has been specified and drawn but not
/// yet built.
///
/// Every route in `docs/04-NAVIGATION.md` resolves to something from day one,
/// so a deep link never crashes and a reviewer never mistakes a missing screen
/// for a broken build. Each one names the spec and the task that will fill it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../components/lists.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

class ComingSoonScreen extends ConsumerWidget {
  const ComingSoonScreen({
    super.key,
    required this.titleKey,
    required this.subtitleKey,
    required this.bodyKey,
  });

  final String titleKey;
  final String subtitleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final strings = ref.watch(stringsProvider);
    final canPop = context.canPop();

    return SsScaffold(
      title: strings[titleKey],
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x4),
          Text(
            strings[subtitleKey],
            style: SsText.micro.copyWith(
              color: c.violet600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: SsSpace.x2),
          Text(
            strings[bodyKey],
            style: SsText.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x6),
          const HeroIllustration(
            asset: 'assets/3d/empty-budget.jpg',
            height: 200,
          ),
          const SizedBox(height: SsSpace.x4),
          Center(
            child: SsBadge(
              label: strings['comingSoon'],
              color: c.violet600,
              icon: Icons.construction_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
