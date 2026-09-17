import 'package:flutter/foundation.dart';

@immutable
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.name,
    required this.type,
    required this.accountId,
    required this.currency,
    required this.amount,
    required this.amountMinor,
    required this.frequency,
    required this.interval,
    required this.startsOn,
    required this.mode,
    required this.remindDaysBefore,
    required this.paused,
    this.categoryId,
    this.transferAccountId,
    this.merchant,
    this.endsOn,
    this.nextOccurrenceOn,
    this.categoryName,
    this.categoryKey,
    this.categoryIcon,
    this.categoryColor,
  });

  final String id;
  final String name;
  final String type;
  final String accountId;
  final String? categoryId;
  final String? transferAccountId;
  final String currency;
  final String amount;
  final int amountMinor;
  final String? merchant;
  final String frequency;
  final int interval;
  final String startsOn;
  final String? endsOn;
  final String? nextOccurrenceOn;
  final String mode;
  final int remindDaysBefore;
  final bool paused;
  final String? categoryName;
  final String? categoryKey;
  final String? categoryIcon;
  final String? categoryColor;

  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return RecurringRule(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      transferAccountId: json['transfer_account_id'] as String?,
      currency: json['currency'] as String,
      amount: json['amount'] as String,
      amountMinor: json['amount_minor'] as int,
      merchant: json['merchant'] as String?,
      frequency: json['frequency'] as String,
      interval: json['interval'] as int,
      startsOn: json['starts_on'] as String,
      endsOn: json['ends_on'] as String?,
      nextOccurrenceOn: json['next_occurrence_on'] as String?,
      mode: json['mode'] as String,
      remindDaysBefore: json['remind_days_before'] as int,
      paused: json['paused'] as bool,
      categoryName: category?['name'] as String?,
      categoryKey: category?['default_key'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
    );
  }
}
