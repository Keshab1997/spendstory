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
