import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Converts API JSON into Drift companions.
abstract final class SyncMapper {
  static DateTime _date(Object? value) => DateTime.parse(value as String).toUtc();

  static AccountsCompanion account(Map<String, dynamic> json) => AccountsCompanion.insert(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    currency: json['currency'] as String,
    openingBalance: Value(json['opening_balance_minor'] as int),
    balance: Value(json['balance_minor'] as int),
    color: Value(json['color'] as String?),
    icon: Value(json['icon'] as String?),
    includeInTotal: Value(json['include_in_total'] as bool),
    archived: Value(json['archived'] as bool),
    sortOrder: Value(json['sort_order'] as int),
    updatedAt: _date(json['updated_at']),
  );

  static CategoriesCompanion category(Map<String, dynamic> json) => CategoriesCompanion.insert(
    id: json['id'] as String,
    name: json['name'] as String,
    defaultKey: Value(json['default_key'] as String?),
    type: json['type'] as String,
    parentId: Value(json['parent_id'] as String?),
    color: Value(json['color'] as String?),
    icon: Value(json['icon'] as String?),
    archived: Value(json['archived'] as bool),
    sortOrder: Value(json['sort_order'] as int),
    updatedAt: _date(json['updated_at']),
  );

  static TransactionsCompanion transaction(Map<String, dynamic> json) => TransactionsCompanion.insert(
    id: json['id'] as String,
    type: json['type'] as String,
    amount: json['amount_minor'] as int,
    currency: json['currency'] as String,
    accountId: json['account_id'] as String,
    categoryId: Value(json['category_id'] as String?),
    transferAccountId: Value(json['transfer_account_id'] as String?),
    transferAmount: Value(json['transfer_amount_minor'] as int?),
    occurredAt: _date(json['occurred_at']),
    payee: Value(json['payee'] as String?),
    note: Value(json['note'] as String?),
    updatedAt: _date(json['updated_at']),
  );
}
