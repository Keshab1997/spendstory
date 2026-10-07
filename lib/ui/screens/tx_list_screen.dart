/// S-10 Transaction list.
///
/// Grouped by day with a running total per day, because that is the question a
/// user actually has when they open this screen ("what did I spend on Tuesday?"),
/// not "show me row 47".
///
/// The filter chips are real: they filter the same list the tests assert on.
/// So is the month strip — the screen never shows "all time" pretending to be a
/// month, and the two summary chips are computed from exactly the rows below
/// them, so the header can never disagree with the list.
///
/// Swipe is the fast path for the two corrections an auto-captured ledger
/// actually needs: *that was not a real transaction* (left → delete, undoable)
/// and *that went in the wrong category* (right → pick a new one). Editing the
/// amount or the note is a detail-screen job (S-11), not a swipe.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../components/category_sheet.dart';
import '../components/controls.dart';
import '../components/lists.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../format.dart';
import '../strings.dart';
import '../tokens.dart';
import 'tx_edit_sheet.dart';

enum _Filter { all, expense, income }

class TxListScreen extends ConsumerStatefulWidget {
  const TxListScreen({super.key});

  @override
  ConsumerState<TxListScreen> createState() => _TxListScreenState();
}

class _TxListScreenState extends ConsumerState<TxListScreen>
    with SingleTickerProviderStateMixin {
  _Filter _filter = _Filter.all;

  /// Rows the user has just dismissed, held locally for exactly as long as it
  /// takes the provider to catch up.
  ///
  /// `Dismissible` asserts that a dismissed row leaves the tree in the *same*
  /// frame, and both backends are asynchronous — the database write awaits, and
  /// the overlay goes through a `FutureProvider` rebuild. Without this set the
  /// row is still there for one frame and Flutter throws "a dismissed
  /// Dismissible widget is still part of the tree".
  final Set<String> _justDeleted = <String>{};

  /// Drives the list's stagger. One controller for the whole list, with an
  /// `Interval` per row, rather than a timer per row: no pending timers for a
  /// widget test to trip over, and it restarts when the month or filter
  /// changes — which is exactly when the list is new enough to deserve it.
  late final AnimationController _stagger = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  void _replay() => _stagger.forward(from: 0);

  void _setFilter(_Filter f) {
    if (_filter == f) return;
    setState(() => _filter = f);
    _replay();
  }

  void _shiftMonth(int delta) {
    final current = ref.read(selectedMonthProvider);
    final d = DateTime.fromMillisecondsSinceEpoch(current);
    final next = DateTime(d.year, d.month + delta).millisecondsSinceEpoch;
    if (next > startOfMonth(DateTime.now().millisecondsSinceEpoch)) return;
    ref.read(selectedMonthProvider.notifier).state = next;
    _replay();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final categoryById = ref.watch(categoryByIdProvider);
    final month = ref.watch(selectedMonthProvider);

    final all =
        ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];

    final inMonth = all
        .where(
          (t) =>
              !_justDeleted.contains(t.id) &&
              t.occurredAtMs >= month &&
              t.occurredAtMs <= endOfMonth(month),
        )
        .toList();

    final visible = switch (_filter) {
      _Filter.all => inMonth,
      _Filter.expense =>
        inMonth.where((t) => t.direction != TxnDirection.income).toList(),
      _Filter.income =>
        inMonth.where((t) => t.direction == TxnDirection.income).toList(),
    };

    // The chips describe the month, not the filter: hiding income should not
    // make the month's income disappear from the summary.
    final summary = LedgerSummary.from(inMonth);
    final groups = _groupByDay(visible, locale);
    final atCurrentMonth =
        month >= startOfMonth(DateTime.now().millisecondsSinceEpoch);

    return SsScaffold(
      floatingNav: true,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),
          Row(
            children: [
              Expanded(child: Text(s.txTitle, style: SsText.h1)),
              SsIconButton(
                icon: Icons.search_rounded,
                tooltip: s['search'],
                onPressed: () => context.push('/search'),
              ),
            ],
          ),
          const SizedBox(height: SsSpace.x3),
          _MonthStrip(
            label: monthLabel(month, locale: locale),
            onPrevious: () => _shiftMonth(-1),
            // No future months: the ledger cannot contain them, and an empty
            // screen the user cannot explain is worse than a disabled arrow.
            onNext: atCurrentMonth ? null : () => _shiftMonth(1),
          ),
          const SizedBox(height: SsSpace.x3),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: s.expense,
                  paise: summary.expensePaise,
                  tone: AmountTone.expense,
                  color: c.rose500,
                ),
              ),
              const SizedBox(width: SsSpace.x2),
              Expanded(
                child: _SummaryChip(
                  label: s.income,
                  paise: summary.incomePaise,
                  tone: AmountTone.income,
                  color: c.teal500,
                ),
              ),
            ],
          ),
          const SizedBox(height: SsSpace.x3),
          // Scrollable rather than a fixed Row: at a large text scale the three
          // Bengali labels together are wider than a 360dp phone, and more
          // filters are coming (date range, account).
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                CategoryChip(
                  label: s.txFilterAll,
                  selected: _filter == _Filter.all,
                  onTap: () => _setFilter(_Filter.all),
                ),
                const SizedBox(width: SsSpace.x2),
                CategoryChip(
                  label: s.expense,
                  selected: _filter == _Filter.expense,
                  color: c.rose500,
                  icon: '↗',
                  onTap: () => _setFilter(_Filter.expense),
                ),
                const SizedBox(width: SsSpace.x2),
                CategoryChip(
                  label: s.income,
                  selected: _filter == _Filter.income,
                  color: c.teal500,
                  icon: '↙',
                  onTap: () => _setFilter(_Filter.income),
                ),
              ],
            ),
          ),
          const SizedBox(height: SsSpace.x1),
          Expanded(
            child: groups.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      // Two different nothings: an empty app, and a month the
                      // user simply has no transactions in. Saying "add your
                      // first expense" to someone with 300 of them is a bug.
                      title: all.isEmpty ? s.emptyTxTitle : s.txMonthEmptyTitle,
                      message: all.isEmpty ? s.emptyTxBody : s.txMonthEmptyBody,
                      actionLabel: all.isEmpty ? s.addFirst : null,
                      onAction: all.isEmpty
                          ? () => TxEditSheet.show(context)
                          : null,
                    ),
                  )
                : _TxGroupList(
                    groups: groups,
                    locale: locale,
                    categoryById: categoryById,
                    stagger: _stagger,
                    onDelete: _deleteWithUndo,
                    onRecategorise: _pickCategory,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWithUndo(TxnView txn) async {
    final s = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _justDeleted.add(txn.id));
    await ref.read(txActionsProvider).delete(txn.id);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(s.txDeleted),
        behavior: SnackBarBehavior.floating,
        // Long enough to notice and act on; the row is only soft-deleted, so
        // nothing is actually gone when it expires either.
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: s.txUndo,
          onPressed: () async {
            await ref.read(txActionsProvider).restore(txn.id);
            if (mounted) setState(() => _justDeleted.remove(txn.id));
          },
        ),
      ),
    );
  }

  Future<void> _pickCategory(TxnView txn) async {
    final s = ref.read(stringsProvider);
    final locale = ref.read(localeProvider);
    final categories =
        ref.read(categoriesProvider).valueOrNull ?? const <CategoryView>[];

    // Offer only the categories that match the row's direction: "Salary" is
    // never the right answer for a debit.
    final offered = categories
        .where((cat) => cat.kind == txn.direction)
        .toList();
    if (offered.isEmpty) return;

    final chosen = await showCategorySheet(
      context,
      title: s.txPickCategory,
      categories: offered,
      locale: locale,
      selectedId: txn.categoryId,
    );

    if (chosen == null || chosen == txn.categoryId) return;
    await ref.read(txActionsProvider).setCategory(txn.id, chosen);
  }

  /// Newest day first; each group carries its own expense total.
  List<_DayGroup> _groupByDay(List<TxnView> txns, String locale) {
    final buckets = <int, List<TxnView>>{};
    for (final t in txns) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.occurredAtMs);
      final key = DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
      buckets.putIfAbsent(key, () => <TxnView>[]).add(t);
    }

    final keys = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final key in keys)
        _DayGroup(
          label: dayLabel(key, locale: locale),
          totalPaise: buckets[key]!
              .where((t) => t.direction != TxnDirection.income)
              .fold<int>(0, (sum, t) => sum + t.amountPaise),
          txns: buckets[key]!,
        ),
    ];
  }
}

