// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get ob1Title => 'हर भुगतान खुद दर्ज हो जाएगा';

  @override
  String get ob1Body =>
      'SpendStory आपके बैंक के लेन-देन SMS और पेमेंट ऐप के नोटिफ़िकेशन पढ़कर खर्च खुद लिख लेता है। टाइप करने की ज़रूरत नहीं।';

  @override
  String get ob1B1 => '50 बैंक सेंडर के साथ काम करता है';

  @override
  String get ob1B2 => 'लाख वाले अंक सही पढ़ता है';

  @override
  String get ob1B3 => 'OTP कभी नहीं पढ़ता';

  @override
  String get ob2Title => 'पैसा कहाँ जा रहा है, साफ़ देखें';

  @override
  String get ob2Body =>
      'श्रेणी-दर-श्रेणी, महीने-दर-महीने — और वो एक आंकड़ा जो आदत बदलता है: बजट में कितना बचा है।';

  @override
  String get ob2B1 => 'श्रेणी विभाजन और टॉप दुकानें';

  @override
  String get ob2B2 => 'मासिक बजट, 80% पर चेतावनी';

  @override
  String get ob2B3 => 'महीने के अंत का अनुमान';

  @override
  String get ob3Title => 'आपका डेटा फ़ोन में ही रहता है';

  @override
  String get ob3Body =>
      'कोई सर्वर नहीं, कोई अकाउंट नहीं, कोई लॉगिन नहीं। सब कुछ इसी डिवाइस पर रहता है।';

  @override
  String get ob3B1 => 'कुछ भी अपलोड नहीं होता';

  @override
  String get ob3B2 => 'कभी भी सब मिटा दें';

  @override
  String get ob3B3 => 'बिना इंटरनेट भी चलता है';

  @override
  String get obNext => 'आगे';

  @override
  String get obBack => 'पीछे';

  @override
  String get obSkip => 'छोड़ें';

  @override
  String get obStart => 'शुरू करें';

  @override
  String get permTitle => 'बैंक के SMS पढ़ने दें?';

  @override
  String get permWhy =>
      'इसी से ऐप बिना टाइपिंग के खर्च दर्ज करता है। अगले स्टेप में Android अनुमति माँगेगा।';

  @override
  String get permReads => 'क्या पढ़ता है';

  @override
  String get permReadsBody =>
      'बैंक, कार्ड और वॉलेट के लेन-देन अलर्ट — रकम, दुकान और तारीख़।';

  @override
  String get permNever => 'क्या कभी नहीं छूता';

  @override
  String get permNeverBody =>
      'OTP, पासवर्ड, PIN और निजी मैसेज। OTP बाक़ी सब से पहले हटा दिया जाता है, और कोई मैसेज कहीं भेजा नहीं जाता।';

  @override
  String get permAllow => 'SMS पढ़ने दें';

  @override
  String get permTryAgain => 'फिर कोशिश करें';

  @override
  String get permNotNow => 'अभी नहीं';

  @override
  String get permDenied =>
      'कोई बात नहीं — खर्च हाथ से जोड़ सकते हैं, और बाद में सेटिंग्स से चालू कर सकते हैं।';

  @override
  String get permWebNote =>
      'वेब प्रीव्यू में पूछने के लिए कोई Android नहीं है — असली डायलॉग सिर्फ़ फ़ोन बिल्ड में आता है। आगे बढ़ने के लिए “अभी नहीं” दबाएँ।';

  @override
  String get manualLink => 'SMS की अनुमति नहीं देना चाहता';

  @override
  String get notifTitle => 'एक और, और ये ज़रूरी नहीं';

  @override
  String get notifWhy =>
      'Google Pay और PhonePe जैसे ऐप अपना नोटिफ़िकेशन भेजते हैं। अनुमति मिलने पर वो भी दर्ज होते हैं — वरना बैंक का SMS देर से आने पर UPI भुगतान छूट सकता है।';

  @override
  String get notifOn => 'नोटिफ़िकेशन एक्सेस चालू है';

  @override
  String get notifOff => 'नोटिफ़िकेशन एक्सेस बंद है';

  @override
  String get notifApps => 'सिर्फ़ ये छह ऐप देखे जाते हैं:';

  @override
  String get notifOnlyThese =>
      'बाक़ी सारे नोटिफ़िकेशन पूरी तरह नज़रअंदाज़ होते हैं। WhatsApp, ईमेल या निजी मैसेज SpendStory नहीं पढ़ता।';

  @override
  String get notifOpen => 'नोटिफ़िकेशन सेटिंग्स खोलें';

  @override
  String get notifSkip => 'छोड़ दें';

  @override
  String get notifContinue => 'आगे बढ़ें';

  @override
  String get notifManualHint =>
      'सेटिंग्स → नोटिफ़िकेशन → नोटिफ़िकेशन एक्सेस खोलकर SpendStory चालू करें।';

  @override
  String get manualTitle => 'हाथ से इस्तेमाल करें';

  @override
  String get manualBody =>
      'बिल्कुल ठीक — खाता, बजट और विश्लेषण खुद जोड़े गए खर्चों से भी पूरा चलता है। बाद में सेटिंग्स से कैप्चर चालू कर सकते हैं।';

  @override
  String get manualP1 => 'तीन टैप में जोड़ें';

  @override
  String get manualP1Body => 'रकम, श्रेणी, हो गया।';

  @override
  String get manualP2 => 'सब कुछ वैसे ही चलता है';

  @override
  String get manualP2Body => 'बजट, श्रेणियाँ, विश्लेषण, एक्सपोर्ट।';

  @override
  String get manualP3 => 'बाद में कैप्चर चालू करें';

  @override
  String get manualP3Body => 'सेटिंग्स → SMS कैप्चर, कभी भी।';

  @override
  String get manualStart => 'SpendStory शुरू करें';

  @override
  String get manualBack => 'नहीं, SMS की अनुमति देता हूँ';

  @override
  String get appName => 'SpendStory';

  @override
  String get appTagline => 'आपके पैसों की कहानी, आपके फ़ोन पर';

  @override
  String get greeting => 'नमस्ते';

  @override
  String get heroLabel => 'इस महीने का खर्च';

  @override
  String get income => 'आय';

  @override
  String get expense => 'खर्च';

  @override
  String get recentTx => 'हाल के लेन-देन';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get addTx => 'जोड़ें';

  @override
  String get budget => 'बजट';

  @override
  String get categories => 'श्रेणियाँ';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get vsLastMonth => 'पिछले महीने से';

  @override
  String get monthlyBudget => 'मासिक बजट';

  @override
  String get budgetLeft => 'बचा';

  @override
  String get over => 'ज़्यादा';

  @override
  String get txTitle => 'लेन-देन';

  @override
  String get insights => 'विश्लेषण';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get appearance => 'रूप';

  @override
  String get theme => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get language => 'भाषा';

  @override
  String get languagePrompt =>
      'तीन भाषाओं में उपलब्ध — आप इसे कभी भी बदल सकते हैं।';

  @override
  String get start => 'शुरू करें';

  @override
  String get home => 'होम';

  @override
  String get uncategorised => 'बिना श्रेणी';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get trend => 'पिछले 6 महीने';

  @override
  String get topCategories => 'पैसा कहाँ गया';

  @override
  String get noDataTitle => 'अभी कुछ नहीं';

  @override
  String get noDataBody => 'खर्च करते ही लेन-देन यहाँ दिखेंगे।';

  @override
  String get addFirst => 'पहला जोड़ें';

  @override
  String get emptyTxTitle => 'अभी कोई लेन-देन नहीं';

  @override
  String get emptyTxBody =>
      'SMS कैप्चर चालू करें — हर भुगतान खुद दर्ज हो जाएगा।';

  @override
  String get demoBanner => 'वेब प्रीव्यू';

  @override
  String get demoBannerBody =>
      'डेमो डेटा। फ़ोन बिल्ड आपके बैंक SMS पढ़ता है — सिर्फ़ डिवाइस पर।';

  @override
  String get about => 'SpendStory के बारे में';

  @override
  String get aboutBody => 'आपका डेटा फ़ोन से बाहर नहीं जाता';

  @override
  String get privacy => 'प्राइवेसी';

  @override
  String get privacyBody => 'सिर्फ़ बैंक SMS पढ़ता है। कभी अपलोड नहीं।';

  @override
  String get privacyDetails =>
      'SpendStory सिर्फ़ बैंक लेन-देन के SMS पढ़ता है — OTP कभी नहीं। आपका डेटा किसी सर्वर पर नहीं भेजा जाता और किसी खाते की ज़रूरत नहीं है। ऐप हटाने पर उसका डेटा भी फ़ोन से मिट जाता है।';

  @override
  String get privacyOnDevice => '100% डिवाइस पर';

  @override
  String get version => 'वर्ज़न';

  @override
  String get proTitle => 'SpendStory Pro';

  @override
  String get proBody => 'कोई विज्ञापन नहीं, असीमित बजट, खर्च का अनुमान';

  @override
  String get search => 'खोजें';

  @override
  String get accounts => 'खाते';

  @override
  String get savings => 'बचत';

  @override
  String get comingSoon => 'अगले बैच में';

  @override
  String get comingSoonBody =>
      'यह स्क्रीन बैच 4–6 में बनेगी। शेल, थीम और डेमो डेटा अब चालू है।';

  @override
  String get adLabel => 'विज्ञापन';

  @override
  String get adBanner => 'बैनर';

  @override
  String get adNative => 'नेटिव';

  @override
  String get unknownCategory => 'अज्ञात';

  @override
  String get budgetExceeded => 'बजट पार हो गया — खर्च कम करने का समय है।';

  @override
  String get forecast => 'महीने के अंत तक अनुमानित खर्च';

  @override
  String get addEditUnavailable => 'लेन-देन जोड़ना और बदलना जल्द उपलब्ध होगा।';

  @override
  String get activeNoAds => 'चालू · विज्ञापन नहीं';

  @override
  String get budgetSettingBody => 'श्रेणी के अनुसार मासिक सीमा तय करें';

  @override
  String get categoriesSettingBody => 'अपनी श्रेणियाँ बनाएँ';

  @override
  String get accountsSettingBody => 'बैंक · नकद · वॉलेट';

  @override
  String get deleteAllData => 'सारा डेटा मिटाएँ';

  @override
  String get deleteAllDataSubtitle =>
      'दो बार पुष्टि के बाद सब कुछ हमेशा के लिए मिट जाएगा';

  @override
  String get eraseTitle => 'सारा डेटा मिटाएँ?';

  @override
  String get eraseBody =>
      'सभी लेन-देन, बजट और श्रेणियाँ मिट जाएँगी। इसे वापस नहीं लाया जा सकता।';

  @override
  String get keep => 'रहने दें';

  @override
  String get erase => 'मिटाएँ';

  @override
  String get confirm => 'क्या आप पक्का चाहते हैं?';

  @override
  String get lastChance => 'आख़िरी मौका — इसके बाद सब कुछ मिट जाएगा।';

  @override
  String get no => 'नहीं';

  @override
  String get yesErase => 'हाँ, सब मिटाएँ';

  @override
  String get demoEraseUnavailable =>
      'डेमो मोड में डेटा मिटाना बंद है। डेटा मिटाने के लिए फ़ोन ऐप इस्तेमाल करें।';

  @override
  String get transactionDetailTitle => 'लेन-देन का विवरण';

  @override
  String get transactionDetailSubtitle => 'S-11 · लेन-देन का विवरण';

  @override
  String get transactionDetailBody =>
      'मूल SMS, श्रेणी बदलना, नोट जोड़ना और हटाना — सब यहाँ होगा। बैच 5 (T-403) में आ रहा है।';

  @override
  String get categoryPageSubtitle => 'S-13 · श्रेणी प्रबंधन';

  @override
  String get categoryPageBody =>
      'अपनी श्रेणियाँ बनाएँ और उनके आइकन व रंग चुनें। बैच 5 (T-405) में।';

  @override
  String get searchPageSubtitle => 'S-18 · खोज और फ़िल्टर';

  @override
  String get searchPageBody =>
      'दुकान, रकम या तारीख से लेन-देन खोजें। बैच 5 (T-406) में।';

  @override
  String get notFoundTitle => 'पेज नहीं मिला';

  @override
  String get notFoundSubtitle => '404';

  @override
  String get notFoundBody => 'सेटिंग्स से होम पर लौटें।';

  @override
  String get txFilterAll => 'सभी';

  @override
  String get txDelete => 'मिटाएँ';

  @override
  String get txRecategorise => 'श्रेणी बदलें';

  @override
  String get txPickCategory => 'कौन सी श्रेणी?';

  @override
  String get txDeleted => 'मिटा दिया';

  @override
  String get txUndo => 'वापस लाएँ';

  @override
  String get txSwipeHint =>
      'पंक्ति खिसकाएँ — बाएँ मिटाने के लिए, दाएँ श्रेणी बदलने के लिए।';

  @override
  String get txMonthEmptyTitle => 'इस महीने कुछ नहीं';

  @override
  String get txMonthEmptyBody => 'दूसरा महीना चुनें, या फ़िल्टर हटाएँ।';

  @override
  String get detailTitle => 'लेन-देन';

  @override
  String get detailDate => 'तारीख़';

  @override
  String get detailCategory => 'श्रेणी';

  @override
  String get detailAccount => 'खाता';

  @override
  String get detailMode => 'तरीका';

  @override
  String get detailSource => 'स्रोत';

  @override
  String get detailNote => 'नोट';

  @override
  String get detailChange => 'बदलें';

  @override
  String get detailRawTitle => 'मूल संदेश';

  @override
  String get detailRawHint =>
      'यह वही लिखावट है जिससे यह प्रविष्टि पढ़ी गई। यह आपके फ़ोन से कभी बाहर नहीं जाती।';

  @override
  String get detailNoRaw =>
      'यह आपने ख़ुद लिखा था, इसलिए दिखाने को कोई संदेश नहीं है।';

  @override
  String get detailEdit => 'बदलें';

  @override
  String get detailDeleteConfirmTitle => 'यह लेन-देन मिटाएँ?';

  @override
  String get detailDeleteConfirmBody =>
      'यह तुरंत आपके जोड़ से हट जाएगा। सूची से वापस ला सकते हैं।';

  @override
  String get detailNotFound => 'वह लेन-देन अब यहाँ नहीं है।';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get addTitle => 'नया लेन-देन';

  @override
  String get editTitle => 'लेन-देन बदलें';

  @override
  String get amountLabel => 'रकम';

  @override
  String get merchantHint => 'कहाँ? (वैकल्पिक)';

  @override
  String get noteHint => 'नोट (वैकल्पिक)';

  @override
  String get save => 'सेव करें';

  @override
  String get saved => 'सेव हो गया';

  @override
  String get amountRequired => 'पहले रकम लिखें';

  @override
  String get today => 'आज';

  @override
  String get modeCash => 'नकद';

  @override
  String get modeUpi => 'UPI';

  @override
  String get modeCard => 'कार्ड';

  @override
  String get modeNetbanking => 'नेटबैंकिंग';

  @override
  String get modeWallet => 'वॉलेट';

  @override
  String get modeOther => 'अन्य';

  @override
  String get catManagerTitle => 'श्रेणियाँ';

  @override
  String get catNew => 'नई श्रेणी';

  @override
  String get catEditTitle => 'श्रेणी बदलें';

  @override
  String get catNameEn => 'नाम (अंग्रेज़ी)';

  @override
  String get catNameHi => 'नाम (हिन्दी)';

  @override
  String get catNameBn => 'नाम (बांग्ला)';

  @override
  String get catIcon => 'आइकन';

  @override
  String get catColor => 'रंग';

  @override
  String get catMonthlyCap => 'मासिक सीमा (वैकल्पिक)';

  @override
  String get catDelete => 'श्रेणी मिटाएँ';

  @override
  String get catDeleteWarn =>
      'इसमें दर्ज लेन-देन का इतिहास बना रहेगा — बस लेबल हट जाएगा।';

  @override
  String get catNameRequired => 'श्रेणी का कम से कम एक नाम ज़रूरी है';

  @override
  String get catEmpty => 'यहाँ अभी कोई श्रेणी नहीं';

  @override
  String get catEmptyBody => '+ बटन से एक जोड़ें।';

  @override
  String get searchTitle => 'खोजें';

  @override
  String get searchHint => 'दुकान, नोट या रकम';

  @override
  String get searchResultCount => 'नतीजे';

  @override
  String get searchNoResults => 'कुछ नहीं मिला';

  @override
  String get searchNoResultsBody => 'छोटा शब्द आज़माएँ, या कोई फ़िल्टर हटाएँ।';

  @override
  String get searchStartTitle => 'अपना हिसाब खोजें';

  @override
  String get searchStartBody => 'दुकान, नोट, या 1240 जैसी रकम लिखें।';

  @override
  String get filterSourceAuto => 'सिर्फ़ ऑटो';

  @override
  String get filterSourceManual => 'सिर्फ़ लिखा हुआ';

  @override
  String get filterClear => 'हटाएँ';

  @override
  String get planMonthly => 'मासिक';

  @override
  String get planYearly => 'सालाना';

  @override
  String get planLifetime => 'लाइफ़टाइम';

  @override
  String get planMonthlyNote => 'हर महीने';

  @override
  String get planYearlyNote => 'हर साल · 41% की बचत';

  @override
  String get planLifetimeNote => 'एक बार भुगतान, हमेशा के लिए';

  @override
  String get featureNoAdsTitle => 'कोई विज्ञापन नहीं';

  @override
  String get featureNoAdsBody => 'होम, बजट और विश्लेषण से विज्ञापन हट जाएँगे।';

  @override
  String get featureUnlimitedBudgetsTitle => 'असीमित बजट';

  @override
  String get featureUnlimitedBudgetsBody =>
      'जितनी चाहें श्रेणी-बजट बनाएँ, हर एक के लिए अलर्ट के साथ।';

  @override
  String get featureForecastTitle => 'खर्च का अनुमान';

  @override
  String get featureForecastBody =>
      'महीने के अंत तक संभावित खर्च पहले से जानें।';

  @override
  String get featureExportTitle => 'एक्सपोर्ट और रिपोर्ट';

  @override
  String get featureExportBody =>
      'रिवॉर्डेड विज्ञापन से CSV और PDF अनलॉक करें या Pro में सीधे पाएँ।';

  @override
  String get trialDisclaimer => '7 दिन मुफ़्त, कभी भी रद्द करें।';

  @override
  String get popular => 'सबसे लोकप्रिय';

  @override
  String get proActive => 'Pro चालू है';

  @override
  String get startTrial => '7 दिन का मुफ़्त ट्रायल शुरू करें';

  @override
  String get proActivatedDemo =>
      'डेमो: Pro चालू है और विज्ञापन छिप गए हैं। असली बिलिंग बैच 7 (T-601) में आएगी।';

  @override
  String get billingNotAvailable =>
      'स्टोर से संपर्क नहीं हो सका। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String savePercentTemplate(String pct) {
    return '$pct% बचत';
  }

  @override
  String get priceEstimateNote =>
      'अनुमानित — भुगतान से पहले स्टोर आपकी मुद्रा में सही दाम दिखाता है।';

  @override
  String get purchasePending => 'स्टोर का इंतज़ार…';

  @override
  String get purchaseThanks => 'स्टोर खुल रहा है… ख़रीद कुछ ही देर में दिखेगी।';

  @override
  String get restorePurchases => 'ख़रीद वापस लाएँ';

  @override
  String get restoreDone => 'इस डिवाइस पर Pro फिर चालू है।';

  @override
  String get restoreNothing => 'इस अकाउंट के लिए कोई ख़रीद नहीं मिली।';

  @override
  String get maybeLater => 'बाद में';

  @override
  String get terms => 'शर्तें';

  @override
  String get termsBody =>
      'SpendStory आपका हिसाब इसी फ़ोन में रखता है। Pro विज्ञापन हटाता है और पूर्वानुमान, कस्टम तारीख़ें, PDF एक्सपोर्ट और असीमित बजट खोलता है। सब्सक्रिप्शन Play Store से रद्द करने तक अपने आप नवीनीकृत होता है; जब चाहें रद्द करें — जिस अवधि का भुगतान किया है वो पूरी चलेगी। लाइफ़टाइम एक बार का भुगतान है। रिफ़ंड Play Store की नीति के अनुसार। आपका ख़र्च कभी हम तक नहीं आता, इसलिए रद्द करने पर हिसाब कभी नहीं जाता।';

  @override
  String get subscriptionFootNote => 'Play Store से कभी भी रद्द करें।';

  @override
  String get proActiveBody =>
      'Pro चालू है। बिना विज्ञापन वाले ऐप के लिए शुक्रिया।';

  @override
  String renewsOnTemplate(String date) {
    return '$date को नवीनीकरण';
  }

  @override
  String get billingPending =>
      'स्टोर इस भुगतान की समीक्षा कर रहा है — पहली ख़रीद में आम है। पूरा होते ही Pro अपने आप चालू हो जाएगा।';

  @override
  String get billingCanceled => 'ख़रीद रद्द। कुछ नहीं कटा।';

  @override
  String get billingFailed =>
      'स्टोर ने भुगतान नहीं लिया। आपके खाते से कुछ नहीं गया।';

  @override
  String get billingSucceeded => 'भुगतान मिल गया। Pro चालू है।';

  @override
  String get personalizedAds => 'व्यक्तिगत विज्ञापन';

  @override
  String get personalizedAdsBody =>
      'भारत में डिफ़ॉल्ट रूप से बंद। बंद रहने पर भी विज्ञापन ऐप का ख़र्च निकालते हैं — बस आपके बारे में कम जानते हैं। आपका ख़र्च किसी हाल में कहीं नहीं भेजा जाता।';

  @override
  String get privacyOptions => 'विज्ञापन प्राइवेसी विकल्प';

  @override
  String get privacyOptionsBody => 'अपनी सहमति कभी भी बदलें।';

  @override
  String get privacyOptionsShown => 'आपके विकल्प खुल गए।';

  @override
  String get privacyOptionsMissing =>
      'अभी फ़ॉर्म नहीं खुल सका। थोड़ी देर बाद कोशिश करें।';

  @override
  String get planTaste => '24 घंटे का टेस्ट';

  @override
  String get proTasteBody =>
      '24 घंटे के लिए Pro चालू है। विज्ञापन बंद, पूर्वानुमान खुला — देखने के लिए शुक्रिया।';

  @override
  String get watchAdForTaste => 'विज्ञापन देखें, 24 घंटे का Pro पाएँ';

  @override
  String get tasteEarned => '24 घंटे के लिए Pro चालू है। मज़े करें।';

  @override
  String get tasteMissed =>
      'विज्ञापन पूरा होने से पहले बंद हो गया, इसलिए कुछ नहीं मिला। कभी भी फिर कोशिश करें।';

  @override
  String get tasteUnavailable =>
      'अभी कोई विज्ञापन उपलब्ध नहीं है। थोड़ी देर बाद देखें।';

  @override
  String get tasteTomorrow =>
      'आज का 24 घंटे वाला Pro ले लिया गया है। कल फिर मिलेगा।';

  @override
  String get trialEndsTitle => 'फ़्री ट्रायल ख़त्म हो रहा है';

  @override
  String get trialEndsBody =>
      'आपका फ़्री ट्रायल लगभग पूरा हो गया। Play Store से कभी भी रद्द करें — हिसाब हर हाल में इसी फ़ोन पर रहेगा।';

  @override
  String get sourceAutoSms => 'SMS से अपने आप जोड़ा गया';

  @override
  String get sourceAutoNotification => 'सूचना से अपने आप जोड़ा गया';

  @override
  String get sourceRecurring => 'नियमित भुगतान';

  @override
  String get budgetThisMonth => 'इस महीने का बजट';

  @override
  String get budgetUsed => 'इस्तेमाल';

  @override
  String get budgetNew => 'नया बजट';

  @override
  String get budgetSetTitle => 'बजट तय करें';

  @override
  String get budgetEmptyTitle => 'कोई बजट नहीं';

  @override
  String get budgetEmptyBody =>
      'एक कुल सीमा, या हर श्रेणी की अलग। 80% पर चेतावनी मिलेगी, और सीमा पार होते ही फिर।';

  @override
  String get budgetOverallCap => 'कुल मासिक बजट';

  @override
  String get budgetCategoryCap => 'श्रेणी बजट';

  @override
  String get budgetWhichCategory => 'किस श्रेणी का?';

  @override
  String get budgetAmountLabel => 'मासिक सीमा';

  @override
  String get budgetStartDay => 'चक्र कब से';

  @override
  String get budgetStartDayBody => 'जिस दिन वेतन आता है वह चुनें।';

  @override
  String get budgetAlertsLabel => 'चेतावनी';

  @override
  String get budgetAlert80 => '80% पर बताएँ';

  @override
  String get budgetAlert100 => 'सीमा पार होते ही बताएँ';

  @override
  String get budgetSave => 'बजट सहेजें';

  @override
  String get budgetDelete => 'बजट हटाएँ';

  @override
  String get budgetDeleteTitle => 'यह बजट हटाएँ?';

  @override
  String get budgetDeleteBody => 'अब तक का खर्च लेनदेन में बना रहेगा।';

  @override
  String get budgetDailyTitle => 'रोज़ की छूट';

  @override
  String budgetDailyTemplate(String amt) {
    return 'बजट के अंदर रहने के लिए रोज़ करीब $amt खर्च करें।';
  }

  @override
  String get budgetAllSpent =>
      'बजट खत्म हो गया — इससे ज़्यादा हर खर्च सीमा पार करेगा।';

  @override
  String budgetDaysLeftTemplate(String n) {
    return '$n दिन बाकी';
  }

  @override
  String get budgetSpentLabel => 'खर्च';

  @override
  String get budgetRemainingLabel => 'बचा';

  @override
  String get budgetTotalLabel => 'सीमा';

  @override
  String budgetSuggestTemplate(String pct) {
    return 'यह बजट $pct% से ऊपर है। सीमा बढ़ाएँ या खर्च धीमा करें?';
  }

  @override
  String get budgetRecentTx => 'यहाँ का हाल का खर्च';

  @override
  String get budgetNoTx => 'इस बजट में अभी कुछ दर्ज नहीं हुआ।';

  @override
  String get budgetEdit => 'बजट बदलें';

  @override
  String get budgetAmountRequired => 'रकम डालें';

  @override
  String get budgetOverallName => 'कुल';

  @override
  String get accountsTotalNet => 'कुल बैलेंस';

  @override
  String get accountAdd => 'खाता जोड़ें';

  @override
  String get accountEdit => 'खाता बदलें';

  @override
  String get accountName => 'नाम';

  @override
  String get accountType => 'प्रकार';

  @override
  String get accountTypeBank => 'बैंक';

  @override
  String get accountTypeCash => 'नकद';

  @override
  String get accountTypeWallet => 'वॉलेट';

  @override
  String get accountTypeCard => 'कार्ड';

  @override
  String get accountOpeningBalance => 'शुरुआती बैलेंस';

  @override
  String get accountLast4 => 'आखिरी 4 अंक (वैकल्पिक)';

  @override
  String get accountColor => 'रंग';

  @override
  String get accountBalanceNote =>
      'बैलेंस = शुरुआती + जमा − खर्च — गणना इसी फ़ोन पर।';

  @override
  String get accountNoTx => 'इस खाते से अभी कोई लेनदेन नहीं।';

  @override
  String get accountDeleteTitle => 'यह खाता हटाएँ?';

  @override
  String get accountDeleteBody =>
      'लेनदेन बने रहेंगे — सिर्फ़ खाता सूची से हटेगा।';

  @override
  String get accountSave => 'खाता सहेजें';

  @override
  String get accountNameRequired => 'खाते का नाम लिखें';

  @override
  String get periodWeek => 'सप्ताह';

  @override
  String get periodMonth => 'महीना';

  @override
  String get periodYear => 'साल';

  @override
  String get periodCustom => 'कस्टम';

  @override
  String get trend30 => 'पिछले 30 दिन का रोज़ाना खर्च';

  @override
  String get topMerchants => 'सबसे ज़्यादा खर्च कहाँ';

  @override
  String get monthCompare => 'यह महीना बनाम पिछला';

  @override
  String get biggestJump => 'सबसे बड़ी बढ़त';

  @override
  String get patternTitle => 'पैटर्न';

  @override
  String get patternWeekend => 'वीकेंड में खर्च ज़्यादा होता है।';

  @override
  String get patternSteady => 'आपका खर्च हफ़्ते भर एक जैसा रहता है।';

  @override
  String get insightProTitle => 'यह महीना कहाँ खत्म होगा';

  @override
  String get insightProBody =>
      'अनुमान और कस्टम तारीख़ की सीमा Pro में शामिल हैं।';

  @override
  String get insightProCta => 'Pro देखें';

  @override
  String deltaMoreTemplate(String pct) {
    return 'पिछले महीने से $pct% ज़्यादा';
  }

  @override
  String deltaLessTemplate(String pct) {
    return 'पिछले महीने से $pct% कम';
  }

  @override
  String get deltaSame => 'पिछले महीने जैसा ही';

  @override
  String get insightTapSlice => 'विवरण के लिए किसी हिस्से पर टैप करें';

  @override
  String shareOfSpendingTemplate(String pct) {
    return 'खर्च का $pct%';
  }

  @override
  String txCountTemplate(String n) {
    return '$n लेनदेन';
  }

  @override
  String get alert80Title => 'बजट का 80% इस्तेमाल हो गया';

  @override
  String alert80BodyTemplate(String amt, String cat) {
    return '$cat: $amt बचा है';
  }

  @override
  String get alert100Title => 'बजट पार हो गया';

  @override
  String alert100BodyTemplate(String amt, String cat) {
    return '$cat: $amt ज़्यादा';
  }

  @override
  String get recurringTitle => 'नियमित भुगतान और रिमाइंडर';

  @override
  String get recurringStripTitle => 'अगले ३० दिन';

  @override
  String get recurringEmptyTitle => 'अभी कुछ नहीं';

  @override
  String get recurringEmptyBody =>
      'किराया, EMI और सब्सक्रिप्शन — एक बार सेट करें, खर्च खुद लिखा जाएगा या याद दिलाया जाएगा।';

  @override
  String get recurringAdd => 'नियमित भुगतान जोड़ें';

  @override
  String recurringNextDueTemplate(String date) {
    return 'अगली बार $date';
  }

  @override
  String recurringDueCountTemplate(String n) {
    return 'अगले ३० दिनों में $n';
  }

  @override
  String get recurringAutoPost => 'अपने आप लिख जाए';

  @override
  String get recurringAutoPostNote =>
      'तारीख आने पर खर्च खुद बही में जुड़ जाएगा।';

  @override
  String get recurringRemindNote => 'इसके लिए कोई रिमाइंडर नहीं है।';

  @override
  String get recurringDueToday => 'आज देना है';

  @override
  String get recurringOverdue => 'तारीख निकल गई';

  @override
  String get freqDaily => 'रोज़';

  @override
  String get freqWeekly => 'साप्ताहिक';

  @override
  String get freqMonthly => 'मासिक';

  @override
  String get freqYearly => 'सालाना';

  @override
  String recurringEveryTemplate(String n, String unit) {
    return 'हर $n $unit';
  }

  @override
  String get unitDays => 'दिन';

  @override
  String get unitWeeks => 'हफ़्ते';

  @override
  String get unitMonths => 'महीने';

  @override
  String get unitYears => 'साल';

  @override
  String get recurringNameLabel => 'किस चीज़ का?';

  @override
  String get recurringNameHint => 'घर का किराया';

  @override
  String get recurringAmountLabel => 'रकम';

  @override
  String get recurringCategoryLabel => 'श्रेणी';

  @override
  String get recurringAccountLabel => 'खाता';

  @override
  String get recurringAccountNone => 'सेट नहीं';

  @override
  String get recurringFrequencyLabel => 'कितनी बार';

  @override
  String get recurringIntervalLabel => 'हर';

  @override
  String get recurringDayLabel => 'महीने की तारीख';

  @override
  String get recurringDayNote =>
      'जिस महीने में यह तारीख न हो, वहाँ उसका आख़िरी दिन लिया जाएगा।';

  @override
  String get recurringFirstDue => 'पहला भुगतान';

  @override
  String get recurringRemindLabel => 'याद दिलाएँ';

  @override
  String get recurringRemindNone => 'नहीं';

  @override
  String get recurringRemindSameDay => 'उसी दिन';

  @override
  String get recurringRemindOneDay => 'एक दिन पहले';

  @override
  String get recurringRemindThreeDays => 'तीन दिन पहले';

  @override
  String get recurringSave => 'सेव करें';

  @override
  String get recurringDelete => 'यह नियम हटाएँ';

  @override
  String get recurringDeleteTitle => 'नियमित भुगतान हटाएँ?';

  @override
  String get recurringDeleteBody =>
      'जो भुगतान पहले लिखे जा चुके हैं वे बही में रहेंगे।';

  @override
  String get recurringNameRequired => 'नाम दें';

  @override
  String get recurringAmountRequired => 'रकम लिखें';

  @override
  String get recurringSettingBody => 'किराया, EMI, सब्सक्रिप्शन';

  @override
  String get reminderTitle => 'आने वाला भुगतान';

  @override
  String reminderTodayBodyTemplate(String amt, String title) {
    return '$title: $amt आज देना है';
  }

  @override
  String reminderSoonBodyTemplate(String amt, String n, String title) {
    return '$title: $n दिन में $amt';
  }

  @override
  String get sourceManual => 'खुद जोड़ा गया';
}
