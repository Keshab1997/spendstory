/// Date, month and digit formatting for the three shipped languages.
///
/// `intl` is used for the heavy lifting in Batch 8 (T-701) with real ARB files;
/// these helpers cover what the shell needs today and — importantly — render
/// Bengali and Devanagari numerals, which an Indian user notices immediately if
/// we get wrong.
library;

const List<String> _monthsEn = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _monthsBn = <String>[
  'জানু',
  'ফেব্রু',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্ট',
  'অক্টো',
  'নভে',
  'ডিসে',
];

const List<String> _monthsHi = <String>[
  'जन',
  'फ़र',
  'मार्च',
  'अप्रै',
  'मई',
  'जून',
  'जुल',
  'अग',
  'सित',
  'अक्टू',
  'नव',
  'दिस',
];

const List<String> _monthsFullBn = <String>[
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

const List<String> _monthsFullHi = <String>[
  'जनवरी',
  'फ़रवरी',
  'मार्च',
  'अप्रैल',
  'मई',
  'जून',
  'जुलाई',
  'अगस्त',
  'सितंबर',
  'अक्टूबर',
  'नवंबर',
  'दिसंबर',
];

const List<String> _weekdaysBn = <String>[
  'সোম',
  'মঙ্গল',
  'বুধ',
  'বৃহস্পতি',
  'শুক্র',
  'শনি',
  'রবি',
];

const List<String> _weekdaysHi = <String>[
  'सोम',
  'मंगल',
  'बुध',
  'गुरु',
  'शुक्र',
  'शनि',
  'रवि',
];

const List<String> _weekdaysEn = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const String _bnDigits = '০১২৩৪৫৬৭৮৯';
const String _hiDigits = '०१२३४५६७८९';

/// Rewrites ASCII digits in [input] using the locale's numeral system.
String localizeDigits(String input, String locale) {
  final table = switch (locale) {
    'bn' => _bnDigits,
    'hi' => _hiDigits,
    _ => null,
  };
  if (table == null) return input;
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final code = ch.codeUnitAt(0);
    if (code >= 48 && code <= 57) {
      buffer.write(table[code - 48]);
    } else {
      buffer.write(ch);
    }
  }
  return buffer.toString();
}

int _startOfDay(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
}

int startOfMonth(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month).millisecondsSinceEpoch;
}

int endOfMonth(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month + 1).millisecondsSinceEpoch - 1;
}

int startOfPreviousMonth(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month - 1).millisecondsSinceEpoch;
}

int endOfPreviousMonth(int ms) => startOfMonth(ms) - 1;

/// "১২ সেপ্ট" — the short form used in a transaction row.
String shortDate(int ms, {String locale = 'bn'}) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final months = switch (locale) {
    'en' => _monthsEn,
    'hi' => _monthsHi,
    _ => _monthsBn,
  };
  return localizeDigits('${d.day} ${months[d.month - 1]}', locale);
}

/// "আজ" / "গতকাল" / "১২ সেপ্টেম্বর" — the grouped-ledger day header.
///
/// [nowMs] is injectable so the grouping is testable without freezing the clock.
String dayLabel(int ms, {String locale = 'bn', int? nowMs}) {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  final today = _startOfDay(now);
  final yesterday = today - 24 * 60 * 60 * 1000;
  final day = _startOfDay(ms);

  if (day == today) {
    return switch (locale) {
      'en' => 'Today',
      'hi' => 'आज',
      _ => 'আজ',
    };
  }
  if (day == yesterday) {
    return switch (locale) {
      'en' => 'Yesterday',
      'hi' => 'कल',
      _ => 'গতকাল',
    };
  }

  final months = switch (locale) {
    'en' => _monthsEn,
    'hi' => _monthsFullHi,
    _ => _monthsFullBn,
  };
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return localizeDigits('${d.day} ${months[d.month - 1]}', locale);
}

/// "অক্টোবর ২০২৬" — the home month selector.
String monthLabel(int ms, {String locale = 'bn'}) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final name = switch (locale) {
    'en' => '${_monthsFullEn(d.month)} ${d.year}',
    'hi' => '${_monthsFullHi[d.month - 1]} ${d.year}',
    _ => '${_monthsFullBn[d.month - 1]} ${d.year}',
  };
  return localizeDigits(name, locale);
}

String _monthsFullEn(int month) => const <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

/// The single-letter-ish weekday marker used by the mini calendar strip.
String weekdayShort(int ms, {String locale = 'bn'}) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final names = switch (locale) {
    'en' => _weekdaysEn,
    'hi' => _weekdaysHi,
    _ => _weekdaysBn,
  };
  return names[d.weekday - 1];
}

/// "১২ ঘ : ৪৫ মি" — a time of day, used on the transaction detail screen.
String timeOfDay(int ms, {String locale = 'bn'}) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final suffix = switch (locale) {
    'en' => d.hour < 12 ? 'AM' : 'PM',
    'hi' => d.hour < 12 ? 'पूर्वाह्न' : 'अपराह्न',
    _ => d.hour < 12 ? 'সকাল' : 'বিকেল',
  };
  return localizeDigits('$hour:$minute $suffix', locale);
}

/// Days elapsed in the current month, and how many it has — the forecast input.
({int elapsed, int total}) monthProgress(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final total = DateTime(d.year, d.month + 1, 0).day;
  return (elapsed: d.day, total: total);
}
