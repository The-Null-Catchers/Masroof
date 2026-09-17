import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/error_text.dart';
import '../../accounts/application/account_providers.dart';
import '../../categories/application/category_providers.dart';
import '../../planning/application/planning_providers.dart';
import '../data/recurring.dart';

class RecurringFormScreen extends ConsumerStatefulWidget {
  const RecurringFormScreen({super.key, this.rule});

  final RecurringRule? rule;

  @override
  ConsumerState<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends ConsumerState<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.rule?.name);
  late final _amount = TextEditingController(text: widget.rule?.amount);
  late final _merchant = TextEditingController(text: widget.rule?.merchant);
  late final _interval = TextEditingController(text: '${widget.rule?.interval ?? 1}');
  late final _remind = TextEditingController(text: '${widget.rule?.remindDaysBefore ?? 1}');
  late String _type = widget.rule?.type ?? 'expense';
  late String? _accountId = widget.rule?.accountId;
  late String? _categoryId = widget.rule?.categoryId;
  late String? _transferAccountId = widget.rule?.transferAccountId;
  late String _frequency = widget.rule?.frequency ?? 'monthly';
  late String _mode = widget.rule?.mode ?? 'auto';
  late DateTime _startsOn = widget.rule == null ? DateTime.now() : DateTime.parse(widget.rule!.startsOn);
  late DateTime? _endsOn = widget.rule?.endsOn == null ? null : DateTime.parse(widget.rule!.endsOn!);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _amount, _merchant, _interval, _remind]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(String currency) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final fmt = DateFormat('yyyy-MM-dd');
    try {
      await ref.read(planningRepositoryProvider).saveRecurring(widget.rule?.id, {
        'name': _name.text.trim(),
        'type': _type,
        'account_id': _accountId,
        'category_id': _type == 'transfer' ? null : _categoryId,
        'transfer_account_id': _type == 'transfer' ? _transferAccountId : null,
        'amount': Money.toDecimal(Money.tryParse(_amount.text, currency)!, currency),
        'merchant': _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
        'frequency': _frequency,
        'interval': int.tryParse(Money.normalizeDigits(_interval.text)) ?? 1,
        'starts_on': fmt.format(_startsOn),
        'ends_on': _endsOn == null ? null : fmt.format(_endsOn!),
        'mode': _mode,
        'remind_days_before': int.tryParse(Money.normalizeDigits(_remind.text)) ?? 1,
      });
      ref.invalidate(recurringProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accounts = ref.watch(accountsProvider(false)).value ?? const [];
    final categories = ref.watch(categoriesProvider(_type == 'income' ? 'income' : 'expense')).value ?? const [];
    _accountId ??= accounts.firstOrNull?.id;
    final account = accounts.firstWhereOrNull((a) => a.id == _accountId);
    final currency = account?.currency ?? 'ILS';
    final dateFmt = DateFormat.yMMMd(context.localeCode);

    return Scaffold(
      appBar: AppBar(title: Text(widget.rule == null ? l10n.addRecurring : l10n.editRecurring)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'expense', label: Text(l10n.typeExpense)),
                ButtonSegment(value: 'income', label: Text(l10n.typeIncome)),
                ButtonSegment(value: 'transfer', label: Text(l10n.typeTransfer)),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() {
                _type = v.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              maxLength: 80,
              decoration: InputDecoration(labelText: l10n.recurringName, counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: Money.symbolFor(currency, context.localeCode),
              ),
              validator: (v) {
                final minor = Money.tryParse(v ?? '', currency);
                return (minor == null || minor <= 0) ? l10n.invalidAmount : null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              isExpanded: true,
              decoration: InputDecoration(labelText: _type == 'transfer' ? l10n.fromAccount : l10n.account),
              items: [
                for (final a in accounts) DropdownMenuItem(value: a.id, child: Text('${a.name} · ${a.currency}')),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
            if (_type == 'transfer')
              DropdownButtonFormField<String>(
                initialValue: _transferAccountId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.toAccount),
                items: [
                  for (final a in accounts.where((a) => a.id != _accountId && a.currency == currency))
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                validator: (v) => v == null ? l10n.selectAccount : null,
                onChanged: (v) => setState(() => _transferAccountId = v),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey('rec-category-$_type'),
                initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.category),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(l10n.categoryLabel(name: c.name, defaultKey: c.defaultKey)),
                    ),
                ],
                validator: (v) => v == null ? l10n.selectCategory : null,
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _frequency,
                    decoration: InputDecoration(labelText: l10n.frequency),
                    items: [
                      for (final f in ['daily', 'weekly', 'monthly', 'yearly'])
                        DropdownMenuItem(value: f, child: Text(l10n.frequencyLabel(f))),
                    ],
                    onChanged: (v) => setState(() => _frequency = v ?? _frequency),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _interval,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.everyInterval),
                    validator: (v) {
                      final n = int.tryParse(Money.normalizeDigits(v ?? ''));
                      return (n == null || n < 1 || n > 366) ? l10n.requiredField : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_outlined),
                    label: Text('${l10n.startsOn}: ${dateFmt.format(_startsOn)}'),
                    onPressed: () async {
                      final d = await _pick(_startsOn);
                      if (d != null) setState(() => _startsOn = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_busy_outlined),
              label: Text('${l10n.endsOn}: ${_endsOn == null ? '—' : dateFmt.format(_endsOn!)}'),
              onPressed: () async {
                final d = await _pick(_endsOn ?? _startsOn);
                setState(() => _endsOn = d);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _mode,
              decoration: InputDecoration(labelText: l10n.whenDue),
              items: [
                DropdownMenuItem(value: 'auto', child: Text(l10n.modeAuto)),
                DropdownMenuItem(value: 'remind', child: Text(l10n.modeRemind)),
              ],
              onChanged: (v) => setState(() => _mode = v ?? _mode),
            ),
            if (_mode == 'remind') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _remind,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.remindDaysBefore),
              ),
            ],
            if (_type != 'transfer') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _merchant,
                maxLength: 120,
                decoration: InputDecoration(labelText: '${l10n.merchant} (${l10n.optional})', counterText: ''),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(onPressed: _saving || account == null ? null : () => _save(currency), child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
