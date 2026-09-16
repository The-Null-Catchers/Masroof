import 'package:flutter/foundation.dart';

@immutable
class Insight {
  const Insight({required this.key, required this.severity, required this.message});

  final String key;

  /// positive | info | warning | critical
  final String severity;
  final String message;

  factory Insight.fromJson(Map<String, dynamic> json) =>
      Insight(key: json['key'] as String, severity: json['severity'] as String, message: json['message'] as String);
}

@immutable
class CategoryTotal {
  const CategoryTotal({
    required this.total,
    required this.count,
    this.categoryId,
    this.name,
    this.defaultKey,
    this.color,
    this.icon,
    this.previousTotal = 0,
    this.change,
  });

  final String? categoryId;
  final String? name;
  final String? defaultKey;
  final String? color;
  final String? icon;
  final int total;
  final int count;
  final int previousTotal;
  final double? change;

  factory CategoryTotal.fromJson(Map<String, dynamic> json) => CategoryTotal(
    categoryId: json['category_id'] as String?,
    name: json['name'] as String?,
    defaultKey: json['default_key'] as String?,
    color: json['color'] as String?,
    icon: json['icon'] as String?,
    total: json['total'] as int,
    count: json['count'] as int,
    previousTotal: json['previous_total'] as int? ?? 0,
    change: (json['change'] as num?)?.toDouble(),
  );
}

@immutable
class TrendMonth {
  const TrendMonth({
    required this.label,
    required this.income,
    required this.expense,
    required this.savings,
    required this.closingBalance,
  });

  final String label;
  final int income;
  final int expense;
  final int savings;
  final int closingBalance;

  factory TrendMonth.fromJson(Map<String, dynamic> json) => TrendMonth(
    label: json['label'] as String,
    income: json['income'] as int,
    expense: json['expense'] as int,
    savings: json['savings'] as int,
    closingBalance: json['closing_balance'] as int,
  );
}

@immutable
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.currency,
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
    required this.savings,
    required this.averageDailySpending,
    required this.categories,
    required this.fixed,
    required this.variable,
    required this.topMerchants,
    required this.largestExpenses,
    this.savingsRate,
    this.incomeChange,
    this.expenseChange,
  });

  final String currency;
  final String start;
  final String end;
  final int income;
  final int expense;
  final int savings;
  final double? savingsRate;
  final int averageDailySpending;
  final double? incomeChange;
  final double? expenseChange;
  final List<CategoryTotal> categories;
  final int fixed;
  final int variable;
  final List<({String merchant, int count, int total})> topMerchants;
  final List<({String? merchant, String? category, String? defaultKey, int amount, DateTime occurredAt})>
  largestExpenses;

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final changes = json['changes'] as Map<String, dynamic>;
    final fixedVariable = json['fixed_vs_variable'] as Map<String, dynamic>;
    return AnalyticsSummary(
      currency: json['currency'] as String,
      start: (json['period'] as Map)['start'] as String,
      end: (json['period'] as Map)['end'] as String,
      income: json['income'] as int,
      expense: json['expense'] as int,
      savings: json['savings'] as int,
      savingsRate: (json['savings_rate'] as num?)?.toDouble(),
      averageDailySpending: json['average_daily_spending'] as int,
      incomeChange: (changes['income'] as num?)?.toDouble(),
      expenseChange: (changes['expense'] as num?)?.toDouble(),
      categories: [for (final c in json['categories'] as List) CategoryTotal.fromJson(c as Map<String, dynamic>)],
      fixed: fixedVariable['fixed'] as int,
      variable: fixedVariable['variable'] as int,
      topMerchants: [
        for (final m in json['top_merchants'] as List)
          (merchant: (m as Map)['merchant'] as String, count: m['count'] as int, total: m['total'] as int),
      ],
      largestExpenses: [
        for (final e in json['largest_expenses'] as List)
          (
            merchant: (e as Map)['merchant'] as String?,
            category: e['category'] as String?,
            defaultKey: e['default_key'] as String?,
            amount: e['amount'] as int,
            occurredAt: DateTime.parse(e['occurred_at'] as String),
          ),
      ],
    );
  }
}
