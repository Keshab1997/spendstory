// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ob1Title => 'Every payment files itself';

  @override
  String get ob1Body =>
      'SpendStory reads your bank\'s transaction SMS and your payment apps\' notifications, and writes the expense down for you. No typing.';

  @override
  String get ob1B1 => 'Works with 50 bank senders';

  @override
  String get ob1B2 => 'Reads lakh-format amounts correctly';

  @override
  String get ob1B3 => 'An OTP is never read, ever';

  @override
  String get ob2Title => 'See where the money goes';

  @override
  String get ob2Body =>
      'Category by category, month by month, with the one number that changes behaviour: what is left in the budget.';

  @override
  String get ob2B1 => 'Category split and top merchants';

  @override
  String get ob2B2 => 'Monthly budget with an 80% warning';

  @override
  String get ob2B3 => 'Forecast for the end of the month';

  @override
  String get ob3Title => 'Your data stays on your phone';

  @override
  String get ob3Body =>
      'There is no server, no account and no sign-in. Everything is stored on this device and nowhere else.';

  @override
  String get ob3B1 => 'Nothing is uploaded — not one byte';

  @override
  String get ob3B2 => 'Delete everything, any time';

  @override
  String get ob3B3 => 'Works with no internet at all';

  @override
  String get obNext => 'Next';

  @override
  String get obBack => 'Back';

  @override
  String get obSkip => 'Skip';

  @override
  String get obStart => 'Get started';

  @override
  String get permTitle => 'Let SpendStory read bank SMS?';

  @override
  String get permWhy =>
      'This is how the app captures spending without you typing. Android will ask for permission in the next step.';

  @override
  String get permReads => 'What it reads';

  @override
  String get permReadsBody =>
      'Transaction alerts from banks, cards and wallets — the amount, the merchant and the date.';

  @override
  String get permNever => 'What it never touches';

  @override
  String get permNeverBody =>
      'OTPs, passwords, PINs and personal messages. OTPs are dropped before anything else looks at them, and no message is ever sent anywhere.';

  @override
  String get permAllow => 'Allow reading SMS';

  @override
  String get permTryAgain => 'Try again';

  @override
  String get permNotNow => 'Not now';

  @override
  String get permDenied =>
      'No problem — you can add expenses by hand, and turn this on later from Settings.';

  @override
  String get permWebNote =>
      'On the web preview there is no Android to ask — the real prompt only appears in the phone build. Use “Not now” to carry on.';

  @override
  String get manualLink => 'I would rather not give SMS access';

  @override
  String get notifTitle => 'One more, and it is optional';

  @override
  String get notifWhy =>
      'Payment apps like Google Pay and PhonePe send their own notification. With access, those are captured too — otherwise a UPI payment may be missed if the bank\'s SMS is delayed.';

  @override
  String get notifOn => 'Notification access is on';

  @override
  String get notifOff => 'Notification access is off';

  @override
  String get notifApps => 'Only these six apps are ever looked at:';

  @override
  String get notifOnlyThese =>
      'Every other notification on your phone is ignored completely. SpendStory never reads WhatsApp, email or personal messages.';

  @override
  String get notifOpen => 'Open notification settings';

  @override
  String get notifSkip => 'Skip this';

  @override
  String get notifContinue => 'Continue';

  @override
  String get notifManualHint =>
      'Open Settings → Notifications → Notification access, and turn on SpendStory.';

  @override
  String get manualTitle => 'Use it by hand';

  @override
  String get manualBody =>
      'Perfectly fine — the ledger, budgets and insights all work with expenses you enter yourself. You can switch capture on later from Settings.';

  @override
  String get manualP1 => 'Add in three taps';

  @override
  String get manualP1Body => 'Amount, category, done.';

  @override
  String get manualP2 => 'Everything still works';

  @override
  String get manualP2Body => 'Budgets, categories, insights, export.';

  @override
  String get manualP3 => 'Turn on capture later';

  @override
  String get manualP3Body => 'Settings → SMS capture, any time.';

  @override
  String get manualStart => 'Start using SpendStory';

  @override
  String get manualBack => 'Actually, let me give SMS access';

  @override
  String get appName => 'SpendStory';

  @override
  String get appTagline => 'Your money\'s story, right on your phone';

  @override
  String get greeting => 'Hello';

  @override
  String get heroLabel => 'Spent this month';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Spent';

  @override
  String get recentTx => 'Recent transactions';

  @override
  String get seeAll => 'See all';

  @override
  String get addTx => 'Add';

  @override
  String get budget => 'Budget';

  @override
  String get categories => 'Categories';

  @override
  String get reports => 'Reports';

  @override
  String get vsLastMonth => 'vs last month';

  @override
  String get monthlyBudget => 'Monthly budget';

  @override
  String get budgetLeft => 'left';

  @override
  String get over => 'over';

  @override
  String get txTitle => 'Transactions';

  @override
  String get insights => 'Insights';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languagePrompt => 'Choose a language. You can change it anytime.';

  @override
  String get start => 'Get started';

  @override
  String get home => 'Home';

  @override
  String get uncategorised => 'Uncategorised';

  @override
  String get thisMonth => 'This month';

  @override
  String get trend => 'Last 6 months';

  @override
  String get topCategories => 'Where the money went';

  @override
  String get noDataTitle => 'Nothing here yet';

  @override
  String get noDataBody =>
      'Your transactions will appear here as soon as you spend.';

  @override
  String get addFirst => 'Add the first one';

  @override
  String get emptyTxTitle => 'No transactions yet';

  @override
  String get emptyTxBody =>
      'Turn on SMS capture and every payment files itself. Or add one by hand.';

  @override
  String get demoBanner => 'Web preview';

  @override
  String get demoBannerBody =>
      'Demo data. The phone build reads your bank SMS — on device only.';

  @override
  String get about => 'About SpendStory';

  @override
  String get aboutBody => 'Nothing leaves your phone';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody => 'Reads only bank SMS. Never uploaded.';

  @override
  String get privacyDetails =>
      'SpendStory reads bank transaction SMS only — never OTPs. Your data is never sent to a server, and no account is needed. Uninstall the app to remove its data from your phone.';

  @override
  String get privacyOnDevice => '100% on-device';

  @override
  String get version => 'Version';

  @override
  String get proTitle => 'SpendStory Pro';

  @override
  String get proBody => 'No ads, unlimited budgets, forecasts';

  @override
  String get search => 'Search';

  @override
  String get accounts => 'Accounts';

  @override
  String get savings => 'Net saved';

  @override
  String get comingSoon => 'Coming in the next batch';

  @override
  String get comingSoonBody =>
      'This screen is built in Batch 4–6. The shell, theme and demo data are live now.';

  @override
  String get adLabel => 'Advertisement';

  @override
  String get adBanner => 'banner';

  @override
  String get adNative => 'native';

  @override
  String get unknownCategory => 'Unknown';

  @override
  String get budgetExceeded =>
      'You\'ve gone over budget — time to rein in spending.';

  @override
  String get forecast => 'Estimated spending by month-end';

  @override
  String get addEditUnavailable =>
      'Adding and editing transactions are coming soon.';

  @override
  String get activeNoAds => 'Active · ad-free';

  @override
  String get budgetSettingBody => 'Set monthly limits by category';

  @override
  String get categoriesSettingBody => 'Create your own categories';

  @override
  String get accountsSettingBody => 'Bank · cash · wallet';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataSubtitle =>
      'Permanently erase everything after two confirmations';

  @override
  String get eraseTitle => 'Delete all data?';

  @override
  String get eraseBody =>
      'All transactions, budgets and categories will be deleted. This cannot be undone.';

  @override
  String get keep => 'Keep it';

  @override
  String get erase => 'Delete';

  @override
  String get confirm => 'Are you sure?';

  @override
  String get lastChance =>
      'Last chance — everything will be erased after this.';

  @override
  String get no => 'No';

  @override
  String get yesErase => 'Yes, delete everything';

  @override
  String get demoEraseUnavailable =>
      'Data deletion is disabled in demo mode. Use the phone app to erase your data.';

  @override
  String get transactionDetailTitle => 'Transaction details';

  @override
  String get transactionDetailSubtitle => 'S-11 · Transaction detail';

  @override
  String get transactionDetailBody =>
      'Original SMS, category changes, notes and deletion will appear here. Coming in Batch 5 (T-403).';

  @override
  String get categoryPageSubtitle => 'S-13 · Category manager';

  @override
  String get categoryPageBody =>
      'Create your own categories and choose their icons and colours. Coming in Batch 5 (T-405).';

  @override
  String get searchPageSubtitle => 'S-18 · Search and filters';

  @override
  String get searchPageBody =>
      'Find transactions by merchant, amount or date. Coming in Batch 5 (T-406).';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundSubtitle => '404';

  @override
  String get notFoundBody => 'Return to Home from Settings.';

  @override
  String get txFilterAll => 'All';

  @override
  String get txDelete => 'Delete';

  @override
  String get txRecategorise => 'Change category';

  @override
  String get txPickCategory => 'Which category?';

  @override
  String get txDeleted => 'Deleted';

  @override
  String get txUndo => 'Undo';

  @override
  String get txSwipeHint =>
      'Swipe a row — left to delete, right to change its category.';

  @override
  String get txMonthEmptyTitle => 'Nothing in this month';

  @override
  String get txMonthEmptyBody => 'Pick another month, or clear the filter.';

  @override
  String get detailTitle => 'Transaction';

  @override
  String get detailDate => 'Date';

  @override
  String get detailCategory => 'Category';

  @override
  String get detailAccount => 'Account';

  @override
  String get detailMode => 'Mode';

  @override
  String get detailSource => 'Source';

  @override
  String get detailNote => 'Note';

  @override
  String get detailChange => 'Change';

  @override
  String get detailRawTitle => 'Original message';

  @override
  String get detailRawHint =>
      'This is the exact text this entry was read from. It never leaves your phone.';

  @override
  String get detailNoRaw =>
      'You typed this one in, so there is no message to show.';

  @override
  String get detailEdit => 'Edit';

  @override
  String get detailDeleteConfirmTitle => 'Delete this transaction?';

  @override
  String get detailDeleteConfirmBody =>
      'It leaves your totals right away. You can undo it from the list.';

  @override
  String get detailNotFound => 'That transaction is no longer here.';

  @override
  String get cancel => 'Cancel';

  @override
  String get addTitle => 'New transaction';

  @override
  String get editTitle => 'Edit transaction';

  @override
  String get amountLabel => 'Amount';

  @override
  String get merchantHint => 'Where? (optional)';

  @override
  String get noteHint => 'Note (optional)';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get amountRequired => 'Enter an amount first';

  @override
  String get today => 'Today';

  @override
  String get modeCash => 'Cash';

  @override
  String get modeUpi => 'UPI';

  @override
  String get modeCard => 'Card';

  @override
  String get modeNetbanking => 'Netbanking';

  @override
  String get modeWallet => 'Wallet';

  @override
  String get modeOther => 'Other';

  @override
  String get catManagerTitle => 'Categories';

  @override
  String get catNew => 'New category';

  @override
  String get catEditTitle => 'Edit category';

  @override
  String get catNameEn => 'Name (English)';

  @override
  String get catNameHi => 'Name (Hindi)';

  @override
  String get catNameBn => 'Name (Bengali)';

  @override
  String get catIcon => 'Icon';

  @override
  String get catColor => 'Colour';

  @override
  String get catMonthlyCap => 'Monthly limit (optional)';

  @override
  String get catDelete => 'Delete category';

  @override
  String get catDeleteWarn =>
      'Transactions already filed here keep their history — they just lose the label.';

  @override
  String get catNameRequired => 'A category needs at least one name';

  @override
  String get catEmpty => 'No categories here yet';

  @override
  String get catEmptyBody => 'Add one with the + button.';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Merchant, note or amount';

  @override
  String get searchResultCount => 'results';

  @override
  String get searchNoResults => 'Nothing matched';

  @override
  String get searchNoResultsBody => 'Try a shorter word, or clear a filter.';

  @override
  String get searchStartTitle => 'Search your ledger';

  @override
  String get searchStartBody =>
      'Type a merchant, a note, or an amount like 1240.';

  @override
  String get filterSourceAuto => 'Auto only';

  @override
  String get filterSourceManual => 'Typed only';

  @override
  String get filterClear => 'Clear';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly';

  @override
  String get planLifetime => 'Lifetime';

  @override
  String get planMonthlyNote => 'Per month';

  @override
  String get planYearlyNote => 'Per year · 41% savings';

  @override
  String get planLifetimeNote => 'One payment, forever';

  @override
  String get featureNoAdsTitle => 'No ads';

  @override
  String get featureNoAdsBody => 'Removes ads from Home, Budgets and Insights.';

  @override
  String get featureUnlimitedBudgetsTitle => 'Unlimited budgets';

  @override
  String get featureUnlimitedBudgetsBody =>
      'Create as many category budgets as you need, each with alerts.';

  @override
  String get featureForecastTitle => 'Spending forecast';

  @override
  String get featureForecastBody =>
      'See how much you are likely to spend by the end of the month.';

  @override
  String get featureExportTitle => 'Exports and reports';

  @override
  String get featureExportBody =>
      'CSV export is free for everyone. The PDF statement comes with Pro, or with one rewarded ad.';

  @override
  String get trialDisclaimer => '7 days free, cancel anytime.';

  @override
  String get popular => 'Most popular';

  @override
  String get proActive => 'Pro is active';

  @override
  String get startTrial => 'Start your 7-day free trial';

  @override
  String get proActivatedDemo =>
      'Demo: Pro is active and ads are hidden. Real billing is coming in Batch 7 (T-601).';

  @override
  String get billingNotAvailable =>
      'The store could not be reached. Check your connection and try again.';

  @override
  String savePercentTemplate(String pct) {
    return 'Save $pct%';
  }

  @override
  String get priceEstimateNote =>
      'Estimates — the store shows the exact price in your currency before you pay.';

  @override
  String get purchasePending => 'Waiting for the store…';

  @override
  String get purchaseThanks =>
      'Opening the store… your purchase will appear in a moment.';

  @override
  String get restorePurchases => 'Restore a purchase';

  @override
  String get restoreDone => 'Pro is active again on this device.';

  @override
  String get restoreNothing => 'No purchase found for this account.';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get terms => 'Terms';

  @override
  String get termsBody =>
      'SpendStory keeps your ledger on this phone. Pro removes ads and unlocks the forecast, custom date ranges, PDF export and unlimited budgets. Subscriptions renew automatically until you cancel in the Play Store; cancel any time and Pro stays until the period you paid for ends. Lifetime is a one-time payment. Refunds follow the Play Store policy. Your spending data is never sent to us, so cancelling never costs you your ledger.';

  @override
  String get subscriptionFootNote => 'Cancel any time in the Play Store.';

  @override
  String get proActiveBody =>
      'Pro is on. Thanks for paying for an app with no ads.';

  @override
  String renewsOnTemplate(String date) {
    return 'Renews on $date';
  }

  @override
  String get billingPending =>
      'The store is holding this payment for review — common for a first purchase. Pro turns on by itself when it clears.';

  @override
  String get billingCanceled => 'Purchase cancelled. Nothing was charged.';

  @override
  String get billingFailed =>
      'The store refused the payment. No money left your account.';

  @override
  String get billingSucceeded => 'Payment received. Pro is on.';

  @override
  String get personalizedAds => 'Personalized ads';

  @override
  String get personalizedAdsBody =>
      'Off by default in India. With it off, ads still pay for the app — they just know less about you. Your spending is never sent anywhere either way.';

  @override
  String get privacyOptions => 'Ad privacy options';

  @override
  String get privacyOptionsBody => 'Change your consent choices at any time.';

  @override
  String get privacyOptionsShown => 'Your choices are open.';

  @override
  String get privacyOptionsMissing =>
      'The form could not be opened right now. Try again later.';

  @override
  String get planTaste => '24-hour taste';

  @override
  String get proTasteBody =>
      'Pro is on for 24 hours. No ads, and the forecast is open — thanks for watching.';

  @override
  String get watchAdForTaste => 'Watch an ad for 24 hours of Pro';

  @override
  String get tasteEarned => 'Pro is on for 24 hours. Enjoy it.';

  @override
  String get tasteMissed =>
      'The ad was closed before it finished, so nothing was granted. Try again any time.';

  @override
  String get tasteUnavailable =>
      'No ad is available right now. Try again in a while.';

  @override
  String get tasteTomorrow =>
      'You have used today’s 24-hour Pro. It comes back tomorrow.';

  @override
  String get trialEndsTitle => 'Free trial ending';

  @override
  String get trialEndsBody =>
      'Your free trial is nearly over. Cancel any time in the Play Store — your ledger stays on this phone either way.';

  @override
  String get sourceAutoSms => 'Automatically added from SMS';

  @override
  String get sourceAutoNotification => 'Automatically added from notification';

  @override
  String get sourceRecurring => 'Recurring payment';

  @override
  String get budgetThisMonth => 'This month\'s budget';

  @override
  String get budgetUsed => 'used';

  @override
  String get budgetNew => 'New budget';

  @override
  String get budgetSetTitle => 'Set a budget';

  @override
  String get budgetEmptyTitle => 'No budget set';

  @override
  String get budgetEmptyBody =>
      'One overall cap, or limits per category. SpendStory warns you at 80% and again when you cross.';

  @override
  String get budgetOverallCap => 'Overall monthly budget';

  @override
  String get budgetCategoryCap => 'Category budget';

  @override
  String get budgetWhichCategory => 'Which category?';

  @override
  String get budgetAmountLabel => 'Monthly limit';

  @override
  String get budgetStartDay => 'Cycle starts on';

  @override
  String get budgetStartDayBody => 'Pick the day your salary arrives.';

  @override
  String get budgetAlertsLabel => 'Alerts';

  @override
  String get budgetAlert80 => 'Warn me at 80%';

  @override
  String get budgetAlert100 => 'Warn me when I cross it';

  @override
  String get budgetSave => 'Save budget';

  @override
  String get budgetDelete => 'Delete budget';

  @override
  String get budgetDeleteTitle => 'Delete this budget?';

  @override
  String get budgetDeleteBody =>
      'The spending already counted stays in the ledger.';

  @override
  String get budgetDailyTitle => 'Daily allowance';

  @override
  String budgetDailyTemplate(String amt) {
    return 'Spend about $amt a day to stay inside the budget.';
  }

  @override
  String get budgetAllSpent =>
      'The budget is used up — anything more goes over.';

  @override
  String budgetDaysLeftTemplate(String n) {
    return '$n days left';
  }

  @override
  String get budgetSpentLabel => 'Spent';

  @override
  String get budgetRemainingLabel => 'Left';

  @override
  String get budgetTotalLabel => 'Limit';

  @override
  String budgetSuggestTemplate(String pct) {
    return 'This one is $pct% over. Raise the cap, or slow the spending?';
  }

  @override
  String get budgetRecentTx => 'Recent spending here';

  @override
  String get budgetNoTx => 'Nothing counted against this budget yet.';

  @override
  String get budgetEdit => 'Edit budget';

  @override
  String get budgetAmountRequired => 'Enter an amount';

  @override
  String get budgetOverallName => 'Overall';

  @override
  String get accountsTotalNet => 'Total balance';

  @override
  String get accountAdd => 'Add account';

  @override
  String get accountEdit => 'Edit account';

  @override
  String get accountName => 'Name';

  @override
  String get accountType => 'Type';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeWallet => 'Wallet';

  @override
  String get accountTypeCard => 'Card';

  @override
  String get accountOpeningBalance => 'Opening balance';

  @override
  String get accountLast4 => 'Last 4 digits (optional)';

  @override
  String get accountColor => 'Colour';

  @override
  String get accountBalanceNote =>
      'Balance = opening + credits − debits, worked out on this phone.';

  @override
  String get accountNoTx => 'No transactions through this account yet.';

  @override
  String get accountDeleteTitle => 'Remove this account?';

  @override
  String get accountDeleteBody =>
      'Its transactions stay in the ledger — only the card disappears.';

  @override
  String get accountSave => 'Save account';

  @override
  String get accountNameRequired => 'Give the account a name';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get periodCustom => 'Custom';

  @override
  String get trend30 => 'Daily spending, last 30 days';

  @override
  String get topMerchants => 'Where the money goes';

  @override
  String get monthCompare => 'This month vs last';

  @override
  String get biggestJump => 'Biggest jump';

  @override
  String get patternTitle => 'Pattern';

  @override
  String get patternWeekend => 'Weekends cost more than weekdays.';

  @override
  String get patternSteady => 'Your spending is steady through the week.';

  @override
  String get insightProTitle => 'Where this month ends';

  @override
  String get insightProBody =>
      'The forecast and a custom date range are part of Pro.';

  @override
  String get insightProCta => 'See Pro';

  @override
  String deltaMoreTemplate(String pct) {
    return '$pct% more than last month';
  }

  @override
  String deltaLessTemplate(String pct) {
    return '$pct% less than last month';
  }

  @override
  String get deltaSame => 'About the same as last month';

  @override
  String get insightTapSlice => 'Tap a slice for the details';

  @override
  String shareOfSpendingTemplate(String pct) {
    return '$pct% of spending';
  }

  @override
  String txCountTemplate(String n) {
    return '$n transactions';
  }

  @override
  String get alert80Title => '80% of your budget is used';

  @override
  String alert80BodyTemplate(String amt, String cat) {
    return '$cat: $amt left';
  }

  @override
  String get alert100Title => 'Budget crossed';

  @override
  String alert100BodyTemplate(String amt, String cat) {
    return '$cat: $amt over';
  }

  @override
  String get recurringTitle => 'Recurring & reminders';

  @override
  String get recurringStripTitle => 'Next 30 days';

  @override
  String get recurringEmptyTitle => 'Nothing recurring yet';

  @override
  String get recurringEmptyBody =>
      'Rent, EMIs and subscriptions — set them once, and they either post themselves or remind you.';

  @override
  String get recurringAdd => 'Add a recurring payment';

  @override
  String recurringNextDueTemplate(String date) {
    return 'Next on $date';
  }

  @override
  String recurringDueCountTemplate(String n) {
    return '$n due in the next 30 days';
  }

  @override
  String get recurringAutoPost => 'Post it automatically';

  @override
  String get recurringAutoPostNote =>
      'Writes the payment into the ledger on the day.';

  @override
  String get recurringRemindNote => 'No reminder is set for this one.';

  @override
  String get recurringDueToday => 'due today';

  @override
  String get recurringOverdue => 'was due';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String recurringEveryTemplate(String n, String unit) {
    return 'Every $n $unit';
  }

  @override
  String get unitDays => 'days';

  @override
  String get unitWeeks => 'weeks';

  @override
  String get unitMonths => 'months';

  @override
  String get unitYears => 'years';

  @override
  String get recurringNameLabel => 'What is it?';

  @override
  String get recurringNameHint => 'House rent';

  @override
  String get recurringAmountLabel => 'Amount';

  @override
  String get recurringCategoryLabel => 'Category';

  @override
  String get recurringAccountLabel => 'Account';

  @override
  String get recurringAccountNone => 'Not set';

  @override
  String get recurringFrequencyLabel => 'How often';

  @override
  String get recurringIntervalLabel => 'Every';

  @override
  String get recurringDayLabel => 'Day of the month';

  @override
  String get recurringDayNote => 'A month without that day uses its last one.';

  @override
  String get recurringFirstDue => 'First payment';

  @override
  String get recurringRemindLabel => 'Remind me';

  @override
  String get recurringRemindNone => 'Not at all';

  @override
  String get recurringRemindSameDay => 'On the day';

  @override
  String get recurringRemindOneDay => 'A day before';

  @override
  String get recurringRemindThreeDays => 'Three days before';

  @override
  String get recurringSave => 'Save';

  @override
  String get recurringDelete => 'Delete this rule';

  @override
  String get recurringDeleteTitle => 'Delete this recurring payment?';

  @override
  String get recurringDeleteBody =>
      'Payments already posted stay in the ledger.';

  @override
  String get recurringNameRequired => 'Give it a name';

  @override
  String get recurringAmountRequired => 'Enter an amount';

  @override
  String get recurringSettingBody => 'Rent, EMIs, subscriptions';

  @override
  String get reminderTitle => 'Upcoming payment';

  @override
  String reminderTodayBodyTemplate(String amt, String title) {
    return '$title: $amt due today';
  }

  @override
  String reminderSoonBodyTemplate(String amt, String n, String title) {
    return '$title: $amt in $n days';
  }

  @override
  String get sourceManual => 'Added manually';

  @override
  String get aboutScreenTitle => 'About & privacy';

  @override
  String get aboutCollectTitle => 'What we collect';

  @override
  String get aboutCollectBody =>
      'Nothing. Your transactions, budgets and notes stay on this phone. There is no server, no account and no sign-in, so there is nowhere for them to go — the app cannot send your data out even if it wanted to.';

  @override
  String get aboutReadTitle => 'What we read, and why';

  @override
  String get aboutReadBody =>
      'Each permission below is asked for exactly one reason. Hand any of them back in Android settings and the app keeps working — you just type more of it yourself.';

  @override
  String get aboutPermSmsTitle => 'Bank SMS';

  @override
  String get aboutPermSmsBody =>
      'Transaction alerts from banks, cards and wallets only — the amount, the merchant and the date. OTPs, passwords and personal messages are dropped before anything else looks at them, and no message is ever sent anywhere.';

  @override
  String get aboutPermNotifyTitle => 'Payment app notifications';

  @override
  String get aboutPermNotifyBody =>
      'With your permission, SpendStory reads notifications from the payment apps you choose — PhonePe, Google Pay, Paytm and the rest — so a UPI payment lands in the ledger the moment it happens.';

  @override
  String get aboutPermAlertsTitle => 'Notifications from us';

  @override
  String get aboutPermAlertsBody =>
      'Only for the budget warnings and payment reminders you switch on yourself. Nothing else is ever notified.';

  @override
  String get aboutPermLockTitle => 'Fingerprint or face (optional)';

  @override
  String get aboutPermLockBody =>
      'Used only to open the app on this phone. The reading stays inside Android — SpendStory never sees it.';

  @override
  String get aboutPermInternetTitle => 'Internet';

  @override
  String get aboutPermInternetBody =>
      'Needed for the ads in the free version and for Play billing. No transaction, amount, merchant or category ever travels with an ad request.';

  @override
  String get aboutRightsTitle => 'Your rights over your data';

  @override
  String get aboutRightAccessTitle => 'See all of it';

  @override
  String get aboutRightAccessBody =>
      'Take the whole ledger out as CSV or JSON from Settings, any time, free.';

  @override
  String get aboutRightCorrectTitle => 'Correct anything';

  @override
  String get aboutRightCorrectBody =>
      'Edit any transaction, change its category, or delete it. A wrong guess by the parser is yours to overrule.';

  @override
  String get aboutRightEraseTitle => 'Erase everything';

  @override
  String get aboutRightEraseBody =>
      'Settings, Delete all data, confirm twice — every transaction, budget and category is gone from this phone immediately.';

  @override
  String get aboutRightWithdrawTitle => 'Take permission back';

  @override
  String get aboutRightWithdrawBody =>
      'Turn SMS or notification access off in Android settings whenever you like. The app goes back to manual entry — nothing is held hostage.';

  @override
  String get aboutEraseTitle => 'How to delete everything';

  @override
  String get aboutEraseStep1 => 'Open Settings → Delete all data.';

  @override
  String get aboutEraseStep2 =>
      'Confirm twice. The second confirmation lists what is about to go.';

  @override
  String get aboutEraseStep3 =>
      'Uninstalling the app takes the database and every setting with it.';

  @override
  String get aboutContactTitle => 'Questions or complaints';

  @override
  String get aboutContactBody =>
      'Write to us and we answer within 30 days. Your data is on your phone, so we cannot look at your ledger — but we can fix what is broken.';

  @override
  String get aboutGrievanceEmail => 'Support email';

  @override
  String get aboutEmailMissing =>
      'The support address is being set up. Until it is live, open an issue on the source repository below.';

  @override
  String get aboutSourceTitle => 'Source code';

  @override
  String get aboutSourceBody =>
      'The whole app is public. Every sentence on this screen can be checked against it.';

  @override
  String get aboutTapToCopy => 'Tap to copy';

  @override
  String get aboutCopied => 'Copied';

  @override
  String get privacyReadAll => 'Read the full policy';

  @override
  String get exportTitle => 'Export & backup';

  @override
  String get exportBody =>
      'Everything here leaves the phone in a file you control. Nothing is uploaded — there is no server to upload it to.';

  @override
  String get exportBackupTitle => 'Back up now';

  @override
  String get exportBackupBody =>
      'Your ledger is locked with AES-256 under a password you choose. We cannot recover that password, so keep it somewhere you trust.';

  @override
  String get exportPassword => 'Password';

  @override
  String get exportPasswordHint =>
      'At least 8 characters. You will need it to restore.';

  @override
  String get exportPasswordTooShort => 'Use at least 8 characters.';

  @override
  String get exportCreateBackup => 'Create backup file';

  @override
  String get exportWorking => 'Encrypting…';

  @override
  String get exportBackupReady => 'Backup ready. Choose where to save it.';

  @override
  String get exportBackupDismissed => 'Nothing was shared.';

  @override
  String get exportBackupUnavailable =>
      'This device has no share sheet to hand the file to.';

  @override
  String get exportBackupFailed => 'The file could not be written.';

  @override
  String exportLastBackup(String when) {
    return 'Last backup: $when';
  }

  @override
  String get exportNeverBackedUp => 'No backup yet.';

  @override
  String get exportDue => 'Your weekly backup is due.';

  @override
  String get exportAutoBackup => 'Weekly reminder';

  @override
  String get exportAutoBackupBody =>
      'Without your password the app cannot open its own backup, so it reminds you once a week instead of writing a file you could not read.';

  @override
  String get exportRestoreTitle => 'Restore from a backup';

  @override
  String get exportRestoreBody =>
      'Pick a backup file and type the password you used. Everything in the file is added; what is already on this phone stays.';

  @override
  String get exportPickFile => 'Choose file';

  @override
  String get exportRestoreAction => 'Restore';

  @override
  String get exportRestoreNeedFile => 'Choose a backup file first.';

  @override
  String get exportRestoreNeedPassword => 'Type the password for this file.';

  @override
  String exportRestoreDone(
    String tx,
    String cats,
    String budgets,
    String accounts,
  ) {
    return 'Restored $tx transactions, $cats categories, $budgets budgets and $accounts accounts.';
  }

  @override
  String get exportRestoreFailed =>
      'That file could not be opened. Check the password and try again.';

  @override
  String get exportCsvTitle => 'CSV export';

  @override
  String get exportCsvBody =>
      'Every transaction as a spreadsheet file. Free, for everyone, always.';

  @override
  String get exportCsvFree => 'Free';

  @override
  String get exportCsvAction => 'Export CSV';

  @override
  String get exportCsvEmpty => 'There is nothing to export yet.';

  @override
  String get exportPdfTitle => 'PDF statement';

  @override
  String get exportPdfPro => 'Pro';

  @override
  String get exportPdfBody =>
      'A printable statement for one month, with totals — part of Pro.';

  @override
  String get exportPdfAction => 'Export PDF';

  @override
  String get exportPdfWatchAd => 'Watch an ad for a free PDF';

  @override
  String exportPdfCredits(String n) {
    return 'Free PDF exports left today: $n';
  }

  @override
  String get exportPdfNoCredits =>
      'Today’s free PDFs are used. Tomorrow they reset.';

  @override
  String get exportPdfEarned => 'Free PDF unlocked.';

  @override
  String get exportPdfMissed => 'No reward this time, so the PDF stays Pro.';

  @override
  String get exportPdfUnavailable => 'No ad to show right now.';

  @override
  String get exportPdfProOnly => 'The PDF statement is part of Pro.';

  @override
  String get exportMonthPrev => 'Previous month';

  @override
  String get exportMonthNext => 'Next month';

  @override
  String get exportDemoUnavailable =>
      'Backups need the installed app — the web preview keeps no ledger.';

  @override
  String get exportShareDrive =>
      'In the share sheet, pick Drive to keep a copy there. SpendStory never uploads the file itself.';

  @override
  String get exportSettingBody => 'Encrypted backup, restore, CSV and PDF';
}
