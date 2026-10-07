/// S-12 Add / Edit transaction (T-404).
///
/// The most-used action in the app, so it is built against a stopwatch rather
/// than a wireframe: the keypad is already open, the direction and category
/// carry sensible defaults, and **Save** is reachable without scrolling on a
/// 6" phone. Three taps — amount, category, save — is the target the spec sets,
/// and the widget test asserts it.
///
/// A custom keypad instead of the system one: the system keyboard on an amount
/// field gives you a locale-dependent decimal separator, a comma that may or
/// may not be there, and a layout that moves. Money is nine buttons; we own
/// them.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/money.dart';
import '../format.dart';
import '../strings.dart';
import '../tokens.dart';

class TxEditSheet extends ConsumerStatefulWidget {
  const TxEditSheet({super.key, this.existing, this.onDone});

  /// Null when adding; the row being changed when editing.
  final TxnView? existing;

  /// How to leave. A bottom sheet pops itself, which is the default; the
  /// full-page host at `/transactions/edit` has no sheet to pop and hands in a
  /// router pop instead. Without this the form finishes saving and then spins
  /// forever on a route it cannot close.
  final void Function(bool saved)? onDone;

  /// Opens the sheet at 88% height, as the spec draws it.
  static Future<bool?> show(BuildContext context, {TxnView? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.88,
        child: TxEditSheet(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<TxEditSheet> createState() => _TxEditSheetState();
}

class _TxEditSheetState extends ConsumerState<TxEditSheet> {
  /// The amount as the user typed it, in paise, built digit by digit. Holding
  /// an int rather than a parsed string means there is no decimal separator to
  /// get wrong in three languages.
  late int _paise;
  late TxnDirection _direction;
  late PaymentMode _mode;
  late DateTime _date;
  String? _categoryId;

  late final TextEditingController _merchant;
  late final TextEditingController _note;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _paise = e?.amountPaise ?? 0;
    _direction = e?.direction ?? TxnDirection.expense;
    _mode = e?.mode ?? PaymentMode.cash;
    _date = DateTime.fromMillisecondsSinceEpoch(
      e?.occurredAtMs ?? DateTime.now().millisecondsSinceEpoch,
    );
    _categoryId = e?.categoryId;
    _merchant = TextEditingController(text: e?.merchant ?? '');
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  void _tapDigit(int d) {
    // Cap at ₹99,99,999.99 — beyond that the display stops being readable and
    // the number is almost certainly a mis-tap.
    if (_paise > 99999999) return;
    setState(() => _paise = _paise * 10 + d);
  }

  void _backspace() => setState(() => _paise ~/= 10);

  void _clear() => setState(() => _paise = 0);

  void _leave(bool saved) {
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone(saved);
      return;
    }
    Navigator.of(context).pop(saved);
  }

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);

    if (_paise <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(s.amountRequired)));
      return;
    }

    setState(() => _saving = true);
    final actions = ref.read(txActionsProvider);
    final merchant = _merchant.text.trim();
    final note = _note.text.trim();

    final existing = widget.existing;
    if (existing == null) {
      await actions.add(
        amountPaise: _paise,
        direction: _direction,
        occurredAtMs: _date.millisecondsSinceEpoch,
        merchant: merchant.isEmpty ? null : merchant,
        categoryId: _categoryId,
        mode: _mode,
        note: note.isEmpty ? null : note,
      );
    } else {
      await actions.update(
        TxnView(
          id: existing.id,
          amountPaise: _paise,
          direction: _direction,
          occurredAtMs: _date.millisecondsSinceEpoch,
          merchant: merchant.isEmpty ? null : merchant,
          categoryId: _categoryId,
          mode: _mode,
          source: existing.source,
          note: note.isEmpty ? null : note,
          rawText: existing.rawText,
          accountId: existing.accountId,
        ),
      );
    }

    // Deliberately not awaited: a vibration is feedback, not a step. On a
    // device the future resolves in microseconds; in a widget test there is no
    // platform to answer it, and awaiting it leaves the sheet spinning forever.
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(s.saved),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    _leave(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final categories = ref
        .watch(categoriesProvider)
        .maybeWhen(
          data: (list) => list.where((cat) => cat.kind == _direction).toList(),
          orElse: () => const <CategoryView>[],
        );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SsSpace.x4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null ? s.addTitle : s.editTitle,
                    style: SsText.h2,
                  ),
                ),
                SsIconButton(
                  icon: Icons.close_rounded,
                  tooltip: s.cancel,
                  onPressed: () => _leave(false),
                ),
              ],
            ),
            const SizedBox(height: SsSpace.x3),

            // ---- amount ---------------------------------------------------
            Text(
              s.amountLabel,
              style: SsText.micro.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: SsSpace.x1),
            MoneyText(
              _paise,
              tone: _direction == TxnDirection.income
                  ? AmountTone.income
                  : AmountTone.expense,
              showPaise: true,
              style: SsText.displayMoney,
            ),
            const SizedBox(height: SsSpace.x3),

            SsSegmented<TxnDirection>(
              values: const [TxnDirection.expense, TxnDirection.income],
              labels: [s.expense, s.income],
              selected: _direction,
              onChanged: (d) => setState(() {
                _direction = d;
                // The old category belongs to the other direction now.
                _categoryId = null;
              }),
            ),
            const SizedBox(height: SsSpace.x3),

            // ---- everything that scrolls ----------------------------------
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          for (final cat in categories) ...[
                            CategoryChip(
                              label: cat.label(locale),
                              icon: cat.icon,
                              color: cat.color,
                              selected: cat.id == _categoryId,
                              onTap: () => setState(() => _categoryId = cat.id),
                            ),
                            const SizedBox(width: SsSpace.x2),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: SsSpace.x3),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.event_rounded,
                            label: _isToday(_date)
                                ? s.today
                                : shortDate(
                                    _date.millisecondsSinceEpoch,
                                    locale: locale,
                                  ),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: SsSpace.x2),
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.account_balance_wallet_outlined,
                            label: _modeLabel(s, _mode),
                            onTap: _pickMode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SsSpace.x3),
                    _Field(controller: _merchant, hint: s.merchantHint),
                    const SizedBox(height: SsSpace.x2),
                    _Field(controller: _note, hint: s.noteHint),
                    const SizedBox(height: SsSpace.x3),
                    _Keypad(
                      onDigit: _tapDigit,
                      onBackspace: _backspace,
                      onClear: _clear,
                    ),
                    const SizedBox(height: SsSpace.x3),
                  ],
                ),
              ),
            ),

            // ---- sticky save ----------------------------------------------
            Padding(
              padding: const EdgeInsets.only(bottom: SsSpace.x3),
              child: SsActionButton(
                label: s.save,
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _modeLabel(SsStrings s, PaymentMode mode) => switch (mode) {
    PaymentMode.cash => s.modeCash,
    PaymentMode.upi => s.modeUpi,
    PaymentMode.card => s.modeCard,
    PaymentMode.netbanking => s.modeNetbanking,
    PaymentMode.wallet => s.modeWallet,
    PaymentMode.other => s.modeOther,
  };

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 3),
      // No future transactions: you cannot have spent tomorrow's money.
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickMode() async {
    final s = ref.read(stringsProvider);
    final picked = await showModalBottomSheet<PaymentMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in PaymentMode.values)
              ListTile(
                title: Text(_modeLabel(s, mode)),
                trailing: mode == _mode
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(mode),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _mode = picked);
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(hintText: hint, isDense: true),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: SsRadius.rMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SsSpace.x3,
          vertical: SsSpace.x3,
        ),
        decoration: BoxDecoration(
          color: c.surfaceTint,
          borderRadius: SsRadius.rMd,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.textSecondary),
            const SizedBox(width: SsSpace.x2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SsText.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The money keypad: twelve large targets, no decimal key.
///
/// Digits are entered in paise and shifted up, the way a cash register works,
/// so "1 2 4 0 0 0" is ₹1,240.00 and there is never a half-typed decimal.
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    // A stable key per key, so a widget test can press "5" without depending
    // on where the grid happens to lay it out.
    Widget key(Widget child, VoidCallback onTap, {required String id}) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Semantics(
              button: true,
              label: id,
              child: InkWell(
                key: ValueKey<String>(id),
                onTap: onTap,
                borderRadius: SsRadius.rMd,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceTint,
                    borderRadius: SsRadius.rMd,
                    border: Border.all(color: c.border),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );

    Widget digit(int d) =>
        key(Text('$d', style: SsText.h2), () => onDigit(d), id: 'keypad-$d');

    return Column(
      children: [
        for (final row in const <List<int>>[
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Row(children: [for (final d in row) digit(d)]),
        Row(
          children: [
            key(
              Icon(Icons.backspace_outlined, size: 20, color: c.textSecondary),
              onBackspace,
              id: 'keypad-backspace',
            ),
            digit(0),
            key(
              Text('C', style: SsText.h2.copyWith(color: c.textSecondary)),
              onClear,
              id: 'keypad-clear',
            ),
          ],
        ),
      ],
    );
  }
}
