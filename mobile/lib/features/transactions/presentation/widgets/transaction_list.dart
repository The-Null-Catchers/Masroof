import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/dates.dart';
import '../../data/transactions_repository.dart';
import 'transaction_tile.dart';

/// Sliver list of transactions grouped under day headers.
class TransactionSliverList extends StatelessWidget {
  const TransactionSliverList({super.key, required this.items, this.perspectiveAccountId});

  final List<TransactionView> items;
  final String? perspectiveAccountId;

  @override
  Widget build(BuildContext context) {
    final entries = <Object>[];
    DateTime? currentDay;
    for (final item in items) {
      final day = dayOf(item.transaction.occurredAt);
      if (day != currentDay) {
        entries.add(day);
        currentDay = day;
      }
      entries.add(item);
    }

    final theme = Theme.of(context);
    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        if (entry is DateTime) {
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 6),
            child: Text(
              dayLabel(entry, context.l10n, context.localeCode),
              style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w600),
            ),
          );
        }
        final view = entry as TransactionView;
        return TransactionTile(
          view: view,
          perspectiveAccountId: perspectiveAccountId,
          onTap: () => context.push('/transactions/${view.transaction.id}/edit'),
        );
      },
    );
  }
}
