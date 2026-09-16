import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/progress_bar.dart';
import '../data/budget.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget, this.onTap});

  final Budget budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = budget.progress;
    final locale = context.localeCode;
    final dates = DateFormat.MMMd(locale);
    final statusColor = switch (p.status) {
      'exceeded' => context.moneyColors.expense,
      'warning' => AppColors.gold,
      _ => context.moneyColors.income,
    };
    final marker = budget.amountMinor == 0 ? null : p.expectedSpentMinor * 100 / budget.amountMinor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(budget.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          '${l10n.budgetPeriodLabel(budget.period)} · ${dates.format(DateTime.parse(p.start))} – ${dates.format(DateTime.parse(p.end))}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.budgetStatusLabel(p.status),
                      style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AmountText(
                      p.spentMinor,
                      budget.currency,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${p.percent.round()}% · ${Money.format(budget.amountMinor, budget.currency, locale: locale)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              MoneyProgressBar(
                percent: p.percent,
                tone: toneForStatus(p.status),
                marker: p.daysLeft > 0 ? marker : null,
                label: budget.name,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.remaining, style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                        p.remainingMinor >= 0
                            ? AmountText(
                                p.remainingMinor,
                                budget.currency,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              )
                            : Text(
                                l10n.overBy(Money.format(-p.remainingMinor, budget.currency, locale: locale)),
                                style: TextStyle(color: context.moneyColors.expense, fontWeight: FontWeight.w600),
                              ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        p.daysLeft > 0 ? l10n.daysLeft(p.daysLeft) : l10n.periodEnded,
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                      ),
                      if (p.daysLeft > 0)
                        Text(
                          l10n.perDay(Money.format(p.safeToSpendDailyMinor, budget.currency, locale: locale)),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
              if (p.daysLeft > 0 && p.projectedSpentMinor > budget.amountMinor) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.projectedAtPace(Money.format(p.projectedSpentMinor, budget.currency, locale: locale)),
                  style: theme.textTheme.bodySmall?.copyWith(color: context.moneyColors.expense),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
