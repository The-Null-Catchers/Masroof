import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, Transactions, PendingOperations, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'masroof'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX idx_transactions_occurred ON transactions (occurred_at DESC)');
      await customStatement('CREATE INDEX idx_transactions_account ON transactions (account_id)');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.renameColumn(transactions, 'payee', transactions.merchant);
        await m.addColumn(transactions, transactions.paymentMethod);
        await m.addColumn(transactions, transactions.tags);
        await m.addColumn(accounts, accounts.notes);
      }
    },
  );

  Future<String?> readValue(String key) async {
    final row = await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeValue(String key, String? value) async {
    if (value == null) {
      await (delete(keyValues)..where((t) => t.key.equals(key))).go();
    } else {
      await into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));
    }
  }

  /// Removes every locally cached record (used on sign-out).
  Future<void> clearAll() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });
}
