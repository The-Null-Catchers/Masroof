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
    'groceries' => categoryGroceries,
    'transport' => categoryTransport,
    'housing' => categoryHousing,
    'bills' => categoryBills,
    'shopping' => categoryShopping,
    'health' => categoryHealth,
    'education' => categoryEducation,
    'entertainment' => categoryEntertainment,
    'travel' => categoryTravel,
    'charity' => categoryCharity,
    'family' => categoryFamily,
    'other_expense' => categoryOtherExpense,
    'salary' => categorySalary,
    'business' => categoryBusiness,
    'gifts' => categoryGifts,
    'investments' => categoryInvestments,
    'other_income' => categoryOtherIncome,
    _ => name,
  };
}
