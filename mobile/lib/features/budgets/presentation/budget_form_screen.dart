import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/error_text.dart';
import '../../auth/application/auth_controller.dart';
import '../../categories/application/category_providers.dart';
import '../../planning/application/planning_providers.dart';
import '../data/budget.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budget});

  final Budget? budget;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.budget?.name);
  late final _amount = TextEditingController(text: widget.budget?.amount);
  late final _thresholds = TextEditingController(
    text: (widget.budget?.alertThresholds ?? const [50, 75, 90, 100]).join(', '),
  );
  late String _period = widget.budget?.period ?? 'monthly';
  late String _currency = widget.budget?.currency ?? _defaultCurrency();
  late final Set<String> _categoryIds = {...?widget.budget?.categoryIds};
  DateTimeRange? _range;
  bool _saving = false;

  String _defaultCurrency() {
    final auth = ref.read(authControllerProvider);
    return auth is Authenticated ? auth.user.currency : 'ILS';
  }

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    if (b?.startsOn != null && b?.endsOn != null) {
      _range = DateTimeRange(start: DateTime.parse(b!.startsOn!), end: DateTime.parse(b.endsOn!));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _thresholds.dispose();
    super.dispose();
  }

  List<int>? _parseThresholds() {
    final values = _thresholds.text
        .split(RegExp(r'[,،\s]+'))
        .where((v) => v.isNotEmpty)
        .map((v) => int.tryParse(Money.normalizeDigits(v)));
    if (values.isEmpty || values.any((v) => v == null || v < 1 || v > 200)) return null;
    return (values.cast<int>().toSet().toList()..sort());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    if (_period == 'custom' && _range == null) {
      showErrorSnack(context, l10n.requiredField);
      return;
    }
    setState(() => _saving = true);
    final fmt = DateFormat('yyyy-MM-dd');
    try {
      await ref.read(planningRepositoryProvider).saveBudget(widget.budget?.id, {
        'name': _name.text.trim(),
        'period': _period,
        'currency': _currency,
        'amount': Money.toDecimal(Money.tryParse(_amount.text, _currency)!, _currency),
        'starts_on': _period == 'custom' ? fmt.format(_range!.start) : null,
        'ends_on': _period == 'custom' ? fmt.format(_range!.end) : null,
        'alert_thresholds': _parseThresholds(),
        'category_ids': _categoryIds.toList(),
      });
      ref.invalidate(budgetsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    try {
      await ref.read(planningRepositoryProvider).deleteBudget(widget.budget!.id);
      ref.invalidate(budgetsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = (ref.watch(categoriesProvider('expense')).value ?? const []).where((c) => c.parentId == null);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? l10n.addBudget : l10n.editBudget),
        actions: [
          if (widget.budget != null)
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
              decoration: InputDecoration(labelText: l10n.budgetName, counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'monthly', label: Text(l10n.periodMonthly)),
                ButtonSegment(value: 'weekly', label: Text(l10n.periodWeekly)),
                ButtonSegment(value: 'custom', label: Text(l10n.periodCustom)),
              ],
              selected: {_period},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _period = v.first),
            ),
            if (_period == 'custom') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  _range == null
                      ? '${l10n.startsOn} – ${l10n.endsOn}'
                      : '${DateFormat.yMMMd(context.localeCode).format(_range!.start)} – ${DateFormat.yMMMd(context.localeCode).format(_range!.end)}',
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    initialDateRange: _range,
                  );
                  if (picked != null) setState(() => _range = picked);
                },
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _amount,
                    textDirection: TextDirection.ltr,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.budgetAmount,
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
                    onChanged: (v) => setState(() => _currency = v ?? _currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.categories, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(l10n.allCategories),
                  selected: _categoryIds.isEmpty,
                  onSelected: (_) => setState(_categoryIds.clear),
                ),
                for (final c in categories)
                  FilterChip(
                    label: Text(l10n.categoryLabel(name: c.name, defaultKey: c.defaultKey)),
                    selected: _categoryIds.contains(c.id),
                    onSelected: (selected) =>
                        setState(() => selected ? _categoryIds.add(c.id) : _categoryIds.remove(c.id)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _thresholds,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.alertThresholds, helperText: l10n.alertThresholdsHint),
              validator: (_) => _parseThresholds() == null ? l10n.alertThresholdsHint : null,
            ),
            const SizedBox(height: 28),
            FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