class _DayGroup {
  const _DayGroup({
    required this.label,
    required this.totalPaise,
    required this.txns,
  });

  final String label;
  final int totalPaise;
  final List<TxnView> txns;
}

/// ‹ October 2026 ›
class _MonthStrip extends StatelessWidget {
  const _MonthStrip({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SsSpace.x1),
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: SsRadius.rPill,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: c.textSecondary,
            onPressed: onPrevious,
            tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SsText.bodyStrong,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: onNext == null ? c.border : c.textSecondary,
            onPressed: onNext,
            tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.paise,
    required this.tone,
    required this.color,
  });

  final String label;
  final int paise;
  final AmountTone tone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SsSpace.x3,
        vertical: SsSpace.x2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceTint,
        borderRadius: SsRadius.rLg,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: SsSpace.x1 + 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SsText.micro.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          MoneyText(paise, tone: tone),
        ],
      ),
    );
  }
}

/// The grouped, swipeable, staggered list.
class _TxGroupList extends StatelessWidget {
  const _TxGroupList({
    required this.groups,
    required this.locale,
    required this.categoryById,
    required this.stagger,
    required this.onDelete,
    required this.onRecategorise,
  });

  final List<_DayGroup> groups;
  final String locale;
  final Map<String, CategoryView> categoryById;
  final AnimationController stagger;
  final Future<void> Function(TxnView) onDelete;
  final Future<void> Function(TxnView) onRecategorise;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings(locale);

