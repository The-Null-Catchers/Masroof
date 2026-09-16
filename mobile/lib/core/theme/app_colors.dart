import 'package:flutter/material.dart';

/// Masroof design tokens. Mirrored in web/src/app/globals.css.
abstract final class AppColors {
  // Brand
  static const emerald = Color(0xFF0F7A68);
  static const emeraldDark = Color(0xFF07463D);
  static const emeraldLight = Color(0xFFE6F4F1);
  static const mint = Color(0xFF7FE3C1);
  static const gold = Color(0xFFF5B83D);

  // Semantic money colors
  static const income = Color(0xFF15803D);
  static const incomeDark = Color(0xFF4ADE80);
  static const expense = Color(0xFFDC2626);
  static const expenseDark = Color(0xFFF87171);
  static const transfer = Color(0xFF2563EB);
  static const transferDark = Color(0xFF60A5FA);

  // Neutrals
  static const ink = Color(0xFF0F172A);
  static const slate = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const canvas = Color(0xFFF7F9F8);
  static const canvasDark = Color(0xFF0B1211);
  static const surfaceDark = Color(0xFF131C1A);

  /// Palette offered when users create accounts and categories.
  static const pickerPalette = <Color>[
    Color(0xFF0F7A68),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFDC2626),
    Color(0xFFF97316),
    Color(0xFFF5B83D),
    Color(0xFF65A30D),
    Color(0xFF0891B2),
    Color(0xFF475569),
  ];
}

/// Money semantics resolved for the current brightness.
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  const MoneyColors({required this.income, required this.expense, required this.transfer});

  final Color income;
  final Color expense;
  final Color transfer;

  static const light = MoneyColors(income: AppColors.income, expense: AppColors.expense, transfer: AppColors.transfer);

  static const dark = MoneyColors(
    income: AppColors.incomeDark,
    expense: AppColors.expenseDark,
    transfer: AppColors.transferDark,
  );

  @override
  MoneyColors copyWith({Color? income, Color? expense, Color? transfer}) {
    return MoneyColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transfer: transfer ?? this.transfer,
    );
  }

  @override
  MoneyColors lerp(MoneyColors? other, double t) {
    if (other == null) return this;
    return MoneyColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
    );
  }
}

extension MoneyColorsX on BuildContext {
  MoneyColors get moneyColors => Theme.of(this).extension<MoneyColors>() ?? MoneyColors.light;
}
