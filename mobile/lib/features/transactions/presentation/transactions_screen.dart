import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/transaction_providers.dart';
import '../data/transactions_repository.dart';
import 'widgets/transaction_list.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _type;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => setState(() => _query = value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = TransactionFilter(type: _type, search: _query.isEmpty ? null : _query, limit: 500);
    final transactions = ref.watch(transactionsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactions),
        actions: [
          IconButton(
            key: const Key('scan-receipt'),
            tooltip: l10n.scanReceipt,
            onPressed: () => context.push('/transactions/scan'),
            icon: const Icon(Icons.document_scanner_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addTransaction,
        onPressed: () => context.push('/transactions/new'),
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncEngineProvider).sync(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: l10n.searchTransactions,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final (value, label) in [
                      (null, l10n.all),
                      ('expense', l10n.typeExpense),
                      ('income', l10n.typeIncome),
                      ('transfer', l10n.typeTransfer),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: _type == value,
                        onSelected: (_) => setState(() => _type = value),
                      ),
                  ],
                ),
              ),
            ),
            ...transactions.when(
              loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
              error: (e, _) => [SliverFillRemaining(child: Center(child: Text(l10n.genericError)))],
              data: (items) => items.isEmpty
                  ? [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: filter == const TransactionFilter(limit: 500)
                              ? l10n.emptyTransactionsTitle
                              : l10n.noResults,
                          body: l10n.emptyTransactionsBody,
                        ),
                      ),
                    ]
                  : [TransactionSliverList(items: items), const SliverToBoxAdapter(child: SizedBox(height: 96))],
            ),
          ],
        ),
      ),
    );
  }
}
