import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/error_text.dart';
import '../../accounts/application/account_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../planning/application/planning_providers.dart';
import '../data/goal.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goal});

  final Goal? goal;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.goal?.name);
  late final _target = TextEditingController(text: widget.goal?.targetAmount);
  late final _notes = TextEditingController(text: widget.goal?.notes);
  late String _kind = widget.goal?.kind ?? 'custom';
  late String _currency = widget.goal?.currency ?? _defaultCurrency();
  late DateTime? _targetDate = widget.goal?.targetDate == null ? null : DateTime.parse(widget.goal!.targetDate!);
  late String? _accountId = widget.goal?.accountId;
  bool _saving = false;

  String _defaultCurrency() {
    final auth = ref.read(authControllerProvider);
    return auth is Authenticated ? auth.user.currency : 'ILS';
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(planningRepositoryProvider).saveGoal(widget.goal?.id, {
        'name': _name.text.trim(),
        'kind': _kind,
        if (widget.goal == null) 'currency': _currency,
        'target_amount': Money.toDecimal(Money.tryParse(_target.text, _currency)!, _currency),
        'target_date': _targetDate == null ? null : DateFormat('yyyy-MM-dd').format(_targetDate!),
        'account_id': _accountId,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });
      ref.invalidate(goalsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    try {
      await ref.read(planningRepositoryProvider).deleteGoal(widget.goal!.id);
      ref.invalidate(goalsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = ref.watch(accountsProvider(false)).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? l10n.addGoal : l10n.editGoal),
        actions: [
          if (widget.goal != null)
            IconButton(tooltip: l10n.delete, onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              maxLength: 60,
              decoration: InputDecoration(labelText: l10n.goalName, counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: InputDecoration(labelText: l10n.goalKind),
              items: [for (final k in goalKinds) DropdownMenuItem(value: k, child: Text(l10n.goalKindLabel(k)))],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _target,
                    textDirection: TextDirection.ltr,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.targetAmount,
                      suffixText: Money.symbolFor(_currency, context.localeCode),
                    ),
                    validator: (v) {
                      final minor = Money.tryParse(v ?? '', _currency);
                      return (minor == null || minor <= 0) ? l10n.invalidAmount : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(labelText: l10n.currency),
                    items: [for (final c in Money.currencies) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: widget.goal == null ? (v) => setState(() => _currency = v ?? _currency) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 180)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '${l10n.targetDate} (${l10n.optional})',
                  prefixIcon: const Icon(Icons.event_outlined),
                  suffixIcon: _targetDate == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => setState(() => _targetDate = null),
                        ),
                ),
                child: Text(_targetDate == null ? '—' : DateFormat.yMMMd(context.localeCode).format(_targetDate!)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: accounts.any((a) => a.id == _accountId) ? _accountId : null,
              decoration: InputDecoration(labelText: '${l10n.linkedAccount} (${l10n.optional})'),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(l10n.none)),
                for (final a in accounts) DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 1,
              maxLength: 1000,
              decoration: InputDecoration(labelText: '${l10n.notes} (${l10n.optional})', counterText: ''),
            ),
            const SizedBox(height: 28),
            FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
