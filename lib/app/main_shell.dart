/// The tab shell — `docs/04-NAVIGATION.md` §4.
///
/// A floating glass bar rather than Material's docked `NavigationBar`: it
/// implies the content scrolls *under* it, which is what makes the layout read
/// as modern rather than as a stock Android app.
///
/// Two rules from the spec are enforced here rather than left to discipline:
/// the bar is never covered by an ad, and the tab order is fixed — Home ·
/// Transactions · Insights · Settings.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/format.dart';
import '../ui/tokens.dart';
import 'providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Budget alerts (T-505) are checked when the shell comes up and again
    // whenever the ledger changes. That is the whole trigger: the app has no
    // background service, and it does not need one — every new expense reaches
    // this process first. The once-a-day cap lives in the runner, which is what
    // makes calling it this often safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(budgetAlertRunnerProvider)());
      unawaited(ref.read(recurringRunnerProvider)());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(transactionsProvider, (previous, next) {
      if (next.hasValue) unawaited(ref.read(budgetAlertRunnerProvider)());
    });

    // Recurring rules have the same two triggers, and the same guarantee: a
    // due date is acted on once, whatever the ledger does afterwards.
    ref.listen(recurringProvider, (previous, next) {
      if (next.hasValue) unawaited(ref.read(recurringRunnerProvider)());
    });

    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final uncategorised = ref.watch(uncategorisedCountProvider);
    final pro = ref.watch(proStatusProvider);

    final items = <_NavItem>[
      _NavItem(
        icon: Icons.home_rounded,
        outlineIcon: Icons.home_outlined,
        label: s['home'],
      ),
      _NavItem(
        icon: Icons.receipt_long_rounded,
        outlineIcon: Icons.receipt_long_outlined,
        label: s['txTitle'],
        badge: uncategorised > 0 ? uncategorised : null,
      ),
      _NavItem(
        icon: Icons.insights_rounded,
        outlineIcon: Icons.insights_outlined,
        label: s['insights'],
      ),
      _NavItem(
        icon: Icons.settings_rounded,
        outlineIcon: Icons.settings_outlined,
        label: s['settings'],
        dot: !pro,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: widget.shell,
      bottomNavigationBar: _FloatingNav(
        locale: locale,
        items: items,
        currentIndex: widget.shell.currentIndex,
        onTap: (index) => widget.shell.goBranch(
          index,
          // Tapping the tab you are already on pops that branch back to its
          // root — the standard Android behaviour.
          initialLocation: index == widget.shell.currentIndex,
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.outlineIcon,
    required this.label,
    this.badge,
    this.dot = false,
  });

  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final int? badge;
  final bool dot;
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.locale = 'bn',
  });

  final String locale;
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: SsSpace.x4,
        right: SsSpace.x4,
        bottom: SsSpace.x3 + media.padding.bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SsRadius.pill),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: c.isDark
                  ? c.surfaceElev.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(SsRadius.pill),
              border: Border.all(color: c.border),
              boxShadow: SsShadow.card(c),
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      locale: locale,
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.locale = 'bn',
  });

  final String locale;
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final colour = selected ? c.teal500 : c.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SsRadius.pill),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected ? item.icon : item.outlineIcon,
                    key: ValueKey<bool>(selected),
                    size: 22,
                    color: colour,
                  ),
                ),
                if (item.badge != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: c.rose500,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        localizeDigits('${item.badge}', locale),
                        textAlign: TextAlign.center,
                        style: SsText.micro.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  )
                else if (item.dot)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: c.gold500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SsText.micro.copyWith(
                color: colour,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            // The dot indicator from the spec: a second, non-colour signal that
            // this is the active tab.
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(top: 3),
              height: 3,
              width: selected ? 14 : 0,
              decoration: BoxDecoration(
                color: c.teal500,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
