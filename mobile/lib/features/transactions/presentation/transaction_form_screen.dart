import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/icon_catalog.dart';
import '../../accounts/application/account_providers.dart';
import '../../categories/application/category_providers.dart';
import '../data/transactions_repository.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.transactionId, this.initialType = 'expense', this.initialAccountId});

  final String? transactionId;
  final String initialType;
  final String? initialAccountId;

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _transferAmount = TextEditingController();
  final _payee = TextEditingController();
  final _note = TextEditingController();

  late String _type = widget.initialType;
  String? _accountId;
  String? _transferAccountId;
  String? _categoryId;
  DateTime _occurredAt = DateTime.now();
  bool _loaded = false;
  bool _saving = false;

  bool get _editing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
    if (_editing) {
      unawaited(_load());
    } else {
      _loaded = true;
    }
  }

  Future<void> _load() async {
    final repo = ref.read(transactionsRepositoryProvider);
    final t = await repo.find(widget.transactionId!);
    if (!mounted) return;
    if (t == null) {
      context.pop();
      return;
    }
    final destinationCurrency = t.transferAccountId == null
        ? null
        : (await ref
                  .read(databaseProvider)
                  .managers
                  .accounts
                  .filter((a) => a.id.equals(t.transferAccountId!))
                  .getSingleOrNull())
              ?.currency;
    setState(() {
      _type = t.type;
      _accountId = t.accountId;
      _transferAccountId = t.transferAccountId;
      _categoryId = t.categoryId;
      _occurredAt = t.occurredAt.toLocal();
      _amount.text = Money.toDecimal(t.amount, t.currency);
      if (t.transferAmount != null && destinationCurrency != null) {
        _transferAmount.text = Money.toDecimal(t.transferAmount!, destinationCurrency);
      }
      _payee.text = t.payee ?? '';
      _note.text = t.note ?? '';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _transferAmount.dispose();
    _payee.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(List<AccountEntity> accounts) async {
    if (!_formKey.currentState!.validate()) return;
    final account = accounts.firstWhere((a) => a.id == _accountId);
    final destination = accounts.firstWhereOrNull((a) => a.id == _transferAccountId);
    final crossCurrency = _type == 'transfer' && destination != null && destination.currency != account.currency;

    final draft = TransactionDraft(
      type: _type,
      accountId: account.id,
      amount: Money.tryParse(_amount.text, account.currency)!,
      occurredAt: _occurredAt,
      categoryId: _type == 'transfer' ? null : _categoryId,
      transferAccountId: _type == 'transfer' ? _transferAccountId : null,
      transferAmount: crossCurrency ? Money.tryParse(_transferAmount.text, destination.currency) : null,
      payee: _type == 'transfer' ? null : _payee.text,
      note: _note.text,
    );

    setState(() => _saving = true);
    final repo = ref.read(transactionsRepositoryProvider);
    if (_editing) {
      await repo.update(widget.transactionId!, draft);
    } else {
      await repo.create(draft);
    }
    unawaited(ref.read(syncEngineProvider).sync());
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
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
    if (confirmed != true) return;
    await ref.read(transactionsRepositoryProvider).delete(widget.transactionId!);
    unawaited(ref.read(syncEngineProvider).sync());
    if (mounted) context.pop();
  }

  String? _validateAmount(String? value, String? currency) {
    final l10n = context.l10n;
    if (value == null || value.trim().isEmpty) return l10n.requiredField;
    if (currency == null) return null;
    final minor = Money.tryParse(value, currency);
    if (minor == null) return l10n.invalidAmount;
    if (minor <= 0) return l10n.amountMustBePositive;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsProvider(true));

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l10n.editTransaction : l10n.newTransaction),
        actions: [
          if (_editing)
            IconButton(tooltip: l10n.delete, onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.genericError)),
        data: (allAccounts) {
          final active = allAccounts
              .where((a) => !a.archived || a.id == _accountId || a.id == _transferAccountId)
              .toList();
          if (active.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: l10n.emptyAccountsTitle,
              body: l10n.needAccountFirst,
              action: FilledButton.icon(
                onPressed: () => context.pushReplacement('/accounts/new'),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addAccount),
              ),
            );
          }
          if (!_loaded) return const Center(child: CircularProgressIndicator());

          _accountId ??= active.first.id;
          final account = active.firstWhereOrNull((a) => a.id == _accountId) ?? active.first;
          final destination = active.firstWhereOrNull((a) => a.id == _transferAccountId);
          final crossCurrency = _type == 'transfer' && destination != null && destination.currency != account.currency;
          final moneyColors = context.moneyColors;
          final typeColor = switch (_type) {
            'income' => moneyColors.income,
            'transfer' => moneyColors.transfer,
            _ => moneyColors.expense,
          };

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'expense',
                      label: Text(l10n.typeExpense),
                      icon: const Icon(Icons.north_east_rounded),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text(l10n.typeIncome),
                      icon: const Icon(Icons.south_west_rounded),
                    ),
                    ButtonSegment(
                      value: 'transfer',
                      label: Text(l10n.typeTransfer),
                      icon: const Icon(Icons.swap_horiz_rounded),
                    ),
                  ],
                  selected: {_type},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) => setState(() {
                    if (_type != value.first) _categoryId = null;
                    _type = value.first;
                  }),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('amount-field'),
                  controller: _amount,
                  autofocus: !_editing,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫]'))],
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: typeColor),
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    suffixText: Money.symbolFor(account.currency, context.localeCode),
                  ),
                  validator: (v) => _validateAmount(v, account.currency),
                ),
                const SizedBox(height: 16),
                _AccountField(
                  label: _type == 'transfer' ? l10n.fromAccount : l10n.account,
                  accounts: active,
                  value: account.id,
                  onChanged: (id) => setState(() => _accountId = id),
                ),
                if (_type == 'transfer') ...[
                  const SizedBox(height: 16),
                  _AccountField(
                    label: l10n.toAccount,
                    accounts: active,
                    value: _transferAccountId,
                    onChanged: (id) => setState(() => _transferAccountId = id),
                    validator: (id) {
                      if (id == null) return l10n.selectAccount;
                      if (id == account.id) return l10n.sameAccountError;
                      return null;
                    },
                  ),
                  if (crossCurrency) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _transferAmount,
                      textDirection: TextDirection.ltr,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.amountReceived(destination.currency),
                        suffixText: Money.symbolFor(destination.currency, context.localeCode),
                      ),
                      validator: (v) => _validateAmount(v, destination.currency),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  _CategoryField(type: _type, value: _categoryId, onChanged: (id) => setState(() => _categoryId = id)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _payee,
                    textInputAction: TextInputAction.next,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: '${l10n.payee} (${l10n.optional})',
                      prefixIcon: const Icon(Icons.storefront_outlined),
                      counterText: '',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _occurredAt,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked == null) return;
                    setState(
                      () => _occurredAt = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        _occurredAt.hour,
                        _occurredAt.minute,
                      ),
                    );
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: l10n.date, prefixIcon: const Icon(Icons.event_outlined)),
                    child: Text(DateFormat.yMMMMEEEEd(context.localeCode).format(_occurredAt)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: '${l10n.note} (${l10n.optional})',
                    prefixIcon: const Icon(Icons.notes_rounded),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  key: const Key('save-transaction'),
                  onPressed: _saving ? null : () => _save(allAccounts),
                  child: Text(l10n.save),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.label,
    required this.accounts,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final List<AccountEntity> accounts;
  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      items: [
        for (final a in accounts)
          DropdownMenuItem(
            value: a.id,
            child: Row(
              children: [
                Icon(IconCatalog.forAccountType(a.type), size: 20, color: parseHexColor(a.color)),
                const SizedBox(width: 10),
                Expanded(child: Text('${a.name} · ${a.currency}', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CategoryField extends ConsumerWidget {
  const _CategoryField({required this.type, required this.value, required this.onChanged});

  final String type;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider(type)).value ?? const [];
    final selected = categories.firstWhereOrNull((c) => c.id == value);

    return FormField<String>(
      key: ValueKey('category-$type'),
      initialValue: value,
      validator: (_) => value == null ? l10n.selectCategory : null,
      builder: (field) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final picked = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (context) => _CategoryPicker(categories: categories, selectedId: value),
          );
          if (picked != null) {
            onChanged(picked);
            field.didChange(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: l10n.category, errorText: field.errorText),
          child: selected == null
              ? Text(l10n.selectCategory, style: TextStyle(color: Theme.of(context).hintColor))
              : Row(
                  children: [
                    ColoredIconAvatar.named(selected.icon, selected.color, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.categoryLabel(name: selected.name, defaultKey: selected.defaultKey)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.categories, required this.selectedId});

  final List<CategoryEntity> categories;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parents = categories.where((c) => c.parentId == null).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final parent in parents) ...[
            _tile(context, parent, l10n, indent: false),
            for (final child in categories.where((c) => c.parentId == parent.id))
              _tile(context, child, l10n, indent: true),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, CategoryEntity c, AppLocalizations l10n, {required bool indent}) {
    return ListTile(
      contentPadding: EdgeInsetsDirectional.only(start: indent ? 48 : 16, end: 16),
      leading: ColoredIconAvatar.named(c.icon, c.color, size: indent ? 32 : 40),
      title: Text(l10n.categoryLabel(name: c.name, defaultKey: c.defaultKey)),
      trailing: c.id == selectedId
          ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(context, c.id),
    );
  }
}
