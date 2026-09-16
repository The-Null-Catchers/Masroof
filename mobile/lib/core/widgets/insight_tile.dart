import 'package:flutter/material.dart';

import '../../features/analytics/data/analytics.dart';
import '../theme/app_colors.dart';

class InsightTile extends StatelessWidget {
  const InsightTile({super.key, required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyColors;
    final (icon, color) = switch (insight.severity) {
      'positive' => (Icons.check_circle_rounded, colors.income),
      'critical' => (Icons.error_rounded, colors.expense),
      'warning' => (Icons.warning_amber_rounded, AppColors.gold),
      _ => (Icons.info_rounded, colors.transfer),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(insight.message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}
