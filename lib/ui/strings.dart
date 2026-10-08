/// The strings a screen reads: a per-locale facade over the ARB files.
///
/// Since T-701 the copy itself lives in `lib/l10n/app_en.arb`, `app_hi.arb` and
/// `app_bn.arb` — the one place a user-facing string is written, translated and
/// reviewed ([docs/09-LOCALIZATION.md]). Two generators read those files:
/// `flutter gen-l10n` builds the `AppLocalizations` that `MaterialApp` hands to
/// Flutter (so date pickers, text selection and tooltips follow the app
/// language), and `tool/l10n_gen.py` builds `ssStringsTable` — the table this
/// class reads. Both generated files are checked in and neither is edited by
/// hand.
///
/// This class stays because the app reads its own copy in three shapes the
/// generated `AppLocalizations` does not offer: `s['key']` at ~270 call sites,
/// [fill] for the {placeholder} templates, and `SsStrings(locale)` in the tests,
/// which render a screen's copy without building a widget tree. Prefer the
/// typed getter at every new call site — `s.txTitle` compiles, `s['txTitel']`
/// only fails at runtime, and the getters below are hand-written (an extension
/// generated into the .g.dart would only resolve in the files that import it).
///
/// English is the template: a key is born in `app_en.arb`, and a missing
/// translation in either sibling is a red test
/// (`test/l10n/l10n_test.dart`), not an English leak in a Bengali screen.
/// [missingKeys] is that same rule, at runtime.
library;

import '../l10n/strings_table.g.dart';
// Prefixed: the date wrappers below share their names with these functions on
// purpose, and an unqualified call would find the method, not the table.
import 'format.dart' as fmt;

class SsStrings {
  const SsStrings(this.locale, {this.nativeDigits = false});

  /// `en` | `hi` | `bn`
  final String locale;

  /// Whether numbers are written in [locale]'s own digits — the S-20 switch
  /// "বাংলা সংখ্যা দেখাও" (docs/09-LOCALIZATION.md §2).
  ///
  /// False is the shipped default and the default in the tests: a Bengali
  /// reader expects `₹1,240`, because that is how their bank writes it. The
  /// switch moves the *digits* only — the words around them were already
  /// Bengali, and they stay Bengali either way.
  final bool nativeDigits;

  /// What the numeral tables in `format.dart` understand: the language, when the
  /// user asked for its digits, and `en` ("leave them alone") when they did not.
  String get numeralLocale => nativeDigits ? locale : 'en';

  /// [input] with its ASCII digits written the way this user reads numbers:
  /// `1240` → `১২৪০` / `१२४०`, or unchanged.
  ///
  /// Every numeral a screen shows goes through here or through
  /// [numeralLocale], which is what makes the one switch enough
  /// (`test/ui/numerals_test.dart` fails if a call site goes around it).
  String digits(String input) => fmt.localizeDigits(input, numeralLocale);

  /// The date helpers in `format.dart`, resolved against the same choice: a
  /// Bengali ledger that left the numerals switch off writes `12 সেপ্টেম্বর`,
  /// and one that turned it on writes `১২ সেপ্টেম্বর`. Same words either way —
  /// only the digits move.
  String shortDate(int ms) =>
      fmt.shortDate(ms, locale: locale, nativeDigits: nativeDigits);

  String dayLabel(int ms, {int? nowMs}) => fmt.dayLabel(
    ms,
    locale: locale,
    nativeDigits: nativeDigits,
    nowMs: nowMs,
  );

  String monthLabel(int ms) =>
      fmt.monthLabel(ms, locale: locale, nativeDigits: nativeDigits);

  String timeOfDay(int ms) =>
      fmt.timeOfDay(ms, locale: locale, nativeDigits: nativeDigits);

  static const List<String> supportedLocales = <String>['bn', 'en', 'hi'];

  String operator [](String key) {
    final value = ssStringsTable[locale]?[key];
    // Never silently borrow English copy into a Bengali or Hindi screen.
    if (value == null) return '⟦$key⟧';
    return digits(value);
  }

  /// `{n} days left` — the one phrase S-14 and S-15 both read out.
  String daysLeft(int days) =>
      fill('budgetDaysLeftTemplate', {'n': digits('$days')});

