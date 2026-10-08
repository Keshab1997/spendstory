/// The recurring-rule editor (S-19, T-506).
///
/// One sheet for a new rule and for an existing one, so the two cannot drift
/// apart — the same reason the budget and category editors are single sheets.
///
/// The only field that needs explaining is the day of the month: a rule on the
/// 31st has to mean something in February, and the sheet says out loud what it
/// will do instead of surprising the user once a year.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/recurring_math.dart';
import '../../domain/view_models.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../tokens.dart';

Future<bool> showRecurringEditor(
  BuildContext context, {
  RecurringRuleView? existing,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: RecurringEditorSheet(existing: existing),
    ),
  );
  return result ?? false;
}

class RecurringEditorSheet extends ConsumerStatefulWidget {
  const RecurringEditorSheet({super.key, this.existing});

  final RecurringRuleView? existing;

  @override
  ConsumerState<RecurringEditorSheet> createState() =>
      _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends ConsumerState<RecurringEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late TxnDirection _direction;
  late String? _categoryId;
  late String? _accountId;
  late RecurringFrequency _frequency;
  late int _interval;
  late DateTime _firstDue;
  late bool _autoPost;

  /// `kNoReminder`, or days before the due date (0 = that day).
  late int _remind;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = ref.read(nowProvider);

    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(
      text: e == null ? '' : (e.amountPaise ~/ 100).toString(),
    );
    _direction = e?.direction ?? TxnDirection.expense;
    _categoryId = e?.categoryId;
    _accountId = e?.accountId;
    _frequency = e?.frequencyEnum ?? RecurringFrequency.monthly;
    _interval = e?.interval ?? 1;
    _autoPost = e?.autoPost ?? false;
    _remind = e?.remindDaysBefore ?? 1;
    _firstDue = e == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime.fromMillisecondsSinceEpoch(dayStartMs(e.nextDueAt));
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  bool get _needsDay =>
      _frequency == RecurringFrequency.monthly ||
      _frequency == RecurringFrequency.yearly;

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final existing = widget.existing;

