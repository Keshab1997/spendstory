/// Interim trilingual strings.
///
/// This is deliberately **not** the final localization layer. Batch 8 (T-701)
/// replaces it with `flutter_localizations` + ARB files and a generated
/// `AppLocalizations`, which is what the store listing and the CI locale checks
/// will be built on. It exists now so that the shell can be *seen* in all three
/// languages — Bengali first — while the rest of the app is being built, and so
/// a missing string is a visible gap rather than an English leak.
///
/// Every key must exist in all three languages; [SsStrings.missingKeys] is
/// asserted by a test so this cannot silently rot.
library;

class SsStrings {
  const SsStrings(this.locale);

  /// `en` | `hi` | `bn`
  final String locale;

  static const List<String> supportedLocales = <String>['bn', 'en', 'hi'];

  static const Map<String, Map<String, String>> _table =
      <String, Map<String, String>>{'en': _en, 'hi': _hi, 'bn': _bn};

  String operator [](String key) =>
      _table[locale]?[key] ?? _table['en']?[key] ?? key;

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
  'version': 'Version',
  'proTitle': 'SpendStory Pro',
  'proBody': 'No ads, unlimited budgets, forecast',
  'search': 'Search',
  'accounts': 'Accounts',
  'savings': 'Net saved',
  'comingSoon': 'Coming in the next batch',
  'comingSoonBody': 'This screen is built in Batch 4–6. The shell, theme and demo data are live now.',
};

const Map<String, String> _hi = <String, String>{
  'appName': 'SpendStory',
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
  'version': 'वर्ज़न',
  'proTitle': 'SpendStory Pro',
  'proBody': 'कोई विज्ञापन नहीं, अनलिमिटेड बजट, फ़ोरकास्ट',
  'search': 'खोजें',
  'accounts': 'खाते',
  'savings': 'बचत',
  'comingSoon': 'अगले बैच में',
  'comingSoonBody':
      'यह स्क्रीन बैच 4–6 में बनेगी। शेल, थीम और डेमो डेटा अब चालू है।',
};

const Map<String, String> _bn = <String, String>{
  'appName': 'SpendStory',
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
  'version': 'ভার্সন',
  'proTitle': 'SpendStory Pro',
  'proBody': 'বিজ্ঞাপন নেই, আনলিমিটেড বাজেট, পূর্বাভাস',
  'search': 'খুঁজুন',
  'accounts': 'অ্যাকাউন্ট',
  'savings': 'সঞ্চয়',
  'comingSoon': 'পরের ব্যাচে আসছে',
  'comingSoonBody':
      'এই স্ক্রিনটা ব্যাচ ৪–৬ এ বানবে। এখন শেল, থিম আর ডেমো ডেটা চালু।',
};
