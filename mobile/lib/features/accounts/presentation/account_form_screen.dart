import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/icon_catalog.dart';
import '../../auth/application/auth_controller.dart';
import '../data/accounts_repository.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.accountId});

  final String? accountId;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _opening = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String _type = 'bank';
  String _currency = 'ILS';
  String _color = toHexColor(AppColors.pickerPalette.first);
  bool _includeInTotal = true;
  bool _archived = false;
  bool _currencyLocked = false;
  bool _loaded = false;

  bool get _editing => widget.accountId != null;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    if (auth is Authenticated) _currency = auth.user.currency;
    if (_editing) {
      unawaited(_load());
    } else {
      _loaded = true;
    }
  }

  Future<void> _load() async {
    final repo = ref.read(accountsRepositoryProvider);
    final account = await repo.watch(widget.accountId!).first;
    final locked = await repo.hasTransactions(widget.accountId!);
    if (!mounted || account == null) return;
    setState(() {
      _name.text = account.name;
      _type = account.type;
      _currency = account.currency;
      _opening.text = Money.toDecimal(account.openingBalance, account.currency);
      _color = account.color ?? _color;
      _includeInTotal = account.includeInTotal;
      _notes.text = account.notes ?? '';
      _archived = account.archived;
      _currencyLocked = locked;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final negative = _opening.text.trim().startsWith('-');
    final minor = Money.tryParse(_opening.text.trim().replaceFirst('-', ''), _currency)!;
    final draft = AccountDraft(
      name: _name.text.trim(),
      type: _type,
      currency: _currency,
      openingBalance: negative ? -minor : minor,
      color: _color,
      icon: null,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      includeInTotal: _includeInTotal,
    );
    final repo = ref.read(accountsRepositoryProvider);
    if (_editing) {
      await repo.update(widget.accountId!, draft);
    } else {
      await repo.create(draft);
    }
    unawaited(ref.read(syncEngineProvider).sync());
    if (mounted) context.pop();
  }

  Future<void> _toggleArchive() async {
    await ref.read(accountsRepositoryProvider).setArchived(widget.accountId!, !_archived);
    unawaited(ref.read(syncEngineProvider).sync());
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountsRepositoryProvider).delete(widget.accountId!);
    unawaited(ref.read(syncEngineProvider).sync());
    if (mounted) context.go('/accounts');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? l10n.editAccount : l10n.addAccount)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.accountName, counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 16),
            Text(l10n.accountType, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in accountTypes)
                  ChoiceChip(
                    avatar: Icon(IconCatalog.forAccountType(type), size: 18),
                    label: Text(l10n.accountTypeLabel(type)),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(
                labelText: l10n.currency,
                helperText: _currencyLocked ? l10n.currencyLocked : null,
              ),
              items: [
                for (final code in Money.currencies)
                  DropdownMenuItem(value: code, child: Text('$code · ${Money.symbolFor(code, context.localeCode)}')),
              ],
              onChanged: _currencyLocked ? null : (v) => setState(() => _currency = v ?? _currency),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _opening,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫-]'))],
              decoration: InputDecoration(
                labelText: l10n.openingBalance,
                suffixText: Money.symbolFor(_currency, context.localeCode),
              ),
              validator: (v) {
                final value = (v ?? '').trim().replaceFirst('-', '');
                if (value.isEmpty) return l10n.requiredField;
                return Money.tryParse(value, _currency) == null ? l10n.invalidAmount : null;
              },
            ),
            const SizedBox(height: 20),
            Text(l10n.color, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in AppColors.pickerPalette)
                  Semantics(
                    button: true,
                    selected: toHexColor(color) == _color,
                    child: GestureDetector(
                      onTap: () => setState(() => _color = toHexColor(color)),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: color,
                        child: toHexColor(color) == _color
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 1,
              maxLength: 1000,
              decoration: InputDecoration(labelText: '${l10n.notes} (${l10n.optional})', counterText: ''),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.includeInTotal),
              value: _includeInTotal,
              onChanged: (v) => setState(() => _includeInTotal = v),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
            if (_editing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _toggleArchive,
                icon: Icon(_archived ? Icons.unarchive_outlined : Icons.archive_outlined),
                label: Text(_archived ? l10n.unarchive : l10n.archive),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l10n.delete),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
