import 'package:flutter/widgets.dart';

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
  });

  final String id;
  final String name;
  final String email;
  final String locale;
  final String currency;
  final String timezone;
  final int weekStart;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    locale: json['locale'] as String,
    currency: json['currency'] as String,
    timezone: json['timezone'] as String,
    weekStart: json['week_start'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'locale': locale,
    'currency': currency,
    'timezone': timezone,
    'week_start': weekStart,
  };

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.characters.first).join().toUpperCase();
  }
}
