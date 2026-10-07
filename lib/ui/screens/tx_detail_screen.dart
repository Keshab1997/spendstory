/// S-11 Transaction detail (T-403).
///
/// The screen that answers "where did this number come from?". For an app that
/// reads your bank SMS, that question is the whole trust relationship, so the
/// **source row and the raw-message viewer are the point of this screen**, not
/// a footnote: the user can open the exact text the entry was parsed from and
/// check it themselves. Nothing here is summarised or prettified — a wrong
/// parse should be visible, not hidden.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../components/category_sheet.dart';
import '../components/controls.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../format.dart';
import '../tokens.dart';
import 'tx_edit_sheet.dart';

/// `Iterable.firstWhere` throws when nothing matches and `orElse` cannot return
/// null for a non-nullable element type, so this says the quiet part out loud.
T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

class TxDetailScreen extends ConsumerWidget {
  const TxDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);

    final all =
        ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
    final txn = _firstWhereOrNull(all, (t) => t.id == id);
    final categoryById = ref.watch(categoryByIdProvider);
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <AccountView>[];

    if (txn == null) {
      // Deleted from under us, or a deep link to a row that never existed.
      // Say so plainly rather than rendering an empty skeleton.
      return SsScaffold(
        title: s.detailTitle,
        leading: _backButton(context),
        child: Padding(
          padding: const EdgeInsets.only(top: SsSpace.x8),
          child: Text(
            s.detailNotFound,
            style: SsText.body.copyWith(color: c.textSecondary),
          ),
        ),
      );
    }

    final category = categoryById[txn.categoryId];
    final account = _firstWhereOrNull(accounts, (a) => a.id == txn.accountId);
    final isIncome = txn.direction == TxnDirection.income;

    return SsScaffold(
      title: s.detailTitle,
      leading: _backButton(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x4),
          Center(
            child: Column(
              children: [
                _HeroIcon(
                  icon: category?.icon ?? (isIncome ? '💰' : '💳'),
                  color: category?.color ?? c.violet600,
                ),
                const SizedBox(height: SsSpace.x4),
                MoneyText(
                  txn.amountPaise,
                  tone: isIncome ? AmountTone.income : AmountTone.expense,
                  showSign: true,
                  style: SsText.displayMoney,
                ),
                const SizedBox(height: SsSpace.x1),
                Text(
                  txn.merchant?.trim().isNotEmpty == true
                      ? txn.merchant!.trim()
                      : (category?.label(locale) ?? s['unknownCategory']),
                  style: SsText.h2,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: SsSpace.x6),
          SsCard(
            child: Column(
              children: [
                _DetailRow(
                  label: s.detailDate,
                  value:
                      '${dayLabel(txn.occurredAtMs, locale: locale)}'
                      ' · ${timeOfDay(txn.occurredAtMs, locale: locale)}',
                ),
                _DetailRow(
                  label: s.detailCategory,
                  value: category?.label(locale) ?? s['unknownCategory'],
                  trailing: TextButton(
                    onPressed: () => _changeCategory(context, ref, txn),
                    child: Text(s.detailChange),
                  ),
                ),
                if (account != null)
                  _DetailRow(label: s.detailAccount, value: account.label),
                _DetailRow(
                  label: s.detailMode,
                  value: _modeLabel(ref, txn.mode),
                ),
                _DetailRow(
                  label: s.detailSource,
                  value: txn.sourceLabel(locale),
                  // The one row with a tick: it is the claim the user is being
                  // asked to trust, so it is marked as a claim.
                  valueIcon: txn.source == 'manual'
                      ? Icons.edit_outlined
                      : Icons.verified_outlined,
                ),
                if (txn.note?.trim().isNotEmpty == true)
                  _DetailRow(label: s.detailNote, value: txn.note!.trim()),
              ],
            ),
          ),
          const SizedBox(height: SsSpace.x4),
          _RawMessageViewer(txn: txn),
          const SizedBox(height: SsSpace.x6),
          Row(
            children: [
              Expanded(
                child: SsActionButton(
                  label: s.detailEdit,
                  icon: Icons.edit_outlined,
                  tone: SsButtonTone.secondary,
                  onPressed: () => TxEditSheet.show(context, existing: txn),
                ),
              ),
              const SizedBox(width: SsSpace.x3),
              Expanded(
                child: SsActionButton(
                  label: s.txDelete,
                  icon: Icons.delete_outline_rounded,
                  tone: SsButtonTone.danger,
                  onPressed: () => _confirmDelete(context, ref, txn),
                ),
              ),
            ],
          ),
          const SizedBox(height: SsSpace.x6),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () =>
        context.canPop() ? context.pop() : context.go('/transactions'),
  );

  String _modeLabel(WidgetRef ref, PaymentMode mode) {
    final s = ref.read(stringsProvider);
    return switch (mode) {
      PaymentMode.cash => s.modeCash,
      PaymentMode.upi => s.modeUpi,
      PaymentMode.card => s.modeCard,
      PaymentMode.netbanking => s.modeNetbanking,
      PaymentMode.wallet => s.modeWallet,
      PaymentMode.other => s.modeOther,
    };
  }

  Future<void> _changeCategory(
    BuildContext context,
    WidgetRef ref,
    TxnView txn,
  ) async {
    final locale = ref.read(localeProvider);
    final offered =
        (ref.read(categoriesProvider).valueOrNull ?? const <CategoryView>[])
            .where((cat) => cat.kind == txn.direction)
            .toList();
    if (offered.isEmpty) return;

    final chosen = await showCategorySheet(
      context,
      title: ref.read(stringsProvider).txPickCategory,
      categories: offered,
      locale: locale,
      selectedId: txn.categoryId,
    );
    if (chosen == null || chosen == txn.categoryId) return;
    await ref.read(txActionsProvider).setCategory(txn.id, chosen);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TxnView txn,
  ) async {
    final s = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.detailDeleteConfirmTitle),
        content: Text(s.detailDeleteConfirmBody),
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
    if (confirmed != true || !context.mounted) return;

    await ref.read(txActionsProvider).delete(txn.id);
    if (!context.mounted) return;
    context.canPop() ? context.pop() : context.go('/transactions');
  }
}

/// The big category mark at the top, with the soft glow from the design system.
class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon, required this.color});

  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 88,
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.tintOf(color),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(icon, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailing,
    this.valueIcon,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final IconData? valueIcon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SsSpace.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: SsText.caption.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(width: SsSpace.x2),
          Expanded(
            child: Row(
              children: [
                if (valueIcon != null) ...[
                  Icon(valueIcon, size: 15, color: c.teal500),
                  const SizedBox(width: SsSpace.x1 + 2),
                ],
                Flexible(child: Text(value, style: SsText.bodyStrong)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// The trust feature: the exact message the row was parsed from, collapsed by
/// default so it does not shout, and never summarised.
class _RawMessageViewer extends ConsumerStatefulWidget {
  const _RawMessageViewer({required this.txn});

  final TxnView txn;

  @override
  ConsumerState<_RawMessageViewer> createState() => _RawMessageViewerState();
}

class _RawMessageViewerState extends ConsumerState<_RawMessageViewer> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final raw = widget.txn.rawText?.trim();

    return SsCard(
      onTap: raw == null ? null : () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sms_outlined, size: 18, color: c.violet600),
              const SizedBox(width: SsSpace.x2),
              Expanded(child: Text(s.detailRawTitle, style: SsText.bodyStrong)),
              if (raw != null)
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
          if (raw == null) ...[
            const SizedBox(height: SsSpace.x2),
            Text(
              s.detailNoRaw,
              style: SsText.caption.copyWith(color: c.textSecondary),
            ),
          ] else
            // Built only when open, not merely hidden: a collapsed viewer that
            // still has the SMS in the widget tree is not collapsed, it is
            // invisible — and it would hand the message to the accessibility
            // tree and to a screenshot of the semantics layer.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: SsSpace.x3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(SsSpace.x3),
                            decoration: BoxDecoration(
                              color: c.surfaceTint,
                              borderRadius: SsRadius.rMd,
                              border: Border.all(color: c.border),
                            ),
                            // Monospace and unprettified on purpose: this is
                            // evidence, not copy.
                            child: SelectableText(
                              raw,
                              style: SsText.caption.copyWith(
                                fontFamily: 'monospace',
                                color: c.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: SsSpace.x2),
                          Text(
                            s.detailRawHint,
                            style: SsText.micro.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
