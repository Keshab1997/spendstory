/// S-18 Search & filter (T-406).
///
/// Searching a ledger is mostly searching for *an amount you half-remember* —
/// "that ₹1,240 thing" — so the query matches the merchant, the note **and**
/// the amount, and typing `1240` finds ₹1,240.00 without the user knowing the
/// app stores paise.
///
/// Everything is read-only here: one list, one set of filters, a visible result
/// count. No ads on this screen, per `docs/08`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../components/lists.dart';
import '../components/surfaces.dart';
import '../tokens.dart';

enum _SourceFilter { any, auto, manual }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  TxnDirection? _direction;
  _SourceFilter _source = _SourceFilter.any;
  final Set<String> _categoryIds = <String>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _direction != null ||
      _source != _SourceFilter.any ||
      _categoryIds.isNotEmpty;

  void _clearFilters() => setState(() {
    _direction = null;
    _source = _SourceFilter.any;
    _categoryIds.clear();
  });

  /// Digits only, so "1,240" and "1240" and "₹1240" are the same query.
  static String _digits(String input) =>
      input.replaceAll(RegExp(r'[^0-9]'), '');

  bool _matches(
    TxnView t,
    String raw,
    Map<String, CategoryView> byId,
    String locale,
  ) {
    if (_direction != null && t.direction != _direction) return false;

    final isAuto = t.source.startsWith('auto');
    if (_source == _SourceFilter.auto && !isAuto) return false;
    if (_source == _SourceFilter.manual && isAuto) return false;

    if (_categoryIds.isNotEmpty && !_categoryIds.contains(t.categoryId)) {
      return false;
    }

    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return true;

    if ((t.merchant ?? '').toLowerCase().contains(q)) return true;
    if ((t.note ?? '').toLowerCase().contains(q)) return true;
    if ((byId[t.categoryId]?.label(locale) ?? '').toLowerCase().contains(q)) {
      return true;
    }

    // Amount: compare whole rupees, so 1240 matches ₹1,240.00.
    final digits = _digits(q);
    if (digits.isNotEmpty) {
      final rupees = (t.amountPaise ~/ 100).toString();
      if (rupees.contains(digits)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final byId = ref.watch(categoryByIdProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <CategoryView>[];
    final all =
        ref.watch(transactionsProvider).valueOrNull ?? const <TxnView>[];

    final query = _query.text;
    final results = all.where((t) => _matches(t, query, byId, locale)).toList();
    final idle = query.trim().isEmpty && !_hasFilters;

    return SsScaffold(
      title: s.searchTitle,
      scrollable: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x3),
          TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: s.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(_query.clear),
                    ),
            ),
          ),
          const SizedBox(height: SsSpace.x3),

          // ---- filters -------------------------------------------------
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                CategoryChip(
                  label: s.expense,
                  icon: '↗',
                  color: c.rose500,
                  selected: _direction == TxnDirection.expense,
                  onTap: () => setState(
                    () => _direction = _direction == TxnDirection.expense
                        ? null
                        : TxnDirection.expense,
                  ),
                ),
                const SizedBox(width: SsSpace.x2),
                CategoryChip(
                  label: s.income,
                  icon: '↙',
                  color: c.teal500,
                  selected: _direction == TxnDirection.income,
                  onTap: () => setState(
                    () => _direction = _direction == TxnDirection.income
                        ? null
                        : TxnDirection.income,
                  ),
                ),
                const SizedBox(width: SsSpace.x2),
                CategoryChip(
                  label: s.filterSourceAuto,
                  selected: _source == _SourceFilter.auto,
                  onTap: () => setState(
                    () => _source = _source == _SourceFilter.auto
                        ? _SourceFilter.any
                        : _SourceFilter.auto,
                  ),
                ),
                const SizedBox(width: SsSpace.x2),
                CategoryChip(
                  label: s.filterSourceManual,
                  selected: _source == _SourceFilter.manual,
                  onTap: () => setState(
                    () => _source = _source == _SourceFilter.manual
                        ? _SourceFilter.any
                        : _SourceFilter.manual,
                  ),
                ),
                for (final cat in categories) ...[
                  const SizedBox(width: SsSpace.x2),
                  CategoryChip(
                    label: cat.label(locale),
                    icon: cat.icon,
                    color: cat.color,
                    selected: _categoryIds.contains(cat.id),
                    onTap: () => setState(() {
                      if (!_categoryIds.remove(cat.id)) {
                        _categoryIds.add(cat.id);
                      }
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: SsSpace.x2),

          if (!idle)
            Row(
              children: [
                Text(
                  '${results.length} ${s.searchResultCount}',
                  style: SsText.caption.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_hasFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: Text(s.filterClear),
                  ),
              ],
            ),

          Expanded(
            child: idle
                ? SingleChildScrollView(
                    child: EmptyState(
                      title: s.searchStartTitle,
                      message: s.searchStartBody,
                    ),
                  )
                : results.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      title: s.searchNoResults,
                      message: s.searchNoResultsBody,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32),
                    physics: const BouncingScrollPhysics(),
                    itemCount: results.length,
                    separatorBuilder: (context, _) =>
                        Divider(color: c.divider, height: 1),
                    itemBuilder: (context, index) => TxRow(
                      txn: results[index],
                      locale: locale,
                      category: byId[results[index].categoryId],
                      onTap: () =>
                          context.push('/transactions/${results[index].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
