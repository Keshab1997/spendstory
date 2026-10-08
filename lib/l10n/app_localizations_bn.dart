// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get ob1Title => 'প্রতিটা খরচ নিজে থেকে জমা হবে';

  @override
  String get ob1Body =>
      'SpendStory আপনার ব্যাঙ্কের লেনদেন SMS আর পেমেন্ট অ্যাপের নোটিফিকেশন পড়ে খরচ নিজেই লিখে রাখে। টাইপ করার দরকার নেই।';

  @override
  String get ob1B1 => '৫০টি ব্যাঙ্ক সেন্ডার সাপোর্ট করে';

  @override
  String get ob1B2 => 'লাখ-ফরম্যাটের অঙ্কও ঠিক পড়ে';

  @override
  String get ob1B3 => 'OTP কখনো পড়ে না, একবারও না';

  @override
  String get ob2Title => 'টাকা কোথায় যাচ্ছে, স্পষ্ট দেখুন';

  @override
  String get ob2Body =>
      'ক্যাটাগরি ধরে, মাস ধরে — আর সেই একটা সংখ্যা যা অভ্যাস বদলায়: বাজেটে কত বাকি।';

  @override
  String get ob2B1 => 'ক্যাটাগরি ভাগ আর টপ দোকান';

  @override
  String get ob2B2 => 'মাসিক বাজেট, ৮০% এ সতর্কতা';

  @override
  String get ob2B3 => 'মাস শেষে কত হবে তার পূর্বাভাস';

  @override
  String get ob3Title => 'আপনার ডেটা ফোনেই থাকে';

  @override
  String get ob3Body =>
      'কোনো সার্ভার নেই, কোনো অ্যাকাউন্ট নেই, কোনো লগইন নেই। সব এই ডিভাইসেই জমা থাকে।';

  @override
  String get ob3B1 => 'একটা বাইটও কোথাও যায় না';

  @override
  String get ob3B2 => 'যেকোনো সময় সব মুছে ফেলুন';

  @override
  String get ob3B3 => 'ইন্টারনেট ছাড়াও চলে';

  @override
  String get obNext => 'পরেরটা';

  @override
  String get obBack => 'পিছনে';

  @override
  String get obSkip => 'এড়িয়ে যান';

  @override
  String get obStart => 'শুরু করুন';

  @override
  String get permTitle => 'ব্যাঙ্কের SMS পড়ার অনুমতি দেবেন?';

  @override
  String get permWhy =>
      'এই ভাবেই অ্যাপটা আপনাকে দিয়ে কিছু টাইপ না করিয়েই খরচ জমা করে। পরের ধাপে Android অনুমতি চাইবে।';

  @override
  String get permReads => 'কী পড়ে';

  @override
  String get permReadsBody =>
      'ব্যাঙ্ক, কার্ড আর ওয়ালেটের লেনদেন অ্যালার্ট — টাকার অঙ্ক, দোকান আর তারিখ।';

  @override
  String get permNever => 'কী কখনো ছোঁয় না';

  @override
  String get permNeverBody =>
      'OTP, পাসওয়ার্ড, PIN আর ব্যক্তিগত মেসেজ। OTP আর কিছু দেখার আগেই বাদ পড়ে যায়, আর কোনো মেসেজ কোথাও পাঠানো হয় না।';

  @override
  String get permAllow => 'SMS পড়ার অনুমতি দিন';

  @override
  String get permTryAgain => 'আবার চেষ্টা করুন';

  @override
  String get permNotNow => 'এখন নয়';

  @override
  String get permDenied =>
      'সমস্যা নেই — হাতে খরচ যোগ করতে পারবেন, আর পরে সেটিংস থেকে চালু করতে পারবেন।';

  @override
  String get permWebNote =>
      'ওয়েব প্রিভিউতে জিজ্ঞেস করার মতো কোনো Android নেই — আসল ডায়ালগ শুধু ফোনের বিল্ডে আসে। এগিয়ে যেতে “এখন নয়” চাপুন।';

  @override
  String get manualLink => 'আমি SMS-এর অনুমতি দিতে চাই না';

  @override
  String get notifTitle => 'আর একটা — এটা নিতান্তই ঐচ্ছিক';

  @override
  String get notifWhy =>
      'Google Pay, PhonePe-র মতো অ্যাপ নিজের নোটিফিকেশন পাঠায়। অনুমতি থাকলে সেগুলোও জমা হয় — নইলে ব্যাঙ্কের SMS দেরি হলে একটা UPI পেমেন্ট বাদ পড়ে যেতে পারে।';

  @override
  String get notifOn => 'নোটিফিকেশন অ্যাক্সেস চালু আছে';

  @override
  String get notifOff => 'নোটিফিকেশন অ্যাক্সেস বন্ধ আছে';

  @override
  String get notifApps => 'শুধু এই ছয়টা অ্যাপ দেখা হয়:';

  @override
  String get notifOnlyThese =>
      'বাকি সব নোটিফিকেশন সম্পূর্ণ উপেক্ষা করা হয়। WhatsApp, ইমেল বা ব্যক্তিগত মেসেজ SpendStory পড়ে না।';

  @override
  String get notifOpen => 'নোটিফিকেশন সেটিংস খুলুন';

  @override
  String get notifSkip => 'এড়িয়ে যান';

  @override
  String get notifContinue => 'এগিয়ে যান';

  @override
  String get notifManualHint =>
      'সেটিংস → নোটিফিকেশন → নোটিফিকেশন অ্যাক্সেস খুলে SpendStory চালু করুন।';

  @override
  String get manualTitle => 'হাতে হাতে চালান';

  @override
  String get manualBody =>
      'একদম ঠিক আছে — খাতা, বাজেট আর বিশ্লেষণ সব নিজে যোগ করা খরচ দিয়েই পুরোপুরি চলে। পরে সেটিংস থেকে ক্যাপচার চালু করতে পারবেন।';

  @override
  String get manualP1 => 'তিন ট্যাপে যোগ';

  @override
  String get manualP1Body => 'অঙ্ক, ক্যাটাগরি, হয়ে গেল।';

  @override
  String get manualP2 => 'সব কিছুই চলে';

  @override
  String get manualP2Body => 'বাজেট, ক্যাটাগরি, বিশ্লেষণ, এক্সপোর্ট।';

  @override
  String get manualP3 => 'পরে ক্যাপচার চালু করুন';

  @override
  String get manualP3Body => 'সেটিংস → SMS ক্যাপচার, যখন খুশি।';

  @override
  String get manualStart => 'SpendStory শুরু করুন';

  @override
  String get manualBack => 'না, আমাকে SMS-এর অনুমতি দিতে দিন';

  @override
  String get appName => 'SpendStory';

  @override
  String get appTagline => 'তোমার টাকার গল্প, তোমার ফোনেই';

  @override
  String get greeting => 'নমস্কার';

  @override
  String get heroLabel => 'এই মাসের খরচ';

  @override
  String get income => 'আয়';

  @override
  String get expense => 'খরচ';

  @override
  String get recentTx => 'সাম্প্রতিক লেনদেন';

  @override
  String get seeAll => 'সব দেখুন';

  @override
  String get addTx => 'যোগ করুন';

  @override
  String get budget => 'বাজেট';

  @override
  String get categories => 'ক্যাটাগরি';

  @override
  String get reports => 'রিপোর্ট';

  @override
  String get vsLastMonth => 'গত মাসের তুলনায়';

  @override
  String get monthlyBudget => 'মাসিক বাজেট';

  @override
  String get budgetLeft => 'বাকি';

  @override
  String get over => 'বেশি';

  @override
  String get txTitle => 'লেনদেন';

  @override
  String get insights => 'বিশ্লেষণ';

  @override
  String get settings => 'সেটিংস';

  @override
  String get appearance => 'চেহারা';

  @override
  String get theme => 'থিম';

  @override
  String get themeSystem => 'সিস্টেম';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get language => 'ভাষা';

  @override
  String get languagePrompt =>
      'তিনটি ভাষায় ব্যবহার করা যায় — যেকোনো সময় বদলাতে পারবেন।';

  @override
  String get start => 'শুরু করুন';

  @override
  String get home => 'হোম';

  @override
  String get uncategorised => 'বিনা ক্যাটাগরি';

  @override
  String get thisMonth => 'এই মাসে';

  @override
  String get trend => 'গত ৬ মাস';

  @override
  String get topCategories => 'টাকা কোথায় গেল';

  @override
  String get noDataTitle => 'এখনো কিছু নেই';

  @override
  String get noDataBody => 'খরচ করলেই লেনদেন এখানে এসে জমা হবে।';

  @override
  String get addFirst => 'প্রথমটা যোগ করুন';

  @override
  String get emptyTxTitle => 'এখনো কোনো লেনদেন নেই';

  @override
  String get emptyTxBody =>
      'SMS ক্যাপচার চালু করলে প্রতিটা পেমেন্ট নিজে থেকে জমা হবে।';

  @override
  String get demoBanner => 'ওয়েব প্রিভিউ';

  @override
  String get demoBannerBody =>
      'ডেমো ডেটা। ফোনের অ্যাপ আপনার ব্যাঙ্ক SMS পড়ে — শুধু ডিভাইসেই।';

  @override
  String get about => 'SpendStory সম্পর্কে';

  @override
  String get aboutBody => 'আপনার ডেটা ফোন থেকে বেরোয় না';

  @override
  String get privacy => 'প্রাইভেসি';

  @override
  String get privacyBody => 'শুধু ব্যাঙ্কের SMS পড়ে। কখনো আপলোড হয় না।';

  @override
  String get privacyDetails =>
      'SpendStory শুধু ব্যাঙ্কের লেনদেনের SMS পড়ে — OTP কখনো নয়। কোনো ডেটা সার্ভারে পাঠানো হয় না, অ্যাকাউন্টও লাগে না। অ্যাপ আনইনস্টল করলে ফোন থেকে সব ডেটা মুছে যাবে।';

  @override
  String get privacyOnDevice => '১০০% ডিভাইসেই';

  @override
  String get version => 'ভার্সন';

  @override
  String get proTitle => 'SpendStory Pro';

  @override
  String get proBody => 'বিজ্ঞাপন নেই, যত খুশি বাজেট, খরচের পূর্বাভাস';

  @override
  String get search => 'খুঁজুন';

  @override
  String get accounts => 'অ্যাকাউন্ট';

  @override
  String get savings => 'সঞ্চয়';

  @override
  String get comingSoon => 'পরের ব্যাচে আসছে';

  @override
  String get comingSoonBody =>
      'এই স্ক্রিনটা ব্যাচ ৪–৬ এ বানবে। এখন শেল, থিম আর ডেমো ডেটা চালু।';

  @override
  String get adLabel => 'বিজ্ঞাপন';

  @override
  String get adBanner => 'ব্যানার';

  @override
  String get adNative => 'নেটিভ';

  @override
  String get unknownCategory => 'অজানা';

  @override
  String get budgetExceeded => 'বাজেট ছাড়িয়ে গেছেন — খরচ কমানোর সময়।';

  @override
  String get forecast => 'মাসের শেষে আনুমানিক খরচ';

  @override
  String get addEditUnavailable =>
      'লেনদেন যোগ করা আর বদলানোর সুবিধা শিগগিরই আসছে।';

  @override
  String get activeNoAds => 'চালু · বিজ্ঞাপন নেই';

  @override
  String get budgetSettingBody => 'ক্যাটাগরি অনুযায়ী মাসিক সীমা ঠিক করুন';

  @override
  String get categoriesSettingBody => 'নিজের ক্যাটাগরি তৈরি করুন';

  @override
  String get accountsSettingBody => 'ব্যাঙ্ক · ক্যাশ · ওয়ালেট';

  @override
  String get deleteAllData => 'সব ডেটা মুছুন';

  @override
  String get deleteAllDataSubtitle =>
      'দুবার নিশ্চিত করার পর সবকিছু চিরতরে মুছে যাবে';

  @override
  String get eraseTitle => 'সব ডেটা মুছবেন?';

  @override
  String get eraseBody =>
      'সব লেনদেন, বাজেট আর ক্যাটাগরি মুছে যাবে। এটি ফেরানো যাবে না।';

  @override
  String get keep => 'থাক';

  @override
  String get erase => 'মুছুন';

  @override
  String get confirm => 'নিশ্চিত?';

  @override
  String get lastChance => 'শেষ সুযোগ — এরপর সবকিছু মুছে যাবে।';

  @override
  String get no => 'না';

  @override
  String get yesErase => 'হ্যাঁ, সব মুছুন';

  @override
  String get demoEraseUnavailable =>
      'ডেমো মোডে ডেটা মোছা বন্ধ। ডেটা মুছতে ফোনের অ্যাপ ব্যবহার করুন।';

  @override
  String get transactionDetailTitle => 'লেনদেনের বিস্তারিত';

  @override
  String get transactionDetailSubtitle => 'S-11 · লেনদেনের বিস্তারিত';

  @override
  String get transactionDetailBody =>
      'SMS-এর মূল লেখা, ক্যাটাগরি বদল, নোট যোগ আর মুছে ফেলা — সব এখানে থাকবে। ব্যাচ ৫ (T-403) এ আসছে।';

  @override
  String get categoryPageSubtitle => 'S-13 · ক্যাটাগরি ম্যানেজার';

  @override
  String get categoryPageBody =>
      'নিজের ক্যাটাগরি তৈরি করুন, আইকন আর রং বেছে নিন। ব্যাচ ৫ (T-405) এ আসছে।';

  @override
  String get searchPageSubtitle => 'S-18 · সার্চ ও ফিল্টার';

  @override
  String get searchPageBody =>
      'মার্চেন্ট, টাকার অঙ্ক বা তারিখ দিয়ে লেনদেন খুঁজুন। ব্যাচ ৫ (T-406) এ আসছে।';

  @override
  String get notFoundTitle => 'পাতা খুঁজে পাওয়া গেল না';

  @override
  String get notFoundSubtitle => '404';

  @override
  String get notFoundBody => 'সেটিংস থেকে হোমে ফিরে যান।';

  @override
  String get txFilterAll => 'সব';

  @override
  String get txDelete => 'মুছুন';

  @override
  String get txRecategorise => 'ক্যাটাগরি বদলান';

  @override
  String get txPickCategory => 'কোন ক্যাটাগরি?';

  @override
  String get txDeleted => 'মুছে ফেলা হয়েছে';

  @override
  String get txUndo => 'ফিরিয়ে আনুন';

  @override
  String get txSwipeHint =>
      'সারি সোয়াইপ করুন — বাঁয়ে মুছতে, ডানে ক্যাটাগরি বদলাতে।';

  @override
  String get txMonthEmptyTitle => 'এই মাসে কিছু নেই';

  @override
  String get txMonthEmptyBody => 'অন্য মাস বাছুন, বা ফিল্টার সরান।';

  @override
  String get detailTitle => 'লেনদেন';

  @override
  String get detailDate => 'তারিখ';

  @override
  String get detailCategory => 'ক্যাটাগরি';

  @override
  String get detailAccount => 'অ্যাকাউন্ট';

  @override
  String get detailMode => 'মোড';

  @override
  String get detailSource => 'সোর্স';

  @override
  String get detailNote => 'নোট';

  @override
  String get detailChange => 'বদলান';

  @override
  String get detailRawTitle => 'মূল মেসেজ';

  @override
  String get detailRawHint =>
      'এই লেখাটা থেকেই এন্ট্রিটা পড়া হয়েছে। এটা কখনো আপনার ফোনের বাইরে যায় না।';

  @override
  String get detailNoRaw =>
      'এটা আপনি নিজে লিখেছেন, তাই দেখানোর মতো কোনো মেসেজ নেই।';

  @override
  String get detailEdit => 'এডিট';

  @override
  String get detailDeleteConfirmTitle => 'এই লেনদেনটা মুছবেন?';

  @override
  String get detailDeleteConfirmBody =>
      'এটা সঙ্গে সঙ্গে হিসেব থেকে বাদ যাবে। তালিকা থেকে ফিরিয়ে আনতে পারবেন।';

  @override
  String get detailNotFound => 'সেই লেনদেনটা আর নেই।';

  @override
  String get cancel => 'বাতিল';

  @override
  String get addTitle => 'নতুন লেনদেন';

  @override
  String get editTitle => 'লেনদেন বদলান';

  @override
  String get amountLabel => 'টাকার অঙ্ক';

  @override
  String get merchantHint => 'কোথায়? (ঐচ্ছিক)';

  @override
  String get noteHint => 'নোট (ঐচ্ছিক)';

  @override
  String get save => 'সেভ করুন';

  @override
  String get saved => 'সেভ হয়েছে';

  @override
  String get amountRequired => 'আগে টাকার অঙ্ক লিখুন';

  @override
  String get today => 'আজ';

  @override
  String get modeCash => 'ক্যাশ';

  @override
  String get modeUpi => 'UPI';

  @override
  String get modeCard => 'কার্ড';

  @override
  String get modeNetbanking => 'নেটব্যাঙ্কিং';

  @override
  String get modeWallet => 'ওয়ালেট';

  @override
  String get modeOther => 'অন্যান্য';

  @override
  String get catManagerTitle => 'ক্যাটাগরি';

  @override
  String get catNew => 'নতুন ক্যাটাগরি';

  @override
  String get catEditTitle => 'ক্যাটাগরি বদলান';

  @override
  String get catNameEn => 'নাম (ইংরেজি)';

  @override
  String get catNameHi => 'নাম (হিন্দি)';

  @override
  String get catNameBn => 'নাম (বাংলা)';

  @override
  String get catIcon => 'আইকন';

  @override
  String get catColor => 'রং';

  @override
  String get catMonthlyCap => 'মাসিক সীমা (ঐচ্ছিক)';

  @override
  String get catDelete => 'ক্যাটাগরি মুছুন';

  @override
  String get catDeleteWarn =>
      'এতে থাকা লেনদেনগুলোর ইতিহাস থেকেই যাবে — শুধু লেবেলটা চলে যাবে।';

  @override
  String get catNameRequired => 'ক্যাটাগরির অন্তত একটা নাম দরকার';

  @override
  String get catEmpty => 'এখানে এখনো কোনো ক্যাটাগরি নেই';

  @override
  String get catEmptyBody => '+ বোতাম দিয়ে একটা যোগ করুন।';

  @override
  String get searchTitle => 'খুঁজুন';

  @override
  String get searchHint => 'মার্চেন্ট, নোট বা টাকার অঙ্ক';

  @override
  String get searchResultCount => 'ফলাফল';

  @override
  String get searchNoResults => 'কিছু মিলল না';

  @override
  String get searchNoResultsBody =>
      'ছোট শব্দ দিয়ে দেখুন, বা একটা ফিল্টার সরান।';

  @override
  String get searchStartTitle => 'আপনার হিসেব খুঁজুন';

  @override
  String get searchStartBody => 'মার্চেন্ট, নোট, বা 1240-এর মতো অঙ্ক লিখুন।';

  @override
  String get filterSourceAuto => 'শুধু অটো';

  @override
  String get filterSourceManual => 'শুধু হাতে লেখা';

  @override
  String get filterClear => 'সরান';

  @override
  String get planMonthly => 'মাসিক';

  @override
  String get planYearly => 'বার্ষিক';

  @override
  String get planLifetime => 'লাইফটাইম';

  @override
  String get planMonthlyNote => 'প্রতি মাসে';

  @override
  String get planYearlyNote => 'প্রতি বছরে · ৪১% সাশ্রয়';

  @override
  String get planLifetimeNote => 'একবার, চিরদিনের জন্য';

  @override
  String get featureNoAdsTitle => 'বিজ্ঞাপন নেই';

  @override
  String get featureNoAdsBody => 'হোম, বাজেট আর ইনসাইট থেকে বিজ্ঞাপন সরে যাবে।';

  @override
  String get featureUnlimitedBudgetsTitle => 'আনলিমিটেড বাজেট';

  @override
  String get featureUnlimitedBudgetsBody =>
      'যত খুশি ক্যাটাগরি-বাজেট তৈরি করুন, প্রতিটায় অ্যালার্টসহ।';

  @override
  String get featureForecastTitle => 'খরচের পূর্বাভাস';

  @override
  String get featureForecastBody => 'মাস শেষে কত খরচ হতে পারে, আগেই জেনে নিন।';

  @override
  String get featureExportTitle => 'এক্সপোর্ট ও রিপোর্ট';

  @override
  String get featureExportBody =>
      'CSV এক্সপোর্ট সবার জন্য ফ্রি। PDF স্টেটমেন্ট Pro-তে পাওয়া যায়, নয়তো একটা rewarded ad দেখে।';

  @override
  String get trialDisclaimer => '৭ দিন ফ্রি, যেকোনো সময় বাতিল করুন।';

  @override
  String get popular => 'সবচেয়ে জনপ্রিয়';

  @override
  String get proActive => 'Pro চালু আছে';

  @override
  String get startTrial => '৭ দিনের ফ্রি ট্রায়াল শুরু করুন';

  @override
  String get proActivatedDemo =>
      'ডেমো: Pro চালু হয়েছে, বিজ্ঞাপন লুকানো। আসল বিলিং ব্যাচ ৭ (T-601) এ আসছে।';

  @override
  String get billingNotAvailable =>
      'স্টোরে পৌঁছানো গেল না। ইন্টারনেট দেখে আবার চেষ্টা করুন।';

  @override
  String savePercentTemplate(String pct) {
    return '$pct% সাশ্রয়';
  }

  @override
  String get priceEstimateNote =>
      'আনুমানিক — টাকা দেওয়ার আগে স্টোর আপনার মুদ্রায় সঠিক দাম দেখাবে।';

  @override
  String get purchasePending => 'স্টোরের অপেক্ষায়…';

  @override
  String get purchaseThanks => 'স্টোর খুলছে… কিনতে কয়েক সেকেন্ড লাগবে।';

  @override
  String get restorePurchases => 'কেনা ফিরিয়ে আনুন';

  @override
  String get restoreDone => 'এই ফোনে Pro আবার চালু হয়েছে।';

  @override
  String get restoreNothing => 'এই অ্যাকাউন্টে কোনো কেনা পাওয়া যায়নি।';

  @override
  String get maybeLater => 'পরে দেখব';

  @override
  String get terms => 'শর্তাবলি';

  @override
  String get termsBody =>
      'SpendStory আপনার হিসাব এই ফোনেই রাখে। Pro বিজ্ঞাপন সরায় আর ভবিষ্যৎ খরচের পূর্বাভাস, কাস্টম তারিখ, PDF এক্সপোর্ট আর সীমাহীন বাজেট খুলে দেয়। সাবস্ক্রিপশন Play Store থেকে বাতিল না করলে নিজে থেকেই নবীন হয়; যখন খুশি বাতিল করুন — যে সময়ের টাকা দিয়েছেন সেটা পুরো চলে। আজীবন মানে একবার পেমেন্ট। রিফান্ড Play Store নীতি অনুযায়ী। আপনার খরচের ডেটা কখনো আমাদের কাছে যায় না, তাই বাতিল করলেও হিসাব থাকবে।';

  @override
  String get subscriptionFootNote => 'Play Store থেকে যখন খুশি বাতিল করুন।';

  @override
  String get proActiveBody => 'Pro চালু। বিজ্ঞাপন-হীন অ্যাপের জন্য ধন্যবাদ।';

  @override
  String renewsOnTemplate(String date) {
    return 'নবীন হবে $date';
  }

  @override
  String get billingPending =>
      'স্টোর পেমেন্টটা দেখে নিচ্ছে — প্রথম কেনায় এটা স্বাভাবিক। পাস হলে Pro নিজে থেকেই চালু হবে।';

  @override
  String get billingCanceled => 'কেনা বাতিল হয়েছে। কোনো টাকা কাটা হয়নি।';

  @override
  String get billingFailed =>
      'স্টোর পেমেন্ট নেয়নি। আপনার অ্যাকাউন্ট থেকে টাকা যায়নি।';

  @override
  String get billingSucceeded => 'পেমেন্ট পেয়ে গেছি। Pro চালু।';

  @override
  String get personalizedAds => 'ব্যক্তিগতকৃত বিজ্ঞাপন';

  @override
  String get personalizedAdsBody =>
      'ভারতে ডিফল্টে বন্ধ। বন্ধ থাকলেও বিজ্ঞাপন অ্যাপের খরচ চালায় — শুধু আপনার সম্পর্কে কম জানে। আপনার খরচের ডেটা কোনোভাবেই কোথাও যায় না।';

  @override
  String get privacyOptions => 'বিজ্ঞাপনের প্রাইভেসি অপশন';

  @override
  String get privacyOptionsBody => 'আপনার সম্মতি যখন খুশি বদলান।';

  @override
  String get privacyOptionsShown => 'আপনার পছন্দ খুলে গেল।';

  @override
  String get privacyOptionsMissing =>
      'এখন ফর্ম খোলা গেল না। কিছুক্ষণ পরে চেষ্টা করুন।';

  @override
  String get planTaste => '২৪ ঘণ্টার টেস্ট';

  @override
  String get proTasteBody =>
      '২৪ ঘণ্টার জন্য Pro চালু। বিজ্ঞাপন বন্ধ, পূর্বাভাস খোলা — দেখার জন্য ধন্যবাদ।';

  @override
  String get watchAdForTaste => 'বিজ্ঞাপন দেখে ২৪ ঘণ্টার Pro নিন';

  @override
  String get tasteEarned => '২৪ ঘণ্টার জন্য Pro চালু হলো। উপভোগ করুন।';

  @override
  String get tasteMissed =>
      'বিজ্ঞাপন শেষ হওয়ার আগেই বন্ধ হয়ে গেল, তাই কিছু পাওয়া গেল না। যখন খুশি আবার চেষ্টা করুন।';

  @override
  String get tasteUnavailable => 'এখন কোনো বিজ্ঞাপন নেই। কিছুক্ষণ পরে দেখুন।';

  @override
  String get tasteTomorrow =>
      'আজকের ২৪ ঘণ্টার Pro নেওয়া হয়ে গেছে। কাল আবার আসবে।';

  @override
  String get trialEndsTitle => 'ফ্রি ট্রায়াল শেষের পথে';

  @override
  String get trialEndsBody =>
      'আপনার ফ্রি ট্রায়াল প্রায় শেষ। Play Store থেকে যখন খুশি বাতিল করুন — হিসাব তো এই ফোনেই থাকবে।';

  @override
  String get sourceAutoSms => 'SMS থেকে নিজে থেকেই যোগ হয়েছে';

  @override
  String get sourceAutoNotification => 'নোটিফিকেশন থেকে নিজে থেকেই যোগ হয়েছে';

  @override
  String get sourceRecurring => 'নিয়মিত পেমেন্ট';

  @override
  String get budgetThisMonth => 'এই মাসের বাজেট';

  @override
  String get budgetUsed => 'ব্যবহৃত';

  @override
  String get budgetNew => 'নতুন বাজেট';

  @override
  String get budgetSetTitle => 'বাজেট ঠিক করুন';

  @override
  String get budgetEmptyTitle => 'কোনো বাজেট নেই';

  @override
  String get budgetEmptyBody =>
      'একটা সামগ্রিক সীমা, বা ক্যাটাগরি ধরে আলাদা। ৮০% হলে সতর্ক করবে, ছাড়িয়ে গেলে আবার।';

  @override
  String get budgetOverallCap => 'সামগ্রিক মাসিক বাজেট';

  @override
  String get budgetCategoryCap => 'ক্যাটাগরি বাজেট';

  @override
  String get budgetWhichCategory => 'কোন ক্যাটাগরির?';

  @override
  String get budgetAmountLabel => 'মাসিক সীমা';

  @override
  String get budgetStartDay => 'চক্র শুরু কোন তারিখে';

  @override
  String get budgetStartDayBody => 'যেদিন মাইনে আসে সেদিনটা বেছে নিন।';

  @override
  String get budgetAlertsLabel => 'সতর্কতা';

  @override
  String get budgetAlert80 => '৮০% হলে জানাবে';

  @override
  String get budgetAlert100 => 'ছাড়িয়ে গেলে জানাবে';

  @override
  String get budgetSave => 'বাজেট সেভ করুন';

  @override
  String get budgetDelete => 'বাজেট মুছুন';

  @override
  String get budgetDeleteTitle => 'এই বাজেটটা মুছে দেব?';

  @override
  String get budgetDeleteBody => 'এখন পর্যন্ত গোনা খরচ লেনদেনেই থেকে যাবে।';

  @override
  String get budgetDailyTitle => 'দৈনিক ভাতা';

  @override
  String budgetDailyTemplate(String amt) {
    return 'দিনে প্রায় $amt খরচ করলে বাজেটের ভিতরে থাকবেন।';
  }

  @override
  String get budgetAllSpent => 'বাজেট শেষ — এরপরের যেকোনো খরচ সীমা ছাড়াবে।';

  @override
  String budgetDaysLeftTemplate(String n) {
    return '$n দিন বাকি';
  }

  @override
  String get budgetSpentLabel => 'খরচ';

  @override
  String get budgetRemainingLabel => 'বাকি';

  @override
  String get budgetTotalLabel => 'সীমা';

  @override
  String budgetSuggestTemplate(String pct) {
    return 'এটা $pct% ছাড়িয়ে গেছে। সীমা বাড়াবেন, নাকি খরচ কমান?';
  }

  @override
  String get budgetRecentTx => 'এই ক্যাটাগরির সাম্প্রতিক খরচ';

  @override
  String get budgetNoTx => 'এই বাজেটে এখনো কিছু গোনা হয়নি।';

  @override
  String get budgetEdit => 'বাজেট বদলান';

  @override
  String get budgetAmountRequired => 'টাকার পরিমাণ লিখুন';

  @override
  String get budgetOverallName => 'সব মিলিয়ে';

  @override
  String get accountsTotalNet => 'মোট ব্যালেন্স';

  @override
  String get accountAdd => 'অ্যাকাউন্ট যোগ করুন';

  @override
  String get accountEdit => 'অ্যাকাউন্ট বদলান';

  @override
  String get accountName => 'নাম';

  @override
  String get accountType => 'ধরন';

  @override
  String get accountTypeBank => 'ব্যাঙ্ক';

  @override
  String get accountTypeCash => 'ক্যাশ';

  @override
  String get accountTypeWallet => 'ওয়ালেট';

  @override
  String get accountTypeCard => 'কার্ড';

  @override
  String get accountOpeningBalance => 'শুরুর ব্যালেন্স';

  @override
  String get accountLast4 => 'শেষ ৪ সংখ্যা (ঐচ্ছিক)';

  @override
  String get accountColor => 'রঙ';

  @override
  String get accountBalanceNote =>
      'ব্যালেন্স = শুরুর + জমা − খরচ — হিসাব এই ফোনেই।';

  @override
  String get accountNoTx => 'এই অ্যাকাউন্টে এখনো কোনো লেনদেন নেই।';

  @override
  String get accountDeleteTitle => 'এই অ্যাকাউন্টটা সরিয়ে দেব?';

  @override
  String get accountDeleteBody =>
      'লেনদেনগুলো থেকে যাবে — শুধু তালিকা থেকে সরে যাবে।';

  @override
  String get accountSave => 'অ্যাকাউন্ট সেভ করুন';

  @override
  String get accountNameRequired => 'অ্যাকাউন্টের নাম লিখুন';

  @override
  String get periodWeek => 'সপ্তাহ';

  @override
  String get periodMonth => 'মাস';

  @override
  String get periodYear => 'বছর';

  @override
  String get periodCustom => 'নিজের মতো';

  @override
  String get trend30 => 'গত ৩০ দিনের দৈনিক খরচ';

  @override
  String get topMerchants => 'সবচেয়ে বেশি খরচ কোথায়';

  @override
  String get monthCompare => 'এ মাস বনাম গত মাস';

  @override
  String get biggestJump => 'সবচেয়ে বড় লাফ';

  @override
  String get patternTitle => 'প্রবণতা';

  @override
  String get patternWeekend => 'সপ্তাহান্তে খরচ বেশি হয়।';

  @override
  String get patternSteady => 'সপ্তাহজুড়ে খরচ প্রায় একই রকম।';

  @override
  String get insightProTitle => 'এই মাস কোথায় শেষ হবে';

  @override
  String get insightProBody => 'আগাম অনুমান আর নিজের তারিখের সীমা Pro-তে।';

  @override
  String get insightProCta => 'Pro দেখুন';

  @override
  String deltaMoreTemplate(String pct) {
    return 'গত মাসের চেয়ে $pct% বেশি';
  }

  @override
  String deltaLessTemplate(String pct) {
    return 'গত মাসের চেয়ে $pct% কম';
  }

  @override
  String get deltaSame => 'গত মাসের মতোই';

  @override
  String get insightTapSlice => 'বিস্তারিত দেখতে যেকোনো ভাগে চাপ দিন';

  @override
  String shareOfSpendingTemplate(String pct) {
    return 'খরচের $pct%';
  }

  @override
  String txCountTemplate(String n) {
    return '$nটি লেনদেন';
  }

  @override
  String get alert80Title => 'বাজেটের ৮০% শেষ';

  @override
  String alert80BodyTemplate(String amt, String cat) {
    return '$cat: $amt বাকি';
  }

  @override
  String get alert100Title => 'বাজেট ছাড়িয়ে গেছে';

  @override
  String alert100BodyTemplate(String amt, String cat) {
    return '$cat: $amt বেশি';
  }

  @override
  String get recurringTitle => 'নিয়মিত পেমেন্ট ও রিমাইন্ডার';

  @override
  String get recurringStripTitle => 'আগামী ৩০ দিন';

  @override
  String get recurringEmptyTitle => 'এখনও কিছু নেই';

  @override
  String get recurringEmptyBody =>
      'বাড়িভাড়া, EMI আর সাবস্ক্রিপশন — একবার সেট করলে হয় নিজে থেকেই খাতায় লেখা হবে, নয় মনে করিয়ে দেবে।';

  @override
  String get recurringAdd => 'নিয়মিত পেমেন্ট যোগ করুন';

  @override
  String recurringNextDueTemplate(String date) {
    return 'পরের বার $date';
  }

  @override
  String recurringDueCountTemplate(String n) {
    return 'আগামী ৩০ দিনে $nটি';
  }

  @override
  String get recurringAutoPost => 'নিজে থেকেই লিখে যাবে';

  @override
  String get recurringAutoPostNote =>
      'দিনে পৌঁছলেই খরচটা খাতায় যোগ হয়ে যাবে।';

  @override
  String get recurringRemindNote => 'এটার জন্য কোনো রিমাইন্ডার নেই।';

  @override
  String get recurringDueToday => 'আজ দিতে হবে';

  @override
  String get recurringOverdue => 'তারিখ পেরিয়ে গেছে';

  @override
  String get freqDaily => 'রোজ';

  @override
  String get freqWeekly => 'সাপ্তাহিক';

  @override
  String get freqMonthly => 'মাসিক';

  @override
  String get freqYearly => 'বার্ষিক';

  @override
  String recurringEveryTemplate(String n, String unit) {
    return 'প্রতি $n $unit';
  }

  @override
  String get unitDays => 'দিনে';

  @override
  String get unitWeeks => 'সপ্তাহে';

  @override
  String get unitMonths => 'মাসে';

  @override
  String get unitYears => 'বছরে';

  @override
  String get recurringNameLabel => 'কী বাবদ?';

  @override
  String get recurringNameHint => 'বাড়িভাড়া';

  @override
  String get recurringAmountLabel => 'টাকার পরিমাণ';

  @override
  String get recurringCategoryLabel => 'ক্যাটাগরি';

  @override
  String get recurringAccountLabel => 'অ্যাকাউন্ট';

  @override
  String get recurringAccountNone => 'সেট করা নেই';

  @override
  String get recurringFrequencyLabel => 'কত ঘন ঘন';

  @override
  String get recurringIntervalLabel => 'প্রতি';

  @override
  String get recurringDayLabel => 'মাসের কোন তারিখে';

  @override
  String get recurringDayNote =>
      'যে মাসে ওই তারিখ থাকে না, সেখানে মাসের শেষ দিন ধরা হয়।';

  @override
  String get recurringFirstDue => 'প্রথম পেমেন্ট';

  @override
  String get recurringRemindLabel => 'মনে করিয়ে দেব';

  @override
  String get recurringRemindNone => 'না';

  @override
  String get recurringRemindSameDay => 'সেদিন';

  @override
  String get recurringRemindOneDay => 'এক দিন আগে';

  @override
  String get recurringRemindThreeDays => 'তিন দিন আগে';

  @override
  String get recurringSave => 'সেভ করুন';

  @override
  String get recurringDelete => 'এই নিয়মটা মুছুন';

  @override
  String get recurringDeleteTitle => 'নিয়মিত পেমেন্টটা মুছে ফেলবেন?';

  @override
  String get recurringDeleteBody =>
      'যেগুলো আগে লেখা হয়ে গেছে সেগুলো খাতায় থাকবে।';

  @override
  String get recurringNameRequired => 'একটা নাম দিন';

  @override
  String get recurringAmountRequired => 'টাকার পরিমাণ লিখুন';

  @override
  String get recurringSettingBody => 'বাড়িভাড়া, EMI, সাবস্ক্রিপশন';

  @override
  String get reminderTitle => 'আসন্ন পেমেন্ট';

  @override
  String reminderTodayBodyTemplate(String amt, String title) {
    return '$title: আজ $amt দিতে হবে';
  }

  @override
  String reminderSoonBodyTemplate(String amt, String n, String title) {
    return '$title: $n দিন পরে $amt';
  }

  @override
  String get sourceManual => 'নিজে যোগ করা';

  @override
  String get aboutScreenTitle => 'পরিচিতি ও প্রাইভেসি';

  @override
  String get aboutCollectTitle => 'আমরা কী নিই';

  @override
  String get aboutCollectBody =>
      'কিছুই না। তোমার লেনদেন, বাজেট আর নোট সব এই ফোনেই থাকে। কোনো সার্ভার নেই, অ্যাকাউন্ট নেই, সাইন-ইন নেই — তাই এগুলোর যাওয়ার জায়গাই নেই। চাইলেও অ্যাপ তোমার ডেটা বাইরে পাঠাতে পারে না।';

  @override
  String get aboutReadTitle => 'আমরা কী পড়ি, আর কেন';

  @override
  String get aboutReadBody =>
      'নিচের প্রতিটা অনুমতি ঠিক একটা কারণেই চাওয়া হয়। Android settings-এ ফিরিয়ে দিলে অ্যাপ তবু চলবে — শুধু কিছু জিনিস নিজে লিখতে হবে।';

  @override
  String get aboutPermSmsTitle => 'ব্যাঙ্কের SMS';

  @override
  String get aboutPermSmsBody =>
      'শুধু ব্যাঙ্ক, কার্ড আর ওয়ালেটের লেনদেনের SMS — টাকার পরিমাণ, দোকান আর তারিখ। OTP, পাসওয়ার্ড বা ব্যক্তিগত message আর কিছু দেখার আগেই বাদ পড়ে, আর কোনো message কোথাও পাঠানো হয় না।';

  @override
  String get aboutPermNotifyTitle => 'পেমেন্ট অ্যাপের notification';

  @override
  String get aboutPermNotifyBody =>
      'তোমার অনুমতি নিয়ে SpendStory তোমার বাছা পেমেন্ট অ্যাপগুলোর — PhonePe, Google Pay, Paytm — notification পড়ে, যাতে UPI পেমেন্ট হওয়ার সঙ্গে সঙ্গেই খাতায় উঠে যায়।';

  @override
  String get aboutPermAlertsTitle => 'আমাদের পাঠানো notification';

  @override
  String get aboutPermAlertsBody =>
      'শুধু তুমি নিজে চালু করা বাজেট সতর্কতা আর পেমেন্টের রিমাইন্ডারের জন্য। আর কিছুর জন্য কখনো নয়।';

  @override
  String get aboutPermLockTitle => 'ফিঙ্গারপ্রিন্ট বা মুখ (ইচ্ছে হলে)';

  @override
  String get aboutPermLockBody =>
      'শুধু এই ফোনে অ্যাপ খোলার জন্য। পড়াটা Android-এর ভিতরেই থাকে — SpendStory কখনো দেখে না।';

  @override
  String get aboutPermInternetTitle => 'ইন্টারনেট';

  @override
  String get aboutPermInternetBody =>
      'ফ্রি ভার্সনের বিজ্ঞাপন আর Play billing-এর জন্য দরকার। কোনো লেনদেন, টাকার পরিমাণ, দোকান বা ক্যাটাগরি কোনো ad request-এর সঙ্গে যায় না।';

  @override
  String get aboutRightsTitle => 'তোমার ডেটার উপর তোমার অধিকার';

  @override
  String get aboutRightAccessTitle => 'সবটা দেখো';

  @override
  String get aboutRightAccessBody =>
      'Settings থেকে পুরো খাতা CSV বা JSON-এ যেকোনো সময়, ফ্রিতে নিয়ে যাও।';

  @override
  String get aboutRightCorrectTitle => 'যা খুশি ঠিক করো';

  @override
  String get aboutRightCorrectBody =>
      'যেকোনো লেনদেন এডিট করো, ক্যাটাগরি বদলাও বা মুছে ফেলো। parser ভুল করলে সেটা তুমিই বদলাতে পারো।';

  @override
  String get aboutRightEraseTitle => 'সব মুছে ফেলো';

  @override
  String get aboutRightEraseBody =>
      'Settings, সব ডেটা মুছুন, দুবার নিশ্চিত — এই ফোন থেকে সব লেনদেন, বাজেট আর ক্যাটাগরি সঙ্গে সঙ্গে মুছে যায়।';

  @override
  String get aboutRightWithdrawTitle => 'অনুমতি ফিরিয়ে নাও';

  @override
  String get aboutRightWithdrawBody =>
      'Android settings-এ SMS বা notification access যখন খুশি বন্ধ করে দাও। অ্যাপ নিজে লেখার মোডে ফিরে যায় — কোনো সুবিধা জিম্মি করে রাখা নেই।';

  @override
  String get aboutEraseTitle => 'সব মুছবে কীভাবে';

  @override
  String get aboutEraseStep1 => 'Settings → সব ডেটা মুছুন খোলো।';

  @override
  String get aboutEraseStep2 =>
      'দুবার নিশ্চিত করো। দ্বিতীয়বার কী কী মুছে যাবে সেটা লেখা থাকে।';

  @override
  String get aboutEraseStep3 =>
      'অ্যাপ আনইনস্টল করলে ডেটাবেস আর সব সেটিংসও সঙ্গে চলে যায়।';

  @override
  String get aboutContactTitle => 'প্রশ্ন বা অভিযোগ';

  @override
  String get aboutContactBody =>
      'লিখে পাঠাও, ৩০ দিনের মধ্যে উত্তর পাবে। তোমার ডেটা তোমার ফোনে, তাই আমরা তোমার খাতা দেখতে পারি না — কিন্তু যা নষ্ট তা ঠিক করতে পারি।';

  @override
  String get aboutGrievanceEmail => 'সাপোর্ট ইমেল';

  @override
  String get aboutEmailMissing =>
      'সাপোর্ট অ্যাড্রেস ঠিক করা হচ্ছে। চালু হওয়ার আগে নিচের সোর্স রিপোজিটরিতে একটা issue খুলে দাও।';

  @override
  String get aboutSourceTitle => 'সোর্স কোড';

  @override
  String get aboutSourceBody =>
      'পুরো অ্যাপ পাবলিক। এই স্ক্রিনের প্রতিটা কথা ওটাতে মিলিয়ে দেখা যায়।';

  @override
  String get aboutTapToCopy => 'কপি করতে চাপ দাও';

  @override
  String get aboutCopied => 'কপি হয়েছে';

  @override
  String get privacyReadAll => 'পুরো প্রাইভেসি নীতি দেখো';

  @override
  String get exportTitle => 'এক্সপোর্ট ও ব্যাকআপ';

  @override
  String get exportBody =>
      'এখান থেকে সব ডেটা তোমার নিজের ফাইলে যায়। কিছুই আপলোড হয় না — আপলোড করার সার্ভারই নেই।';

  @override
  String get exportBackupTitle => 'এখনই ব্যাকআপ নাও';

  @override
  String get exportBackupBody =>
      'তোমার খাতা তোমার বেছে নেওয়া পাসওয়ার্ডে AES-256 দিয়ে বন্ধ করা হয়। পাসওয়ার্ডটা আমরা ফেরাতে পারি না, তাই ভরসার জায়গায় রেখো।';

  @override
  String get exportPassword => 'পাসওয়ার্ড';

  @override
  String get exportPasswordHint => 'অন্তত ৮ অক্ষর। ফিরিয়ে আনতে এটাই লাগবে।';

  @override
  String get exportPasswordTooShort => 'অন্তত ৮ অক্ষর দাও।';

  @override
  String get exportCreateBackup => 'ব্যাকআপ ফাইল বানাও';

  @override
  String get exportWorking => 'এনক্রিপ্ট হচ্ছে…';

  @override
  String get exportBackupReady => 'ব্যাকআপ তৈরি। কোথায় রাখবে বেছে নাও।';

  @override
  String get exportBackupDismissed => 'কিছু শেয়ার হয়নি।';

  @override
  String get exportBackupUnavailable => 'এই ফোনে ফাইল পাঠানোর শেয়ার শিট নেই।';

  @override
  String get exportBackupFailed => 'ফাইল লেখা গেল না।';

  @override
  String exportLastBackup(String when) {
    return 'শেষ ব্যাকআপ: $when';
  }

  @override
  String get exportNeverBackedUp => 'এখনো কোনো ব্যাকআপ নেই।';

  @override
  String get exportDue => 'সাপ্তাহিক ব্যাকআপের সময় হয়েছে।';

  @override
  String get exportAutoBackup => 'সপ্তাহে একবার মনে করিয়ে দাও';

  @override
  String get exportAutoBackupBody =>
      'তোমার পাসওয়ার্ড ছাড়া অ্যাপ নিজের ব্যাকআপ খুলতে পারে না, তাই ফাইল লেখার বদলে সপ্তাহে একবার মনে করিয়ে দেয়।';

  @override
  String get exportRestoreTitle => 'ব্যাকআপ থেকে ফিরিয়ে আনো';

  @override
  String get exportRestoreBody =>
      'ব্যাকআপ ফাইল বেছে নিয়ে সেই পাসওয়ার্ড দাও। ফাইলের সব ডেটা যোগ হবে; এই ফোনের ডেটা মুছবে না।';

  @override
  String get exportPickFile => 'ফাইল বাছো';

  @override
  String get exportRestoreAction => 'ফিরিয়ে আনো';

  @override
  String get exportRestoreNeedFile => 'আগে একটা ব্যাকআপ ফাইল বাছো।';

  @override
  String get exportRestoreNeedPassword => 'এই ফাইলের পাসওয়ার্ড দাও।';

  @override
  String exportRestoreDone(
    String tx,
    String cats,
    String budgets,
    String accounts,
  ) {
    return '$txটি লেনদেন, $catsটি ক্যাটাগরি, $budgetsটি বাজেট আর $accountsটি অ্যাকাউন্ট ফিরে এসেছে।';
  }

  @override
  String get exportRestoreFailed =>
      'ফাইলটা খোলা গেল না। পাসওয়ার্ড মিলিয়ে আবার চেষ্টা করো।';

  @override
  String get exportCsvTitle => 'CSV এক্সপোর্ট';

  @override
  String get exportCsvBody =>
      'প্রতিটি লেনদেন একটা স্প্রেডশিট ফাইলে। সবার জন্য ফ্রি, সবসময়।';

  @override
  String get exportCsvFree => 'ফ্রি';

  @override
  String get exportCsvAction => 'CSV এক্সপোর্ট করো';

  @override
  String get exportCsvEmpty => 'এখনো এক্সপোর্ট করার মতো কিছু নেই।';

  @override
  String get exportPdfTitle => 'PDF স্টেটমেন্ট';

  @override
  String get exportPdfPro => 'Pro';

  @override
  String get exportPdfBody =>
      'এক মাসের ছাপার মতো স্টেটমেন্ট, টোটালসহ — Pro-তে আছে।';

  @override
  String get exportPdfAction => 'PDF এক্সপোর্ট করো';

  @override
  String get exportPdfWatchAd => 'বিজ্ঞাপন দেখে একটা ফ্রি PDF নাও';

  @override
  String exportPdfCredits(String n) {
    return 'আজ বাকি ফ্রি PDF: $n';
  }

  @override
  String get exportPdfNoCredits => 'আজকের ফ্রি PDF শেষ। কাল আবার পাবে।';

  @override
  String get exportPdfEarned => 'ফ্রি PDF পাওয়া গেছে।';

  @override
  String get exportPdfMissed => 'এবার পুরস্কার মেলেনি, PDFটা Pro-তেই রইল।';

  @override
  String get exportPdfUnavailable => 'এখন দেখানোর মতো বিজ্ঞাপন নেই।';

  @override
  String get exportPdfProOnly => 'PDF স্টেটমেন্ট Pro-তে পাওয়া যায়।';

  @override
  String get exportMonthPrev => 'আগের মাস';

  @override
  String get exportMonthNext => 'পরের মাস';

  @override
  String get exportDemoUnavailable =>
      'ব্যাকআপের জন্য অ্যাপটা লাগবে — ওয়েব প্রিভিউ কোনো খাতা রাখে না।';

  @override
  String get exportShareDrive =>
      'শেয়ার শিটে Drive বেছে নিয়ে সেখানে কপি রেখে দাও। SpendStory নিজে কখনো ফাইল আপলোড করে না।';

  @override
  String get exportSettingBody => 'এনক্রিপ্ট করা ব্যাকআপ, ফেরানো, CSV আর PDF';
}
