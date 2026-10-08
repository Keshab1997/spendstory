/// The budget editor sheet (S-14, S-15).
///
/// One sheet for both screens, for the same reason the category editor is one
/// sheet: a budget edited from the list and a budget edited from its own detail
/// screen must not be able to drift apart. The only difference between the two
/// entry points is what the sheet opens *on* — a new cap, an existing one, or a
/// new one for a category the user tapped from somewhere else.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../format.dart';
import '../tokens.dart';

/// Opens the editor. Returns true when something was saved or deleted.
Future<bool> showBudgetEditor(
  BuildContext context, {
  BudgetView? existing,
  String? fixedCategoryId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.86,
      child: BudgetEditorSheet(
        existing: existing,
        fixedCategoryId: fixedCategoryId,
      ),
    ),
  );
  return result ?? false;
}

class BudgetEditorSheet extends ConsumerStatefulWidget {
  const BudgetEditorSheet({
    super.key,
    this.existing,
    this.fixedCategoryId,
  });

  final BudgetView? existing;

  /// Set when the sheet was opened from a category's row: the category is then
  /// a fact, not a choice, and the picker is not shown.
  final String? fixedCategoryId;

  @override
  ConsumerState<BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends ConsumerState<BudgetEditorSheet> {
  late final TextEditingController _amount;
  late String? _categoryId;
  late int _startDay;
  late bool _alert80;
  late bool _alert100;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = TextEditingController(
      text: e == null ? '' : (e.amountPaise ~/ 100).toString(),
    );
    _categoryId = e?.categoryId ?? widget.fixedCategoryId;
    _startDay = e?.startDay ?? 1;
    _alert80 = e?.alertAt80 ?? true;
    _alert100 = e?.alertAt100 ?? true;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final rupees = int.tryParse(_amount.text.trim()) ?? 0;
    if (rupees <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(s['budgetAmountRequired'])));
      return;
    }

    final existing = widget.existing;
    final budget = BudgetView(
      // A new budget gets an id that is stable and readable in the database —
      // budgets are few, and a uuid here would buy nothing.
      id:
          existing?.id ??
          'budget-${_categoryId ?? 'overall'}',
      categoryId: _categoryId,
      amountPaise: rupees * 100,
      period: existing?.period ?? 'monthly',
      startDay: _startDay,
      alertAt80: _alert80,
      alertAt100: _alert100,
    );

    await ref.read(budgetActionsProvider).save(budget);
    navigator.pop(true);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final s = ref.read(stringsProvider);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s['budgetDeleteTitle']),
        content: Text(s['budgetDeleteBody']),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s['keep']),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s['txDelete']),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(budgetActionsProvider).delete(existing.id);
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final all =
        ref.watch(categoriesProvider).valueOrNull ?? const <CategoryView>[];
    final expenseCategories =
        all.where((cat) => cat.kind == TxnDirection.expense).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SsSpace.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? s['budgetSetTitle'] : s['budgetEdit'],
              style: SsText.h2,
            ),
            const SizedBox(height: SsSpace.x3),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- which cap -------------------------------------------
                    if (widget.fixedCategoryId == null) ...[
                      Text(
                        s['budgetCategoryCap'],
                        style: SsText.caption.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: SsSpace.x2),
                      Wrap(
                        spacing: SsSpace.x2,
                        runSpacing: SsSpace.x2,
                        children: [
                          CategoryChip(
                            label: s['budgetOverallName'],
                            icon: 'Σ',
                            selected: _categoryId == null,
                            color: c.violet600,
                            onTap: () => setState(() => _categoryId = null),
                          ),
                          for (final cat in expenseCategories)
                            CategoryChip(
                              label: cat.label(locale),
                              icon: cat.icon,
                              selected: _categoryId == cat.id,
                              color: cat.color,
                              onTap: () =>
                                  setState(() => _categoryId = cat.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: SsSpace.x4),
                    ],

                    // ---- how much -------------------------------------------
                    _LabelledField(
                      label: s['budgetAmountLabel'],
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      prefix: '₹',
                    ),
                    const SizedBox(height: SsSpace.x4),

                    // ---- when the cycle starts ------------------------------
                    Text(
                      s['budgetStartDay'],
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: SsSpace.x2),
                    Row(
                      children: [
                        SsIconButton(
                          icon: Icons.remove_rounded,
                          tooltip: s['budgetStartDay'],
                          onPressed: _startDay > 1
                              ? () => setState(() => _startDay--)
                              : null,
                        ),
                        const SizedBox(width: SsSpace.x3),
                        Text(
                          localizeDigits('$_startDay', locale),
                          style: SsText.h3,
                        ),
                        const SizedBox(width: SsSpace.x3),
                        SsIconButton(
                          icon: Icons.add_rounded,
                          tooltip: s['budgetStartDay'],
                          onPressed: _startDay < 28
                              ? () => setState(() => _startDay++)
                              : null,
                        ),
                        const SizedBox(width: SsSpace.x3),
                        Expanded(
                          child: Text(
                            s['budgetStartDayBody'],
                            style: SsText.micro.copyWith(
                              color: c.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SsSpace.x4),

                    // ---- alerts ---------------------------------------------
                    Text(
                      s['budgetAlertsLabel'],
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                    _AlertSwitch(
                      label: s['budgetAlert80'],
                      value: _alert80,
                      onChanged: (v) => setState(() => _alert80 = v),
                    ),
                    _AlertSwitch(
                      label: s['budgetAlert100'],
                      value: _alert100,
                      onChanged: (v) => setState(() => _alert100 = v),
                    ),
                    const SizedBox(height: SsSpace.x5),
                  ],
                ),
              ),
            ),
            SsActionButton(
              label: s['budgetSave'],
              onPressed: _save,
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: SsSpace.x2),
              SsActionButton(
                label: s['budgetDelete'],
                tone: SsButtonTone.danger,
                icon: Icons.delete_outline_rounded,
                onPressed: _delete,
              ),
            ],
            const SizedBox(height: SsSpace.x3),
          ],
        ),
      ),
    );
  }
}

class _AlertSwitch extends StatelessWidget {
  const _AlertSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    title: Text(label, style: SsText.body),
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefix,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        filled: true,
        fillColor: c.surfaceTint,
        border: OutlineInputBorder(
          borderRadius: SsRadius.rMd,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SsRadius.rMd,
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }
}
