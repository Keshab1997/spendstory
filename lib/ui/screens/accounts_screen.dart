/// S-16 Accounts (T-503).
///
/// Balances here are **computed, never stored** — opening balance + credits −
/// debits, summed from the same transactions every other screen reads
/// (`docs/05-DATA-MODEL.md` §2). That is the whole design: a stored balance is
/// a second source of truth, and the moment it disagrees with the ledger the
/// user stops trusting both numbers.
///
/// There is no bank API and no sync. This screen knows what the user told it
/// and what the ledger already captured, and says so in one line at the top
/// rather than implying a connection it does not have.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/view_models.dart';
import '../components/ad_slot.dart';
import '../components/controls.dart';
import '../components/money.dart';
import '../components/surfaces.dart';
import '../strings.dart';
import '../tokens.dart';
import 'account_edit_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = SsColors.of(context);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final showAds = ref.watch(adsVisibleProvider);
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <AccountView>[];
    final balances =
        ref.watch(accountBalancesProvider).valueOrNull ?? const <String, int>{};

    final total = accounts.fold<int>(
      0,
      (sum, a) => sum + (balances[a.id] ?? a.openingBalancePaise),
    );

    return SsScaffold(
      title: s.accounts,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SsSpace.x2),

          // ---- everything, added up -------------------------------------------
          SsCard(
            gradient: c.moneyGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['accountsTotalNet'],
                  style: SsText.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: SsSpace.x1),
                MoneyText(
                  total,
                  style: SsText.displayMoney,
                  color: Colors.white,
                ),
                const SizedBox(height: SsSpace.x2),
                Text(
                  s['accountBalanceNote'],
                  style: SsText.micro.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: SsSpace.x4),

          for (final account in accounts)
            Padding(
              padding: const EdgeInsets.only(bottom: SsSpace.x3),
              child: _AccountCard(
                account: account,
                balancePaise:
                    balances[account.id] ?? account.openingBalancePaise,
                locale: locale,
                onTap: () => showAccountEditor(context, existing: account),
              ),
            ),

          // One banner unit at the bottom, never between the cards: comparing
          // two balances across an ad is not a thing anyone should have to do.
          if (showAds) const AdSlot(placement: AdPlacement.accountsBanner),

          const SizedBox(height: SsSpace.x4),
          SsActionButton(
            label: s['accountAdd'],
            icon: Icons.add_rounded,
            tone: SsButtonTone.secondary,
            onPressed: () => showAccountEditor(context),
          ),
          const SizedBox(height: SsSpace.x3),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balancePaise,
    required this.locale,
    required this.onTap,
  });

  final AccountView account;
  final int balancePaise;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final tint = account.colorHex == null
        ? accountTypeTint(account.type, c)
        : colorFromHex(account.colorHex!);

    return SsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(SsSpace.x3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: SsRadius.rMd,
            ),
            child: Icon(accountTypeIcon(account.type), color: tint, size: 20),
          ),
          const SizedBox(width: SsSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SsText.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  accountTypeLabel(SsStrings(locale), account.type),
                  style: SsText.micro.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: SsSpace.x2),
          // The amount is the one rigid thing in this row, so in Bengali at a
          // large text scale it is what overflows first. A FittedBox scales a
          // long balance down instead of clipping it or wrapping a currency
          // amount across two lines.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: MoneyText(
                balancePaise,
                style: SsText.h3,
                tone: AmountTone.neutral,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The icon and tint each account type gets when the user has not picked a
/// colour. Kept here rather than in the editor so the list and the sheet can
/// never disagree about what a wallet looks like.
IconData accountTypeIcon(String type) => switch (type) {
  'bank' => Icons.account_balance_rounded,
  'cash' => Icons.payments_rounded,
  'wallet' => Icons.account_balance_wallet_rounded,
  'card' => Icons.credit_card_rounded,
  _ => Icons.account_balance_rounded,
};

Color accountTypeTint(String type, SsColors c) => switch (type) {
  'bank' => c.violet600,
  'cash' => c.teal500,
  'wallet' => c.gold500,
  'card' => c.rose500,
  _ => c.violet600,
};

/// `bank` → the word, in the active language.
String accountTypeLabel(SsStrings s, String type) => switch (type) {
  'bank' => s['accountTypeBank'],
  'cash' => s['accountTypeCash'],
  'wallet' => s['accountTypeWallet'],
  'card' => s['accountTypeCard'],
  _ => s['accountTypeBank'],
};

/// The four kinds, in the order the editor offers them.
const List<String> kAccountTypes = <String>['bank', 'cash', 'wallet', 'card'];
