/// S-05 Language picker.
///
/// Three options, each written **in its own script** — a language chooser that
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
  String _selected = 'bn';

  static const List<
    ({String code, String native, String english, String sample})
  >
  _options = <({String code, String native, String english, String sample})>[
    (
      code: 'bn',
      native: 'বাংলা',
      english: 'Bengali',
      sample: 'এই মাসে খরচ ₹১২,৪০০',
    ),
    (
      code: 'hi',
      native: 'हिन्दी',
      english: 'Hindi',
      sample: 'इस महीने खर्च ₹12,400',
    ),
    (
      code: 'en',
      native: 'English',
      english: 'English',
      sample: 'Spent this month ₹12,400',
    ),
  ];

  Future<void> _continue() async {
    ref.read(localeProvider.notifier).state = _selected;

    final db = ref.read(appDbProvider);
    if (db != null) {
      await db.setMeta('locale', _selected);
      // Onboarding pages land in Batch 4 (T-302/303). Until then, choosing a
      // language is the whole first-run flow — and it is written to the database
      // exactly as it will be afterwards.
      await db.setMeta('onboarded', 'true');
      ref.invalidate(bootProvider);
    }

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings(_selected);

    return SsScaffold(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x10),
          Text(s['language'], style: SsText.h1),
          const SizedBox(height: SsSpace.x2),
          Text(
            'তিনটি ভাষায় চলে — যেকোনো সময় বদলাতে পারবেন।',
            style: SsText.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x8),
          for (final option in _options) ...[
            _LanguageCard(
              native: option.native,
              english: option.english,
              sample: option.sample,
              selected: _selected == option.code,
              onTap: () => setState(() => _selected = option.code),
            ),
            const SizedBox(height: SsSpace.x3),
          ],
          const Spacer(),
          SsActionButton(label: 'শুরু করুন', onPressed: _continue),
          const SizedBox(height: SsSpace.x5),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.native,
    required this.english,
    required this.sample,
    required this.selected,
    required this.onTap,
  });

  final String native;
  final String english;
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
