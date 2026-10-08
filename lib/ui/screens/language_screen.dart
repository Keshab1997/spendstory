/// S-05 Language picker.
///
/// Three options, each written in its own script — a language chooser that
/// asks a Bengali speaker to read the word "Bengali" is a small insult.
///
/// The switch is instant: `localeProvider` drives every string, so tapping a
/// card re-renders the whole app without a restart (`docs/02` §6).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../components/controls.dart';
import '../components/surfaces.dart';
import '../strings.dart';
import '../tokens.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String? _selected;

  static const List<({String code, String native, String sample})> _options =
      <({String code, String native, String sample})>[
        (code: 'bn', native: 'বাংলা', sample: 'এই মাসে খরচ ₹১২,৪০০'),
        (code: 'hi', native: 'हिन्दी', sample: 'इस महीने खर्च ₹12,400'),
        (code: 'en', native: 'English', sample: 'Spent this month ₹12,400'),
      ];

  Future<void> _continue(String selected) async {
    ref.read(localeProvider.notifier).state = selected;

    // The choice is stored immediately: if the user kills the app during
    // onboarding, they come back to a Bengali (or Hindi, or English) app rather
    // than to this screen. `onboarded` stays false until the flow actually ends,
    // which is what keeps the guard honest.
    await ref.read(appDbProvider)?.setMeta('locale', selected);

    if (mounted) context.go('/onboarding/1');
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final String selected = _selected ?? ref.watch(localeProvider);
    // The preview shows what the app will look like, digits included: with the
    // numerals switch on, the Bengali card reads `১২৪০` the way the ledger will.
    final s = SsStrings(selected, nativeDigits: ref.watch(numeralsProvider));

    // The button stays pinned to the bottom and the options scroll: this is the
    // first screen a user ever sees, and at 1.3× text scale the three cards plus
    // the heading are taller than a 640 px phone. A plain `Spacer` in a fixed
    // Column hides that by overflowing; scrolling the cards keeps the primary
    // action where the thumb expects it and clips nothing.
    return SsScaffold(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: SsSpace.x8),
                  Text(s['language'], style: SsText.h1),
                  const SizedBox(height: SsSpace.x2),
                  Text(
                    s['languagePrompt'],
                    style: SsText.body.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: SsSpace.x5),
                  for (final option in _options) ...[
                    _LanguageCard(
                      native: option.native,
                      sample: option.sample,
                      selected: selected == option.code,
                      onTap: () => setState(() => _selected = option.code),
                    ),
                    const SizedBox(height: SsSpace.x3),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: SsSpace.x3),
          SsActionButton(
            label: s['start'],
            onPressed: () => _continue(selected),
          ),
          const SizedBox(height: SsSpace.x5),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.native,
    required this.sample,
    required this.selected,
    required this.onTap,
  });

  final String native;
  final String sample;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return SsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(SsSpace.x4),
      color: selected ? c.violet100 : c.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(native, style: SsText.h3),
                const SizedBox(height: 2),
                Text(
                  sample,
                  style: SsText.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? c.violet600 : Colors.transparent,
              border: Border.all(
                color: selected ? c.violet600 : c.border,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}
