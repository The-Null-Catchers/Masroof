import 'package:flutter/widgets.dart';

@immutable
class UserSettings {
  const UserSettings({
    this.monthlyIncomeEstimate,
    this.mainGoal,
    this.budgetAlerts = true,
    this.recurringReminders = true,
    this.defaultAccountId,
    this.monthStartDay = 1,
    this.onboardingCompleted = true,
  });

  final String? monthlyIncomeEstimate;
  final String? mainGoal;
  final bool budgetAlerts;
  final bool recurringReminders;
  final String? defaultAccountId;
  final int monthStartDay;
  final bool onboardingCompleted;

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    monthlyIncomeEstimate: json['monthly_income_estimate'] as String?,
    mainGoal: json['main_goal'] as String?,
    budgetAlerts: json['budget_alerts'] as bool? ?? true,
    recurringReminders: json['recurring_reminders'] as bool? ?? true,
    defaultAccountId: json['default_account_id'] as String?,
    monthStartDay: json['month_start_day'] as int? ?? 1,
    onboardingCompleted: json['onboarding_completed'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'monthly_income_estimate': monthlyIncomeEstimate,
    'main_goal': mainGoal,
    'budget_alerts': budgetAlerts,
    'recurring_reminders': recurringReminders,
    'default_account_id': defaultAccountId,
    'month_start_day': monthStartDay,
    'onboarding_completed': onboardingCompleted,
  };
}

@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.locale,
    required this.currency,
    required this.timezone,
    required this.weekStart,
    this.emailVerified = true,
    this.settings = const UserSettings(),
  });

  final String id;
  final String name;
  final String email;
  final String locale;
  final String currency;
  final String timezone;
  final int weekStart;
  final bool emailVerified;
  final UserSettings settings;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    locale: json['locale'] as String,
    currency: json['currency'] as String,
    timezone: json['timezone'] as String,
    weekStart: json['week_start'] as int,
    // Sessions cached by older app versions lack these fields; don't block them.
    emailVerified: json['email_verified'] as bool? ?? true,
    settings: json['settings'] is Map<String, dynamic>
        ? UserSettings.fromJson(json['settings'] as Map<String, dynamic>)
        : const UserSettings(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'locale': locale,
    'currency': currency,
    'timezone': timezone,
    'week_start': weekStart,
    'email_verified': emailVerified,
    'settings': settings.toJson(),
  };

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.characters.first).join().toUpperCase();
  }
}
