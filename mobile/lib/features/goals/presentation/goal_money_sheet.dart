import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/error_text.dart';
import '../../planning/application/planning_providers.dart';
import '../data/goal.dart';

Future<void> showGoalMoneySheet(BuildContext context, Goal goal) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => GoalMoneySheet(goal: goal),
);

/// Add or withdraw money, and review/undo past entries.
class GoalMoneySheet extends ConsumerStatefulWidget {
  const GoalMoneySheet({super.key, required this.goal});

  final Goal goal;

  @override
  ConsumerState<GoalMoneySheet> createState() => _GoalMoneySheetState();
}

class _GoalMoneySheetState extends ConsumerState<GoalMoneySheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _type = 'contribution';
  String? _error;
  bool _saving = false;
  late Future<List<GoalEntry>> _entries = ref.read(planningRepositoryProvider).goalEntries(widget.goal.id);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final minor = Money.tryParse(_amount.text, widget.goal.currency);
    if (minor == null || minor <= 0) {
      setState(() => _error = context.l10n.invalidAmount);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(planningRepositoryProvider)
          .addGoalEntry(
            widget.goal.id,
            type: _type,
            amount: Money.toDecimal(minor, widget.goal.currency),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      ref.invalidate(goalsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final goal = widget.goal;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(goal.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: l10n.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/goals/${goal.id}/edit', extra: goal);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'contribution', label: Text(l10n.addMoney), icon: const Icon(Icons.add_rounded)),
                ButtonSegment(value: 'withdrawal', label: Text(l10n.withdraw), icon: const Icon(Icons.remove_rounded)),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: true,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: Money.symbolFor(goal.currency, context.localeCode),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 255,
              decoration: InputDecoration(labelText: '${l10n.note} (${l10n.optional})', counterText: ''),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
            const SizedBox(height: 20),
            Text(l10n.history, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            FutureBuilder<List<GoalEntry>>(
              future: _entries,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text(describeError(context, snapshot.error!));
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final entries = snapshot.data!;
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(l10n.noEntries, style: TextStyle(color: theme.hintColor)),
                  );
                }
                return Column(
                  children: [
                    for (final entry in entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.type == 'withdrawal' ? l10n.withdrawal : l10n.contribution),
                        subtitle: Text(
                          [
                            DateFormat.yMMMd(context.localeCode).format(entry.occurredAt.toLocal()),
                            ?entry.note,
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AmountText(
                              entry.type == 'withdrawal' ? -entry.amountMinor : entry.amountMinor,
                              goal.currency,
                              signed: true,
                              tone: entry.type == 'withdrawal' ? AmountTone.expense : AmountTone.income,
                            ),
                            IconButton(
                              tooltip: l10n.delete,
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () async {
                                try {
                                  await ref.read(planningRepositoryProvider).deleteGoalEntry(goal.id, entry.id);
                                  ref.invalidate(goalsProvider);
                                  setState(() => _entries = ref.read(planningRepositoryProvider).goalEntries(goal.id));
                                } catch (e) {
                                  if (context.mounted) showErrorSnack(context, e);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
