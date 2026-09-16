import 'package:flutter/material.dart';

/// Icon names shared with the API (Material Symbols identifiers).
abstract final class IconCatalog {
  static const icons = <String, IconData>{
    'restaurant': Icons.restaurant_rounded,
    'shopping_basket': Icons.shopping_basket_rounded,
    'directions_car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'receipt': Icons.receipt_long_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'favorite': Icons.favorite_rounded,
    'school': Icons.school_rounded,
    'movie': Icons.movie_rounded,
    'flight': Icons.flight_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'family_restroom': Icons.family_restroom_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'payments': Icons.payments_rounded,
    'storefront': Icons.storefront_rounded,
    'redeem': Icons.redeem_rounded,
    'trending_up': Icons.trending_up_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'pets': Icons.pets_rounded,
    'phone_iphone': Icons.phone_iphone_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'checkroom': Icons.checkroom_rounded,
    'child_care': Icons.child_care_rounded,
    'account_balance': Icons.account_balance_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'credit_card': Icons.credit_card_rounded,
    'savings': Icons.savings_rounded,
    'wallet': Icons.wallet_rounded,
    'category': Icons.category_rounded,
  };

  static IconData resolve(String? name, {IconData fallback = Icons.category_rounded}) => icons[name] ?? fallback;

  static IconData forAccountType(String type) => switch (type) {
    'cash' => Icons.payments_rounded,
    'bank' => Icons.account_balance_rounded,
    'credit_card' => Icons.credit_card_rounded,
    'savings' => Icons.savings_rounded,
    'e_wallet' => Icons.account_balance_wallet_rounded,
    _ => Icons.wallet_rounded,
  };
}

Color? parseHexColor(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

String toHexColor(Color color) {
  final argb = color.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
