import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../money/money.dart';
import '../theme/app_colors.dart';

enum AmountTone { neutral, income, expense, transfer, auto }

class AmountText extends StatelessWidget {
  const AmountText(
    this.minor,
    this.currency, {
    super.key,
    this.style,
    this.tone = AmountTone.neutral,
    this.signed = false,
  });

  final int minor;
  final String currency;
  final TextStyle? style;
  final AmountTone tone;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyColors;
    final color = switch (tone) {
      AmountTone.income => colors.income,
      AmountTone.expense => colors.expense,
      AmountTone.transfer => colors.transfer,
      AmountTone.auto => minor < 0 ? colors.expense : null,
      AmountTone.neutral => null,
    };
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      Money.format(minor, currency, locale: context.localeCode, signed: signed),
      style: base.copyWith(color: color ?? base.color, fontFeatures: const [FontFeature.tabularFigures()]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
