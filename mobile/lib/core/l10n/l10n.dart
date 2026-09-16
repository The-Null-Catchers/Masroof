import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

export '../../l10n/generated/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String get localeCode => Localizations.localeOf(this).languageCode;
}

/// Localized labels for server enums and built-in categories.
extension DomainLabels on AppLocalizations {
  String accountTypeLabel(String type) => switch (type) {
    'cash' => accountTypeCash,
    'bank' => accountTypeBank,
    'credit_card' => accountTypeCreditCard,
    'savings' => accountTypeSavings,
    'e_wallet' => accountTypeEWallet,
    _ => accountTypeOther,
  };

  String transactionTypeLabel(String type) => switch (type) {
    'income' => typeIncome,
    'transfer' => typeTransfer,
    _ => typeExpense,
  };

  /// Built-in categories follow the UI language until the user renames them.
  String categoryLabel({required String name, String? defaultKey}) => switch (defaultKey) {
    'food' => categoryFood,
    'restaurants' => categoryRestaurants,
    'groceries' => categoryGroceries,
    'transportation' => categoryTransportation,
    'fuel' => categoryFuel,
    'shopping' => categoryShopping,
    'entertainment' => categoryEntertainment,
    'bills' => categoryBills,
    'internet' => categoryInternet,
    'mobile' => categoryMobile,
    'rent' => categoryRent,
    'healthcare' => categoryHealthcare,
    'education' => categoryEducation,
    'travel' => categoryTravel,
    'gifts' => categoryGifts,
    'subscriptions' => categorySubscriptions,
    'family' => categoryFamily,
    'other_expense' => categoryOtherExpense,
    'salary' => categorySalary,
    'freelancing' => categoryFreelancing,
    'business' => categoryBusiness,
    'investments' => categoryInvestments,
    'gifts_income' => categoryGiftsIncome,
    'refunds' => categoryRefunds,
    'other_income' => categoryOtherIncome,
    _ => name,
  };

  String paymentMethodLabel(String method) => switch (method) {
    'cash' => paymentCash,
    'card' => paymentCard,
    'bank_transfer' => paymentBankTransfer,
    'wallet' => paymentWallet,
    'cheque' => paymentCheque,
    _ => paymentOther,
  };

  String goalLabel(String goal) => switch (goal) {
    'track_spending' => goalTrackSpending,
    'save_money' => goalSaveMoney,
    'emergency_fund' => goalEmergencyFund,
    'pay_debt' => goalPayDebt,
    'budget_better' => goalBudgetBetter,
    'invest' => goalInvest,
    _ => goalOther,
  };

  String goalKindLabel(String kind) => switch (kind) {
    'emergency_fund' => goalKindEmergencyFund,
    'laptop' => goalKindLaptop,
    'car' => goalKindCar,
    'travel' => goalKindTravel,
    'wedding' => goalKindWedding,
    'home' => goalKindHome,
    _ => goalKindCustom,
  };

  String budgetPeriodLabel(String period) => switch (period) {
    'weekly' => periodWeekly,
    'custom' => periodCustom,
    _ => periodMonthly,
  };

  String budgetStatusLabel(String status) => switch (status) {
    'exceeded' => statusExceeded,
    'warning' => statusWarning,
    _ => statusOnTrack,
  };
}
