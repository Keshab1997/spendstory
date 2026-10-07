/// Interim trilingual strings.
///
/// This is deliberately **not** the final localization layer. Batch 8 (T-701)
/// replaces it with `flutter_localizations` + ARB files and a generated
/// `AppLocalizations`, which is what the store listing and the CI locale checks
/// will be built on. It exists now so that the shell can be seen in all three
/// languages while the rest of the app is being built, and so a missing string
/// is a visible gap rather than an English leak.
///
/// Every key must exist in all three languages; [SsStrings.missingKeys] is
/// asserted by a test so this cannot silently rot.
library;

import 'format.dart';

class SsStrings {
  const SsStrings(this.locale);

  /// `en` | `hi` | `bn`
  final String locale;

  static const List<String> supportedLocales = <String>['bn', 'en', 'hi'];

  static const Map<String, Map<String, String>> _table =
      <String, Map<String, String>>{'en': _en, 'hi': _hi, 'bn': _bn};

  String operator [](String key) {
    final value = _table[locale]?[key];
    // Never silently borrow English copy into a Bengali or Hindi screen.
    if (value == null) return '⟦$key⟧';
    return localizeDigits(value, locale);
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

  /// Keys present in one language but missing in another — empty is correct.
  static List<String> get missingKeys {
    final all = <String>{for (final t in _table.values) ...t.keys};
    final missing = <String>[];
    for (final entry in _table.entries) {
      for (final key in all) {
        if (!entry.value.containsKey(key)) {
          missing.add('${entry.key}:$key');
        }
      }
    }
    return missing;
  }
}

const Map<String, String> _en = <String, String>{
  "ob1Title": "Every payment files itself",
  "ob1Body": "SpendStory reads your bank's transaction SMS and your payment apps' notifications, and writes the expense down for you. No typing.",
  "ob1B1": "Works with 50 bank senders",
  "ob1B2": "Reads lakh-format amounts correctly",
  "ob1B3": "An OTP is never read, ever",
  "ob2Title": "See where the money goes",
  "ob2Body": "Category by category, month by month, with the one number that changes behaviour: what is left in the budget.",
  "ob2B1": "Category split and top merchants",
  "ob2B2": "Monthly budget with an 80% warning",
  "ob2B3": "Forecast for the end of the month",
  "ob3Title": "Your data stays on your phone",
  "ob3Body": "There is no server, no account and no sign-in. Everything is stored on this device and nowhere else.",
  "ob3B1": "Nothing is uploaded — not one byte",
  "ob3B2": "Delete everything, any time",
  "ob3B3": "Works with no internet at all",
  "obNext": "Next",
  "obBack": "Back",
  "obSkip": "Skip",
  "obStart": "Get started",
  "permTitle": "Let SpendStory read bank SMS?",
  "permWhy": "This is how the app captures spending without you typing. Android will ask for permission in the next step.",
  "permReads": "What it reads",
  "permReadsBody": "Transaction alerts from banks, cards and wallets — the amount, the merchant and the date.",
  "permNever": "What it never touches",
  "permNeverBody": "OTPs, passwords, PINs and personal messages. OTPs are dropped before anything else looks at them, and no message is ever sent anywhere.",
  "permAllow": "Allow reading SMS",
  "permTryAgain": "Try again",
  "permNotNow": "Not now",
  "permDenied": "No problem — you can add expenses by hand, and turn this on later from Settings.",
  "permWebNote": "On the web preview there is no Android to ask — the real prompt only appears in the phone build. Use “Not now” to carry on.",
  "manualLink": "I would rather not give SMS access",
  "notifTitle": "One more, and it is optional",
  "notifWhy": "Payment apps like Google Pay and PhonePe send their own notification. With access, those are captured too — otherwise a UPI payment may be missed if the bank's SMS is delayed.",
  "notifOn": "Notification access is on",
  "notifOff": "Notification access is off",
  "notifApps": "Only these six apps are ever looked at:",
  "notifOnlyThese": "Every other notification on your phone is ignored completely. SpendStory never reads WhatsApp, email or personal messages.",
  "notifOpen": "Open notification settings",
  "notifSkip": "Skip this",
  "notifContinue": "Continue",
  "notifManualHint": "Open Settings → Notifications → Notification access, and turn on SpendStory.",
  "manualTitle": "Use it by hand",
  "manualBody": "Perfectly fine — the ledger, budgets and insights all work with expenses you enter yourself. You can switch capture on later from Settings.",
  "manualP1": "Add in three taps",
  "manualP1Body": "Amount, category, done.",
  "manualP2": "Everything still works",
  "manualP2Body": "Budgets, categories, insights, export.",
  "manualP3": "Turn on capture later",
  "manualP3Body": "Settings → SMS capture, any time.",
  "manualStart": "Start using SpendStory",
  "manualBack": "Actually, let me give SMS access",
  'appName': 'SpendStory',
  'appTagline': "Your money's story, right on your phone",
  'greeting': 'Hello',
  'heroLabel': 'Spent this month',
  'income': 'Income',
  'expense': 'Spent',
  'recentTx': 'Recent transactions',
  'seeAll': 'See all',
  'addTx': 'Add',
  'budget': 'Budget',
  'categories': 'Categories',
  'reports': 'Reports',
  'vsLastMonth': 'vs last month',
  'monthlyBudget': 'Monthly budget',
  'budgetLeft': 'left',
  'over': 'over',
  'txTitle': 'Transactions',
  'insights': 'Insights',
  'settings': 'Settings',
  'appearance': 'Appearance',
  'theme': 'Theme',
  'themeSystem': 'System',
  'themeLight': 'Light',
  'themeDark': 'Dark',
  'language': 'Language',
  'languagePrompt': 'Choose a language. You can change it anytime.',
  'start': 'Get started',
  'home': 'Home',
  'uncategorised': 'Uncategorised',
  'thisMonth': 'This month',
  'trend': 'Last 6 months',
  'topCategories': 'Where the money went',
  'noDataTitle': 'Nothing here yet',
  'noDataBody': 'Your transactions will appear here as soon as you spend.',
  'addFirst': 'Add the first one',
  'emptyTxTitle': 'No transactions yet',
  'emptyTxBody':
      'Turn on SMS capture and every payment files itself. Or add one by hand.',
  'demoBanner': 'Web preview',
  'demoBannerBody':
      'Demo data. The phone build reads your bank SMS — on device only.',
  'about': 'About SpendStory',
  'aboutBody': 'Nothing leaves your phone',
  'privacy': 'Privacy',
  'privacyBody': 'Reads only bank SMS. Never uploaded.',
  'privacyDetails': 'SpendStory reads bank transaction SMS only — never OTPs. Your data is never sent to a server, and no account is needed. Uninstall the app to remove its data from your phone.',
  'privacyOnDevice': '100% on-device',
  'version': 'Version',
  'proTitle': 'SpendStory Pro',
  'proBody': 'No ads, unlimited budgets, forecasts',
  'search': 'Search',
  'accounts': 'Accounts',
  'savings': 'Net saved',
  'comingSoon': 'Coming in the next batch',
  'comingSoonBody': 'This screen is built in Batch 4–6. The shell, theme and demo data are live now.',
  'adLabel': 'Advertisement',
  'adBanner': 'banner',
  'adNative': 'native',
  'unknownCategory': 'Unknown',
  'budgetExceeded': "You've gone over budget — time to rein in spending.",
  'forecast': 'Estimated spending by month-end',
  'addEditUnavailable': 'Adding and editing transactions are coming soon.',
  'activeNoAds': 'Active · ad-free',
  'budgetSettingBody': 'Set monthly limits by category',
  'categoriesSettingBody': 'Create your own categories',
  'accountsSettingBody': 'Bank · cash · wallet',
  'deleteAllData': 'Delete all data',
  'deleteAllDataSubtitle':
      'Permanently erase everything after two confirmations',
  'eraseTitle': 'Delete all data?',
  'eraseBody': 'All transactions, budgets and categories will be deleted. This cannot be undone.',
  'keep': 'Keep it',
  'erase': 'Delete',
  'confirm': 'Are you sure?',
  'lastChance': 'Last chance — everything will be erased after this.',
  'no': 'No',
  'yesErase': 'Yes, delete everything',
  'demoEraseUnavailable': 'Data deletion is disabled in demo mode. Use the phone app to erase your data.',
  'transactionDetailTitle': 'Transaction details',
  'transactionDetailSubtitle': 'S-11 · Transaction detail',
  'transactionDetailBody': 'Original SMS, category changes, notes and deletion will appear here. Coming in Batch 5 (T-403).',
  'budgetPageSubtitle': 'S-14 / S-15 · Budget list and details',
  'budgetPageBody': 'Category limits, a daily allowance and an 80% warning. Coming in Batch 6 (T-501).',
  'accountPageSubtitle': 'S-16 · Account list',
  'accountPageBody':
      'Balances for your bank, cash and wallet accounts. Coming in Batch 6.',
  'categoryPageSubtitle': 'S-13 · Category manager',
  'categoryPageBody': 'Create your own categories and choose their icons and colours. Coming in Batch 5 (T-405).',
  'searchPageSubtitle': 'S-18 · Search and filters',
  'searchPageBody': 'Find transactions by merchant, amount or date. Coming in Batch 5 (T-406).',
  'notFoundTitle': 'Page not found',
  'notFoundSubtitle': '404',
  'notFoundBody': 'Return to Home from Settings.',
  'txFilterAll': 'All',
  'txDelete': 'Delete',
  'txRecategorise': 'Change category',
  'txPickCategory': 'Which category?',
  'txDeleted': 'Deleted',
  'txUndo': 'Undo',
  'txSwipeHint': 'Swipe a row — left to delete, right to change its category.',
  'txMonthEmptyTitle': 'Nothing in this month',
  'txMonthEmptyBody': 'Pick another month, or clear the filter.',
  'planMonthly': 'Monthly',
  'planYearly': 'Yearly',
  'planLifetime': 'Lifetime',
  'planMonthlyNote': 'Per month',
  'planYearlyNote': 'Per year · 41% savings',
  'planLifetimeNote': 'One payment, forever',
  'featureNoAdsTitle': 'No ads',
  'featureNoAdsBody': 'Removes ads from Home, Budgets and Insights.',
  'featureUnlimitedBudgetsTitle': 'Unlimited budgets',
  'featureUnlimitedBudgetsBody':
      'Create as many category budgets as you need, each with alerts.',
  'featureForecastTitle': 'Spending forecast',
  'featureForecastBody':
      'See how much you are likely to spend by the end of the month.',
  'featureExportTitle': 'Exports and reports',
  'featureExportBody': 'Unlock CSV and PDF exports with a rewarded ad, or get them included with Pro.',
  'trialDisclaimer': '7 days free, cancel anytime.',
  'popular': 'Most popular',
  'proActive': 'Pro is active',
  'startTrial': 'Start your 7-day free trial',
  'proActivatedDemo': 'Demo: Pro is active and ads are hidden. Real billing is coming in Batch 7 (T-601).',
  'billingNotAvailable':
      'Payments are not connected yet. Billing is coming in Batch 7 (T-601).',
  'sourceAutoSms': 'Automatically added from SMS',
  'sourceAutoNotification': 'Automatically added from notification',
  'sourceRecurring': 'Recurring payment',
  'sourceManual': 'Added manually',
};

const Map<String, String> _hi = <String, String>{
  "ob1Title": "हर भुगतान खुद दर्ज हो जाएगा",
  "ob1Body": "SpendStory आपके बैंक के लेन-देन SMS और पेमेंट ऐप के नोटिफ़िकेशन पढ़कर खर्च खुद लिख लेता है। टाइप करने की ज़रूरत नहीं।",
  "ob1B1": "50 बैंक सेंडर के साथ काम करता है",
  "ob1B2": "लाख वाले अंक सही पढ़ता है",
  "ob1B3": "OTP कभी नहीं पढ़ता",
  "ob2Title": "पैसा कहाँ जा रहा है, साफ़ देखें",
  "ob2Body": "श्रेणी-दर-श्रेणी, महीने-दर-महीने — और वो एक आंकड़ा जो आदत बदलता है: बजट में कितना बचा है।",
  "ob2B1": "श्रेणी विभाजन और टॉप दुकानें",
  "ob2B2": "मासिक बजट, 80% पर चेतावनी",
  "ob2B3": "महीने के अंत का अनुमान",
  "ob3Title": "आपका डेटा फ़ोन में ही रहता है",
  "ob3Body": "कोई सर्वर नहीं, कोई अकाउंट नहीं, कोई लॉगिन नहीं। सब कुछ इसी डिवाइस पर रहता है।",
  "ob3B1": "कुछ भी अपलोड नहीं होता",
  "ob3B2": "कभी भी सब मिटा दें",
  "ob3B3": "बिना इंटरनेट भी चलता है",
  "obNext": "आगे",
  "obBack": "पीछे",
  "obSkip": "छोड़ें",
  "obStart": "शुरू करें",
  "permTitle": "बैंक के SMS पढ़ने दें?",
  "permWhy": "इसी से ऐप बिना टाइपिंग के खर्च दर्ज करता है। अगले स्टेप में Android अनुमति माँगेगा।",
  "permReads": "क्या पढ़ता है",
  "permReadsBody":
      "बैंक, कार्ड और वॉलेट के लेन-देन अलर्ट — रकम, दुकान और तारीख़।",
  "permNever": "क्या कभी नहीं छूता",
  "permNeverBody": "OTP, पासवर्ड, PIN और निजी मैसेज। OTP बाक़ी सब से पहले हटा दिया जाता है, और कोई मैसेज कहीं भेजा नहीं जाता।",
  "permAllow": "SMS पढ़ने दें",
  "permTryAgain": "फिर कोशिश करें",
  "permNotNow": "अभी नहीं",
  "permDenied": "कोई बात नहीं — खर्च हाथ से जोड़ सकते हैं, और बाद में सेटिंग्स से चालू कर सकते हैं।",
  "permWebNote": "वेब प्रीव्यू में पूछने के लिए कोई Android नहीं है — असली डायलॉग सिर्फ़ फ़ोन बिल्ड में आता है। आगे बढ़ने के लिए “अभी नहीं” दबाएँ।",
  "manualLink": "SMS की अनुमति नहीं देना चाहता",
  "notifTitle": "एक और, और ये ज़रूरी नहीं",
  "notifWhy": "Google Pay और PhonePe जैसे ऐप अपना नोटिफ़िकेशन भेजते हैं। अनुमति मिलने पर वो भी दर्ज होते हैं — वरना बैंक का SMS देर से आने पर UPI भुगतान छूट सकता है।",
  "notifOn": "नोटिफ़िकेशन एक्सेस चालू है",
  "notifOff": "नोटिफ़िकेशन एक्सेस बंद है",
  "notifApps": "सिर्फ़ ये छह ऐप देखे जाते हैं:",
  "notifOnlyThese": "बाक़ी सारे नोटिफ़िकेशन पूरी तरह नज़रअंदाज़ होते हैं। WhatsApp, ईमेल या निजी मैसेज SpendStory नहीं पढ़ता।",
  "notifOpen": "नोटिफ़िकेशन सेटिंग्स खोलें",
  "notifSkip": "छोड़ दें",
  "notifContinue": "आगे बढ़ें",
  "notifManualHint":
      "सेटिंग्स → नोटिफ़िकेशन → नोटिफ़िकेशन एक्सेस खोलकर SpendStory चालू करें।",
  "manualTitle": "हाथ से इस्तेमाल करें",
  "manualBody": "बिल्कुल ठीक — खाता, बजट और विश्लेषण खुद जोड़े गए खर्चों से भी पूरा चलता है। बाद में सेटिंग्स से कैप्चर चालू कर सकते हैं।",
  "manualP1": "तीन टैप में जोड़ें",
  "manualP1Body": "रकम, श्रेणी, हो गया।",
  "manualP2": "सब कुछ वैसे ही चलता है",
  "manualP2Body": "बजट, श्रेणियाँ, विश्लेषण, एक्सपोर्ट।",
  "manualP3": "बाद में कैप्चर चालू करें",
  "manualP3Body": "सेटिंग्स → SMS कैप्चर, कभी भी।",
  "manualStart": "SpendStory शुरू करें",
  "manualBack": "नहीं, SMS की अनुमति देता हूँ",
  'appName': 'SpendStory',
  'appTagline': 'आपके पैसों की कहानी, आपके फ़ोन पर',
  'greeting': 'नमस्ते',
  'heroLabel': 'इस महीने का खर्च',
  'income': 'आय',
  'expense': 'खर्च',
  'recentTx': 'हाल के लेन-देन',
  'seeAll': 'सभी देखें',
  'addTx': 'जोड़ें',
  'budget': 'बजट',
  'categories': 'श्रेणियाँ',
  'reports': 'रिपोर्ट',
  'vsLastMonth': 'पिछले महीने से',
  'monthlyBudget': 'मासिक बजट',
  'budgetLeft': 'बचा',
  'over': 'ज़्यादा',
  'txTitle': 'लेन-देन',
  'insights': 'विश्लेषण',
  'settings': 'सेटिंग्स',
  'appearance': 'रूप',
  'theme': 'थीम',
  'themeSystem': 'सिस्टम',
  'themeLight': 'लाइट',
  'themeDark': 'डार्क',
  'language': 'भाषा',
  'languagePrompt': 'तीन भाषाओं में उपलब्ध — आप इसे कभी भी बदल सकते हैं।',
  'start': 'शुरू करें',
  'home': 'होम',
  'uncategorised': 'बिना श्रेणी',
  'thisMonth': 'इस महीने',
  'trend': 'पिछले 6 महीने',
  'topCategories': 'पैसा कहाँ गया',
  'noDataTitle': 'अभी कुछ नहीं',
  'noDataBody': 'खर्च करते ही लेन-देन यहाँ दिखेंगे।',
  'addFirst': 'पहला जोड़ें',
  'emptyTxTitle': 'अभी कोई लेन-देन नहीं',
  'emptyTxBody': 'SMS कैप्चर चालू करें — हर भुगतान खुद दर्ज हो जाएगा।',
  'demoBanner': 'वेब प्रीव्यू',
  'demoBannerBody':
      'डेमो डेटा। फ़ोन बिल्ड आपके बैंक SMS पढ़ता है — सिर्फ़ डिवाइस पर।',
  'about': 'SpendStory के बारे में',
  'aboutBody': 'आपका डेटा फ़ोन से बाहर नहीं जाता',
  'privacy': 'प्राइवेसी',
  'privacyBody': 'सिर्फ़ बैंक SMS पढ़ता है। कभी अपलोड नहीं।',
  'privacyDetails': 'SpendStory सिर्फ़ बैंक लेन-देन के SMS पढ़ता है — OTP कभी नहीं। आपका डेटा किसी सर्वर पर नहीं भेजा जाता और किसी खाते की ज़रूरत नहीं है। ऐप हटाने पर उसका डेटा भी फ़ोन से मिट जाता है।',
  'privacyOnDevice': '100% डिवाइस पर',
  'version': 'वर्ज़न',
  'proTitle': 'SpendStory Pro',
  'proBody': 'कोई विज्ञापन नहीं, असीमित बजट, खर्च का अनुमान',
  'search': 'खोजें',
  'accounts': 'खाते',
  'savings': 'बचत',
  'comingSoon': 'अगले बैच में',
  'comingSoonBody':
      'यह स्क्रीन बैच 4–6 में बनेगी। शेल, थीम और डेमो डेटा अब चालू है।',
  'adLabel': 'विज्ञापन',
  'adBanner': 'बैनर',
  'adNative': 'नेटिव',
  'unknownCategory': 'अज्ञात',
  'budgetExceeded': 'बजट पार हो गया — खर्च कम करने का समय है।',
  'forecast': 'महीने के अंत तक अनुमानित खर्च',
  'addEditUnavailable': 'लेन-देन जोड़ना और बदलना जल्द उपलब्ध होगा।',
  'activeNoAds': 'चालू · विज्ञापन नहीं',
  'budgetSettingBody': 'श्रेणी के अनुसार मासिक सीमा तय करें',
  'categoriesSettingBody': 'अपनी श्रेणियाँ बनाएँ',
  'accountsSettingBody': 'बैंक · नकद · वॉलेट',
  'deleteAllData': 'सारा डेटा मिटाएँ',
  'deleteAllDataSubtitle': 'दो बार पुष्टि के बाद सब कुछ हमेशा के लिए मिट जाएगा',
  'eraseTitle': 'सारा डेटा मिटाएँ?',
  'eraseBody':
      'सभी लेन-देन, बजट और श्रेणियाँ मिट जाएँगी। इसे वापस नहीं लाया जा सकता।',
  'keep': 'रहने दें',
  'erase': 'मिटाएँ',
  'confirm': 'क्या आप पक्का चाहते हैं?',
  'lastChance': 'आख़िरी मौका — इसके बाद सब कुछ मिट जाएगा।',
  'no': 'नहीं',
  'yesErase': 'हाँ, सब मिटाएँ',
  'demoEraseUnavailable': 'डेमो मोड में डेटा मिटाना बंद है। डेटा मिटाने के लिए फ़ोन ऐप इस्तेमाल करें।',
  'transactionDetailTitle': 'लेन-देन का विवरण',
  'transactionDetailSubtitle': 'S-11 · लेन-देन का विवरण',
  'transactionDetailBody': 'मूल SMS, श्रेणी बदलना, नोट जोड़ना और हटाना — सब यहाँ होगा। बैच 5 (T-403) में आ रहा है।',
  'budgetPageSubtitle': 'S-14 / S-15 · बजट सूची और विवरण',
  'budgetPageBody':
      'श्रेणी की सीमा, रोज़ का भत्ता और 80% पर चेतावनी। बैच 6 (T-501) में।',
  'accountPageSubtitle': 'S-16 · खाते की सूची',
  'accountPageBody':
      'बैंक, नकद और वॉलेट खातों का बैलेंस यहाँ दिखेगा। बैच 6 में।',
  'categoryPageSubtitle': 'S-13 · श्रेणी प्रबंधन',
  'categoryPageBody':
      'अपनी श्रेणियाँ बनाएँ और उनके आइकन व रंग चुनें। बैच 5 (T-405) में।',
  'searchPageSubtitle': 'S-18 · खोज और फ़िल्टर',
  'searchPageBody': 'दुकान, रकम या तारीख से लेन-देन खोजें। बैच 5 (T-406) में।',
  'notFoundTitle': 'पेज नहीं मिला',
  'notFoundSubtitle': '404',
  'notFoundBody': 'सेटिंग्स से होम पर लौटें।',
  'txFilterAll': 'सभी',
  'txDelete': 'मिटाएँ',
  'txRecategorise': 'श्रेणी बदलें',
  'txPickCategory': 'कौन सी श्रेणी?',
  'txDeleted': 'मिटा दिया',
  'txUndo': 'वापस लाएँ',
  'txSwipeHint':
      'पंक्ति खिसकाएँ — बाएँ मिटाने के लिए, दाएँ श्रेणी बदलने के लिए।',
  'txMonthEmptyTitle': 'इस महीने कुछ नहीं',
  'txMonthEmptyBody': 'दूसरा महीना चुनें, या फ़िल्टर हटाएँ।',
  'planMonthly': 'मासिक',
  'planYearly': 'सालाना',
  'planLifetime': 'लाइफ़टाइम',
  'planMonthlyNote': 'हर महीने',
  'planYearlyNote': 'हर साल · 41% की बचत',
  'planLifetimeNote': 'एक बार भुगतान, हमेशा के लिए',
  'featureNoAdsTitle': 'कोई विज्ञापन नहीं',
  'featureNoAdsBody': 'होम, बजट और विश्लेषण से विज्ञापन हट जाएँगे।',
  'featureUnlimitedBudgetsTitle': 'असीमित बजट',
  'featureUnlimitedBudgetsBody':
      'जितनी चाहें श्रेणी-बजट बनाएँ, हर एक के लिए अलर्ट के साथ।',
  'featureForecastTitle': 'खर्च का अनुमान',
  'featureForecastBody': 'महीने के अंत तक संभावित खर्च पहले से जानें।',
  'featureExportTitle': 'एक्सपोर्ट और रिपोर्ट',
  'featureExportBody':
      'रिवॉर्डेड विज्ञापन से CSV और PDF अनलॉक करें या Pro में सीधे पाएँ।',
  'trialDisclaimer': '7 दिन मुफ़्त, कभी भी रद्द करें।',
  'popular': 'सबसे लोकप्रिय',
  'proActive': 'Pro चालू है',
  'startTrial': '7 दिन का मुफ़्त ट्रायल शुरू करें',
  'proActivatedDemo': 'डेमो: Pro चालू है और विज्ञापन छिप गए हैं। असली बिलिंग बैच 7 (T-601) में आएगी।',
  'billingNotAvailable':
      'भुगतान अभी नहीं जुड़े हैं। बिलिंग बैच 7 (T-601) में आएगी।',
  'sourceAutoSms': 'SMS से अपने आप जोड़ा गया',
  'sourceAutoNotification': 'सूचना से अपने आप जोड़ा गया',
  'sourceRecurring': 'नियमित भुगतान',
  'sourceManual': 'खुद जोड़ा गया',
};

const Map<String, String> _bn = <String, String>{
  "ob1Title": "প্রতিটা খরচ নিজে থেকে জমা হবে",
  "ob1Body": "SpendStory আপনার ব্যাঙ্কের লেনদেন SMS আর পেমেন্ট অ্যাপের নোটিফিকেশন পড়ে খরচ নিজেই লিখে রাখে। টাইপ করার দরকার নেই।",
  "ob1B1": "৫০টি ব্যাঙ্ক সেন্ডার সাপোর্ট করে",
  "ob1B2": "লাখ-ফরম্যাটের অঙ্কও ঠিক পড়ে",
  "ob1B3": "OTP কখনো পড়ে না, একবারও না",
  "ob2Title": "টাকা কোথায় যাচ্ছে, স্পষ্ট দেখুন",
  "ob2Body": "ক্যাটাগরি ধরে, মাস ধরে — আর সেই একটা সংখ্যা যা অভ্যাস বদলায়: বাজেটে কত বাকি।",
  "ob2B1": "ক্যাটাগরি ভাগ আর টপ দোকান",
  "ob2B2": "মাসিক বাজেট, ৮০% এ সতর্কতা",
  "ob2B3": "মাস শেষে কত হবে তার পূর্বাভাস",
  "ob3Title": "আপনার ডেটা ফোনেই থাকে",
  "ob3Body": "কোনো সার্ভার নেই, কোনো অ্যাকাউন্ট নেই, কোনো লগইন নেই। সব এই ডিভাইসেই জমা থাকে।",
  "ob3B1": "একটা বাইটও কোথাও যায় না",
  "ob3B2": "যেকোনো সময় সব মুছে ফেলুন",
  "ob3B3": "ইন্টারনেট ছাড়াও চলে",
  "obNext": "পরেরটা",
  "obBack": "পিছনে",
  "obSkip": "এড়িয়ে যান",
  "obStart": "শুরু করুন",
  "permTitle": "ব্যাঙ্কের SMS পড়ার অনুমতি দেবেন?",
  "permWhy": "এই ভাবেই অ্যাপটা আপনাকে দিয়ে কিছু টাইপ না করিয়েই খরচ জমা করে। পরের ধাপে Android অনুমতি চাইবে।",
  "permReads": "কী পড়ে",
  "permReadsBody": "ব্যাঙ্ক, কার্ড আর ওয়ালেটের লেনদেন অ্যালার্ট — টাকার অঙ্ক, দোকান আর তারিখ।",
  "permNever": "কী কখনো ছোঁয় না",
  "permNeverBody": "OTP, পাসওয়ার্ড, PIN আর ব্যক্তিগত মেসেজ। OTP আর কিছু দেখার আগেই বাদ পড়ে যায়, আর কোনো মেসেজ কোথাও পাঠানো হয় না।",
  "permAllow": "SMS পড়ার অনুমতি দিন",
  "permTryAgain": "আবার চেষ্টা করুন",
  "permNotNow": "এখন নয়",
  "permDenied": "সমস্যা নেই — হাতে খরচ যোগ করতে পারবেন, আর পরে সেটিংস থেকে চালু করতে পারবেন।",
  "permWebNote": "ওয়েব প্রিভিউতে জিজ্ঞেস করার মতো কোনো Android নেই — আসল ডায়ালগ শুধু ফোনের বিল্ডে আসে। এগিয়ে যেতে “এখন নয়” চাপুন।",
  "manualLink": "আমি SMS-এর অনুমতি দিতে চাই না",
  "notifTitle": "আর একটা — এটা নিতান্তই ঐচ্ছিক",
  "notifWhy": "Google Pay, PhonePe-র মতো অ্যাপ নিজের নোটিফিকেশন পাঠায়। অনুমতি থাকলে সেগুলোও জমা হয় — নইলে ব্যাঙ্কের SMS দেরি হলে একটা UPI পেমেন্ট বাদ পড়ে যেতে পারে।",
  "notifOn": "নোটিফিকেশন অ্যাক্সেস চালু আছে",
  "notifOff": "নোটিফিকেশন অ্যাক্সেস বন্ধ আছে",
  "notifApps": "শুধু এই ছয়টা অ্যাপ দেখা হয়:",
  "notifOnlyThese": "বাকি সব নোটিফিকেশন সম্পূর্ণ উপেক্ষা করা হয়। WhatsApp, ইমেল বা ব্যক্তিগত মেসেজ SpendStory পড়ে না।",
  "notifOpen": "নোটিফিকেশন সেটিংস খুলুন",
  "notifSkip": "এড়িয়ে যান",
  "notifContinue": "এগিয়ে যান",
  "notifManualHint":
      "সেটিংস → নোটিফিকেশন → নোটিফিকেশন অ্যাক্সেস খুলে SpendStory চালু করুন।",
  "manualTitle": "হাতে হাতে চালান",
  "manualBody": "একদম ঠিক আছে — খাতা, বাজেট আর বিশ্লেষণ সব নিজে যোগ করা খরচ দিয়েই পুরোপুরি চলে। পরে সেটিংস থেকে ক্যাপচার চালু করতে পারবেন।",
  "manualP1": "তিন ট্যাপে যোগ",
  "manualP1Body": "অঙ্ক, ক্যাটাগরি, হয়ে গেল।",
  "manualP2": "সব কিছুই চলে",
  "manualP2Body": "বাজেট, ক্যাটাগরি, বিশ্লেষণ, এক্সপোর্ট।",
  "manualP3": "পরে ক্যাপচার চালু করুন",
  "manualP3Body": "সেটিংস → SMS ক্যাপচার, যখন খুশি।",
  "manualStart": "SpendStory শুরু করুন",
  "manualBack": "না, আমাকে SMS-এর অনুমতি দিতে দিন",
  'appName': 'SpendStory',
  'appTagline': 'তোমার টাকার গল্প, তোমার ফোনেই',
  'greeting': 'নমস্কার',
  'heroLabel': 'এই মাসের খরচ',
  'income': 'আয়',
  'expense': 'খরচ',
  'recentTx': 'সাম্প্রতিক লেনদেন',
  'seeAll': 'সব দেখুন',
  'addTx': 'যোগ করুন',
  'budget': 'বাজেট',
  'categories': 'ক্যাটাগরি',
  'reports': 'রিপোর্ট',
  'vsLastMonth': 'গত মাসের তুলনায়',
  'monthlyBudget': 'মাসিক বাজেট',
  'budgetLeft': 'বাকি',
  'over': 'বেশি',
  'txTitle': 'লেনদেন',
  'insights': 'বিশ্লেষণ',
  'settings': 'সেটিংস',
  'appearance': 'চেহারা',
  'theme': 'থিম',
  'themeSystem': 'সিস্টেম',
  'themeLight': 'লাইট',
  'themeDark': 'ডার্ক',
  'language': 'ভাষা',
  'languagePrompt':
      'তিনটি ভাষায় ব্যবহার করা যায় — যেকোনো সময় বদলাতে পারবেন।',
  'start': 'শুরু করুন',
  'home': 'হোম',
  'uncategorised': 'বিনা ক্যাটাগরি',
  'thisMonth': 'এই মাসে',
  'trend': 'গত ৬ মাস',
  'topCategories': 'টাকা কোথায় গেল',
  'noDataTitle': 'এখনো কিছু নেই',
  'noDataBody': 'খরচ করলেই লেনদেন এখানে এসে জমা হবে।',
  'addFirst': 'প্রথমটা যোগ করুন',
  'emptyTxTitle': 'এখনো কোনো লেনদেন নেই',
  'emptyTxBody': 'SMS ক্যাপচার চালু করলে প্রতিটা পেমেন্ট নিজে থেকে জমা হবে।',
  'demoBanner': 'ওয়েব প্রিভিউ',
  'demoBannerBody':
      'ডেমো ডেটা। ফোনের অ্যাপ আপনার ব্যাঙ্ক SMS পড়ে — শুধু ডিভাইসেই।',
  'about': 'SpendStory সম্পর্কে',
  'aboutBody': 'আপনার ডেটা ফোন থেকে বেরোয় না',
  'privacy': 'প্রাইভেসি',
  'privacyBody': 'শুধু ব্যাঙ্কের SMS পড়ে। কখনো আপলোড হয় না।',
  'privacyDetails': 'SpendStory শুধু ব্যাঙ্কের লেনদেনের SMS পড়ে — OTP কখনো নয়। কোনো ডেটা সার্ভারে পাঠানো হয় না, অ্যাকাউন্টও লাগে না। অ্যাপ আনইনস্টল করলে ফোন থেকে সব ডেটা মুছে যাবে।',
  'privacyOnDevice': '১০০% ডিভাইসেই',
  'version': 'ভার্সন',
  'proTitle': 'SpendStory Pro',
  'proBody': 'বিজ্ঞাপন নেই, যত খুশি বাজেট, খরচের পূর্বাভাস',
  'search': 'খুঁজুন',
  'accounts': 'অ্যাকাউন্ট',
  'savings': 'সঞ্চয়',
  'comingSoon': 'পরের ব্যাচে আসছে',
  'comingSoonBody':
      'এই স্ক্রিনটা ব্যাচ ৪–৬ এ বানবে। এখন শেল, থিম আর ডেমো ডেটা চালু।',
  'adLabel': 'বিজ্ঞাপন',
  'adBanner': 'ব্যানার',
  'adNative': 'নেটিভ',
  'unknownCategory': 'অজানা',
  'budgetExceeded': 'বাজেট ছাড়িয়ে গেছেন — খরচ কমানোর সময়।',
  'forecast': 'মাসের শেষে আনুমানিক খরচ',
  'addEditUnavailable': 'লেনদেন যোগ করা আর বদলানোর সুবিধা শিগগিরই আসছে।',
  'activeNoAds': 'চালু · বিজ্ঞাপন নেই',
  'budgetSettingBody': 'ক্যাটাগরি অনুযায়ী মাসিক সীমা ঠিক করুন',
  'categoriesSettingBody': 'নিজের ক্যাটাগরি তৈরি করুন',
  'accountsSettingBody': 'ব্যাঙ্ক · ক্যাশ · ওয়ালেট',
  'deleteAllData': 'সব ডেটা মুছুন',
  'deleteAllDataSubtitle': 'দুবার নিশ্চিত করার পর সবকিছু চিরতরে মুছে যাবে',
  'eraseTitle': 'সব ডেটা মুছবেন?',
  'eraseBody': 'সব লেনদেন, বাজেট আর ক্যাটাগরি মুছে যাবে। এটি ফেরানো যাবে না।',
  'keep': 'থাক',
  'erase': 'মুছুন',
  'confirm': 'নিশ্চিত?',
  'lastChance': 'শেষ সুযোগ — এরপর সবকিছু মুছে যাবে।',
  'no': 'না',
  'yesErase': 'হ্যাঁ, সব মুছুন',
  'demoEraseUnavailable':
      'ডেমো মোডে ডেটা মোছা বন্ধ। ডেটা মুছতে ফোনের অ্যাপ ব্যবহার করুন।',
  'transactionDetailTitle': 'লেনদেনের বিস্তারিত',
  'transactionDetailSubtitle': 'S-11 · লেনদেনের বিস্তারিত',
  'transactionDetailBody': 'SMS-এর মূল লেখা, ক্যাটাগরি বদল, নোট যোগ আর মুছে ফেলা — সব এখানে থাকবে। ব্যাচ ৫ (T-403) এ আসছে।',
  'budgetPageSubtitle': 'S-14 / S-15 · বাজেটের তালিকা ও বিস্তারিত',
  'budgetPageBody': 'ক্যাটাগরি ধরে সীমা, দৈনিক ভাতা আর ৮০% হলে সতর্কতা। ব্যাচ ৬ (T-501) এ আসছে।',
  'accountPageSubtitle': 'S-16 · অ্যাকাউন্টের তালিকা',
  'accountPageBody': 'ব্যাঙ্ক, ক্যাশ আর ওয়ালেট অ্যাকাউন্টের ব্যালান্স এখানে দেখা যাবে। ব্যাচ ৬ এ আসছে।',
  'categoryPageSubtitle': 'S-13 · ক্যাটাগরি ম্যানেজার',
  'categoryPageBody':
      'নিজের ক্যাটাগরি তৈরি করুন, আইকন আর রং বেছে নিন। ব্যাচ ৫ (T-405) এ আসছে।',
  'searchPageSubtitle': 'S-18 · সার্চ ও ফিল্টার',
  'searchPageBody': 'মার্চেন্ট, টাকার অঙ্ক বা তারিখ দিয়ে লেনদেন খুঁজুন। ব্যাচ ৫ (T-406) এ আসছে।',
  'notFoundTitle': 'পাতা খুঁজে পাওয়া গেল না',
  'notFoundSubtitle': '404',
  'notFoundBody': 'সেটিংস থেকে হোমে ফিরে যান।',
  'txFilterAll': 'সব',
  'txDelete': 'মুছুন',
  'txRecategorise': 'ক্যাটাগরি বদলান',
  'txPickCategory': 'কোন ক্যাটাগরি?',
  'txDeleted': 'মুছে ফেলা হয়েছে',
  'txUndo': 'ফিরিয়ে আনুন',
  'txSwipeHint': 'সারি সোয়াইপ করুন — বাঁয়ে মুছতে, ডানে ক্যাটাগরি বদলাতে।',
  'txMonthEmptyTitle': 'এই মাসে কিছু নেই',
  'txMonthEmptyBody': 'অন্য মাস বাছুন, বা ফিল্টার সরান।',
  'planMonthly': 'মাসিক',
  'planYearly': 'বার্ষিক',
  'planLifetime': 'লাইফটাইম',
  'planMonthlyNote': 'প্রতি মাসে',
  'planYearlyNote': 'প্রতি বছরে · ৪১% সাশ্রয়',
  'planLifetimeNote': 'একবার, চিরদিনের জন্য',
  'featureNoAdsTitle': 'বিজ্ঞাপন নেই',
  'featureNoAdsBody': 'হোম, বাজেট আর ইনসাইট থেকে বিজ্ঞাপন সরে যাবে।',
  'featureUnlimitedBudgetsTitle': 'আনলিমিটেড বাজেট',
  'featureUnlimitedBudgetsBody':
      'যত খুশি ক্যাটাগরি-বাজেট তৈরি করুন, প্রতিটায় অ্যালার্টসহ।',
  'featureForecastTitle': 'খরচের পূর্বাভাস',
  'featureForecastBody': 'মাস শেষে কত খরচ হতে পারে, আগেই জেনে নিন।',
  'featureExportTitle': 'এক্সপোর্ট ও রিপোর্ট',
  'featureExportBody':
      'Rewarded ad দেখে CSV ও PDF আনলক করুন, অথবা Pro-তে সরাসরি পান।',
  'trialDisclaimer': '৭ দিন ফ্রি, যেকোনো সময় বাতিল করুন।',
  'popular': 'সবচেয়ে জনপ্রিয়',
  'proActive': 'Pro চালু আছে',
  'startTrial': '৭ দিনের ফ্রি ট্রায়াল শুরু করুন',
  'proActivatedDemo': 'ডেমো: Pro চালু হয়েছে, বিজ্ঞাপন লুকানো। আসল বিলিং ব্যাচ ৭ (T-601) এ আসছে।',
  'billingNotAvailable':
      'পেমেন্ট এখনো যুক্ত হয়নি। বিলিং ব্যাচ ৭ (T-601) এ আসছে।',
  'sourceAutoSms': 'SMS থেকে নিজে থেকেই যোগ হয়েছে',
  'sourceAutoNotification': 'নোটিফিকেশন থেকে নিজে থেকেই যোগ হয়েছে',
  'sourceRecurring': 'নিয়মিত পেমেন্ট',
  'sourceManual': 'নিজে যোগ করা',
};
