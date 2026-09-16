import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/outbox.dart';
import '../../../core/utils/ulid.dart';

const accountTypes = ['cash', 'bank', 'credit_card', 'savings', 'e_wallet', 'other'];

class AccountDraft {
  const AccountDraft({
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    this.color,
    this.icon,
    this.includeInTotal = true,
  });

  final String name;
  final String type;
  final String currency;
  final int openingBalance;
  final String? color;
  final String? icon;
  final bool includeInTotal;

  Map<String, Object?> toPayload() => {
    'name': name,
    'type': type,
    'currency': currency,
    'opening_balance': Money.toDecimal(openingBalance, currency),
    'color': color,
    'icon': icon,
    'include_in_total': includeInTotal,
  };
}

class AccountsRepository {
  AccountsRepository(this._db, this._outbox);

  final AppDatabase _db;
  final Outbox _outbox;

  Stream<List<AccountEntity>> watchAll({bool includeArchived = false}) {
    final query = _db.select(_db.accounts)
      ..orderBy([(a) => OrderingTerm.asc(a.sortOrder), (a) => OrderingTerm.asc(a.name)]);
    if (!includeArchived) query.where((a) => a.archived.equals(false));
    return query.watch();
  }

  Stream<AccountEntity?> watch(String id) =>
      (_db.select(_db.accounts)..where((a) => a.id.equals(id))).watchSingleOrNull();

  Future<bool> hasTransactions(String id) async {
    final row =
        await (_db.select(_db.transactions)
              ..where((t) => t.accountId.equals(id) | t.transferAccountId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<String> create(AccountDraft draft) async {
    final id = Ulid.generate();
    await _db.transaction(() async {
      await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: id,
              name: draft.name,
              type: draft.type,
              currency: draft.currency,
              openingBalance: Value(draft.openingBalance),
              balance: Value(draft.openingBalance),
              color: Value(draft.color),
              icon: Value(draft.icon),
              includeInTotal: Value(draft.includeInTotal),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
      await _outbox.create(SyncEntity.accounts, id, draft.toPayload());
    });
    return id;
  }

  Future<void> update(String id, AccountDraft draft) => _db.transaction(() async {
    final current = await (_db.select(_db.accounts)..where((a) => a.id.equals(id))).getSingle();
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: Value(draft.name),
        type: Value(draft.type),
        currency: Value(draft.currency),
        openingBalance: Value(draft.openingBalance),
        balance: Value(current.balance + draft.openingBalance - current.openingBalance),
        color: Value(draft.color),
        icon: Value(draft.icon),
        includeInTotal: Value(draft.includeInTotal),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _outbox.update(SyncEntity.accounts, id, draft.toPayload());
  });

  Future<void> setArchived(String id, bool archived) => _db.transaction(() async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(archived: Value(archived), updatedAt: Value(DateTime.now().toUtc())),
    );
    await _outbox.update(SyncEntity.accounts, id, {'archived': archived});
  });

  /// Deletes the account and its history. Transfers from/to other accounts
  /// are reversed so their balances stay correct (matches the API).
  Future<void> delete(String id) => _db.transaction(() async {
    final related = await (_db.select(
      _db.transactions,
    )..where((t) => t.accountId.equals(id) | t.transferAccountId.equals(id))).get();
    for (final t in related.where((t) => t.type == 'transfer')) {
      final otherId = t.accountId == id ? t.transferAccountId! : t.accountId;
      final effect = t.accountId == id ? -(t.transferAmount ?? t.amount) : t.amount;
      await _db.customUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        variables: [Variable.withInt(effect), Variable.withString(otherId)],
        updates: {_db.accounts},
      );
    }
    await (_db.delete(_db.transactions)..where((t) => t.accountId.equals(id) | t.transferAccountId.equals(id))).go();
    await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
    await _outbox.delete(SyncEntity.accounts, id);
  });
}
