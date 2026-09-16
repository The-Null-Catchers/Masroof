import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/category_avatar.dart';
import '../application/category_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _type = 'expense';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider(_type)).value ?? const [];
    final parents = categories.where((c) => c.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.addCategory,
        onPressed: () => context.push('/settings/categories/new?type=$_type'),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'expense', label: Text(l10n.typeExpense)),
              ButtonSegment(value: 'income', label: Text(l10n.typeIncome)),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final parent in parents) ...[
                  ListTile(
                    leading: ColoredIconAvatar.named(parent.icon, parent.color),
                    title: Text(
                      l10n.categoryLabel(name: parent.name, defaultKey: parent.defaultKey),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/categories/${parent.id}/edit'),
                  ),
                  for (final child in categories.where((c) => c.parentId == parent.id))
                    ListTile(
                      contentPadding: const EdgeInsetsDirectional.only(start: 56, end: 16),
                      leading: ColoredIconAvatar.named(child.icon, child.color, size: 32),
                      title: Text(l10n.categoryLabel(name: child.name, defaultKey: child.defaultKey)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/categories/${child.id}/edit'),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
