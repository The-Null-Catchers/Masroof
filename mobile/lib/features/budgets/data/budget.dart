import 'package:flutter/foundation.dart';

@immutable
class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.period,
    required this.currency,
    required this.amount,
    required this.amountMinor,
    required this.alertThresholds,
    required this.categoryIds,
    required this.progress,
    this.startsOn,
    this.endsOn,
  });

  final String id;
  final String name;
  final String period;
  final String currency;
  final String amount;
  final int amountMinor;
  final String? startsOn;
  final String? endsOn;
  final List<int> alertThresholds;
  final List<String> categoryIds;
  final BudgetProgress progress;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'] as String,
    name: json['name'] as String,
    period: json['period'] as String,
    currency: json['currency'] as String,
    amount: json['amount'] as String,
    amountMinor: json['amount_minor'] as int,
    startsOn: json['starts_on'] as String?,
    endsOn: json['ends_on'] as String?,
    alertThresholds: (json['alert_thresholds'] as List).cast<int>(),
    categoryIds: (json['category_ids'] as List).cast<String>(),
    progress: BudgetProgress.fromJson(json['progress'] as Map<String, dynamic>),
  );
}

@immutable
class BudgetProgress {
  const BudgetProgress({
    required this.start,
    required this.end,
    required this.spentMinor,
    required this.remainingMinor,
    required this.percent,
    required this.daysLeft,
    required this.safeToSpendDailyMinor,
    required this.expectedSpentMinor,
    required this.projectedSpentMinor,
    required this.status,
  });

  final String start;
  final String end;
  final int spentMinor;
  final int remainingMinor;
  final double percent;
  final int daysLeft;
  final int safeToSpendDailyMinor;
  final int expectedSpentMinor;
  final int projectedSpentMinor;

  /// on_track | warning | exceeded
  final String status;

  factory BudgetProgress.fromJson(Map<String, dynamic> json) => BudgetProgress(
    start: (json['period'] as Map)['start'] as String,
    end: (json['period'] as Map)['end'] as String,
    spentMinor: json['spent_minor'] as int,
    remainingMinor: json['remaining_minor'] as int,
    percent: (json['percent'] as num).toDouble(),
    daysLeft: json['days_left'] as int,
    safeToSpendDailyMinor: json['safe_to_spend_daily_minor'] as int,
    expectedSpentMinor: json['expected_spent_minor'] as int,
    projectedSpentMinor: json['projected_spent_minor'] as int,
    status: json['status'] as String,
  );
}