    final title = _title.text.trim();
    if (title.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(s['recurringNameRequired'])),
      );
      return;
    }
    final rupees = int.tryParse(_amount.text.trim()) ?? 0;
    if (rupees <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(s['recurringAmountRequired'])),
      );
      return;
    }

    // The picked date *is* the next due date: it is the first occurrence of
    // this schedule, and everything after it is arithmetic.
    final anchor = DateTime(
      _firstDue.year,
      _firstDue.month,
      _firstDue.day,
      9,
    ).millisecondsSinceEpoch;

    await ref
        .read(recurringActionsProvider)
        .save(
          RecurringRuleView(
            id:
                existing?.id ??
                'recurring-${DateTime.now().microsecondsSinceEpoch}',
            title: title,
            amountPaise: rupees * 100,
            direction: _direction,
            categoryId: _categoryId,
            accountId: _accountId,
            frequency: recurringFrequencyWire(_frequency),
            interval: _interval,
            dayOfMonth: _needsDay ? _firstDue.day : null,
            nextDueAt: anchor,
            autoPost: _autoPost,
            remindDaysBefore: _remind,
          ),
        );

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
        title: Text(s['recurringDeleteTitle']),
        content: Text(s['recurringDeleteBody']),
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
    await ref.read(recurringActionsProvider).delete(existing.id);
    navigator.pop(true);
  }

  /// The same one honest moment as the budget alerts: the user has just asked
  /// for a reminder, so that is when Android is asked whether it may deliver
  /// one. The switch stays as they set it either way.
  void _askForNotifications() {
    unawaited(ref.read(permissionsProvider).requestNotifications());
  }

  Future<void> _pickFirstDue() async {
    final now = ref.read(nowProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstDue,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() => _firstDue = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <CategoryView>[];
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <AccountView>[];
    final showing = [
      for (final cat in categories)
        if (cat.kind == _direction) cat,
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SsSpace.x5,
          0,
          SsSpace.x5,
          SsSpace.x5,
        ),
        children: [
          Text(
            widget.existing == null ? s['recurringAdd'] : s['recurringTitle'],
            style: SsText.h2,
          ),
          const SizedBox(height: SsSpace.x4),

          _LabelledField(
            label: s['recurringNameLabel'],
            hint: s['recurringNameHint'],
            controller: _title,
          ),
          const SizedBox(height: SsSpace.x4),

          _LabelledField(
            label: s['recurringAmountLabel'],
            controller: _amount,
            keyboardType: TextInputType.number,
            prefix: '₹',
          ),
          const SizedBox(height: SsSpace.x4),

          // ---- which way the money goes -----------------------------------
          SsSegmented<TxnDirection>(
            values: const [TxnDirection.expense, TxnDirection.income],
            labels: [s['expense'], s['income']],
            selected: _direction,
            onChanged: (v) => setState(() {
              _direction = v;
              // A category only ever belongs to one direction.
              _categoryId = null;
            }),
          ),
          const SizedBox(height: SsSpace.x4),

          if (showing.isNotEmpty) ...[
            Text(
              s['recurringCategoryLabel'],
              style: SsText.caption.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: SsSpace.x2),
            Wrap(
              spacing: SsSpace.x2,
              runSpacing: SsSpace.x2,
              children: [
                for (final cat in showing)
                  CategoryChip(
                    label: cat.label(locale),
                    icon: cat.icon,
                    color: cat.color,
                    selected: _categoryId == cat.id,
                    onTap: () => setState(
                      () => _categoryId = _categoryId == cat.id ? null : cat.id,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SsSpace.x4),
          ],

          if (accounts.isNotEmpty) ...[
            Text(
              s['recurringAccountLabel'],
              style: SsText.caption.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: SsSpace.x2),
            Wrap(
              spacing: SsSpace.x2,
              runSpacing: SsSpace.x2,
              children: [
                CategoryChip(
                  label: s['recurringAccountNone'],
                  selected: _accountId == null,
                  onTap: () => setState(() => _accountId = null),
                ),
                for (final account in accounts)
                  CategoryChip(
                    label: account.name,
                    selected: _accountId == account.id,
                    onTap: () => setState(
                      () => _accountId = _accountId == account.id
                          ? null
                          : account.id,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SsSpace.x4),
          ],

          // ---- the schedule -------------------------------------------------
          Text(
            s['recurringFrequencyLabel'],
            style: SsText.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x2),
          SsSegmented<RecurringFrequency>(
            values: RecurringFrequency.values,
            labels: [
              s['freqDaily'],
              s['freqWeekly'],
              s['freqMonthly'],
              s['freqYearly'],
            ],
            selected: _frequency,
            onChanged: (v) => setState(() => _frequency = v),
          ),
          const SizedBox(height: SsSpace.x3),

          _Stepper(
            label: s['recurringIntervalLabel'],
            value: s.digits('$_interval'),
            onMinus: _interval > 1
                ? () => setState(() => _interval -= 1)
                : null,
            onPlus: _interval < 12
                ? () => setState(() => _interval += 1)
                : null,
          ),

          const SizedBox(height: SsSpace.x4),
          _DateRow(
            label: s['recurringFirstDue'],
            value: s.shortDate(_firstDue.millisecondsSinceEpoch),
            onTap: _pickFirstDue,
          ),
          if (_needsDay) ...[
            const SizedBox(height: SsSpace.x2),
            Text(
              s['recurringDayNote'],
              style: SsText.micro.copyWith(color: c.textTertiary),
            ),
          ],

          const SizedBox(height: SsSpace.x4),
          SwitchListTile(
            value: _autoPost,
            onChanged: (v) => setState(() => _autoPost = v),
            title: Text(s['recurringAutoPost'], style: SsText.body),
            subtitle: Text(
              s['recurringAutoPostNote'],
              style: SsText.caption.copyWith(color: c.textSecondary),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),

          const SizedBox(height: SsSpace.x3),
          Text(
            s['recurringRemindLabel'],
            style: SsText.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: SsSpace.x2),
          SsSegmented<int>(
            values: const [kNoReminder, 0, 1, 3],
            labels: [
              s['recurringRemindNone'],
              s['recurringRemindSameDay'],
              s['recurringRemindOneDay'],
              s['recurringRemindThreeDays'],
            ],
            selected: _remind,
            onChanged: (v) => setState(() {
              _remind = v;
              if (v != kNoReminder) _askForNotifications();
            }),
          ),

          const SizedBox(height: SsSpace.x5),
          SsActionButton(label: s['recurringSave'], onPressed: _save),
          if (widget.existing != null) ...[
            const SizedBox(height: SsSpace.x2),
            SsActionButton(
              label: s['recurringDelete'],
              tone: SsButtonTone.danger,
              icon: Icons.delete_outline_rounded,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.prefix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SsText.caption.copyWith(color: c.textSecondary)),
        const SizedBox(height: SsSpace.x1),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: SsText.body,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    this.onMinus,
    this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Row(
      children: [
        Expanded(child: Text(label, style: SsText.body)),
        SsIconButton(
          icon: Icons.remove_rounded,
          onPressed: onMinus,
          tooltip: label,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SsSpace.x3),
          child: Text(value, style: SsText.bodyStrong),
        ),
        SsIconButton(
          icon: Icons.add_rounded,
          onPressed: onPlus,
          tooltip: label,
        ),
        const SizedBox(width: SsSpace.x2),
        Text('×', style: SsText.caption.copyWith(color: c.textTertiary)),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: SsRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SsSpace.x2),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 20, color: c.violet600),
            const SizedBox(width: SsSpace.x3),
            Expanded(child: Text(label, style: SsText.body)),
            Text(value, style: SsText.bodyStrong),
          ],
        ),
      ),
    );
  }
}
