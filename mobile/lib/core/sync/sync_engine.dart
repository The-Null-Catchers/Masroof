import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'sync_mapper.dart';

enum SyncPhase { idle, syncing, offline, error }

@immutable
class SyncStatus {
  const SyncStatus(this.phase, {this.lastSyncedAt, this.rejected = 0});

  final SyncPhase phase;
  final DateTime? lastSyncedAt;

  /// Local changes the server refused (validation/ownership) in the last run.
  final int rejected;
}

/// Offline-first synchronization.
///
/// 1. Push: replay the outbox in order. Network failures stop the run and
///    keep the queue; server rejections drop the operation and schedule a
///    full refresh so local state converges to the server.
/// 2. Pull: fetch changes since the last cursor and apply them.
class SyncEngine {
  SyncEngine({required this._db, required this._api});

  static const cursorKey = 'sync.cursor';

  final AppDatabase _db;
  final ApiClient _api;
  final _status = StreamController<SyncStatus>.broadcast();
  SyncStatus _current = const SyncStatus(SyncPhase.idle);
  Future<SyncStatus>? _running;
  bool _rerun = false;

  Stream<SyncStatus> get status => _status.stream;
  SyncStatus get current => _current;

  /// Runs a sync; concurrent callers share the in-flight run, and a call
  /// made during a run schedules exactly one follow-up run.
  Future<SyncStatus> sync({bool full = false}) {
    if (_running != null) {
      _rerun = true;
      return _running!;
    }
    return _running = _run(full: full).whenComplete(() {
      _running = null;
      if (_rerun) {
        _rerun = false;
        unawaited(sync());
      }
    });
  }

  Future<SyncStatus> _run({required bool full}) async {
    _emit(SyncStatus(SyncPhase.syncing, lastSyncedAt: _current.lastSyncedAt));
    try {
      final push = await _push();
      if (push.offline) {
        return _emit(SyncStatus(SyncPhase.offline, lastSyncedAt: _current.lastSyncedAt, rejected: push.rejected));
      }
      await _pull(full: full || push.needsRefresh);
      return _emit(SyncStatus(SyncPhase.idle, lastSyncedAt: DateTime.now(), rejected: push.rejected));
    } on ApiException catch (e) {
      return _emit(SyncStatus(e.isNetwork ? SyncPhase.offline : SyncPhase.error, lastSyncedAt: _current.lastSyncedAt));
    }
  }

  Future<({bool offline, bool needsRefresh, int rejected})> _push() async {
    var needsRefresh = false;
    var rejected = 0;

    while (true) {
      final op =
          await (_db.select(_db.pendingOperations)
                ..orderBy([(o) => OrderingTerm.asc(o.seq)])
                ..limit(1))
              .getSingleOrNull();
      if (op == null) break;

      final body = op.payload == null ? null : jsonDecode(op.payload!);
      try {
        switch (op.method) {
          case 'POST':
            await _api.post('/${op.entity}', body);
          case 'PATCH':
            await _api.patch('/${op.entity}/${op.entityId}', body);
          case 'DELETE':
            await _api.delete('/${op.entity}/${op.entityId}', body);
        }
        await _removeOp(op.seq);
      } on ApiException catch (e) {
        if (e.isNetwork || e.kind == ApiErrorKind.server || e.kind == ApiErrorKind.rateLimited) {
          await (_db.update(_db.pendingOperations)..where((o) => o.seq.equals(op.seq))).write(
            PendingOperationsCompanion(attempts: Value(op.attempts + 1), lastError: Value(e.toString())),
          );
          return (offline: true, needsRefresh: needsRefresh, rejected: rejected);
        }
        if (e.kind == ApiErrorKind.unauthorized) rethrow;

        // Deleting something already gone is a success.
        if (!(op.method == 'DELETE' && e.kind == ApiErrorKind.notFound)) {
          rejected++;
          needsRefresh = true;
          if (op.method == 'POST') await _discardLocal(op.entity, op.entityId);
        }
        await _removeOp(op.seq);
      }
    }
    return (offline: false, needsRefresh: needsRefresh, rejected: rejected);
  }

  Future<void> _pull({required bool full}) async {
    var cursor = full ? null : await _db.readValue(cursorKey);

    while (true) {
      final response = await _api.get('/sync', query: {'since': ?cursor});
      await _apply(response, fullReset: full && cursor == null);
      cursor = response['server_time'] as String;
      await _db.writeValue(cursorKey, cursor);
      if (response['has_more'] != true) break;
    }
  }

  Future<void> _apply(Map<String, dynamic> response, {required bool fullReset}) async {
    // Records with local edits still queued keep their optimistic state.
    final pendingIds = (await _db.select(_db.pendingOperations).get()).map((o) => o.entityId).toSet();

    List<Map<String, dynamic>> upserts(String key) => ((response[key] as Map)['upserted'] as List)
        .cast<Map<String, dynamic>>()
        .where((j) => !pendingIds.contains(j['id']))
        .toList();
    List<String> deletions(String key) =>
        ((response[key] as Map)['deleted'] as List).cast<String>().where((id) => !pendingIds.contains(id)).toList();

    await _db.transaction(() async {
      if (fullReset) {
        // Drop synced records the server no longer knows about.
        await (_db.delete(_db.transactions)..where((t) => t.id.isNotIn(pendingIds))).go();
        await (_db.delete(_db.categories)..where((t) => t.id.isNotIn(pendingIds))).go();
        await (_db.delete(_db.accounts)..where((t) => t.id.isNotIn(pendingIds))).go();
      }
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.accounts, upserts('accounts').map(SyncMapper.account));
        batch.insertAllOnConflictUpdate(_db.categories, upserts('categories').map(SyncMapper.category));
        batch.insertAllOnConflictUpdate(_db.transactions, upserts('transactions').map(SyncMapper.transaction));
        batch.deleteWhere(_db.transactions, (t) => t.id.isIn(deletions('transactions')));
        batch.deleteWhere(_db.categories, (t) => t.id.isIn(deletions('categories')));
        batch.deleteWhere(_db.accounts, (t) => t.id.isIn(deletions('accounts')));
      });
    });
  }

  Future<void> _discardLocal(String entity, String id) async {
    switch (entity) {
      case 'transactions':
        await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
      case 'categories':
        await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
      case 'accounts':
        await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
    }
  }

  Future<void> _removeOp(int seq) => (_db.delete(_db.pendingOperations)..where((o) => o.seq.equals(seq))).go();

  SyncStatus _emit(SyncStatus status) {
    _current = status;
    if (!_status.isClosed) _status.add(status);
    return status;
  }

  Future<void> dispose() => _status.close();
}
