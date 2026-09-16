import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/insight_tile.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../core/widgets/stale_notice.dart';
import '../../planning/application/planning_providers.dart';
import '../data/analytics.dart';
import 'trend_charts.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(analyticsSummaryProvider(_offset));
    final trends = ref.watch(trendsProvider).value;
    final insights = ref.watch(insightsProvider).value;

    String periodLabel(int o) => o == 0
        ? l10n.thisMonth2
        : o == -1
        ? l10n.previousMonth
        : l10n.monthsAgo(-o);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analytics),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: DropdownButton<int>(
              value: _offset,
              underline: const SizedBox.shrink(),
              items: [for (var o = 0; o >= -5; o--) DropdownMenuItem(value: o, child: Text(periodLabel(o)))],
              onChanged: (o) => setState(() => _offset = o ?? 0),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendsProvider);
          ref.invalidate(insightsProvider);
          ref.invalidate(analyticsSummaryProvider(_offset));
          await ref.read(analyticsSummaryProvider(_offset).future);
        },
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              EmptyState(icon: Icons.cloud_off_rounded, title: l10n.genericError, body: describeError(context, e)),
            ],
          ),
          data: (data) => _AnalyticsBody(summary: data.summary, stale: data.stale, trends: trends, insights: insights),
        ),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.summary, required this.stale, this.trends, this.insights});

  final AnalyticsSummary summary;
  final bool stale;
  final List<TrendMonth>? trends;
  final List<Insight>? insights;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = summary;
    final c = s.currency;
    final locale = context.localeCode;
    final maxCategory = s.categories.fold<int>(
      1,
      (m, row) => [m, row.total, row.previousTotal].reduce((a, b) => a > b ? a : b),
    );
    final fixedTotal = s.fixed + s.variable;

    Widget section(String title, Widget child) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        StaleNotice(stale: stale),
        Text(
          '${DateFormat.yMMMd(locale).format(DateTime.parse(s.start))} – ${DateFormat.yMMMd(locale).format(DateTime.parse(s.end))}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _Stat(
              label: l10n.income,
              change: s.incomeChange,
              child: AmountText(s.income, c, tone: AmountTone.income),
            ),
            _Stat(
              label: l10n.expenses,
              change: s.expenseChange,
              invert: true,
              child: AmountText(s.expense, c, tone: AmountTone.expense),
            ),
            _Stat(label: l10n.savingsRate, child: Text(s.savingsRate == null ? '—' : '${s.savingsRate!.round()}%')),
            _Stat(label: l10n.avgDailySpending, child: AmountText(s.averageDailySpending, c)),
          ],
        ),
        const SizedBox(height: 12),
        section(
          l10n.insights,
          insights == null
              ? const LinearProgressIndicator()
              : insights!.isEmpty
              ? Text(l10n.noInsights, style: TextStyle(color: theme.hintColor))
              : Column(children: [for (final i in insights!) InsightTile(insight: i)]),
        ),
        const SizedBox(height: 12),
        if (trends != null) ...[
          section(
            l10n.incomeVsExpenses,
            SizedBox(
              height: 200,
              child: IncomeExpenseChart(months: trends!, currency: c),
            ),
          ),
          const SizedBox(height: 12),
          section(
            l10n.spendingTrend,
            SizedBox(
              height: 180,
              child: TrendLineChart(months: trends!, currency: c),
            ),
          ),
          const SizedBox(height: 12),
          section(
            l10n.balanceTrend,
            SizedBox(
              height: 180,
              child: TrendLineChart(months: trends!, currency: c, balance: true),
            ),
          ),
          const SizedBox(height: 12),
        ],
        section(
          l10n.categoryComparison,
          s.categories.isEmpty
              ? Text(l10n.noData, style: TextStyle(color: theme.hintColor))
              : Column(
                  children: [
                    for (final row in s.categories.take(8))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.categoryId == null
                                        ? l10n.uncategorized
                                        : l10n.categoryLabel(name: row.name ?? '', defaultKey: row.defaultKey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (row.change != null) _Change(value: row.change!, invert: true),
                                const SizedBox(width: 8),
                                AmountText(row.total, c, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            MoneyProgressBar(percent: row.total * 100 / maxCategory, height: 7),
                            const SizedBox(height: 3),
                            MoneyProgressBar(
                              percent: row.previousTotal * 100 / maxCategory,
                              tone: ProgressTone.brand,
                              height: 3,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        section(
          l10n.fixedVsVariable,
          Column(
            children: [
              MoneyProgressBar(percent: fixedTotal == 0 ? 0 : s.fixed * 100 / fixedTotal, height: 12),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text('${l10n.fixed} · ${Money.format(s.fixed, c, locale: locale)}')),
                  Text('${l10n.variable} · ${Money.format(s.variable, c, locale: locale)}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        section(
          l10n.largestExpenses,
          Column(
            children: [
              for (final e in s.largestExpenses)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    e.merchant ?? l10n.categoryLabel(name: e.category ?? l10n.uncategorized, defaultKey: e.defaultKey),
                  ),
                  subtitle: Text(DateFormat.MMMd(locale).format(e.occurredAt.toLocal())),
                  trailing: AmountText(e.amount, c, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        section(
          l10n.topMerchants,
          Column(
            children: [
              for (final m in s.topMerchants)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(m.merchant),
                  subtitle: Text(l10n.timesCount(m.count)),
                  trailing: AmountText(m.total, c, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child, this.change, this.invert = false});

  final String label;
  final Widget child;
  final double? change;
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            DefaultTextStyle.merge(
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              child: child,
            ),
            if (change != null) ...[const SizedBox(height: 4), _Change(value: change!, invert: invert)],
          ],
        ),
      ),
    );
  }
}

class _Change extends StatelessWidget {
  const _Change({required this.value, this.invert = false});

  final double value;
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final good = invert ? value <= 0 : value >= 0;
    final color = good ? context.moneyColors.income : context.moneyColors.expense;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(value >= 0 ? Icons.north_east_rounded : Icons.south_east_rounded, size: 14, color: color),
        Text(
          '${value.abs().toStringAsFixed(value.abs() >= 10 ? 0 : 1)}%',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
