/// S-10 Transaction list.
///
/// Grouped by day with a running total per day, because that is the question a
/// user actually has when they open this screen ("what did I spend on Tuesday?"),
/// not "show me row 47".
///
/// The filter chips are real: they filter the same list the tests assert on.
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
import '../format.dart';
import '../tokens.dart';

enum _Filter { all, expense, income }

class TxListScreen extends ConsumerStatefulWidget {
  const TxListScreen({super.key});

  @override
  ConsumerState<TxListScreen> createState() => _TxListScreenState();
}

class _TxListScreenState extends ConsumerState<TxListScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final categoryById = ref.watch(categoryByIdProvider);

    final all =
        ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];
    final visible = switch (_filter) {
      _Filter.all => all,
      _Filter.expense =>
        all.where((t) => t.direction != TxnDirection.income).toList(),
      _Filter.income =>
        all.where((t) => t.direction == TxnDirection.income).toList(),
    };

    final groups = _groupByDay(visible, locale);

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
          const SizedBox(height: SsSpace.x4),
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
                  label: s.txTitle,
                  selected: _filter == _Filter.all,
                  onTap: () => setState(() => _filter = _Filter.all),
                ),
                const SizedBox(width: SsSpace.x2),
                CategoryChip(
                  label: s.expense,
                  selected: _filter == _Filter.expense,
                  color: c.rose500,
                  icon: '↗',
                  onTap: () => setState(() => _filter = _Filter.expense),
                ),
                const SizedBox(width: SsSpace.x2),
                CategoryChip(
                  label: s.income,
                  selected: _filter == _Filter.income,
                  color: c.teal500,
                  icon: '↙',
                  onTap: () => setState(() => _filter = _Filter.income),
                ),
              ],
            ),
          ),
          const SizedBox(height: SsSpace.x1),
          Expanded(
            child: groups.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      title: s.emptyTxTitle,
                      message: s.emptyTxBody,
                      actionLabel: s.addFirst,
                      onAction: () {},
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 110),
                    physics: const BouncingScrollPhysics(),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DayHeader(
                            label: group.label,
                            totalPaise: group.totalPaise,
                          ),
                          SsCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SsSpace.x3,
                              vertical: SsSpace.x1,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < group.txns.length; i++) ...[
                                  if (i > 0)
                                    Divider(color: c.divider, height: 1),
                                  TxRow(
                                    txn: group.txns[i],
                                    locale: locale,
                                    category:
                                        categoryById[group.txns[i].categoryId],
                                    showDate: false,
                                    onTap: () => context.push(
                                      '/transactions/${group.txns[i].id}',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
