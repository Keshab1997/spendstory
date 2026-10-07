/// S-13 Categories manager (T-405).
///
/// Two tabs, a 3-column grid and a `+`. The editor asks for the name in all
/// three languages because a category is the one piece of user-authored text
/// that shows up on every screen — half-translated, it is the thing that makes
/// the app feel half-translated.
///
/// Deleting hides rather than erases: transactions already filed under a
/// category keep their id and their history. Reassigning someone's past
/// spending behind their back to make a grid tidy is not a trade this app makes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

/// The palette the editor offers. The design system's accents plus enough
/// separation that two categories are never the same colour at a glance.
const List<String> kCategoryPalette = <String>[
  '#6C4CF1',
  '#8B6BFF',
  '#14C8B8',
  '#2FD4C4',
  '#F5B843',
  '#FF7A59',
  '#E5484D',
  '#3E63DD',
  '#30A46C',
  '#9C6ADE',
];

const List<String> kCategoryIcons = <String>[
  '🍜',
  '🛒',
  '🚕',
  '💡',
  '🏠',
  '💊',
  '📚',
  '👕',
  '🎬',
  '📱',
  '🏦',
  '🎁',
  '✈️',
  '⛽',
  '🐾',
  '🧾',
  '💰',
  '💼',
  '🧑‍💻',
  '📈',
];

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  TxnDirection _tab = TxnDirection.expense;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final all =
        ref.watch(categoriesProvider).valueOrNull ?? const <CategoryView>[];
    final shown = all.where((cat) => cat.kind == _tab).toList();

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: c.violet600,
        foregroundColor: Colors.white,
        tooltip: s.catNew,
        child: const Icon(Icons.add_rounded),
      ),
      body: SsScaffold(
        title: s.catManagerTitle,
        scrollable: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SsSpace.x3),
            SsSegmented<TxnDirection>(
              values: const [TxnDirection.expense, TxnDirection.income],
              labels: [s.expense, s.income],
              selected: _tab,
              onChanged: (d) => setState(() => _tab = d),
            ),
            const SizedBox(height: SsSpace.x4),
            Expanded(
              child: shown.isEmpty
                  ? SingleChildScrollView(
                      child: EmptyState(
                        title: s.catEmpty,
                        message: s.catEmptyBody,
                        asset: 'assets/3d/empty-budget.jpg',
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: SsSpace.x3,
                            crossAxisSpacing: SsSpace.x3,
                            childAspectRatio: 0.92,
                          ),
                      itemCount: shown.length,
                      itemBuilder: (context, index) => _CategoryCard(
                        category: shown[index],
                        locale: locale,
                        onTap: () => _openEditor(existing: shown[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor({CategoryView? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _CategoryEditor(existing: existing, kind: _tab),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.locale,
    required this.onTap,
  });

  final CategoryView category;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return SsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(SsSpace.x3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CategoryAvatar(icon: category.icon, color: category.color, size: 44),
          const SizedBox(height: SsSpace.x2),
          Flexible(
            child: Text(
              category.label(locale),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SsText.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (category.monthlyCapPaise != null) ...[
            const SizedBox(height: 2),
            Text(
              '₹${(category.monthlyCapPaise! / 100).round()}',
              style: SsText.micro.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Create or edit one category.
class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.existing, required this.kind});

  final CategoryView? existing;
  final TxnDirection kind;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _en;
  late final TextEditingController _hi;
  late final TextEditingController _bn;
  late final TextEditingController _cap;
  late String _icon;
  late String _colorHex;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _en = TextEditingController(text: e?.nameEn ?? '');
    _hi = TextEditingController(text: e?.nameHi ?? '');
    _bn = TextEditingController(text: e?.nameBn ?? '');
    _cap = TextEditingController(
      text: e?.monthlyCapPaise == null
          ? ''
          : (e!.monthlyCapPaise! ~/ 100).toString(),
    );
    _icon = e?.icon ?? kCategoryIcons.first;
    _colorHex = e?.colorHex ?? kCategoryPalette.first;
  }

  @override
  void dispose() {
    _en.dispose();
    _hi.dispose();
    _bn.dispose();
    _cap.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final en = _en.text.trim();
    final hi = _hi.text.trim();
    final bn = _bn.text.trim();
    if (en.isEmpty && hi.isEmpty && bn.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(s.catNameRequired)));
      return;
    }

    // One name is enough to save; the others fall back to it rather than
    // leaving a blank label on a screen in that language.
    final fallback = en.isNotEmpty ? en : (bn.isNotEmpty ? bn : hi);
    final rupees = int.tryParse(_cap.text.trim());

    final existing = widget.existing;
    await ref
        .read(categoryActionsProvider)
        .save(
          CategoryView(
            id: existing?.id ?? 'user-${DateTime.now().microsecondsSinceEpoch}',
            kind: existing?.kind ?? widget.kind,
            nameEn: en.isEmpty ? fallback : en,
            nameHi: hi.isEmpty ? fallback : hi,
            nameBn: bn.isEmpty ? fallback : bn,
            icon: _icon,
            colorHex: _colorHex,
            monthlyCapPaise: rupees == null || rupees <= 0
                ? null
                : rupees * 100,
          ),
        );
    navigator.pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final s = ref.read(stringsProvider);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.catDelete),
        content: Text(s.catDeleteWarn),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.txDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(categoryActionsProvider).delete(existing.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SsSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? s.catNew : s.catEditTitle,
              style: SsText.h2,
            ),
            const SizedBox(height: SsSpace.x3),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CategoryAvatar(
                          icon: _icon,
                          color: colorFromHex(_colorHex),
                          size: 56,
                        ),
                        const SizedBox(width: SsSpace.x3),
                        Expanded(
                          child: Text(
                            s.catIcon,
                            style: SsText.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SsSpace.x2),
                    Wrap(
                      spacing: SsSpace.x2,
                      runSpacing: SsSpace.x2,
                      children: [
                        for (final icon in kCategoryIcons)
                          GestureDetector(
                            onTap: () => setState(() => _icon = icon),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.surfaceTint,
                                borderRadius: SsRadius.rMd,
                                border: Border.all(
                                  color: icon == _icon ? c.violet600 : c.border,
                                  width: icon == _icon ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: SsSpace.x4),
                    Text(
                      s.catColor,
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: SsSpace.x2),
                    Wrap(
                      spacing: SsSpace.x2,
                      runSpacing: SsSpace.x2,
                      children: [
                        for (final hex in kCategoryPalette)
                          GestureDetector(
                            onTap: () => setState(() => _colorHex = hex),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorFromHex(hex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hex == _colorHex
                                      ? c.textPrimary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: SsSpace.x4),
                    _LabelledField(label: s.catNameBn, controller: _bn),
                    const SizedBox(height: SsSpace.x2),
                    _LabelledField(label: s.catNameHi, controller: _hi),
                    const SizedBox(height: SsSpace.x2),
                    _LabelledField(label: s.catNameEn, controller: _en),
                    const SizedBox(height: SsSpace.x2),
                    _LabelledField(
                      label: s.catMonthlyCap,
                      controller: _cap,
                      keyboardType: TextInputType.number,
                    ),
                    if (widget.existing != null) ...[
                      const SizedBox(height: SsSpace.x4),
                      SsActionButton(
                        label: s.catDelete,
                        icon: Icons.delete_outline_rounded,
                        tone: SsButtonTone.danger,
                        onPressed: _delete,
                      ),
                    ],
                    const SizedBox(height: SsSpace.x3),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: SsSpace.x3),
              child: SsActionButton(
                label: s.save,
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