    return ListView.builder(
      // `ListView.builder` + a per-day card: only the visible days are built,
      // which is what keeps 1,000 rows at 60fps (S-10 acceptance).
      padding: const EdgeInsets.only(bottom: 110),
      physics: const BouncingScrollPhysics(),
      itemCount: groups.length + 1,
      itemBuilder: (context, index) {
        if (index == groups.length) {
          return Padding(
            padding: const EdgeInsets.only(top: SsSpace.x4),
            child: Text(
              s.txSwipeHint,
              textAlign: TextAlign.center,
              style: SsText.micro.copyWith(color: c.textSecondary),
            ),
          );
        }

        final group = groups[index];
        return _StaggerIn(
          controller: stagger,
          index: index,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DayHeader(label: group.label, totalPaise: group.totalPaise),
              SsCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: SsSpace.x3,
                  vertical: SsSpace.x1,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < group.txns.length; i++) ...[
                      if (i > 0) Divider(color: c.divider, height: 1),
                      _SwipeableTxRow(
                        txn: group.txns[i],
                        locale: locale,
                        category: categoryById[group.txns[i].categoryId],
                        onDelete: onDelete,
                        onRecategorise: onRecategorise,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One row with its two swipe actions.
class _SwipeableTxRow extends StatelessWidget {
  const _SwipeableTxRow({
    required this.txn,
    required this.locale,
    required this.category,
    required this.onDelete,
    required this.onRecategorise,
  });

  final TxnView txn;
  final String locale;
  final CategoryView? category;
  final Future<void> Function(TxnView) onDelete;
  final Future<void> Function(TxnView) onRecategorise;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = SsStrings(locale);

    return Dismissible(
      key: ValueKey<String>('tx-${txn.id}'),
      background: _SwipeAction(
        label: s.txRecategorise,
        icon: Icons.sell_rounded,
        color: c.violet600,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeAction(
        label: s.txDelete,
        icon: Icons.delete_outline_rounded,
        color: c.rose500,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Re-categorising keeps the row: it springs back and the sheet opens.
          await onRecategorise(txn);
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(txn),
      child: TxRow(
        txn: txn,
        locale: locale,
        category: category,
        showDate: false,
        onTap: () => context.push('/transactions/${txn.id}'),
      ),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.alignment,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: SsSpace.x3),
      decoration: BoxDecoration(
        color: c.tintOf(color),
        borderRadius: SsRadius.rMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: SsSpace.x2),
          Text(
            label,
            style: SsText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades and lifts a row in, offset by its index.
class _StaggerIn extends StatelessWidget {
  const _StaggerIn({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 30ms per row (S-10 motion spec), capped so row 40 is not still waiting.
    final start = (index * 0.07).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, built) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - animation.value)),
          child: built,
        ),
      ),
      child: child,
    );
  }
}
