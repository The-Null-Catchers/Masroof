import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Server-computed data (budgets, goals, analytics) is fetched online and the
/// last successful response is cached locally so screens still work offline.
class CachedResource {
  CachedResource(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  static String _key(String path, Map<String, dynamic>? query) =>
      'cache:$path${query == null || query.isEmpty ? '' : '?${Uri(queryParameters: query.map((k, v) => MapEntry(k, '$v'))).query}'}';

  /// Emits the cached value (if any) immediately, then the fresh value.
  /// Network failures are rethrown only when nothing is cached.
  Stream<CachedValue> watch(String path, {Map<String, dynamic>? query}) async* {
    final key = _key(path, query);
    final cached = await _db.readValue(key);
    if (cached != null) {
      yield CachedValue(jsonDecode(cached) as Map<String, dynamic>, stale: true);
    }
    try {
      final fresh = await _api.get(path, query: query);
      await _db.writeValue(key, jsonEncode(fresh));
      yield CachedValue(fresh, stale: false);
    } on ApiException catch (e) {
      if (cached == null) rethrow;
      if (!e.isNetwork) rethrow;
    }
  }

  Future<void> invalidate(String pathPrefix) async {
    final rows = await (_db.select(_db.keyValues)..where((t) => t.key.like('cache:$pathPrefix%'))).get();
    for (final row in rows) {
      await _db.writeValue(row.key, null);
    }
  }
}

class CachedValue {
  const CachedValue(this.json, {required this.stale});

  final Map<String, dynamic> json;

  /// True when served from the offline cache.
  final bool stale;
}
