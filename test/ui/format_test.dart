/// Money and date formatting.
///
/// The lakh grouping gets its own tests because getting it wrong is the single
/// most obvious way to look like a foreign app to an Indian user: `₹124,000`
/// reads as wrong to anyone who has seen `₹1,24,000` their whole life.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/ui/format.dart';
import 'package:spendstory/ui/components/money.dart';

void main() {
  group('formatInr — Indian grouping', () {
    test('groups by three digits below a thousand', () {
      expect(formatInr(0), '0');
      expect(formatInr(500), '5');
      expect(formatInr(100000), '1,000');
      expect(formatInr(9999900), '99,999');
    });

    test('switches to lakh grouping above a thousand rupees', () {
      expect(formatInr(12400000), '1,24,000');
      expect(formatInr(1240000), '12,400');
      expect(formatInr(123456700), '12,34,567');
      expect(formatInr(1000000000), '1,00,00,000');
    });

    test('shows paise only when they are not zero', () {
      expect(formatInr(124000), '1,240');
      expect(formatInr(124050), '1,240.50');
      expect(formatInr(124005), '1,240.05');
      expect(formatInr(124000, showPaise: true), '1,240.00');
    });

    test('never loses a paisa to floating point', () {
      // 999.99 rupees is the classic float-rounding victim.
      expect(formatInr(99999), '999.99');
      expect(formatInr(1), '0.01');
    });

    test('marks negatives with a minus sign, not a colour', () {
      expect(formatInr(-124000), '−1,240');
      expect(formatInr(-124050), '−1,240.50');
    });

    test('renders in the locale’s own numerals when asked', () {
      expect(formatInr(1409000, showSymbol: true, localize: 'bn'), '₹১৪,০৯০');
      expect(formatInr(1409000, showSymbol: true, localize: 'hi'), '₹१४,०९०');
      expect(formatInrCompact(12400000, localize: 'bn'), '₹১.২L');
    });

    test('can include the rupee symbol', () {
      expect(formatInr(124000, showSymbol: true), '₹1,240');
      expect(formatInr(124050, showSymbol: true), '₹1,240.50');
    });

    test('compact form for tight spaces', () {
      expect(formatInrCompact(124000), '₹1.2k');
      expect(formatInrCompact(12400000), '₹1.2L');
      expect(formatInrCompact(1500000000), '₹1.5Cr');
      expect(formatInrCompact(15000000000), '₹15.0Cr');
      expect(formatInrCompact(50000), '₹500');
    });
  });

  group('localizeDigits', () {
    test('renders Bengali numerals', () {
      expect(localizeDigits('1240', 'bn'), '১২৪০');
      expect(localizeDigits('₹12,400', 'bn'), '₹১২,৪০০');
    });

    test('renders Devanagari numerals', () {
      expect(localizeDigits('1240', 'hi'), '१२४०');
    });

    test('leaves English alone', () {
      expect(localizeDigits('1240', 'en'), '1240');
    });
  });

  group('dates', () {
    final now = DateTime(2026, 10, 7, 20).millisecondsSinceEpoch;

    test('day headers say আজ and গতকাল before falling back to a date', () {
      expect(
        dayLabel(DateTime(2026, 10, 7, 9).millisecondsSinceEpoch, nowMs: now),
        'আজ',
      );
      expect(
        dayLabel(DateTime(2026, 10, 6, 23).millisecondsSinceEpoch, nowMs: now),
        'গতকাল',
      );
      // Latin digits unless the S-20 switch asks otherwise (T-707): the words
      // are Bengali either way.
      expect(
        dayLabel(DateTime(2026, 9, 12).millisecondsSinceEpoch, nowMs: now),
        '12 সেপ্টেম্বর',
      );
      expect(
        dayLabel(
          DateTime(2026, 9, 12).millisecondsSinceEpoch,
          nowMs: now,
          nativeDigits: true,
        ),
        '১২ সেপ্টেম্বর',
      );
    });

    test('the same labels exist in English and Hindi', () {
      expect(
        dayLabel(
          DateTime(2026, 10, 7).millisecondsSinceEpoch,
          locale: 'en',
          nowMs: now,
        ),
        'Today',
      );
      expect(
        dayLabel(
          DateTime(2026, 10, 6).millisecondsSinceEpoch,
          locale: 'hi',
          nowMs: now,
        ),
        'कल',
      );
    });

    test('month boundaries are inclusive', () {
      final start = startOfMonth(now);
      final end = endOfMonth(now);
      expect(end - start, greaterThan(28 * 24 * 60 * 60 * 1000 - 1));
      expect(DateTime.fromMillisecondsSinceEpoch(start).day, 1);
      expect(DateTime.fromMillisecondsSinceEpoch(end).month, 10);
      expect(
        DateTime.fromMillisecondsSinceEpoch(startOfPreviousMonth(now)).month,
        9,
      );
    });

    test('month progress feeds the forecast', () {
      final p = monthProgress(now);
      expect(p.elapsed, 7);
      expect(p.total, 31);
    });
  });
}
