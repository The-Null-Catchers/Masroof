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
  String get payee => 'Payee';

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
  String get searchTransactions => 'Search payee, note or category';

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
  String get categoryFood => 'Food & Dining';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHousing => 'Housing & Rent';

  @override
  String get categoryBills => 'Bills & Utilities';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryCharity => 'Charity & Zakat';

  @override
  String get categoryFamily => 'Family';

  @override
  String get categoryOtherExpense => 'Other';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryBusiness => 'Business';

  @override
  String get categoryGifts => 'Gifts';

  @override
  String get categoryInvestments => 'Investments';

  @override
  String get categoryOtherIncome => 'Other income';
}
