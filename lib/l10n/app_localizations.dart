import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('bn'),
  ];

  /// No description provided for @ob1Title.
  ///
  /// In en, this message translates to:
  /// **'Every payment files itself'**
  String get ob1Title;

  /// No description provided for @ob1Body.
  ///
  /// In en, this message translates to:
  /// **'SpendStory reads your bank\'s transaction SMS and your payment apps\' notifications, and writes the expense down for you. No typing.'**
  String get ob1Body;

  /// No description provided for @ob1B1.
  ///
  /// In en, this message translates to:
  /// **'Works with 50 bank senders'**
  String get ob1B1;

  /// No description provided for @ob1B2.
  ///
  /// In en, this message translates to:
  /// **'Reads lakh-format amounts correctly'**
  String get ob1B2;

  /// No description provided for @ob1B3.
  ///
  /// In en, this message translates to:
  /// **'An OTP is never read, ever'**
  String get ob1B3;

  /// No description provided for @ob2Title.
  ///
  /// In en, this message translates to:
  /// **'See where the money goes'**
  String get ob2Title;

  /// No description provided for @ob2Body.
  ///
  /// In en, this message translates to:
  /// **'Category by category, month by month, with the one number that changes behaviour: what is left in the budget.'**
  String get ob2Body;

  /// No description provided for @ob2B1.
  ///
  /// In en, this message translates to:
  /// **'Category split and top merchants'**
  String get ob2B1;

  /// No description provided for @ob2B2.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget with an 80% warning'**
  String get ob2B2;

  /// No description provided for @ob2B3.
  ///
  /// In en, this message translates to:
  /// **'Forecast for the end of the month'**
  String get ob2B3;

  /// No description provided for @ob3Title.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your phone'**
  String get ob3Title;

  /// No description provided for @ob3Body.
  ///
  /// In en, this message translates to:
  /// **'There is no server, no account and no sign-in. Everything is stored on this device and nowhere else.'**
  String get ob3Body;

  /// No description provided for @ob3B1.
  ///
  /// In en, this message translates to:
  /// **'Nothing is uploaded — not one byte'**
  String get ob3B1;

  /// No description provided for @ob3B2.
  ///
  /// In en, this message translates to:
  /// **'Delete everything, any time'**
  String get ob3B2;

  /// No description provided for @ob3B3.
  ///
  /// In en, this message translates to:
  /// **'Works with no internet at all'**
  String get ob3B3;

  /// No description provided for @obNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get obNext;

  /// No description provided for @obBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get obBack;

  /// No description provided for @obSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get obSkip;

  /// No description provided for @obStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get obStart;

  /// No description provided for @permTitle.
  ///
  /// In en, this message translates to:
  /// **'Let SpendStory read bank SMS?'**
  String get permTitle;

  /// No description provided for @permWhy.
  ///
  /// In en, this message translates to:
  /// **'This is how the app captures spending without you typing. Android will ask for permission in the next step.'**
  String get permWhy;

  /// No description provided for @permReads.
  ///
  /// In en, this message translates to:
  /// **'What it reads'**
  String get permReads;

  /// No description provided for @permReadsBody.
  ///
  /// In en, this message translates to:
  /// **'Transaction alerts from banks, cards and wallets — the amount, the merchant and the date.'**
  String get permReadsBody;

  /// No description provided for @permNever.
  ///
  /// In en, this message translates to:
  /// **'What it never touches'**
  String get permNever;

  /// No description provided for @permNeverBody.
  ///
  /// In en, this message translates to:
  /// **'OTPs, passwords, PINs and personal messages. OTPs are dropped before anything else looks at them, and no message is ever sent anywhere.'**
  String get permNeverBody;

  /// No description provided for @permAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow reading SMS'**
  String get permAllow;

  /// No description provided for @permTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get permTryAgain;

  /// No description provided for @permNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permNotNow;

  /// No description provided for @permDenied.
  ///
  /// In en, this message translates to:
  /// **'No problem — you can add expenses by hand, and turn this on later from Settings.'**
  String get permDenied;

  /// No description provided for @permWebNote.
  ///
  /// In en, this message translates to:
  /// **'On the web preview there is no Android to ask — the real prompt only appears in the phone build. Use “Not now” to carry on.'**
  String get permWebNote;

  /// No description provided for @manualLink.
  ///
  /// In en, this message translates to:
  /// **'I would rather not give SMS access'**
  String get manualLink;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'One more, and it is optional'**
  String get notifTitle;

  /// No description provided for @notifWhy.
  ///
  /// In en, this message translates to:
  /// **'Payment apps like Google Pay and PhonePe send their own notification. With access, those are captured too — otherwise a UPI payment may be missed if the bank\'s SMS is delayed.'**
  String get notifWhy;

  /// No description provided for @notifOn.
  ///
  /// In en, this message translates to:
  /// **'Notification access is on'**
  String get notifOn;

  /// No description provided for @notifOff.
  ///
  /// In en, this message translates to:
  /// **'Notification access is off'**
  String get notifOff;

  /// No description provided for @notifApps.
  ///
  /// In en, this message translates to:
  /// **'Only these six apps are ever looked at:'**
  String get notifApps;

  /// No description provided for @notifOnlyThese.
  ///
  /// In en, this message translates to:
  /// **'Every other notification on your phone is ignored completely. SpendStory never reads WhatsApp, email or personal messages.'**
  String get notifOnlyThese;

  /// No description provided for @notifOpen.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get notifOpen;

  /// No description provided for @notifSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this'**
  String get notifSkip;

  /// No description provided for @notifContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get notifContinue;

  /// No description provided for @notifManualHint.
  ///
  /// In en, this message translates to:
  /// **'Open Settings → Notifications → Notification access, and turn on SpendStory.'**
  String get notifManualHint;

  /// No description provided for @manualTitle.
  ///
  /// In en, this message translates to:
  /// **'Use it by hand'**
  String get manualTitle;

  /// No description provided for @manualBody.
  ///
  /// In en, this message translates to:
  /// **'Perfectly fine — the ledger, budgets and insights all work with expenses you enter yourself. You can switch capture on later from Settings.'**
  String get manualBody;

  /// No description provided for @manualP1.
  ///
  /// In en, this message translates to:
  /// **'Add in three taps'**
  String get manualP1;

  /// No description provided for @manualP1Body.
  ///
  /// In en, this message translates to:
  /// **'Amount, category, done.'**
  String get manualP1Body;

  /// No description provided for @manualP2.
  ///
  /// In en, this message translates to:
  /// **'Everything still works'**
  String get manualP2;

  /// No description provided for @manualP2Body.
  ///
  /// In en, this message translates to:
  /// **'Budgets, categories, insights, export.'**
  String get manualP2Body;

  /// No description provided for @manualP3.
  ///
  /// In en, this message translates to:
  /// **'Turn on capture later'**
  String get manualP3;

  /// No description provided for @manualP3Body.
  ///
  /// In en, this message translates to:
  /// **'Settings → SMS capture, any time.'**
  String get manualP3Body;

  /// No description provided for @manualStart.
  ///
  /// In en, this message translates to:
  /// **'Start using SpendStory'**
  String get manualStart;

  /// No description provided for @manualBack.
  ///
  /// In en, this message translates to:
  /// **'Actually, let me give SMS access'**
  String get manualBack;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SpendStory'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your money\'s story, right on your phone'**
  String get appTagline;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get greeting;

  /// No description provided for @heroLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get heroLabel;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get expense;

  /// No description provided for @recentTx.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTx;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @addTx.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addTx;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get vsLastMonth;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get monthlyBudget;

  /// No description provided for @budgetLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get budgetLeft;

  /// No description provided for @over.
  ///
  /// In en, this message translates to:
  /// **'over'**
  String get over;

  /// No description provided for @txTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get txTitle;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose a language. You can change it anytime.'**
  String get languagePrompt;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get start;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @uncategorised.
  ///
  /// In en, this message translates to:
  /// **'Uncategorised'**
  String get uncategorised;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get trend;

  /// No description provided for @topCategories.
  ///
  /// In en, this message translates to:
  /// **'Where the money went'**
  String get topCategories;

  /// No description provided for @noDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noDataTitle;

  /// No description provided for @noDataBody.
  ///
  /// In en, this message translates to:
  /// **'Your transactions will appear here as soon as you spend.'**
  String get noDataBody;

  /// No description provided for @addFirst.
  ///
  /// In en, this message translates to:
  /// **'Add the first one'**
  String get addFirst;

  /// No description provided for @emptyTxTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get emptyTxTitle;

  /// No description provided for @emptyTxBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on SMS capture and every payment files itself. Or add one by hand.'**
  String get emptyTxBody;

  /// No description provided for @demoBanner.
  ///
  /// In en, this message translates to:
  /// **'Web preview'**
  String get demoBanner;

  /// No description provided for @demoBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Demo data. The phone build reads your bank SMS — on device only.'**
  String get demoBannerBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About SpendStory'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves your phone'**
  String get aboutBody;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Reads only bank SMS. Never uploaded.'**
  String get privacyBody;

  /// No description provided for @privacyDetails.
  ///
  /// In en, this message translates to:
  /// **'SpendStory reads bank transaction SMS only — never OTPs. Your data is never sent to a server, and no account is needed. Uninstall the app to remove its data from your phone.'**
  String get privacyDetails;

  /// No description provided for @privacyOnDevice.
  ///
  /// In en, this message translates to:
  /// **'100% on-device'**
  String get privacyOnDevice;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'SpendStory Pro'**
  String get proTitle;

  /// No description provided for @proBody.
  ///
  /// In en, this message translates to:
  /// **'No ads, unlimited budgets, forecasts'**
  String get proBody;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Net saved'**
  String get savings;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in the next batch'**
  String get comingSoon;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This screen is built in Batch 4–6. The shell, theme and demo data are live now.'**
  String get comingSoonBody;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get adLabel;

  /// No description provided for @adBanner.
  ///
  /// In en, this message translates to:
  /// **'banner'**
  String get adBanner;

  /// No description provided for @adNative.
  ///
  /// In en, this message translates to:
  /// **'native'**
  String get adNative;

  /// No description provided for @unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownCategory;

  /// No description provided for @budgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'You\'ve gone over budget — time to rein in spending.'**
  String get budgetExceeded;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Estimated spending by month-end'**
  String get forecast;

  /// No description provided for @addEditUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Adding and editing transactions are coming soon.'**
  String get addEditUnavailable;

  /// No description provided for @activeNoAds.
  ///
  /// In en, this message translates to:
  /// **'Active · ad-free'**
  String get activeNoAds;

  /// No description provided for @budgetSettingBody.
  ///
  /// In en, this message translates to:
  /// **'Set monthly limits by category'**
  String get budgetSettingBody;

  /// No description provided for @categoriesSettingBody.
  ///
  /// In en, this message translates to:
  /// **'Create your own categories'**
  String get categoriesSettingBody;

  /// No description provided for @accountsSettingBody.
  ///
  /// In en, this message translates to:
  /// **'Bank · cash · wallet'**
  String get accountsSettingBody;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase everything after two confirmations'**
  String get deleteAllDataSubtitle;

  /// No description provided for @eraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get eraseTitle;

  /// No description provided for @eraseBody.
  ///
  /// In en, this message translates to:
  /// **'All transactions, budgets and categories will be deleted. This cannot be undone.'**
  String get eraseBody;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keep;

  /// No description provided for @erase.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get erase;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirm;

  /// No description provided for @lastChance.
  ///
  /// In en, this message translates to:
  /// **'Last chance — everything will be erased after this.'**
  String get lastChance;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesErase.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete everything'**
  String get yesErase;

  /// No description provided for @demoEraseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Data deletion is disabled in demo mode. Use the phone app to erase your data.'**
  String get demoEraseUnavailable;

  /// No description provided for @transactionDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetailTitle;

  /// No description provided for @transactionDetailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'S-11 · Transaction detail'**
  String get transactionDetailSubtitle;

  /// No description provided for @transactionDetailBody.
  ///
  /// In en, this message translates to:
  /// **'Original SMS, category changes, notes and deletion will appear here. Coming in Batch 5 (T-403).'**
  String get transactionDetailBody;

  /// No description provided for @categoryPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'S-13 · Category manager'**
  String get categoryPageSubtitle;

  /// No description provided for @categoryPageBody.
  ///
  /// In en, this message translates to:
  /// **'Create your own categories and choose their icons and colours. Coming in Batch 5 (T-405).'**
  String get categoryPageBody;

  /// No description provided for @searchPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'S-18 · Search and filters'**
  String get searchPageSubtitle;

  /// No description provided for @searchPageBody.
  ///
  /// In en, this message translates to:
  /// **'Find transactions by merchant, amount or date. Coming in Batch 5 (T-406).'**
  String get searchPageBody;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'404'**
  String get notFoundSubtitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Return to Home from Settings.'**
  String get notFoundBody;

  /// No description provided for @txFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get txFilterAll;

  /// No description provided for @txDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get txDelete;

  /// No description provided for @txRecategorise.
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get txRecategorise;

  /// No description provided for @txPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Which category?'**
  String get txPickCategory;

  /// No description provided for @txDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get txDeleted;

  /// No description provided for @txUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get txUndo;

  /// No description provided for @txSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe a row — left to delete, right to change its category.'**
  String get txSwipeHint;

  /// No description provided for @txMonthEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this month'**
  String get txMonthEmptyTitle;

  /// No description provided for @txMonthEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick another month, or clear the filter.'**
  String get txMonthEmptyBody;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get detailTitle;

  /// No description provided for @detailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detailDate;

  /// No description provided for @detailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get detailCategory;

  /// No description provided for @detailAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get detailAccount;

  /// No description provided for @detailMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get detailMode;

  /// No description provided for @detailSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get detailSource;

  /// No description provided for @detailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get detailNote;

  /// No description provided for @detailChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get detailChange;

  /// No description provided for @detailRawTitle.
  ///
  /// In en, this message translates to:
  /// **'Original message'**
  String get detailRawTitle;

  /// No description provided for @detailRawHint.
  ///
  /// In en, this message translates to:
  /// **'This is the exact text this entry was read from. It never leaves your phone.'**
  String get detailRawHint;

  /// No description provided for @detailNoRaw.
  ///
  /// In en, this message translates to:
  /// **'You typed this one in, so there is no message to show.'**
  String get detailNoRaw;

  /// No description provided for @detailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get detailEdit;

  /// No description provided for @detailDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get detailDeleteConfirmTitle;

  /// No description provided for @detailDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It leaves your totals right away. You can undo it from the list.'**
  String get detailDeleteConfirmBody;

  /// No description provided for @detailNotFound.
  ///
  /// In en, this message translates to:
  /// **'That transaction is no longer here.'**
  String get detailNotFound;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @addTitle.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get addTitle;

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTitle;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @merchantHint.
  ///
  /// In en, this message translates to:
  /// **'Where? (optional)'**
  String get merchantHint;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount first'**
  String get amountRequired;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @modeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get modeCash;

  /// No description provided for @modeUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get modeUpi;

  /// No description provided for @modeCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get modeCard;

  /// No description provided for @modeNetbanking.
  ///
  /// In en, this message translates to:
  /// **'Netbanking'**
  String get modeNetbanking;

  /// No description provided for @modeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get modeWallet;

  /// No description provided for @modeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get modeOther;

  /// No description provided for @catManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get catManagerTitle;

  /// No description provided for @catNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get catNew;

  /// No description provided for @catEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get catEditTitle;

  /// No description provided for @catNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get catNameEn;

  /// No description provided for @catNameHi.
  ///
  /// In en, this message translates to:
  /// **'Name (Hindi)'**
  String get catNameHi;

  /// No description provided for @catNameBn.
  ///
  /// In en, this message translates to:
  /// **'Name (Bengali)'**
  String get catNameBn;

  /// No description provided for @catIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get catIcon;

  /// No description provided for @catColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get catColor;

  /// No description provided for @catMonthlyCap.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit (optional)'**
  String get catMonthlyCap;

  /// No description provided for @catDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get catDelete;

  /// No description provided for @catDeleteWarn.
  ///
  /// In en, this message translates to:
  /// **'Transactions already filed here keep their history — they just lose the label.'**
  String get catDeleteWarn;

  /// No description provided for @catNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A category needs at least one name'**
  String get catNameRequired;

  /// No description provided for @catEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories here yet'**
  String get catEmpty;

  /// No description provided for @catEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add one with the + button.'**
  String get catEmptyBody;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Merchant, note or amount'**
  String get searchHint;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get searchResultCount;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get searchNoResults;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter word, or clear a filter.'**
  String get searchNoResultsBody;

  /// No description provided for @searchStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your ledger'**
  String get searchStartTitle;

  /// No description provided for @searchStartBody.
  ///
  /// In en, this message translates to:
  /// **'Type a merchant, a note, or an amount like 1240.'**
  String get searchStartBody;

  /// No description provided for @filterSourceAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto only'**
  String get filterSourceAuto;

  /// No description provided for @filterSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Typed only'**
  String get filterSourceManual;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @planLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get planLifetime;

  /// No description provided for @planMonthlyNote.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get planMonthlyNote;

  /// No description provided for @planYearlyNote.
  ///
  /// In en, this message translates to:
  /// **'Per year · 41% savings'**
  String get planYearlyNote;

  /// No description provided for @planLifetimeNote.
  ///
  /// In en, this message translates to:
  /// **'One payment, forever'**
  String get planLifetimeNote;

  /// No description provided for @featureNoAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get featureNoAdsTitle;

  /// No description provided for @featureNoAdsBody.
  ///
  /// In en, this message translates to:
  /// **'Removes ads from Home, Budgets and Insights.'**
  String get featureNoAdsBody;

  /// No description provided for @featureUnlimitedBudgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited budgets'**
  String get featureUnlimitedBudgetsTitle;

  /// No description provided for @featureUnlimitedBudgetsBody.
  ///
  /// In en, this message translates to:
  /// **'Create as many category budgets as you need, each with alerts.'**
  String get featureUnlimitedBudgetsBody;

  /// No description provided for @featureForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending forecast'**
  String get featureForecastTitle;

  /// No description provided for @featureForecastBody.
  ///
  /// In en, this message translates to:
  /// **'See how much you are likely to spend by the end of the month.'**
  String get featureForecastBody;

  /// No description provided for @featureExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Exports and reports'**
  String get featureExportTitle;

  /// No description provided for @featureExportBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock CSV and PDF exports with a rewarded ad, or get them included with Pro.'**
  String get featureExportBody;

  /// No description provided for @trialDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'7 days free, cancel anytime.'**
  String get trialDisclaimer;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get popular;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'Pro is active'**
  String get proActive;

  /// No description provided for @startTrial.
  ///
  /// In en, this message translates to:
  /// **'Start your 7-day free trial'**
  String get startTrial;

  /// No description provided for @proActivatedDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo: Pro is active and ads are hidden. Real billing is coming in Batch 7 (T-601).'**
  String get proActivatedDemo;

  /// No description provided for @billingNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'The store could not be reached. Check your connection and try again.'**
  String get billingNotAvailable;

  /// No description provided for @savePercentTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save {pct}%'**
  String savePercentTemplate(String pct);

  /// No description provided for @priceEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Estimates — the store shows the exact price in your currency before you pay.'**
  String get priceEstimateNote;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the store…'**
  String get purchasePending;

  /// No description provided for @purchaseThanks.
  ///
  /// In en, this message translates to:
  /// **'Opening the store… your purchase will appear in a moment.'**
  String get purchaseThanks;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore a purchase'**
  String get restorePurchases;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Pro is active again on this device.'**
  String get restoreDone;

  /// No description provided for @restoreNothing.
  ///
  /// In en, this message translates to:
  /// **'No purchase found for this account.'**
  String get restoreNothing;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'SpendStory keeps your ledger on this phone. Pro removes ads and unlocks the forecast, custom date ranges, PDF export and unlimited budgets. Subscriptions renew automatically until you cancel in the Play Store; cancel any time and Pro stays until the period you paid for ends. Lifetime is a one-time payment. Refunds follow the Play Store policy. Your spending data is never sent to us, so cancelling never costs you your ledger.'**
  String get termsBody;

  /// No description provided for @subscriptionFootNote.
  ///
  /// In en, this message translates to:
  /// **'Cancel any time in the Play Store.'**
  String get subscriptionFootNote;

  /// No description provided for @proActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Pro is on. Thanks for paying for an app with no ads.'**
  String get proActiveBody;

  /// No description provided for @renewsOnTemplate.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String renewsOnTemplate(String date);

  /// No description provided for @billingPending.
  ///
  /// In en, this message translates to:
  /// **'The store is holding this payment for review — common for a first purchase. Pro turns on by itself when it clears.'**
  String get billingPending;

  /// No description provided for @billingCanceled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled. Nothing was charged.'**
  String get billingCanceled;

  /// No description provided for @billingFailed.
  ///
  /// In en, this message translates to:
  /// **'The store refused the payment. No money left your account.'**
  String get billingFailed;

  /// No description provided for @billingSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Payment received. Pro is on.'**
  String get billingSucceeded;

  /// No description provided for @personalizedAds.
  ///
  /// In en, this message translates to:
  /// **'Personalized ads'**
  String get personalizedAds;

  /// No description provided for @personalizedAdsBody.
  ///
  /// In en, this message translates to:
  /// **'Off by default in India. With it off, ads still pay for the app — they just know less about you. Your spending is never sent anywhere either way.'**
  String get personalizedAdsBody;

  /// No description provided for @privacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy options'**
  String get privacyOptions;

  /// No description provided for @privacyOptionsBody.
  ///
  /// In en, this message translates to:
  /// **'Change your consent choices at any time.'**
  String get privacyOptionsBody;

  /// No description provided for @privacyOptionsShown.
  ///
  /// In en, this message translates to:
  /// **'Your choices are open.'**
  String get privacyOptionsShown;

  /// No description provided for @privacyOptionsMissing.
  ///
  /// In en, this message translates to:
  /// **'The form could not be opened right now. Try again later.'**
  String get privacyOptionsMissing;

  /// No description provided for @planTaste.
  ///
  /// In en, this message translates to:
  /// **'24-hour taste'**
  String get planTaste;

  /// No description provided for @proTasteBody.
  ///
  /// In en, this message translates to:
  /// **'Pro is on for 24 hours. No ads, and the forecast is open — thanks for watching.'**
  String get proTasteBody;

  /// No description provided for @watchAdForTaste.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad for 24 hours of Pro'**
  String get watchAdForTaste;

  /// No description provided for @tasteEarned.
  ///
  /// In en, this message translates to:
  /// **'Pro is on for 24 hours. Enjoy it.'**
  String get tasteEarned;

  /// No description provided for @tasteMissed.
  ///
  /// In en, this message translates to:
  /// **'The ad was closed before it finished, so nothing was granted. Try again any time.'**
  String get tasteMissed;

  /// No description provided for @tasteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No ad is available right now. Try again in a while.'**
  String get tasteUnavailable;

  /// No description provided for @tasteTomorrow.
  ///
  /// In en, this message translates to:
  /// **'You have used today’s 24-hour Pro. It comes back tomorrow.'**
  String get tasteTomorrow;

  /// No description provided for @trialEndsTitle.
  ///
  /// In en, this message translates to:
  /// **'Free trial ending'**
  String get trialEndsTitle;

  /// No description provided for @trialEndsBody.
  ///
  /// In en, this message translates to:
  /// **'Your free trial is nearly over. Cancel any time in the Play Store — your ledger stays on this phone either way.'**
  String get trialEndsBody;

  /// No description provided for @sourceAutoSms.
  ///
  /// In en, this message translates to:
  /// **'Automatically added from SMS'**
  String get sourceAutoSms;

  /// No description provided for @sourceAutoNotification.
  ///
  /// In en, this message translates to:
  /// **'Automatically added from notification'**
  String get sourceAutoNotification;

  /// No description provided for @sourceRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring payment'**
  String get sourceRecurring;

  /// No description provided for @budgetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month\'s budget'**
  String get budgetThisMonth;

  /// No description provided for @budgetUsed.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get budgetUsed;

  /// No description provided for @budgetNew.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetNew;

  /// No description provided for @budgetSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a budget'**
  String get budgetSetTitle;

  /// No description provided for @budgetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No budget set'**
  String get budgetEmptyTitle;

  /// No description provided for @budgetEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'One overall cap, or limits per category. SpendStory warns you at 80% and again when you cross.'**
  String get budgetEmptyBody;

  /// No description provided for @budgetOverallCap.
  ///
  /// In en, this message translates to:
  /// **'Overall monthly budget'**
  String get budgetOverallCap;

  /// No description provided for @budgetCategoryCap.
  ///
  /// In en, this message translates to:
  /// **'Category budget'**
  String get budgetCategoryCap;

  /// No description provided for @budgetWhichCategory.
  ///
  /// In en, this message translates to:
  /// **'Which category?'**
  String get budgetWhichCategory;

  /// No description provided for @budgetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get budgetAmountLabel;

  /// No description provided for @budgetStartDay.
  ///
  /// In en, this message translates to:
  /// **'Cycle starts on'**
  String get budgetStartDay;

  /// No description provided for @budgetStartDayBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the day your salary arrives.'**
  String get budgetStartDayBody;

  /// No description provided for @budgetAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get budgetAlertsLabel;

  /// No description provided for @budgetAlert80.
  ///
  /// In en, this message translates to:
  /// **'Warn me at 80%'**
  String get budgetAlert80;

  /// No description provided for @budgetAlert100.
  ///
  /// In en, this message translates to:
  /// **'Warn me when I cross it'**
  String get budgetAlert100;

  /// No description provided for @budgetSave.
  ///
  /// In en, this message translates to:
  /// **'Save budget'**
  String get budgetSave;

  /// No description provided for @budgetDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get budgetDelete;

  /// No description provided for @budgetDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this budget?'**
  String get budgetDeleteTitle;

  /// No description provided for @budgetDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The spending already counted stays in the ledger.'**
  String get budgetDeleteBody;

  /// No description provided for @budgetDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily allowance'**
  String get budgetDailyTitle;

  /// No description provided for @budgetDailyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Spend about {amt} a day to stay inside the budget.'**
  String budgetDailyTemplate(String amt);

  /// No description provided for @budgetAllSpent.
  ///
  /// In en, this message translates to:
  /// **'The budget is used up — anything more goes over.'**
  String get budgetAllSpent;

  /// No description provided for @budgetDaysLeftTemplate.
  ///
  /// In en, this message translates to:
  /// **'{n} days left'**
  String budgetDaysLeftTemplate(String n);

  /// No description provided for @budgetSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetSpentLabel;

  /// No description provided for @budgetRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get budgetRemainingLabel;

  /// No description provided for @budgetTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get budgetTotalLabel;

  /// No description provided for @budgetSuggestTemplate.
  ///
  /// In en, this message translates to:
  /// **'This one is {pct}% over. Raise the cap, or slow the spending?'**
  String budgetSuggestTemplate(String pct);

  /// No description provided for @budgetRecentTx.
  ///
  /// In en, this message translates to:
  /// **'Recent spending here'**
  String get budgetRecentTx;

  /// No description provided for @budgetNoTx.
  ///
  /// In en, this message translates to:
  /// **'Nothing counted against this budget yet.'**
  String get budgetNoTx;

  /// No description provided for @budgetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetEdit;

  /// No description provided for @budgetAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get budgetAmountRequired;

  /// No description provided for @budgetOverallName.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get budgetOverallName;

  /// No description provided for @accountsTotalNet.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get accountsTotalNet;

  /// No description provided for @accountAdd.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountAdd;

  /// No description provided for @accountEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountEdit;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountType;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get accountTypeWallet;

  /// No description provided for @accountTypeCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get accountTypeCard;

  /// No description provided for @accountOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountOpeningBalance;

  /// No description provided for @accountLast4.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits (optional)'**
  String get accountLast4;

  /// No description provided for @accountColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get accountColor;

  /// No description provided for @accountBalanceNote.
  ///
  /// In en, this message translates to:
  /// **'Balance = opening + credits − debits, worked out on this phone.'**
  String get accountBalanceNote;

  /// No description provided for @accountNoTx.
  ///
  /// In en, this message translates to:
  /// **'No transactions through this account yet.'**
  String get accountNoTx;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this account?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its transactions stay in the ledger — only the card disappears.'**
  String get accountDeleteBody;

  /// No description provided for @accountSave.
  ///
  /// In en, this message translates to:
  /// **'Save account'**
  String get accountSave;

  /// No description provided for @accountNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the account a name'**
  String get accountNameRequired;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get periodCustom;

  /// No description provided for @trend30.
  ///
  /// In en, this message translates to:
  /// **'Daily spending, last 30 days'**
  String get trend30;

  /// No description provided for @topMerchants.
  ///
  /// In en, this message translates to:
  /// **'Where the money goes'**
  String get topMerchants;

  /// No description provided for @monthCompare.
  ///
  /// In en, this message translates to:
  /// **'This month vs last'**
  String get monthCompare;

  /// No description provided for @biggestJump.
  ///
  /// In en, this message translates to:
  /// **'Biggest jump'**
  String get biggestJump;

  /// No description provided for @patternTitle.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get patternTitle;

  /// No description provided for @patternWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekends cost more than weekdays.'**
  String get patternWeekend;

  /// No description provided for @patternSteady.
  ///
  /// In en, this message translates to:
  /// **'Your spending is steady through the week.'**
  String get patternSteady;

  /// No description provided for @insightProTitle.
  ///
  /// In en, this message translates to:
  /// **'Where this month ends'**
  String get insightProTitle;

  /// No description provided for @insightProBody.
  ///
  /// In en, this message translates to:
  /// **'The forecast and a custom date range are part of Pro.'**
  String get insightProBody;

  /// No description provided for @insightProCta.
  ///
  /// In en, this message translates to:
  /// **'See Pro'**
  String get insightProCta;

  /// No description provided for @deltaMoreTemplate.
  ///
  /// In en, this message translates to:
  /// **'{pct}% more than last month'**
  String deltaMoreTemplate(String pct);

  /// No description provided for @deltaLessTemplate.
  ///
  /// In en, this message translates to:
  /// **'{pct}% less than last month'**
  String deltaLessTemplate(String pct);

  /// No description provided for @deltaSame.
  ///
  /// In en, this message translates to:
  /// **'About the same as last month'**
  String get deltaSame;

  /// No description provided for @insightTapSlice.
  ///
  /// In en, this message translates to:
  /// **'Tap a slice for the details'**
  String get insightTapSlice;

  /// No description provided for @shareOfSpendingTemplate.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of spending'**
  String shareOfSpendingTemplate(String pct);

  /// No description provided for @txCountTemplate.
  ///
  /// In en, this message translates to:
  /// **'{n} transactions'**
  String txCountTemplate(String n);

  /// No description provided for @alert80Title.
  ///
  /// In en, this message translates to:
  /// **'80% of your budget is used'**
  String get alert80Title;

  /// No description provided for @alert80BodyTemplate.
  ///
  /// In en, this message translates to:
  /// **'{cat}: {amt} left'**
  String alert80BodyTemplate(String amt, String cat);

  /// No description provided for @alert100Title.
  ///
  /// In en, this message translates to:
  /// **'Budget crossed'**
  String get alert100Title;

  /// No description provided for @alert100BodyTemplate.
  ///
  /// In en, this message translates to:
  /// **'{cat}: {amt} over'**
  String alert100BodyTemplate(String amt, String cat);

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring & reminders'**
  String get recurringTitle;

  /// No description provided for @recurringStripTitle.
  ///
  /// In en, this message translates to:
  /// **'Next 30 days'**
  String get recurringStripTitle;

  /// No description provided for @recurringEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing recurring yet'**
  String get recurringEmptyTitle;

  /// No description provided for @recurringEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Rent, EMIs and subscriptions — set them once, and they either post themselves or remind you.'**
  String get recurringEmptyBody;

  /// No description provided for @recurringAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a recurring payment'**
  String get recurringAdd;

  /// No description provided for @recurringNextDueTemplate.
  ///
  /// In en, this message translates to:
  /// **'Next on {date}'**
  String recurringNextDueTemplate(String date);

  /// No description provided for @recurringDueCountTemplate.
  ///
  /// In en, this message translates to:
  /// **'{n} due in the next 30 days'**
  String recurringDueCountTemplate(String n);

  /// No description provided for @recurringAutoPost.
  ///
  /// In en, this message translates to:
  /// **'Post it automatically'**
  String get recurringAutoPost;

  /// No description provided for @recurringAutoPostNote.
  ///
  /// In en, this message translates to:
  /// **'Writes the payment into the ledger on the day.'**
  String get recurringAutoPostNote;

  /// No description provided for @recurringRemindNote.
  ///
  /// In en, this message translates to:
  /// **'No reminder is set for this one.'**
  String get recurringRemindNote;

  /// No description provided for @recurringDueToday.
  ///
  /// In en, this message translates to:
  /// **'due today'**
  String get recurringDueToday;

  /// No description provided for @recurringOverdue.
  ///
  /// In en, this message translates to:
  /// **'was due'**
  String get recurringOverdue;

  /// No description provided for @freqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get freqYearly;

  /// No description provided for @recurringEveryTemplate.
  ///
  /// In en, this message translates to:
  /// **'Every {n} {unit}'**
  String recurringEveryTemplate(String n, String unit);

  /// No description provided for @unitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get unitDays;

  /// No description provided for @unitWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get unitWeeks;

  /// No description provided for @unitMonths.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get unitMonths;

  /// No description provided for @unitYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get unitYears;

  /// No description provided for @recurringNameLabel.
  ///
  /// In en, this message translates to:
  /// **'What is it?'**
  String get recurringNameLabel;

  /// No description provided for @recurringNameHint.
  ///
  /// In en, this message translates to:
  /// **'House rent'**
  String get recurringNameHint;

  /// No description provided for @recurringAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recurringAmountLabel;

  /// No description provided for @recurringCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get recurringCategoryLabel;

  /// No description provided for @recurringAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get recurringAccountLabel;

  /// No description provided for @recurringAccountNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get recurringAccountNone;

  /// No description provided for @recurringFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get recurringFrequencyLabel;

  /// No description provided for @recurringIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get recurringIntervalLabel;

  /// No description provided for @recurringDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get recurringDayLabel;

  /// No description provided for @recurringDayNote.
  ///
  /// In en, this message translates to:
  /// **'A month without that day uses its last one.'**
  String get recurringDayNote;

  /// No description provided for @recurringFirstDue.
  ///
  /// In en, this message translates to:
  /// **'First payment'**
  String get recurringFirstDue;

  /// No description provided for @recurringRemindLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get recurringRemindLabel;

  /// No description provided for @recurringRemindNone.
  ///
  /// In en, this message translates to:
  /// **'Not at all'**
  String get recurringRemindNone;

  /// No description provided for @recurringRemindSameDay.
  ///
  /// In en, this message translates to:
  /// **'On the day'**
  String get recurringRemindSameDay;

  /// No description provided for @recurringRemindOneDay.
  ///
  /// In en, this message translates to:
  /// **'A day before'**
  String get recurringRemindOneDay;

  /// No description provided for @recurringRemindThreeDays.
  ///
  /// In en, this message translates to:
  /// **'Three days before'**
  String get recurringRemindThreeDays;

  /// No description provided for @recurringSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get recurringSave;

  /// No description provided for @recurringDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this rule'**
  String get recurringDelete;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this recurring payment?'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Payments already posted stay in the ledger.'**
  String get recurringDeleteBody;

  /// No description provided for @recurringNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get recurringNameRequired;

  /// No description provided for @recurringAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get recurringAmountRequired;

  /// No description provided for @recurringSettingBody.
  ///
  /// In en, this message translates to:
  /// **'Rent, EMIs, subscriptions'**
  String get recurringSettingBody;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payment'**
  String get reminderTitle;

  /// No description provided for @reminderTodayBodyTemplate.
  ///
  /// In en, this message translates to:
  /// **'{title}: {amt} due today'**
  String reminderTodayBodyTemplate(String amt, String title);

  /// No description provided for @reminderSoonBodyTemplate.
  ///
  /// In en, this message translates to:
  /// **'{title}: {amt} in {n} days'**
  String reminderSoonBodyTemplate(String amt, String n, String title);

  /// No description provided for @sourceManual.
  ///
  /// In en, this message translates to:
  /// **'Added manually'**
  String get sourceManual;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
