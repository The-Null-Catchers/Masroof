import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/stale_notice.dart';
import '../../planning/application/planning_providers.dart';
import '../data/recurring.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rules = ref.watch(recurringProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurring)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recurring-add',
        onPressed: () => context.push('/recurring/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addRecurring),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recurringProvider);
          await ref.read(recurringProvider.future);
        },
        child: rules.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              EmptyState(icon: Icons.cloud_off_rounded, title: l10n.genericError, body: describeError(context, e)),
            ],
          ),
          data: (data) => data.rules.isEmpty
              ? ListView(
                  children: [
                    EmptyState(
                      icon: Icons.event_repeat_rounded,
                      title: l10n.emptyRecurringTitle,
                      body: l10n.emptyRecurringBody,
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    StaleNotice(stale: data.stale),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final (i, rule) in data.rules.indexed) ...[
                            if (i > 0) const Divider(indent: 72),
                            _RuleTile(rule: rule),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RuleTile extends ConsumerWidget {
  const _RuleTile({required this.rule});

  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final schedule = rule.interval == 1
        ? l10n.frequencyLabel(rule.frequency)
        : '${l10n.frequencyLabel(rule.frequency)} ×${rule.interval}';
    final next = rule.nextOccurrenceOn == null
        ? l10n.ended
        : l10n.nextOn(DateFormat.MMMd(context.localeCode).format(DateTime.parse(rule.nextOccurrenceOn!)));

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
        ref.invalidate(recurringProvider);
      } catch (e) {
        if (context.mounted) showErrorSnack(context, e);
      }
    }

    return ListTile(
      onTap: () => context.push('/recurring/${rule.id}/edit', extra: rule),
      leading: rule.type == 'transfer'
          ? ColoredIconAvatar(icon: Icons.swap_horiz_rounded, color: context.moneyColors.transfer)
          : ColoredIconAvatar.named(rule.categoryIcon, rule.categoryColor),
      title: Text(
        rule.name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [schedule, next, if (rule.mode == 'remind') l10n.modeRemind, if (rule.paused) l10n.paused].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmountText(
            rule.type == 'expense' ? -rule.amountMinor : rule.amountMinor,
            rule.currency,
            signed: rule.type != 'transfer',
            tone: switch (rule.type) {
              'income' => AmountTone.income,
              'transfer' => AmountTone.transfer,
              _ => AmountTone.expense,
            },
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.edit,
            onSelected: (value) => switch (value) {
              'toggle' => run(
                () => ref.read(planningRepositoryProvider).saveRecurring(rule.id, {'paused': !rule.paused}),
              ),
              'delete' => run(() => ref.read(planningRepositoryProvider).deleteRecurring(rule.id)),
              _ => context.push('/recurring/${rule.id}/edit', extra: rule),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(value: 'toggle', child: Text(rule.paused ? l10n.resume : l10n.pause)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
    );
  }
}
