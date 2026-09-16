import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/outbox.dart';
import '../../../core/utils/ulid.dart';

class CategoryDraft {
  const CategoryDraft({required this.name, required this.type, this.parentId, this.color, this.icon});

  final String name;
  final String type;
  final String? parentId;
  final String? color;
  final String? icon;
}

class CategoriesRepository {
  CategoriesRepository(this._db, this._outbox);

  final AppDatabase _db;
  final Outbox _outbox;

  Stream<List<CategoryEntity>> watchAll({String? type, bool includeArchived = false}) {
    final query = _db.select(_db.categories)
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)]);
    if (type != null) query.where((c) => c.type.equals(type));
    if (!includeArchived) query.where((c) => c.archived.equals(false));
    return query.watch();
  }

  Future<String> create(CategoryDraft draft) async {
    final id = Ulid.generate();
    await _db.transaction(() async {
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: id,
              name: draft.name,
              type: draft.type,
              parentId: Value(draft.parentId),
              color: Value(draft.color),
              icon: Value(draft.icon),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
      await _outbox.create(SyncEntity.categories, id, {
        'name': draft.name,
        'type': draft.type,
        'parent_id': draft.parentId,
        'color': draft.color,
        'icon': draft.icon,
      });
    });
    return id;
  }

  Future<void> update(String id, CategoryDraft draft) => _db.transaction(() async {
    final current = await (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingle();
    final renamed = current.name != draft.name;
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(draft.name),
        defaultKey: renamed ? const Value(null) : const Value.absent(),
        parentId: Value(draft.parentId),
        color: Value(draft.color),
        icon: Value(draft.icon),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _outbox.update(SyncEntity.categories, id, {
      if (renamed) 'name': draft.name,
      'parent_id': draft.parentId,
      'color': draft.color,
      'icon': draft.icon,
    });
  });

  /// Deletes a category, moving its transactions to [replacementId] (or leaving
  /// them uncategorized) and promoting subcategories to the top level.
  Future<void> delete(String id, {String? replacementId}) => _db.transaction(() async {
    await (_db.update(
      _db.transactions,
    )..where((t) => t.categoryId.equals(id))).write(TransactionsCompanion(categoryId: Value(replacementId)));
    await (_db.update(
      _db.categories,
    )..where((c) => c.parentId.equals(id))).write(const CategoriesCompanion(parentId: Value(null)));
    await (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
    await _outbox.delete(SyncEntity.categories, id, {'replacement_id': replacementId});
  });
}