  /// A string with `{placeholders}` filled in.
  ///
  /// Word order differs between the three languages, so a sentence like
  /// "Spend about ₹400 a day" cannot be assembled by concatenation — the
  /// translator has to own the whole sentence. This is the smallest thing that
  /// lets them, without pulling in a formatting package for six templates.
  String fill(String key, Map<String, String> values) {
    var out = this[key];
    for (final entry in values.entries) {
      out = out.replaceAll('{${entry.key}}', entry.value);
    }
    return out;
  }

  String get appName => this['appName'];
  String get txTitle => this['txTitle'];
  String get txFilterAll => this['txFilterAll'];
  String get txDelete => this['txDelete'];
  String get txRecategorise => this['txRecategorise'];
  String get txPickCategory => this['txPickCategory'];
  String get txDeleted => this['txDeleted'];
  String get txUndo => this['txUndo'];
  String get txSwipeHint => this['txSwipeHint'];
  String get txMonthEmptyTitle => this['txMonthEmptyTitle'];
  String get txMonthEmptyBody => this['txMonthEmptyBody'];
  String get detailTitle => this['detailTitle'];
  String get detailDate => this['detailDate'];
  String get detailCategory => this['detailCategory'];
  String get detailAccount => this['detailAccount'];
  String get detailMode => this['detailMode'];
  String get detailSource => this['detailSource'];
  String get detailNote => this['detailNote'];
  String get detailChange => this['detailChange'];
  String get detailRawTitle => this['detailRawTitle'];
  String get detailRawHint => this['detailRawHint'];
  String get detailNoRaw => this['detailNoRaw'];
  String get detailEdit => this['detailEdit'];
  String get detailDeleteConfirmTitle => this['detailDeleteConfirmTitle'];
  String get detailDeleteConfirmBody => this['detailDeleteConfirmBody'];
  String get detailNotFound => this['detailNotFound'];
  String get cancel => this['cancel'];
  String get addTitle => this['addTitle'];
  String get editTitle => this['editTitle'];
  String get amountLabel => this['amountLabel'];
  String get merchantHint => this['merchantHint'];
  String get noteHint => this['noteHint'];
  String get save => this['save'];
  String get saved => this['saved'];
  String get amountRequired => this['amountRequired'];
  String get today => this['today'];
  String get modeCash => this['modeCash'];
  String get modeUpi => this['modeUpi'];
  String get modeCard => this['modeCard'];
  String get modeNetbanking => this['modeNetbanking'];
  String get modeWallet => this['modeWallet'];
  String get modeOther => this['modeOther'];
  String get catManagerTitle => this['catManagerTitle'];
  String get catNew => this['catNew'];
  String get catEditTitle => this['catEditTitle'];
  String get catNameEn => this['catNameEn'];
  String get catNameHi => this['catNameHi'];
  String get catNameBn => this['catNameBn'];
  String get catIcon => this['catIcon'];
  String get catColor => this['catColor'];
  String get catMonthlyCap => this['catMonthlyCap'];
  String get catDelete => this['catDelete'];
  String get catDeleteWarn => this['catDeleteWarn'];
  String get catNameRequired => this['catNameRequired'];
  String get catEmpty => this['catEmpty'];
  String get catEmptyBody => this['catEmptyBody'];
  String get searchTitle => this['searchTitle'];
  String get searchHint => this['searchHint'];
  String get searchResultCount => this['searchResultCount'];
  String get searchNoResults => this['searchNoResults'];
  String get searchNoResultsBody => this['searchNoResultsBody'];
  String get searchStartTitle => this['searchStartTitle'];
  String get searchStartBody => this['searchStartBody'];
  String get filterSourceAuto => this['filterSourceAuto'];
  String get filterSourceManual => this['filterSourceManual'];
  String get filterClear => this['filterClear'];
  String get insights => this['insights'];
  String get settings => this['settings'];
  String get accounts => this['accounts'];
  String get savings => this['savings'];
  String get trend => this['trend'];
  String get topCategories => this['topCategories'];
  String get noDataTitle => this['noDataTitle'];
  String get noDataBody => this['noDataBody'];
  String get emptyTxTitle => this['emptyTxTitle'];
  String get emptyTxBody => this['emptyTxBody'];
  String get addFirst => this['addFirst'];
  String get comingSoon => this['comingSoon'];
  String get comingSoonBody => this['comingSoonBody'];
  String get proTitle => this['proTitle'];
  String get proBody => this['proBody'];
  String get about => this['about'];
  String get aboutBody => this['aboutBody'];
  String get privacy => this['privacy'];
  String get privacyBody => this['privacyBody'];
  String get greeting => this['greeting'];
  String get heroLabel => this['heroLabel'];
  String get income => this['income'];
  String get expense => this['expense'];
  String get recentTx => this['recentTx'];
  String get seeAll => this['seeAll'];
  String get addTx => this['addTx'];
  String get budget => this['budget'];
  String get categories => this['categories'];
  String get reports => this['reports'];
  String get obNext => this['obNext'];
  String get obBack => this['obBack'];
  String get obSkip => this['obSkip'];
  String get obStart => this['obStart'];
  String get permAllow => this['permAllow'];
  String get permNotNow => this['permNotNow'];
  String get permDenied => this['permDenied'];
  String get permWebNote => this['permWebNote'];
  String get manualLink => this['manualLink'];
  String get permTitle => this['permTitle'];
  String get permWhy => this['permWhy'];
  String get permReads => this['permReads'];
  String get permReadsBody => this['permReadsBody'];
  String get permNever => this['permNever'];
  String get permNeverBody => this['permNeverBody'];
  String get notifTitle => this['notifTitle'];
  String get notifWhy => this['notifWhy'];
  String get notifOn => this['notifOn'];
  String get notifOff => this['notifOff'];
  String get notifApps => this['notifApps'];
  String get notifOnlyThese => this['notifOnlyThese'];
  String get notifOpen => this['notifOpen'];
  String get notifSkip => this['notifSkip'];
  String get notifContinue => this['notifContinue'];
  String get notifManualHint => this['notifManualHint'];
  String get manualTitle => this['manualTitle'];
  String get manualBody => this['manualBody'];
  String get manualP1 => this['manualP1'];
  String get manualP1Body => this['manualP1Body'];
  String get manualP2 => this['manualP2'];
  String get manualP2Body => this['manualP2Body'];
  String get manualP3 => this['manualP3'];
  String get manualP3Body => this['manualP3Body'];
  String get manualStart => this['manualStart'];
  String get manualBack => this['manualBack'];
  String get ob1Title => this['ob1Title'];
  String get ob1Body => this['ob1Body'];
  String get ob2Title => this['ob2Title'];
  String get ob2Body => this['ob2Body'];
  String get ob3Title => this['ob3Title'];
  String get ob3Body => this['ob3Body'];

