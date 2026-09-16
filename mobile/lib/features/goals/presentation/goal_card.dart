import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/icon_catalog.dart';
import '../../../core/widgets/progress_bar.dart';
import '../data/goal.dart';

IconData goalIcon(String kind) => switch (kind) {
  'emergency_fund' => Icons.health_and_safety_rounded,
  'laptop' => Icons.laptop_mac_rounded,
  'car' => Icons.directions_car_rounded,
  'travel' => Icons.flight_takeoff_rounded,
  'wedding' => Icons.favorite_rounded,
  'home' => Icons.home_rounded,
  _ => Icons.flag_rounded,
};

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.onTap, this.compact = false});

  final Goal goal;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.localeCode;
    final tint = parseHexColor(goal.color) ?? theme.colorScheme.primary;
    final date = DateFormat.yMMMd(locale);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(goalIcon(goal.kind), color: tint),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          goal.achieved
                              ? l10n.achieved
                              : goal.targetDate != null
                              ? date.format(DateTime.parse(goal.targetDate!))
                              : l10n.goalKindLabel(goal.kind),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: goal.achieved ? context.moneyColors.income : theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AmountText(
                      goal.currentAmountMinor,
                      goal.currency,
                      style: (compact ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    l10n.goalOf(Money.format(goal.targetAmountMinor, goal.currency, locale: locale)),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MoneyProgressBar(percent: goal.percent, label: goal.name),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    '${goal.percent.round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (!goal.achieved && goal.monthlyNeededMinor != null)
                    Text(
                      l10n.monthlyNeeded(Money.format(goal.monthlyNeededMinor!, goal.currency, locale: locale)),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  if (!goal.achieved)
                    Text(
                      goal.expectedCompletionDate != null
                          ? l10n.expectedBy(date.format(DateTime.parse(goal.expectedCompletionDate!)))
                          : l10n.noPace,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
