import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/ledger.dart';
import '../../../core/sync/outbox.dart';
import '../../../core/utils/ulid.dart';

class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.accountId,
    required this.amount,
    required this.occurredAt,
    this.categoryId,
    this.transferAccountId,
    this.transferAmount,
    this.payee,
    this.note,
  });

  final String type;
  final String accountId;
  final int amount;
  final DateTime occurredAt;
  final String? categoryId;
  final String? transferAccountId;
  final int? transferAmount;
  final String? payee;
  final String? note;
}

/// A transaction joined with the records needed to render it.
class TransactionView {
  const TransactionView({required this.transaction, this.account, this.transferAccount, this.category});

  final TransactionEntity transaction;
  final AccountEntity? account;
  final AccountEntity? transferAccount;
  final CategoryEntity? category;
}

class TransactionFilter {
  const TransactionFilter({this.type, this.accountId, this.categoryId, this.from, this.to, this.search, this.limit});

  final String? type;
  final String? accountId;
  final String? categoryId;
  final DateTime? from;
  final DateTime? to;
  final String? search;
  final int? limit;

  TransactionFilter copyWith({String? search, int? limit}) => TransactionFilter(
    type: type,
    accountId: accountId,
    categoryId: categoryId,
    from: from,
    to: to,
    search: search ?? this.search,
    limit: limit ?? this.limit,
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.type == type &&
      other.accountId == accountId &&
      other.categoryId == categoryId &&
      other.from == from &&
      other.to == to &&
      other.search == search &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(type, accountId, categoryId, from, to, search, limit);
}

/// Per-currency totals for a period, excluding transfers.
class PeriodTotals {
  const PeriodTotals({required this.currency, required this.income, required this.expense});

  final String currency;
  final int income;
  final int expense;

  int get net => income - expense;
}

class CategorySpend {
  const CategorySpend({required this.category, required this.currency, required this.total});

  final CategoryEntity? category;
  final String currency;
  final int total;
}

class TransactionsRepository {
  TransactionsRepository(this._db, this._outbox);

  final AppDatabase _db;
  final Outbox _outbox;

