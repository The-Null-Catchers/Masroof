import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

enum SyncEntity {
  accounts('accounts'),
  categories('categories'),
  transactions('transactions');

  const SyncEntity(this.path);
  final String path;
}

/// Records local writes so they can be replayed against the API.
class Outbox {
  Outbox(this._db);

  final AppDatabase _db;

  Future<void> create(SyncEntity entity, String id, Map<String, Object?> payload) =>
      _add(entity, id, 'POST', {'id': id, ...payload});

  Future<void> update(SyncEntity entity, String id, Map<String, Object?> payload) async {
    // Fold edits into a not-yet-pushed create so the server sees one request.
    final pendingCreate = await (_db.select(
      _db.pendingOperations,
    )..where((o) => o.entityId.equals(id) & o.method.equals('POST'))).getSingleOrNull();
    if (pendingCreate != null) {
      final merged = {...jsonDecode(pendingCreate.payload!) as Map<String, dynamic>, ...payload};
      await (_db.update(_db.pendingOperations)..where((o) => o.seq.equals(pendingCreate.seq))).write(
        PendingOperationsCompanion(payload: Value(jsonEncode(merged))),
      );
      return;
    }
    await _add(entity, id, 'PATCH', payload);
  }

  Future<void> delete(SyncEntity entity, String id, [Map<String, Object?>? payload]) async {
    final pending = await (_db.select(_db.pendingOperations)..where((o) => o.entityId.equals(id))).get();
    final neverPushed = pending.any((o) => o.method == 'POST');
    await (_db.delete(_db.pendingOperations)..where((o) => o.entityId.equals(id))).go();
    // A record that never reached the server needs no delete request.
    if (!neverPushed) await _add(entity, id, 'DELETE', payload);
  }

  Stream<int> watchCount() {
    final count = _db.pendingOperations.seq.count();
    return (_db.selectOnly(
      _db.pendingOperations,
    )..addColumns([count])).map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> _add(SyncEntity entity, String id, String method, Map<String, Object?>? payload) {
    return _db
        .into(_db.pendingOperations)
        .insert(
          PendingOperationsCompanion.insert(
            entity: entity.path,
            entityId: id,
            method: method,
            payload: Value(payload == null ? null : jsonEncode(payload)),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }
}
