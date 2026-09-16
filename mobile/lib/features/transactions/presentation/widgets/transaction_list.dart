import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/providers.dart';
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
        return SwipeableTransaction(
          view: view,
          child: TransactionTile(
            view: view,
            perspectiveAccountId: perspectiveAccountId,
            onTap: () => context.push('/transactions/${view.transaction.id}/edit'),
          ),
        );
      },
    );
  }
}

/// Swipe start→end to duplicate, end→start to delete (after confirmation).
/// Directions mirror automatically in right-to-left layouts.
class SwipeableTransaction extends ConsumerWidget {
  const SwipeableTransaction({super.key, required this.view, required this.child});

  final TransactionView view;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final id = view.transaction.id;

    Widget background(AlignmentDirectional alignment, Color color, IconData icon, String label) => Container(
      color: color.withValues(alpha: 0.14),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('swipe-$id'),
      background: background(AlignmentDirectional.centerStart, scheme.primary, Icons.copy_rounded, l10n.duplicate),
      secondaryBackground: background(
        AlignmentDirectional.centerEnd,
        scheme.error,
        Icons.delete_outline_rounded,
        l10n.delete,
      ),
      confirmDismiss: (direction) async {
        final messenger = ScaffoldMessenger.of(context);
        if (direction == DismissDirection.startToEnd) {
          await ref.read(transactionsRepositoryProvider).duplicate(id);
          unawaited(ref.read(syncEngineProvider).sync());
          messenger.showSnackBar(SnackBar(content: Text(l10n.duplicated)));
          return false;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.confirmDeleteTitle),
            content: Text(l10n.confirmDeleteBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) async {
        await ref.read(transactionsRepositoryProvider).delete(id);
        unawaited(ref.read(syncEngineProvider).sync());
      },
      child: child,
    );
  }
}
