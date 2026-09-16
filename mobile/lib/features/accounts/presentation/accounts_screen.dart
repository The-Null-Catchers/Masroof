import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/icon_catalog.dart';
import '../application/account_providers.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider(true));
    final netWorth = ref.watch(netWorthProvider).value ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accounts),
        actions: [
          IconButton(
            tooltip: l10n.showArchived,
            isSelected: _showArchived,
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2_rounded),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/accounts/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addAccount),
      ),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.genericError)),
        data: (all) {
          final visible = all.where((a) => _showArchived || !a.archived).toList();
          if (visible.isEmpty) {
            return EmptyState(useLogo: true, title: l10n.emptyAccountsTitle, body: l10n.emptyAccountsBody);
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(syncEngineProvider).sync(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                if (netWorth.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.netWorth, style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor)),
                          const SizedBox(height: 6),
                          for (final entry in netWorth.entries)
                            AmountText(
                              entry.value,
                              entry.key,
                              tone: AmountTone.auto,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (index, account) in visible.indexed) ...[
                        if (index > 0) const Divider(indent: 72),
                        AccountTile(account: account),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AccountTile extends StatelessWidget {
  const AccountTile({super.key, required this.account});

  final AccountEntity account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => context.push('/accounts/${account.id}'),
      leading: ColoredIconAvatar(icon: IconCatalog.forAccountType(account.type), color: parseHexColor(account.color)),
      title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        [l10n.accountTypeLabel(account.type), if (account.archived) l10n.archived].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      ),
      trailing: AmountText(
        account.balance,
        account.currency,
        tone: AmountTone.auto,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
