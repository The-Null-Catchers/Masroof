import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';

final accountsProvider = StreamProvider.family<List<AccountEntity>, bool>(
  (ref, includeArchived) => ref.watch(accountsRepositoryProvider).watchAll(includeArchived: includeArchived),
);

final accountProvider = StreamProvider.family<AccountEntity?, String>(
  (ref, id) => ref.watch(accountsRepositoryProvider).watch(id),
);

/// Sum of balances per currency for accounts included in the total.
final netWorthProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  return ref.watch(accountsProvider(false)).whenData((accounts) {
    final totals = <String, int>{};
    for (final account in accounts.where((a) => a.includeInTotal)) {
      totals[account.currency] = (totals[account.currency] ?? 0) + account.balance;
    }
    return totals;
  });
});
