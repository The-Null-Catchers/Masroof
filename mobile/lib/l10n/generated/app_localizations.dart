import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Masroof'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your money, clearly.'**
  String get appTagline;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @amountMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get amountMustBePositive;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get confirmDeleteBody;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep track of your money.'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start budgeting in under a minute.'**
  String get registerSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Masroof?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get forgotPasswordBody;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If that email is registered, a reset link is on its way.'**
  String get resetLinkSent;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordRules.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters with letters and numbers'**
  String get passwordRules;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get sessionExpired;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @defaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Main currency'**
  String get defaultCurrency;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greeting(String name);

  /// No description provided for @netWorth.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get netWorth;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @topSpending.
  ///
  /// In en, this message translates to:
  /// **'Top spending'**
  String get topSpending;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @emptyDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your money'**
  String get emptyDashboardTitle;

  /// No description provided for @emptyDashboardBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first account — cash, bank or card — to start tracking.'**
  String get emptyDashboardBody;

  /// No description provided for @emptyTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get emptyTransactionsTitle;

  /// No description provided for @emptyTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Transactions you add will appear here.'**
  String get emptyTransactionsBody;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get noResults;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes will sync when you\'re back online'**
  String get syncOffline;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String syncPending(int count);

  /// No description provided for @syncRejected.
  ///
  /// In en, this message translates to:
  /// **'Some changes were rejected by the server and have been reverted.'**
  String get syncRejected;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountType;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @includeInTotal.
  ///
  /// In en, this message translates to:
  /// **'Include in total balance'**
  String get includeInTotal;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @showArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get showArchived;

  /// No description provided for @currencyLocked.
  ///
  /// In en, this message translates to:
  /// **'Currency can\'t change after transactions are recorded'**
  String get currencyLocked;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting this account also deletes its transactions and reverses its transfers.'**
  String get deleteAccountWarning;

  /// No description provided for @emptyAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get emptyAccountsTitle;

  /// No description provided for @emptyAccountsBody.
  ///
  /// In en, this message translates to:
  /// **'Accounts hold your balances: a wallet, a bank account, a card.'**
  String get emptyAccountsBody;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountTypeCreditCard;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeEWallet.
  ///
  /// In en, this message translates to:
  /// **'E-wallet'**
  String get accountTypeEWallet;

  /// No description provided for @accountTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountTypeOther;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @parentCategory.
  ///
  /// In en, this message translates to:
  /// **'Parent category'**
  String get parentCategory;

  /// No description provided for @noParent.
  ///
  /// In en, this message translates to:
  /// **'None (top level)'**
  String get noParent;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @moveTransactionsTo.
  ///
  /// In en, this message translates to:
  /// **'Move its transactions to'**
  String get moveTransactionsTo;

  /// No description provided for @leaveUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Leave uncategorized'**
  String get leaveUncategorized;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get newTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @typeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get typeExpense;

  /// No description provided for @typeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get typeIncome;

  /// No description provided for @typeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get typeTransfer;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get toAccount;

  /// No description provided for @amountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received ({currency})'**
  String amountReceived(String currency);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select an account'**
  String get selectAccount;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @sameAccountError.
  ///
  /// In en, this message translates to:
  /// **'Choose a different account'**
  String get sameAccountError;

  /// No description provided for @needAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an account before recording transactions.'**
  String get needAccountFirst;

  /// No description provided for @transferTo.
  ///
  /// In en, this message translates to:
  /// **'Transfer to {account}'**
  String transferTo(String account);

  /// No description provided for @transferFrom.
  ///
  /// In en, this message translates to:
  /// **'Transfer from {account}'**
  String transferFrom(String account);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search merchant, note, category or tag'**
  String get searchTransactions;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
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

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Other devices were signed out.'**
  String get passwordChanged;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutPending.
  ///
  /// In en, this message translates to:
  /// **'You have unsynced changes. Signing out now will discard them.'**
  String get signOutPending;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deleteMyAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile and all financial data. Enter your password to confirm.'**
  String get deleteMyAccountBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Masroof'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Masroof helps you understand where your money goes — in Arabic and English, online or offline.'**
  String get aboutBody;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String lastSynced(String time);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentCard;

  /// No description provided for @paymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentBankTransfer;

  /// No description provided for @paymentWallet.
  ///
  /// In en, this message translates to:
  /// **'Digital wallet'**
  String get paymentWallet;

  /// No description provided for @paymentCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get paymentCheque;

  /// No description provided for @paymentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get paymentOther;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @duplicated.
  ///
  /// In en, this message translates to:
  /// **'Transaction duplicated'**
  String get duplicated;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @verifyEmailBanner.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address.'**
  String get verifyEmailBanner;

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get resendLink;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification link sent. Check your inbox.'**
  String get verificationSent;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s personalize Masroof'**
  String get onboardingTitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @finishOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Start using Masroof'**
  String get finishOnboarding;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your main currency'**
  String get onboardingCurrencyTitle;

  /// No description provided for @onboardingCurrencyBody.
  ///
  /// In en, this message translates to:
  /// **'Totals and reports use this currency. Accounts can still use others.'**
  String get onboardingCurrencyBody;

  /// No description provided for @onboardingIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Roughly how much do you earn per month?'**
  String get onboardingIncomeTitle;

  /// No description provided for @onboardingIncomeBody.
  ///
  /// In en, this message translates to:
  /// **'Optional — it helps us suggest realistic budgets.'**
  String get onboardingIncomeBody;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your main financial goal?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on track'**
  String get onboardingAlertsTitle;

  /// No description provided for @goalTrackSpending.
  ///
  /// In en, this message translates to:
  /// **'Understand my spending'**
  String get goalTrackSpending;

  /// No description provided for @goalSaveMoney.
  ///
  /// In en, this message translates to:
  /// **'Save more money'**
  String get goalSaveMoney;

  /// No description provided for @goalEmergencyFund.
  ///
  /// In en, this message translates to:
  /// **'Build an emergency fund'**
  String get goalEmergencyFund;

  /// No description provided for @goalPayDebt.
  ///
  /// In en, this message translates to:
  /// **'Pay off debt'**
  String get goalPayDebt;

  /// No description provided for @goalBudgetBetter.
  ///
  /// In en, this message translates to:
  /// **'Stick to a budget'**
  String get goalBudgetBetter;

  /// No description provided for @goalInvest.
  ///
  /// In en, this message translates to:
  /// **'Grow my investments'**
  String get goalInvest;

  /// No description provided for @goalOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get goalOther;

  /// No description provided for @budgetAlerts.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts'**
  String get budgetAlerts;

  /// No description provided for @budgetAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'Warn me as budgets fill up'**
  String get budgetAlertsHint;

  /// No description provided for @recurringReminders.
  ///
  /// In en, this message translates to:
  /// **'Recurring reminders'**
  String get recurringReminders;

  /// No description provided for @recurringRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'Remind me about upcoming recurring payments'**
  String get recurringRemindersHint;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @defaultAccount.
  ///
  /// In en, this message translates to:
  /// **'Default account'**
  String get defaultAccount;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @monthStartDay.
  ///
  /// In en, this message translates to:
  /// **'Financial month starts on day'**
  String get monthStartDay;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get categoryRestaurants;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryTransportation;

  /// No description provided for @categoryFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get categoryFuel;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get categoryBills;

  /// No description provided for @categoryInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get categoryInternet;

  /// No description provided for @categoryMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get categoryMobile;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @categoryHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get categoryHealthcare;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get categoryGifts;

  /// No description provided for @categorySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get categorySubscriptions;

  /// No description provided for @categoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get categoryFamily;

  /// No description provided for @categoryOtherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOtherExpense;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryFreelancing.
  ///
  /// In en, this message translates to:
  /// **'Freelancing'**
  String get categoryFreelancing;

  /// No description provided for @categoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get categoryBusiness;

  /// No description provided for @categoryInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get categoryInvestments;

  /// No description provided for @categoryGiftsIncome.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get categoryGiftsIncome;

  /// No description provided for @categoryRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get categoryRefunds;

  /// No description provided for @categoryOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOtherIncome;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @offlineData.
  ///
  /// In en, this message translates to:
  /// **'Showing saved data — connect to refresh'**
  String get offlineData;

  /// No description provided for @requiresConnection.
  ///
  /// In en, this message translates to:
  /// **'This action needs an internet connection.'**
  String get requiresConnection;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @addBudget.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get addBudget;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get editBudget;

  /// No description provided for @budgetName.
  ///
  /// In en, this message translates to:
  /// **'Budget name'**
  String get budgetName;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @periodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get periodWeekly;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom period'**
  String get periodCustom;

  /// No description provided for @budgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Budget amount'**
  String get budgetAmount;

  /// No description provided for @startsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts on'**
  String get startsOn;

  /// No description provided for @endsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on'**
  String get endsOn;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All expense categories'**
  String get allCategories;

  /// No description provided for @alertThresholds.
  ///
  /// In en, this message translates to:
  /// **'Alert me at (%)'**
  String get alertThresholds;

  /// No description provided for @alertThresholdsHint.
  ///
  /// In en, this message translates to:
  /// **'Percentages separated by commas, e.g. 50, 75, 90, 100'**
  String get alertThresholdsHint;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @periodEnded.
  ///
  /// In en, this message translates to:
  /// **'Period ended'**
  String get periodEnded;

  /// No description provided for @statusOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get statusOnTrack;

  /// No description provided for @statusWarning.
  ///
  /// In en, this message translates to:
  /// **'Watch it'**
  String get statusWarning;

  /// No description provided for @statusExceeded.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get statusExceeded;

  /// No description provided for @safeToSpend.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend'**
  String get safeToSpend;

  /// No description provided for @emptyBudgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get emptyBudgetsTitle;

  /// No description provided for @emptyBudgetsBody.
  ///
  /// In en, this message translates to:
  /// **'Set a spending limit for the month, the week or a custom period.'**
  String get emptyBudgetsBody;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get goals;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get addGoal;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get editGoal;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalName;

  /// No description provided for @goalKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get goalKind;

  /// No description provided for @goalKindEmergencyFund.
  ///
  /// In en, this message translates to:
  /// **'Emergency fund'**
  String get goalKindEmergencyFund;

  /// No description provided for @goalKindLaptop.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get goalKindLaptop;

  /// No description provided for @goalKindCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get goalKindCar;

  /// No description provided for @goalKindTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get goalKindTravel;

  /// No description provided for @goalKindWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get goalKindWedding;

  /// No description provided for @goalKindHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get goalKindHome;

  /// No description provided for @goalKindCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get goalKindCustom;

  /// No description provided for @targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmount;

  /// No description provided for @targetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get targetDate;

  /// No description provided for @linkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Linked account'**
  String get linkedAccount;

  /// No description provided for @noPace.
  ///
  /// In en, this message translates to:
  /// **'Add contributions to see a projection'**
  String get noPace;

  /// No description provided for @achieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get achieved;

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get addMoney;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @contribution.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get contribution;

  /// No description provided for @withdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get withdrawal;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No contributions yet.'**
  String get noEntries;

  /// No description provided for @emptyGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get emptyGoalsTitle;

  /// No description provided for @emptyGoalsBody.
  ///
  /// In en, this message translates to:
  /// **'Save for an emergency fund, a laptop or a trip.'**
  String get emptyGoalsBody;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @thisMonth2.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth2;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @savingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get savingsRate;

  /// No description provided for @avgDailySpending.
  ///
  /// In en, this message translates to:
  /// **'Avg. daily spending'**
  String get avgDailySpending;

  /// No description provided for @incomeVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income vs expenses'**
  String get incomeVsExpenses;

  /// No description provided for @spendingTrend.
  ///
  /// In en, this message translates to:
  /// **'Spending trend'**
  String get spendingTrend;

  /// No description provided for @balanceTrend.
  ///
  /// In en, this message translates to:
  /// **'Balance trend'**
  String get balanceTrend;

  /// No description provided for @categoryComparison.
  ///
  /// In en, this message translates to:
  /// **'Category comparison'**
  String get categoryComparison;

  /// No description provided for @fixedVsVariable.
  ///
  /// In en, this message translates to:
  /// **'Fixed vs variable'**
  String get fixedVsVariable;

  /// No description provided for @fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixed;

  /// No description provided for @variable.
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get variable;

  /// No description provided for @largestExpenses.
  ///
  /// In en, this message translates to:
  /// **'Largest expenses'**
  String get largestExpenses;

  /// No description provided for @topMerchants.
  ///
  /// In en, this message translates to:
  /// **'Most frequent merchants'**
  String get topMerchants;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @noInsights.
  ///
  /// In en, this message translates to:
  /// **'No insights yet — keep tracking and they will appear here.'**
  String get noInsights;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get noData;

  /// No description provided for @remainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Remaining budget'**
  String get remainingBudget;

  /// No description provided for @seeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'See analytics'**
  String get seeAnalytics;

  /// No description provided for @overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String overBy(String amount);

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} / day'**
  String perDay(String amount);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left} other{{days} days left}}'**
  String daysLeft(int days);

  /// No description provided for @projectedAtPace.
  ///
  /// In en, this message translates to:
  /// **'Projected {amount} at this pace'**
  String projectedAtPace(String amount);

  /// No description provided for @goalOf.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String goalOf(String amount);

  /// No description provided for @monthlyNeeded.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month needed'**
  String monthlyNeeded(String amount);

  /// No description provided for @expectedBy.
  ///
  /// In en, this message translates to:
  /// **'Expected by {date}'**
  String expectedBy(String date);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(int count);

  /// No description provided for @timesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{once} other{{count} times}}'**
  String timesCount(int count);

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring payments'**
  String get recurring;

  /// No description provided for @addRecurring.
  ///
  /// In en, this message translates to:
  /// **'New recurring'**
  String get addRecurring;

  /// No description provided for @editRecurring.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring'**
  String get editRecurring;

  /// No description provided for @recurringName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get recurringName;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get frequency;

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

  /// No description provided for @everyInterval.
  ///
  /// In en, this message translates to:
  /// **'Every (interval)'**
  String get everyInterval;

  /// No description provided for @whenDue.
  ///
  /// In en, this message translates to:
  /// **'When due'**
  String get whenDue;

  /// No description provided for @modeAuto.
  ///
  /// In en, this message translates to:
  /// **'Add automatically'**
  String get modeAuto;

  /// No description provided for @modeRemind.
  ///
  /// In en, this message translates to:
  /// **'Only remind me'**
  String get modeRemind;

  /// No description provided for @remindDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind days before'**
  String get remindDaysBefore;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended;

  /// No description provided for @emptyRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'No recurring payments yet'**
  String get emptyRecurringTitle;

  /// No description provided for @emptyRecurringBody.
  ///
  /// In en, this message translates to:
  /// **'Automate salaries, rent, subscriptions and bills.'**
  String get emptyRecurringBody;

  /// No description provided for @upcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payments'**
  String get upcomingPayments;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences;

  /// No description provided for @inApp.
  ///
  /// In en, this message translates to:
  /// **'In app'**
  String get inApp;

  /// No description provided for @emailChannel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailChannel;

  /// No description provided for @notifBudgetThreshold.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts'**
  String get notifBudgetThreshold;

  /// No description provided for @notifBillReminder.
  ///
  /// In en, this message translates to:
  /// **'Bill reminders'**
  String get notifBillReminder;

  /// No description provided for @notifRecurringReminder.
  ///
  /// In en, this message translates to:
  /// **'Recurring payment reminders'**
  String get notifRecurringReminder;

  /// No description provided for @notifGoalReminder.
  ///
  /// In en, this message translates to:
  /// **'Savings goal reminders'**
  String get notifGoalReminder;

  /// No description provided for @notifWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly spending summary'**
  String get notifWeeklySummary;

  /// No description provided for @notifMonthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly financial summary'**
  String get notifMonthlySummary;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports & exports'**
  String get reports;

  /// No description provided for @reportType.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportType;

  /// No description provided for @reportFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get reportFormat;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate & share'**
  String get generateReport;

  /// No description provided for @reportMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly financial report'**
  String get reportMonthly;

  /// No description provided for @reportTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reportTransactions;

  /// No description provided for @reportBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budget report'**
  String get reportBudgets;

  /// No description provided for @reportIncomeExpense.
  ///
  /// In en, this message translates to:
  /// **'Income & expense summary'**
  String get reportIncomeExpense;

  /// No description provided for @reportCategories.
  ///
  /// In en, this message translates to:
  /// **'Category spending'**
  String get reportCategories;

  /// No description provided for @preparingReport.
  ///
  /// In en, this message translates to:
  /// **'Preparing your report…'**
  String get preparingReport;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'The report could not be generated.'**
  String get reportFailed;

  /// No description provided for @nextOn.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextOn(String date);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