  Stream<List<TransactionView>> watch(TransactionFilter filter) {
    final account = _db.alias(_db.accounts, 'a');
    final transferAccount = _db.alias(_db.accounts, 'ta');
    final category = _db.alias(_db.categories, 'c');

    final query = _db.select(_db.transactions).join([
      leftOuterJoin(account, account.id.equalsExp(_db.transactions.accountId)),
      leftOuterJoin(transferAccount, transferAccount.id.equalsExp(_db.transactions.transferAccountId)),
      leftOuterJoin(category, category.id.equalsExp(_db.transactions.categoryId)),
    ]);

    final t = _db.transactions;
    if (filter.type != null) query.where(t.type.equals(filter.type!));
    if (filter.accountId != null) {
      query.where(t.accountId.equals(filter.accountId!) | t.transferAccountId.equals(filter.accountId!));
    }
    if (filter.categoryId != null) {
      query.where(t.categoryId.equals(filter.categoryId!) | category.parentId.equals(filter.categoryId!));
    }
    if (filter.from != null) query.where(t.occurredAt.isBiggerOrEqualValue(filter.from!.toUtc()));
    if (filter.to != null) query.where(t.occurredAt.isSmallerOrEqualValue(filter.to!.toUtc()));
    final search = filter.search?.trim();
    if (search != null && search.isNotEmpty) {
      final like = '%$search%';
      query.where(t.payee.like(like) | t.note.like(like) | category.name.like(like));
    }

    query.orderBy([OrderingTerm.desc(t.occurredAt), OrderingTerm.desc(t.id)]);
    if (filter.limit != null) query.limit(filter.limit!);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => TransactionView(
              transaction: row.readTable(t),
              account: row.readTableOrNull(account),
              transferAccount: row.readTableOrNull(transferAccount),
              category: row.readTableOrNull(category),
            ),
          )
          .toList(),
    );
  }

  Future<TransactionEntity?> find(String id) =>
      (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<PeriodTotals>> watchTotals(DateTime from, DateTime to) {
    final t = _db.transactions;
    final income = t.amount.sum(filter: t.type.equals('income'));
    final expense = t.amount.sum(filter: t.type.equals('expense'));
    final query = _db.selectOnly(t)
      ..addColumns([t.currency, income, expense])
      ..where(t.occurredAt.isBetweenValues(from.toUtc(), to.toUtc()) & t.type.isIn(['income', 'expense']))
      ..groupBy([t.currency]);
    return query.watch().map(
      (rows) => rows
          .map(
            (r) =>
                PeriodTotals(currency: r.read(t.currency)!, income: r.read(income) ?? 0, expense: r.read(expense) ?? 0),
          )
          .toList(),
    );
  }

  /// Expense totals per top-level category for the period, largest first.
  Stream<List<CategorySpend>> watchSpendByCategory(DateTime from, DateTime to) {
    return watch(TransactionFilter(type: 'expense', from: from, to: to)).asyncMap((views) async {
      final categories = {for (final c in await _db.select(_db.categories).get()) c.id: c};
      final totals = <(String?, String), int>{};
      for (final view in views) {
        var category = view.category;
        if (category?.parentId != null) category = categories[category!.parentId] ?? category;
        final key = (category?.id, view.transaction.currency);
        totals[key] = (totals[key] ?? 0) + view.transaction.amount;
      }
      final result =
          totals.entries
              .map((e) => CategorySpend(category: categories[e.key.$1], currency: e.key.$2, total: e.value))
              .toList()
            ..sort((a, b) => b.total.compareTo(a.total));
      return result;
    });
  }

  Future<String> create(TransactionDraft draft) async {
    final id = Ulid.generate();
    await _db.transaction(() async {
      final normalized = await _normalize(draft);
      final entity = TransactionEntity(
        id: id,
        type: normalized.type,
        amount: normalized.amount,
        currency: normalized.currency,
        accountId: normalized.accountId,
        categoryId: normalized.categoryId,
        transferAccountId: normalized.transferAccountId,
        transferAmount: normalized.transferAmount,
        occurredAt: draft.occurredAt.toUtc(),
        payee: _blankToNull(draft.payee),
        note: _blankToNull(draft.note),
        updatedAt: DateTime.now().toUtc(),
      );
      await _db.into(_db.transactions).insert(entity);
      await _applyEffects(effectsOf(entity));
      await _outbox.create(SyncEntity.transactions, id, await _payload(entity));
    });
    return id;
  }

  Future<void> update(String id, TransactionDraft draft) => _db.transaction(() async {
    final before = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingle();
    final normalized = await _normalize(draft);
    final after = before.copyWith(
      type: normalized.type,
      amount: normalized.amount,
      currency: normalized.currency,
      accountId: normalized.accountId,
      categoryId: Value(normalized.categoryId),
      transferAccountId: Value(normalized.transferAccountId),
      transferAmount: Value(normalized.transferAmount),
      occurredAt: draft.occurredAt.toUtc(),
      payee: Value(_blankToNull(draft.payee)),
      note: Value(_blankToNull(draft.note)),
      updatedAt: DateTime.now().toUtc(),
    );
    await _db.update(_db.transactions).replace(after);
    await _applyEffects(diffEffects(effectsOf(before), effectsOf(after)));
    await _outbox.update(SyncEntity.transactions, id, await _payload(after));
  });

  Future<void> delete(String id) => _db.transaction(() async {
    final existing = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return;
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    await _applyEffects(effectsOf(existing).map((k, v) => MapEntry(k, -v)));
    await _outbox.delete(SyncEntity.transactions, id);
  });

  Future<TransactionEntity> _normalize(TransactionDraft draft) async {
    final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(draft.accountId))).getSingle();
    final isTransfer = draft.type == 'transfer';
    int? transferAmount;
    if (isTransfer) {
      final destination = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(draft.transferAccountId!))).getSingle();
      transferAmount = destination.currency == account.currency ? draft.amount : draft.transferAmount;
      if (transferAmount == null) throw ArgumentError('transferAmount is required across currencies');
    }
    return TransactionEntity(
      id: '',
      type: draft.type,
      amount: draft.amount,
      currency: account.currency,
      accountId: account.id,
      categoryId: isTransfer ? null : draft.categoryId,
      transferAccountId: isTransfer ? draft.transferAccountId : null,
      transferAmount: transferAmount,
      occurredAt: draft.occurredAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<Map<String, Object?>> _payload(TransactionEntity t) async {
    String? transferCurrency;
    if (t.transferAccountId != null) {
      transferCurrency = (await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(t.transferAccountId!))).getSingle()).currency;
    }
    return {
      'type': t.type,
      'account_id': t.accountId,
      'category_id': t.categoryId,
      'amount': Money.toDecimal(t.amount, t.currency),
      'transfer_account_id': t.transferAccountId,
      if (t.transferAmount != null && transferCurrency != null)
        'transfer_amount': Money.toDecimal(t.transferAmount!, transferCurrency),
      'occurred_at': t.occurredAt.toUtc().toIso8601String(),
      'payee': t.payee,
      'note': t.note,
    };
  }

  Future<void> _applyEffects(Map<String, int> effects) async {
    for (final entry in effects.entries) {
      await _db.customUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        variables: [Variable.withInt(entry.value), Variable.withString(entry.key)],
        updates: {_db.accounts},
      );
    }
  }

  static String? _blankToNull(String? value) => (value == null || value.trim().isEmpty) ? null : value.trim();
}
