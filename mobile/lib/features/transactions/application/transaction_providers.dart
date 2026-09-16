import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/transactions_repository.dart';

final transactionsProvider = StreamProvider.family<List<TransactionView>, TransactionFilter>(
  (ref, filter) => ref.watch(transactionsRepositoryProvider).watch(filter),
);

typedef Period = ({DateTime from, DateTime to});

Period currentMonth([DateTime? now]) {
  final today = now ?? DateTime.now();
  final from = DateTime(today.year, today.month);
  final to = DateTime(today.year, today.month + 1).subtract(const Duration(microseconds: 1));
  return (from: from, to: to);
}

final periodTotalsProvider = StreamProvider.family<List<PeriodTotals>, Period>(
  (ref, period) => ref.watch(transactionsRepositoryProvider).watchTotals(period.from, period.to),
);

final spendByCategoryProvider = StreamProvider.family<List<CategorySpend>, Period>(
  (ref, period) => ref.watch(transactionsRepositoryProvider).watchSpendByCategory(period.from, period.to),
);
