import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/presentation/widgets/transaction_list.dart';
import '../application/account_providers.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final account = ref.watch(accountProvider(accountId)).value;
    final transactions = ref.watch(transactionsProvider(TransactionFilter(accountId: accountId, limit: 500)));

    if (account == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/accounts/$accountId/edit'),
          ),
        ],
      ),
      floatingActionButton: account.archived
          ? null
          : FloatingActionButton(
              tooltip: l10n.addTransaction,
              onPressed: () => context.push('/transactions/new?account=$accountId'),
              child: const Icon(Icons.add_rounded),
            ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accountTypeLabel(account.type),
                        style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 6),
                      AmountText(
                        account.balance,
                        account.currency,
                        tone: AmountTone.auto,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (account.archived) ...[
                        const SizedBox(height: 8),
                        Chip(label: Text(l10n.archived), visualDensity: VisualDensity.compact),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          ...transactions.when(
            loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
            error: (_, _) => [SliverFillRemaining(child: Center(child: Text(l10n.genericError)))],
            data: (items) => items.isEmpty
                ? [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: l10n.emptyTransactionsTitle,
                        body: l10n.emptyTransactionsBody,
                      ),
                    ),
                  ]
                : [
                    TransactionSliverList(items: items, perspectiveAccountId: accountId),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
          ),
        ],
      ),
    );
  }
}
