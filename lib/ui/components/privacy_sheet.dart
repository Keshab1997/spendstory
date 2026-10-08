/// The two fine-print sheets: privacy and terms.
///
/// One definition each, because these are the texts a store reviewer reads and
/// the ones a user is entitled to find in the same words wherever the app links
/// to them. S-20 Settings opens them, and `docs/03 §S-22` makes both links
/// mandatory on the paywall — three call sites that must never drift.
///
/// Until T-704 puts the full policy behind a real screen (S-21 About), these
/// sheets carry the summary that is already true of the app: reads only bank
/// SMS, nothing is uploaded, no account, erase everything from Settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../tokens.dart';
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
