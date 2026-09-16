import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../data/analytics.dart';

double _major(int minor, String currency) => minor / _pow10(Money.exponent(currency));

int _pow10(int e) => e == 0 ? 1 : 10 * _pow10(e - 1);

String _compact(double value) => NumberFormat.compact(locale: 'en').format(value);

/// Charts read right-to-left in Arabic: order the series accordingly.
List<TrendMonth> _ordered(BuildContext context, List<TrendMonth> months) =>
    Directionality.of(context) == TextDirection.rtl ? months.reversed.toList() : months;

Widget _monthLabel(BuildContext context, List<TrendMonth> months, double value) {
  // Padding around the series produces fractional ticks; label whole months only.
  if (value != value.roundToDouble()) return const SizedBox.shrink();
  final index = value.toInt();
  if (index < 0 || index >= months.length) return const SizedBox.shrink();
  final label = DateFormat.MMM(context.localeCode).format(DateTime.parse('${months[index].label}-15'));
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

AxisTitles _valueAxis(BuildContext context) => AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 40,
    // Skip the extreme labels so they never collide with the month labels.
    minIncluded: false,
    maxIncluded: false,
    getTitlesWidget: (value, meta) => Text(_compact(value), style: Theme.of(context).textTheme.labelSmall),
  ),
);

FlTitlesData _titles(BuildContext context, List<TrendMonth> months) {
  final rtl = Directionality.of(context) == TextDirection.rtl;
  const none = AxisTitles(sideTitles: SideTitles(showTitles: false));
  return FlTitlesData(
    topTitles: none,
    leftTitles: rtl ? none : _valueAxis(context),
    rightTitles: rtl ? _valueAxis(context) : none,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 24,
        interval: 1,
        getTitlesWidget: (value, meta) => _monthLabel(context, months, value),
      ),
    ),
  );
}

FlGridData _grid(BuildContext context) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1, dashArray: [4, 4]),
);

class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({super.key, required this.months, required this.currency});

  final List<TrendMonth> months;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyColors;
    final data = _ordered(context, months);
    return BarChart(
      BarChartData(
        gridData: _grid(context),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, data),
        barTouchData: BarTouchData(enabled: false),
        barGroups: [
          for (final (i, m) in data.indexed)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: _major(m.income, currency),
                  color: colors.income,
                  width: 9,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: _major(m.expense, currency),
                  color: colors.expense,
                  width: 9,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({super.key, required this.months, required this.currency, this.balance = false});

  final List<TrendMonth> months;
  final String currency;

  /// Plot the closing balance instead of expenses and savings.
  final bool balance;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyColors;
    final primary = Theme.of(context).colorScheme.primary;
    final data = _ordered(context, months);

    LineChartBarData line(List<double> values, Color color, {bool dashed = false, bool fill = false}) =>
        LineChartBarData(
          spots: [for (final (i, v) in values.indexed) FlSpot(i.toDouble(), v)],
          isCurved: true,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 2.5,
          dashArray: dashed ? [6, 4] : null,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: fill, color: color.withValues(alpha: 0.15)),
        );

    return LineChart(
      LineChartData(
        gridData: _grid(context),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, data),
        lineTouchData: const LineTouchData(enabled: false),
        minX: -0.5,
        maxX: data.length - 0.5,
        lineBarsData: balance
            ? [
                line([for (final m in data) _major(m.closingBalance, currency)], primary, fill: true),
              ]
            : [
                line([for (final m in data) _major(m.expense, currency)], colors.expense),
                line([for (final m in data) _major(m.savings, currency)], primary, dashed: true),
              ],
      ),
    );
  }
}
