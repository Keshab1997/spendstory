/// The two fine-print sheets: privacy and terms.
///
/// One definition each, because these are the texts a store reviewer reads and
/// the ones a user is entitled to find in the same words wherever the app links
/// to them. S-20 Settings opens them, and `docs/03 §S-22` makes both links
/// mandatory on the paywall — three call sites that must never drift.
///
/// S-21 (`lib/ui/screens/about_screen.dart`) is the full notice, and it is what
/// Settings' Privacy row opens. These sheets stay for the one place a modal
/// cannot push a screen: the paywall, where `docs/03 §S-22` makes the privacy
/// link mandatory. The summary is short on purpose, and it ends with the way to
/// the long version so nobody has to take the summary's word for it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../tokens.dart';
import 'controls.dart';
import 'lists.dart';

Future<void> showPrivacySheet(BuildContext context, WidgetRef ref) {
  final c = SsColors.of(context);
  final s = ref.read(stringsProvider);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SingleChildScrollView(
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
          Text(s.privacy, style: SsText.h2),
          const SizedBox(height: SsSpace.x3),
          Text(
            s['privacyDetails'],
            style: SsText.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x4),
          SsBadge(
            label: s['privacyOnDevice'],
            color: c.teal500,
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: SsSpace.x5),
          SsActionButton(
            label: s['privacyReadAll'],
            tone: SsButtonTone.secondary,
            icon: Icons.open_in_new_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/about');
            },
          ),
        ],
      ),
    ),
  );
}

/// The terms, in the same plain language. Short on purpose: the app sells one
/// thing, it says what it costs, and it says how to stop paying for it.
Future<void> showTermsSheet(BuildContext context, WidgetRef ref) {
  final c = SsColors.of(context);
  final s = ref.read(stringsProvider);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SingleChildScrollView(
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
          Text(s['terms'], style: SsText.h2),
          const SizedBox(height: SsSpace.x3),
          Text(
            s['termsBody'],
            style: SsText.body.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    ),
  );
}
