// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Masroof';

  @override
  String get appTagline => 'Your money, clearly.';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Try again';

  @override
  String get done => 'Done';

  @override
  String get optional => 'Optional';

  @override
  String get search => 'Search';

  @override
  String get seeAll => 'See all';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidAmount => 'Enter a valid amount';

  @override
  String get amountMustBePositive => 'Amount must be greater than zero';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get networkError => 'You\'re offline. Check your connection and try again.';

  @override
  String get confirmDeleteTitle => 'Delete permanently?';

  @override
  String get confirmDeleteBody => 'This can\'t be undone.';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to keep track of your money.';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Start budgeting in under a minute.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get noAccount => 'New to Masroof?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordBody => 'Enter your email and we\'ll send you a reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetLinkSent => 'If that email is registered, a reset link is on its way.';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordRules => 'At least 8 characters with letters and numbers';

  @override
  String get sessionExpired => 'Your session expired. Please sign in again.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get defaultCurrency => 'Main currency';

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navSettings => 'Settings';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get netWorth => 'Total balance';

  @override
  String get thisMonth => 'This month';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get net => 'Net';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get topSpending => 'Top spending';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get emptyDashboardTitle => 'Let\'s set up your money';

  @override
  String get emptyDashboardBody => 'Add your first account — cash, bank or card — to start tracking.';

  @override
  String get emptyTransactionsTitle => 'No transactions yet';

  @override
  String get emptyTransactionsBody => 'Transactions you add will appear here.';

  @override
  String get noResults => 'No matching transactions';

  @override
  String get syncOffline => 'Offline — changes will sync when you\'re back online';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get syncRejected => 'Some changes were rejected by the server and have been reverted.';

  @override
  String get accounts => 'Accounts';

  @override
  String get addAccount => 'Add account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountName => 'Account name';

  @override
  String get accountType => 'Type';

  @override
  String get currency => 'Currency';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get color => 'Color';

  @override
  String get includeInTotal => 'Include in total balance';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get archived => 'Archived';

  @override
  String get showArchived => 'Show archived';

  @override
  String get currencyLocked => 'Currency can\'t change after transactions are recorded';

  @override
  String get deleteAccountWarning => 'Deleting this account also deletes its transactions and reverses its transfers.';

  @override
  String get emptyAccountsTitle => 'No accounts yet';

  @override
  String get emptyAccountsBody => 'Accounts hold your balances: a wallet, a bank account, a card.';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank account';

  @override
  String get accountTypeCreditCard => 'Credit card';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get accountTypeEWallet => 'E-wallet';

  @override
  String get accountTypeOther => 'Other';

  @override
  String get categories => 'Categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get parentCategory => 'Parent category';

  @override
  String get noParent => 'None (top level)';

  @override
  String get category => 'Category';

  @override
  String get icon => 'Icon';

  @override
  String get moveTransactionsTo => 'Move its transactions to';

  @override
  String get leaveUncategorized => 'Leave uncategorized';

  @override
  String get transactions => 'Transactions';

  @override
  String get newTransaction => 'New transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String get amount => 'Amount';

  @override
  String get account => 'Account';

  @override
  String get fromAccount => 'From account';

  @override
  String get toAccount => 'To account';

  @override
  String amountReceived(String currency) {
    return 'Amount received ($currency)';
  }

  @override
  String get date => 'Date';

  @override
  String get note => 'Note';

  @override
  String get selectAccount => 'Select an account';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get sameAccountError => 'Choose a different account';

  @override
  String get needAccountFirst => 'Add an account before recording transactions.';

  @override
  String transferTo(String account) {
    return 'Transfer to $account';
  }

  @override
  String transferFrom(String account) {
    return 'Transfer from $account';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get all => 'All';

  @override
  String get searchTransactions => 'Search merchant, note, category or tag';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get profile => 'Profile';

  @override
  String get security => 'Security';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordChanged => 'Password changed. Other devices were signed out.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutPending => 'You have unsynced changes. Signing out now will discard them.';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deleteMyAccountBody =>
      'This permanently deletes your profile and all financial data. Enter your password to confirm.';

  @override
  String get about => 'About Masroof';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get aboutBody =>
      'Masroof helps you understand where your money goes — in Arabic and English, online or offline.';

  @override
  String get syncNow => 'Sync now';

  @override
  String lastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get saved => 'Saved';

  @override
  String get merchant => 'Merchant';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCard => 'Card';

  @override
  String get paymentBankTransfer => 'Bank transfer';

  @override
  String get paymentWallet => 'Digital wallet';

  @override
  String get paymentCheque => 'Cheque';

  @override
  String get paymentOther => 'Other';

  @override
  String get tags => 'Tags';

  @override
  String get addTag => 'Add tag';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get duplicated => 'Transaction duplicated';

  @override
  String get undo => 'Undo';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get notes => 'Notes';

  @override
  String get verifyEmailBanner => 'Please verify your email address.';

  @override
  String get resendLink => 'Resend link';

  @override
  String get verificationSent => 'Verification link sent. Check your inbox.';

  @override
  String get onboardingTitle => 'Let\'s personalize Masroof';

  @override
  String get skip => 'Skip';

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get finishOnboarding => 'Start using Masroof';

  @override
  String get onboardingNameTitle => 'What should we call you?';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingCurrencyTitle => 'Your main currency';

  @override
  String get onboardingCurrencyBody => 'Totals and reports use this currency. Accounts can still use others.';

  @override
  String get onboardingIncomeTitle => 'Roughly how much do you earn per month?';

  @override
  String get onboardingIncomeBody => 'Optional — it helps us suggest realistic budgets.';

  @override
  String get onboardingGoalTitle => 'What\'s your main financial goal?';

  @override
  String get onboardingAlertsTitle => 'Stay on track';

  @override
  String get goalTrackSpending => 'Understand my spending';

  @override
  String get goalSaveMoney => 'Save more money';

  @override
  String get goalEmergencyFund => 'Build an emergency fund';

  @override
  String get goalPayDebt => 'Pay off debt';

  @override
  String get goalBudgetBetter => 'Stick to a budget';

  @override
  String get goalInvest => 'Grow my investments';

  @override
  String get goalOther => 'Something else';

  @override
  String get budgetAlerts => 'Budget alerts';

  @override
  String get budgetAlertsHint => 'Warn me as budgets fill up';

  @override
  String get recurringReminders => 'Recurring reminders';

  @override
  String get recurringRemindersHint => 'Remind me about upcoming recurring payments';

  @override
  String get notifications => 'Notifications';

  @override
  String get defaultAccount => 'Default account';

  @override
  String get none => 'None';

  @override
  String get monthStartDay => 'Financial month starts on day';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryRestaurants => 'Restaurants';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryTransportation => 'Transportation';

  @override
  String get categoryFuel => 'Fuel';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryBills => 'Bills';

  @override
  String get categoryInternet => 'Internet';

  @override
  String get categoryMobile => 'Mobile';

  @override
  String get categoryRent => 'Rent';

  @override
  String get categoryHealthcare => 'Healthcare';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryGifts => 'Gifts';

  @override
  String get categorySubscriptions => 'Subscriptions';

  @override
  String get categoryFamily => 'Family';

  @override
  String get categoryOtherExpense => 'Other';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryFreelancing => 'Freelancing';

  @override
  String get categoryBusiness => 'Business';

  @override
  String get categoryInvestments => 'Investments';

  @override
  String get categoryGiftsIncome => 'Gifts';

  @override
  String get categoryRefunds => 'Refunds';

  @override
  String get categoryOtherIncome => 'Other';

  @override
  String get navPlan => 'Plan';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navMore => 'More';

  @override
  String get offlineData => 'Showing saved data — connect to refresh';

  @override
  String get requiresConnection => 'This action needs an internet connection.';

  @override
  String get budgets => 'Budgets';

  @override
  String get addBudget => 'Create budget';

  @override
  String get editBudget => 'Edit budget';

  @override
  String get budgetName => 'Budget name';

  @override
  String get period => 'Period';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get periodCustom => 'Custom period';

  @override
  String get budgetAmount => 'Budget amount';

  @override
  String get startsOn => 'Starts on';

  @override
  String get endsOn => 'Ends on';

  @override
  String get allCategories => 'All expense categories';

  @override
  String get alertThresholds => 'Alert me at (%)';

  @override
  String get alertThresholdsHint => 'Percentages separated by commas, e.g. 50, 75, 90, 100';

  @override
  String get spent => 'Spent';

  @override
  String get remaining => 'Remaining';

  @override
  String get periodEnded => 'Period ended';

  @override
  String get statusOnTrack => 'On track';

  @override
  String get statusWarning => 'Watch it';

  @override
  String get statusExceeded => 'Over budget';

  @override
  String get safeToSpend => 'Safe to spend';

  @override
  String get emptyBudgetsTitle => 'No budgets yet';

  @override
  String get emptyBudgetsBody => 'Set a spending limit for the month, the week or a custom period.';

  @override
  String get goals => 'Savings goals';

  @override
  String get addGoal => 'New goal';

  @override
  String get editGoal => 'Edit goal';

  @override
  String get goalName => 'Goal name';

  @override
  String get goalKind => 'Type';

  @override
  String get goalKindEmergencyFund => 'Emergency fund';

  @override
  String get goalKindLaptop => 'Laptop';

  @override
  String get goalKindCar => 'Car';

  @override
  String get goalKindTravel => 'Travel';

  @override
  String get goalKindWedding => 'Wedding';

  @override
  String get goalKindHome => 'Home';

  @override
  String get goalKindCustom => 'Custom';

  @override
  String get targetAmount => 'Target amount';

  @override
  String get targetDate => 'Target date';

  @override
  String get linkedAccount => 'Linked account';

  @override
  String get noPace => 'Add contributions to see a projection';

  @override
  String get achieved => 'Achieved';

  @override
  String get addMoney => 'Add money';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get contribution => 'Contribution';

  @override
  String get withdrawal => 'Withdrawal';

  @override
  String get history => 'History';

  @override
  String get noEntries => 'No contributions yet.';

  @override
  String get emptyGoalsTitle => 'No goals yet';

  @override
  String get emptyGoalsBody => 'Save for an emergency fund, a laptop or a trip.';

  @override
  String get analytics => 'Analytics';

  @override
  String get thisMonth2 => 'This month';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get savings => 'Savings';

  @override
  String get savingsRate => 'Savings rate';

  @override
  String get avgDailySpending => 'Avg. daily spending';

  @override
  String get incomeVsExpenses => 'Income vs expenses';

  @override
  String get spendingTrend => 'Spending trend';

  @override
  String get balanceTrend => 'Balance trend';

  @override
  String get categoryComparison => 'Category comparison';

  @override
  String get fixedVsVariable => 'Fixed vs variable';

  @override
  String get fixed => 'Fixed';

  @override
  String get variable => 'Variable';

  @override
  String get largestExpenses => 'Largest expenses';

  @override
  String get topMerchants => 'Most frequent merchants';

  @override
  String get insights => 'Insights';

  @override
  String get noInsights => 'No insights yet — keep tracking and they will appear here.';

  @override
  String get noData => 'No data for this period.';

  @override
  String get remainingBudget => 'Remaining budget';

  @override
  String get seeAnalytics => 'See analytics';

  @override
  String overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String perDay(String amount) {
    return '$amount / day';
  }

  @override
  String daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days left', one: '1 day left');
    return '$_temp0';
  }

  @override
  String projectedAtPace(String amount) {
    return 'Projected $amount at this pace';
  }

  @override
  String goalOf(String amount) {
    return 'of $amount';
  }

  @override
  String monthlyNeeded(String amount) {
    return '$amount / month needed';
  }

  @override
  String expectedBy(String date) {
    return 'Expected by $date';
  }

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String timesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count times', one: 'once');
    return '$_temp0';
  }

  @override
  String get navActivity => 'Activity';

  @override
  String get recurring => 'Recurring payments';

  @override
  String get addRecurring => 'New recurring';

  @override
  String get editRecurring => 'Edit recurring';

  @override
  String get recurringName => 'Name';

  @override
  String get frequency => 'Repeats';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get everyInterval => 'Every (interval)';

  @override
  String get whenDue => 'When due';

  @override
  String get modeAuto => 'Add automatically';

  @override
  String get modeRemind => 'Only remind me';

  @override
  String get remindDaysBefore => 'Remind days before';

  @override
  String get paused => 'Paused';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get ended => 'Ended';

  @override
  String get emptyRecurringTitle => 'No recurring payments yet';

  @override
  String get emptyRecurringBody => 'Automate salaries, rent, subscriptions and bills.';

  @override
  String get upcomingPayments => 'Upcoming payments';

  @override
  String get noNotifications => 'You\'re all caught up.';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get inApp => 'In app';

  @override
  String get emailChannel => 'Email';

  @override
  String get notifBudgetThreshold => 'Budget alerts';

  @override
  String get notifBillReminder => 'Bill reminders';

  @override
  String get notifRecurringReminder => 'Recurring payment reminders';

  @override
  String get notifGoalReminder => 'Savings goal reminders';

  @override
  String get notifWeeklySummary => 'Weekly spending summary';

  @override
  String get notifMonthlySummary => 'Monthly financial summary';

  @override
  String get reports => 'Reports & exports';

  @override
  String get reportType => 'Report';

  @override
  String get reportFormat => 'Format';

  @override
  String get generateReport => 'Generate & share';

  @override
  String get reportMonthly => 'Monthly financial report';

  @override
  String get reportTransactions => 'Transactions';

  @override
  String get reportBudgets => 'Budget report';

  @override
  String get reportIncomeExpense => 'Income & expense summary';

  @override
  String get reportCategories => 'Category spending';

  @override
  String get preparingReport => 'Preparing your report…';

  @override
  String get reportFailed => 'The report could not be generated.';

  @override
  String nextOn(String date) {
    return 'Next: $date';
  }

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get receiptScanIntro =>
      'Take a photo of a receipt or pick one from your gallery. We read the merchant, total and date, and you confirm before saving.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get readingReceipt => 'Reading receipt…';

  @override
  String get receiptFailed => 'We could not read this receipt.';

  @override
  String get receiptPartial => 'Some details were not found. You can fill them in on the next step.';

  @override
  String get receiptNeedsInternet =>
      'Scanning a receipt needs an internet connection. You can still add the transaction manually.';

  @override
  String get receiptPickFailed => 'Could not open the camera or gallery.';

  @override
  String get notFound => 'Not found';

  @override
  String get reviewAndSave => 'Review & save';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get reviewReceipt => 'Review receipt';

  @override
  String get receiptVerifyHint => 'Check the details read from the receipt before saving.';
}