  // ---- app lock (T-706) -----------------------------------------------------
  String get security => this['security'];
  String get appLock => this['appLock'];
  String get appLockBody => this['appLockBody'];
  String get appLockPromptReason => this['appLockPromptReason'];
  String get appLockOnDone => this['appLockOnDone'];
  String get appLockOffDone => this['appLockOffDone'];
  String get appLockCancelled => this['appLockCancelled'];
  String get appLockUnavailable => this['appLockUnavailable'];
  String get lockTitle => this['lockTitle'];
  String get lockBody => this['lockBody'];
  String get lockUnlock => this['lockUnlock'];
  String get lockUnavailableBody => this['lockUnavailableBody'];
  String get lockTurnOff => this['lockTurnOff'];

  /// Keys present in one language but missing in another — empty is correct.

  /// `locale:key` pairs for a key any locale is missing.
  ///
  /// The table is generated from ARB files that must agree on their keys, so
  /// this is expected to be empty; it is the runtime half of the l10n test.
  static List<String> get missingKeys {
    final all = <String>{for (final t in ssStringsTable.values) ...t.keys};
    final missing = <String>[];
    for (final entry in ssStringsTable.entries) {
      for (final key in all) {
        if (!entry.value.containsKey(key)) {
          missing.add('${entry.key}:$key');
        }
      }
    }
    return missing;
  }
}
