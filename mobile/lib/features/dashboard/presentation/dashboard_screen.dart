import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/icon_catalog.dart';
import '../../accounts/application/account_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final name = auth is Authenticated ? auth.user.name.split(' ').first : '';
    final accounts = ref.watch(accountsProvider(false));
    final month = currentMonth();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard-add',
        onPressed: () => context.push('/transactions/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addTransaction),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(syncEngineProvider).sync(),
          child: accounts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.genericError)),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.greeting(name),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            DateFormat.yMMMM(context.localeCode).format(DateTime.now()),
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (list.isEmpty)
                  Card(
                    child: EmptyState(
                      useLogo: true,
                      title: l10n.emptyDashboardTitle,
                      body: l10n.emptyDashboardBody,
                      action: FilledButton.icon(
                        onPressed: () => context.push('/accounts/new'),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.addAccount),
                      ),
                    ),
                  )
                else ...[
                  const _BalanceCard(),
                  const SizedBox(height: 16),
                  _MonthSummary(period: month),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final account = list[index];
                        return SizedBox(
                          width: 170,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push('/accounts/${account.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          IconCatalog.forAccountType(account.type),
                                          size: 18,
                                          color: parseHexColor(account.color) ?? theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            account.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    AmountText(
                                      account.balance,
                                      account.currency,
                                      tone: AmountTone.auto,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TopSpending(period: month),
                  const SizedBox(height: 16),
                  const _RecentTransactions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final totals = ref.watch(netWorthProvider).value ?? const {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.emerald, AppColors.emeraldDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.netWorth, style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          if (totals.isEmpty)
            Text('—', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white))
          else
            for (final entry in totals.entries)
              AmountText(
                entry.value,
                entry.key,
                style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
        ],
      ),
    );
  }
}

class _MonthSummary extends ConsumerWidget {
  const _MonthSummary({required this.period});

  final Period period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final totals = ref.watch(periodTotalsProvider(period)).value ?? const <PeriodTotals>[];

    Widget stat(String label, int value, String currency, AmountTone tone, IconData icon) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.hintColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AmountText(
            value,
            currency,
            tone: tone,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.thisMonth, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (totals.isEmpty)
              Text(l10n.emptyTransactionsBody, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            for (final t in totals) ...[
              Row(
                children: [
                  stat(l10n.income, t.income, t.currency, AmountTone.income, Icons.south_west_rounded),
                  stat(l10n.expenses, t.expense, t.currency, AmountTone.expense, Icons.north_east_rounded),
                  stat(l10n.net, t.net, t.currency, AmountTone.auto, Icons.balance_rounded),
                ],
              ),
              if (t.income > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (t.expense / t.income).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    color: t.expense > t.income ? context.moneyColors.expense : theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TopSpending extends ConsumerWidget {
  const _TopSpending({required this.period});

  final Period period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spend = ref.watch(spendByCategoryProvider(period)).value ?? const <CategorySpend>[];
    if (spend.isEmpty) return const SizedBox.shrink();
    final top = spend.take(5).toList();
    final max = top.first.total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.topSpending, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final item in top)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ColoredIconAvatar.named(item.category?.icon, item.category?.color, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.category == null
                                      ? l10n.uncategorized
                                      : l10n.categoryLabel(
                                          name: item.category!.name,
                                          defaultKey: item.category!.defaultKey,
                                        ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AmountText(
                                item.total,
                                item.currency,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: max == 0 ? 0 : item.total / max,
                              minHeight: 6,
                              color: parseHexColor(item.category?.color) ?? theme.colorScheme.primary,
                              backgroundColor: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recent =
        ref.watch(transactionsProvider(const TransactionFilter(limit: 6))).value ?? const <TransactionView>[];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recentTransactions,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(onPressed: () => context.go('/transactions'), child: Text(l10n.seeAll)),
              ],
            ),
          ),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.emptyTransactionsBody,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ),
          for (final view in recent)
            TransactionTile(view: view, onTap: () => context.push('/transactions/${view.transaction.id}/edit')),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
