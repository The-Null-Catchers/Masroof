import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/icon_catalog.dart';
import '../application/category_providers.dart';
import '../data/categories_repository.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoryId, this.initialType = 'expense'});

  final String? categoryId;
  final String initialType;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late String _type = widget.initialType;
  String? _parentId;
  String _icon = 'category';
  String _color = toHexColor(AppColors.pickerPalette.first);
  bool _initialized = false;
  String? _storedName;
  String? _displayedName;

  bool get _editing => widget.categoryId != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final typed = _name.text.trim();
    // An untouched built-in name must not count as a rename (it would stop localizing).
    final name = (_storedName != null && typed == _displayedName) ? _storedName! : typed;
    final draft = CategoryDraft(name: name, type: _type, parentId: _parentId, color: _color, icon: _icon);
    final repo = ref.read(categoriesRepositoryProvider);
    if (_editing) {
      await repo.update(widget.categoryId!, draft);
    } else {
      await repo.create(draft);
    }
    unawaited(ref.read(syncEngineProvider).sync());
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final others = (ref.read(categoriesProvider(_type)).value ?? const [])
        .where((c) => c.id != widget.categoryId)
        .toList();
    String? replacement;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.confirmDeleteTitle),
          content: DropdownButtonFormField<String?>(
            initialValue: replacement,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.moveTransactionsTo),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.leaveUncategorized)),
              for (final c in others)
                DropdownMenuItem(
                  value: c.id,
                  child: Text(l10n.categoryLabel(name: c.name, defaultKey: c.defaultKey)),
                ),
            ],
            onChanged: (v) => setDialogState(() => replacement = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await ref.read(categoriesRepositoryProvider).delete(widget.categoryId!, replacementId: replacement);
    unawaited(ref.read(syncEngineProvider).sync());
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = ref.watch(categoriesProvider(null)).value;
    if (all == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_editing && !_initialized) {
      final existing = all.firstWhereOrNull((c) => c.id == widget.categoryId);
      if (existing != null) {
        _storedName = existing.name;
        _displayedName = l10n.categoryLabel(name: existing.name, defaultKey: existing.defaultKey);
        _name.text = _displayedName!;
        _type = existing.type;
        _parentId = existing.parentId;
        _icon = existing.icon ?? _icon;
        _color = existing.color ?? _color;
      }
    }
    _initialized = true;

    final hasChildren = _editing && all.any((c) => c.parentId == widget.categoryId);
    final parents = all.where((c) => c.type == _type && c.parentId == null && c.id != widget.categoryId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l10n.editCategory : l10n.addCategory),
        actions: [
          if (_editing)
            IconButton(tooltip: l10n.delete, onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (!_editing) ...[
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'expense', label: Text(l10n.typeExpense)),
                  ButtonSegment(value: 'income', label: Text(l10n.typeIncome)),
                ],
                selected: {_type},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() {
                  _type = v.first;
                  _parentId = null;
                }),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _name,
              maxLength: 60,
              decoration: InputDecoration(labelText: l10n.categoryName, counterText: ''),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 16),
            if (!hasChildren)
              DropdownButtonFormField<String?>(
                initialValue: _parentId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.parentCategory),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.noParent)),
                  for (final p in parents)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(l10n.categoryLabel(name: p.name, defaultKey: p.defaultKey)),
                    ),
                ],
                onChanged: (v) => setState(() => _parentId = v),
              ),
            const SizedBox(height: 20),
            Text(l10n.icon, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in IconCatalog.icons.entries)
                  IconButton.filledTonal(
                    isSelected: entry.key == _icon,
                    onPressed: () => setState(() => _icon = entry.key),
                    icon: Icon(entry.value),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.color, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in AppColors.pickerPalette)
                  GestureDetector(
                    onTap: () => setState(() => _color = toHexColor(color)),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: color,
                      child: toHexColor(color) == _color
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
