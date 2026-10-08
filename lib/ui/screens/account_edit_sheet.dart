/// The account editor (S-16).
///
/// Opening balance is the one number the user owns here: everything else on the
/// Accounts screen is computed from the ledger. The sheet says so, because
/// "balance" and "opening balance" being different things is exactly the sort
/// of detail an app usually leaves the user to discover at the wrong moment.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/view_models.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../tokens.dart';
import 'accounts_screen.dart';

const _uuid = Uuid();

/// The palette offered for an account — the same ramp the category editor uses,
/// so two user-chosen colours never clash across screens.
const List<String> kAccountPalette = <String>[
  '#6C4CF1',
  '#14C8B8',
  '#F5B843',
  '#FF7A59',
  '#E5484D',
  '#3E63DD',
  '#30A46C',
  '#9C6ADE',
];

Future<bool> showAccountEditor(
  BuildContext context, {
  AccountView? existing,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.86,
      child: AccountEditorSheet(existing: existing),
    ),
  );
  return result ?? false;
}

class AccountEditorSheet extends ConsumerStatefulWidget {
  const AccountEditorSheet({super.key, this.existing});

  final AccountView? existing;

  @override
  ConsumerState<AccountEditorSheet> createState() => _AccountEditorSheetState();
}

class _AccountEditorSheetState extends ConsumerState<AccountEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _opening;
  late final TextEditingController _last4;
  late String _type;
  late String? _colorHex;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _opening = TextEditingController(
      text: e == null ? '' : (e.openingBalancePaise ~/ 100).toString(),
    );
    _last4 = TextEditingController(text: e?.last4 ?? '');
    _type = e?.type ?? 'bank';
    _colorHex = e?.colorHex;
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    _last4.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final name = _name.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(s['accountNameRequired'])),
      );
      return;
    }

    // A negative opening balance is legitimate — a credit card usually starts
    // below zero, and refusing it would push the user to lie to the app.
    final rupees = int.tryParse(_opening.text.trim()) ?? 0;
    final last4 = _last4.text.trim();

    final existing = widget.existing;
    final account = AccountView(
      id: existing?.id ?? 'acc-${_uuid.v4()}',
      name: name,
      type: _type,
      openingBalancePaise: rupees * 100,
      last4: last4.isEmpty ? null : last4,
      colorHex: _colorHex,
    );

    await ref.read(accountActionsProvider).save(account);
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
        title: Text(s['accountDeleteTitle']),
        content: Text(s['accountDeleteBody']),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s['keep']),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.txDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountActionsProvider).delete(existing.id);
    navigator.pop(true);
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
              widget.existing == null ? s['accountAdd'] : s['accountEdit'],
              style: SsText.h2,
            ),
            const SizedBox(height: SsSpace.x3),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LabelledField(
                      label: s['accountName'],
                      controller: _name,
                    ),
                    const SizedBox(height: SsSpace.x4),

                    Text(
                      s['accountType'],
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: SsSpace.x2),
                    Wrap(
                      spacing: SsSpace.x2,
                      runSpacing: SsSpace.x2,
                      children: [
                        for (final type in kAccountTypes)
                          CategoryChip(
                            label: accountTypeLabel(s, type),
                            selected: _type == type,
                            color: accountTypeTint(type, c),
                            onTap: () {
                              setState(() {
                                _type = type;
                                // Picking the type drops any earlier colour
                                // choice, so the card's tint always agrees with
                                // the chip the user just tapped.
                                _colorHex = null;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: SsSpace.x4),

                    _LabelledField(
                      label: s['accountOpeningBalance'],
                      controller: _opening,
                      keyboardType: TextInputType.number,
                      prefix: '₹',
                      helper: s['accountBalanceNote'],
                    ),
                    const SizedBox(height: SsSpace.x4),

                    _LabelledField(
                      label: s['accountLast4'],
                      controller: _last4,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                    const SizedBox(height: SsSpace.x2),

                    Text(
                      s['accountColor'],
                      style: SsText.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: SsSpace.x2),
                    Wrap(
                      spacing: SsSpace.x2,
                      runSpacing: SsSpace.x2,
                      children: [
                        for (final hex in kAccountPalette)
                          GestureDetector(
                            onTap: () => setState(() => _colorHex = hex),
                            child: Container(
                              width: 34,
                              height: 34,
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
                    const SizedBox(height: SsSpace.x5),
                  ],
                ),
              ),
            ),
            SsActionButton(label: s['accountSave'], onPressed: _save),
            if (widget.existing != null) ...[
              const SizedBox(height: SsSpace.x2),
              SsActionButton(
                label: s['txDelete'],
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

class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.prefix,
    this.helper,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefix;
  final String? helper;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        helperText: helper,
        helperMaxLines: 2,
        counterText: '',
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
