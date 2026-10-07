/// Row-level widgets: the transaction row, the category avatar, category chips.
///
/// The transaction row is the most-seen widget in the app, so it is deliberately
/// boring: 40dp pastel icon, bold merchant, one line of meta, right-aligned
/// tabular amount with a visible sign.
library;

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/view_models.dart';
import '../format.dart';
import '../strings.dart';
import '../tokens.dart';
import 'money.dart';

/// The 40dp rounded-square icon that identifies a category.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.tintByDirection,
    this.direction,
  });

  /// An emoji today; a code point once the icon set lands.
  final String icon;
  final Color color;
  final double size;

  /// When set, a debit gets a violet tint and a credit a teal one, regardless of
  /// the category colour — the direction is the primary signal in a ledger.
  final bool? tintByDirection;
  final TxnDirection? direction;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    var base = color;
    if (tintByDirection == true && direction != null) {
      base = direction == TxnDirection.income ? c.teal500 : c.violet600;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.tintOf(base),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        icon,
        style: TextStyle(fontSize: size * 0.44),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// A pill showing a category name in the active language.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final String? icon;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final base = color ?? c.violet600;

    return InkWell(
      onTap: onTap,
      borderRadius: SsRadius.rPill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: SsSpace.x3,
          vertical: SsSpace.x2,
        ),
        decoration: BoxDecoration(
          color: selected ? c.tintOf(base) : c.surfaceTint,
          borderRadius: SsRadius.rPill,
          border: Border.all(color: selected ? base : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: SsSpace.x1 + 2),
            ],
            Text(
              label,
              style: SsText.caption.copyWith(
                color: selected ? c.textPrimary : c.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the ledger. Used by Home's recent list, the Transactions tab and
/// Search — a single widget, so a row can never look different in two places.
class TxRow extends StatelessWidget {
  const TxRow({
    super.key,
    required this.txn,
    required this.locale,
    this.category,
    this.onTap,
    this.showDate = true,
    this.dense = false,
  });

  final TxnView txn;
  final String locale;
  final CategoryView? category;
  final VoidCallback? onTap;
  final bool showDate;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final isIncome = txn.direction == TxnDirection.income;

    final title = txn.merchant?.trim().isNotEmpty == true
        ? txn.merchant!.trim()
        : (category?.label(locale) ?? SsStrings(locale)['unknownCategory']);

    final meta = <String>[
      if (category != null) category!.label(locale),
      if (showDate) shortDate(txn.occurredAtMs, locale: locale),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: SsRadius.rMd,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SsSpace.x1,
          vertical: dense ? SsSpace.x2 : SsSpace.x3,
        ),
        child: Row(
          children: [
            CategoryAvatar(
              icon: category?.icon ?? (isIncome ? '💰' : '💳'),
              color: category?.color ?? c.violet600,
              tintByDirection: category == null,
              direction: txn.direction,
            ),
            const SizedBox(width: SsSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SsText.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: SsText.caption.copyWith(color: c.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: SsSpace.x2),
            MoneyText(
              txn.amountPaise,
              tone: isIncome ? AmountTone.income : AmountTone.expense,
              showSign: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// The day separator in the grouped ledger — "আজ", "গতকাল", "১২ সেপ্টেম্বর".
class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.label, this.totalPaise});

  final String label;
  final int? totalPaise;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: SsSpace.x1,
        right: SsSpace.x1,
        top: SsSpace.x5,
        bottom: SsSpace.x2,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: SsText.micro.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const Spacer(),
          if (totalPaise != null)
            MoneyText(
              totalPaise!,
              tone: AmountTone.neutral,
              style: SsText.caption.copyWith(color: c.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// A small coloured label — "নতুন", "Pro", "৮০%".
class SsBadge extends StatelessWidget {
  const SsBadge({super.key, required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final base = color ?? c.violet600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: SsSpace.x2, vertical: 3),
      decoration: BoxDecoration(
        color: c.tintOf(base),
        borderRadius: SsRadius.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: base),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SsText.micro.copyWith(
                color: base,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
