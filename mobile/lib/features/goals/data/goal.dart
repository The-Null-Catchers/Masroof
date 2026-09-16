import 'package:flutter/foundation.dart';

const goalKinds = ['emergency_fund', 'laptop', 'car', 'travel', 'wedding', 'home', 'custom'];

@immutable
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.kind,
    required this.currency,
    required this.targetAmount,
    required this.targetAmountMinor,
    required this.currentAmountMinor,
    required this.achieved,
    required this.percent,
    required this.remainingMinor,
    this.targetDate,
    this.accountId,
    this.color,
    this.notes,
    this.monthlyNeededMinor,
    this.expectedCompletionDate,
  });

  final String id;
  final String name;
  final String kind;
  final String currency;
  final String targetAmount;
  final int targetAmountMinor;
  final int currentAmountMinor;
  final String? targetDate;
  final String? accountId;
  final String? color;
  final String? notes;
  final bool achieved;
  final double percent;
  final int remainingMinor;
  final int? monthlyNeededMinor;
  final String? expectedCompletionDate;

  factory Goal.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>;
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      currency: json['currency'] as String,
      targetAmount: json['target_amount'] as String,
      targetAmountMinor: json['target_amount_minor'] as int,
      currentAmountMinor: json['current_amount_minor'] as int,
      targetDate: json['target_date'] as String?,
      accountId: json['account_id'] as String?,
      color: json['color'] as String?,
      notes: json['notes'] as String?,
      achieved: json['achieved'] as bool,
      percent: (progress['percent'] as num).toDouble(),
      remainingMinor: progress['remaining_minor'] as int,
      monthlyNeededMinor: progress['monthly_needed_minor'] as int?,
      expectedCompletionDate: progress['expected_completion_date'] as String?,
    );
  }
}

@immutable
class GoalEntry {
  const GoalEntry({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.occurredAt,
    this.note,
  });

  final String id;
  final String type;
  final int amountMinor;
  final DateTime occurredAt;
  final String? note;

  factory GoalEntry.fromJson(Map<String, dynamic> json) => GoalEntry(
    id: json['id'] as String,
    type: json['type'] as String,
    amountMinor: json['amount_minor'] as int,
    occurredAt: DateTime.parse(json['occurred_at'] as String),
    note: json['note'] as String?,
  );
}
