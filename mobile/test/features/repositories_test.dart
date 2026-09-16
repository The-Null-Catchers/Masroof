import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:masroof/core/database/app_database.dart';
import 'package:masroof/core/sync/outbox.dart';
import 'package:masroof/features/accounts/data/accounts_repository.dart';
import 'package:masroof/features/categories/data/categories_repository.dart';
import 'package:masroof/features/transactions/data/transactions_repository.dart';

import '../helpers/fakes.dart';

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;
  late CategoriesRepository categories;
  late TransactionsRepository transactions;

  setUp(() {
    db = memoryDatabase();
    final outbox = Outbox(db);
    accounts = AccountsRepository(db, outbox);
    categories = CategoriesRepository(db, outbox);
    transactions = TransactionsRepository(db, outbox);
  });

  tearDown(() => db.close());

  Future<int> balanceOf(String id) async => (await accounts.watch(id).first)!.balance;
  Future<List<PendingOperation>> ops() => db.select(db.pendingOperations).get();

  test('creating an account queues a POST with a decimal opening balance', () async {
    final id = await accounts.create(
      const AccountDraft(name: 'Bank', type: 'bank', currency: 'KWD', openingBalance: 12345),
    );

    expect(await balanceOf(id), 12345);
    final queued = await ops();
    expect(queued.single.method, 'POST');
    expect(jsonDecode(queued.single.payload!), containsPair('opening_balance', '12.345'));
    expect(jsonDecode(queued.single.payload!), containsPair('id', id));
  });

  test('expense, edit and delete keep the local balance consistent', () async {
    final bank = await accounts.create(
      const AccountDraft(name: 'Bank', type: 'bank', currency: 'SAR', openingBalance: 100000),
    );
    final food = await categories.create(const CategoryDraft(name: 'Food', type: 'expense'));

    final id = await transactions.create(
      TransactionDraft(
        type: 'expense',
        accountId: bank,
        categoryId: food,
        amount: 4550,
        occurredAt: DateTime(2026, 9, 1),
      ),
    );
    expect(await balanceOf(bank), 95450);

    await transactions.update(
      id,
      TransactionDraft(
        type: 'income',
        accountId: bank,
        categoryId: food,
        amount: 1000,
        occurredAt: DateTime(2026, 9, 1),
      ),
    );
    expect(await balanceOf(bank), 101000);

    await transactions.delete(id);
    expect(await balanceOf(bank), 100000);
  });

  test('edits and deletes of never-synced records collapse in the outbox', () async {
    final bank = await accounts.create(
      const AccountDraft(name: 'Bank', type: 'bank', currency: 'SAR', openingBalance: 0),
    );
    final food = await categories.create(const CategoryDraft(name: 'Food', type: 'expense'));
    await db.delete(db.pendingOperations).go();

    final id = await transactions.create(
      TransactionDraft(type: 'expense', accountId: bank, categoryId: food, amount: 100, occurredAt: DateTime(2026)),
    );
    await transactions.update(
      id,
      TransactionDraft(type: 'expense', accountId: bank, categoryId: food, amount: 250, occurredAt: DateTime(2026)),
    );
    var queued = await ops();
    expect(queued.single.method, 'POST');
    expect(jsonDecode(queued.single.payload!), containsPair('amount', '2.50'));

    await transactions.delete(id);
    queued = await ops();
    expect(queued, isEmpty);
  });

  test('cross-currency transfer credits the received amount', () async {
    final sar = await accounts.create(
      const AccountDraft(name: 'SAR', type: 'bank', currency: 'SAR', openingBalance: 100000),
    );
    final kwd = await accounts.create(
      const AccountDraft(name: 'KWD', type: 'bank', currency: 'KWD', openingBalance: 0),
    );

    await transactions.create(
      TransactionDraft(
        type: 'transfer',
        accountId: sar,
        transferAccountId: kwd,
        amount: 10000,
        transferAmount: 8123,
        occurredAt: DateTime(2026),
      ),
    );

    expect(await balanceOf(sar), 90000);
    expect(await balanceOf(kwd), 8123);
    final payload = jsonDecode((await ops()).last.payload!) as Map<String, dynamic>;
    expect(payload['amount'], '100.00');
    expect(payload['transfer_amount'], '8.123');
  });

  test('deleting an account reverses transfers into other accounts', () async {
    final a = await accounts.create(
      const AccountDraft(name: 'A', type: 'bank', currency: 'SAR', openingBalance: 10000),
    );
    final b = await accounts.create(const AccountDraft(name: 'B', type: 'cash', currency: 'SAR', openingBalance: 0));
    await transactions.create(
      TransactionDraft(type: 'transfer', accountId: a, transferAccountId: b, amount: 4000, occurredAt: DateTime(2026)),
    );

    await accounts.delete(a);

    expect(await balanceOf(b), 0);
    expect(await transactions.watch(const TransactionFilter()).first, isEmpty);
  });

  test('period totals exclude transfers and group by currency', () async {
    final bank = await accounts.create(
      const AccountDraft(name: 'Bank', type: 'bank', currency: 'SAR', openingBalance: 0),
    );
    final cash = await accounts.create(
      const AccountDraft(name: 'Cash', type: 'cash', currency: 'SAR', openingBalance: 0),
    );
    final food = await categories.create(const CategoryDraft(name: 'Food', type: 'expense'));
    final salary = await categories.create(const CategoryDraft(name: 'Salary', type: 'income'));
    final day = DateTime(2026, 9, 10);
    await transactions.create(
      TransactionDraft(type: 'income', accountId: bank, categoryId: salary, amount: 500000, occurredAt: day),
    );
    await transactions.create(
      TransactionDraft(type: 'expense', accountId: bank, categoryId: food, amount: 2500, occurredAt: day),
    );
    await transactions.create(
      TransactionDraft(type: 'transfer', accountId: bank, transferAccountId: cash, amount: 9999, occurredAt: day),
    );

    final totals = await transactions.watchTotals(DateTime(2026, 9), DateTime(2026, 10)).first;

    expect(totals.single.currency, 'SAR');
    expect(totals.single.income, 500000);
    expect(totals.single.expense, 2500);
  });

  test('search matches payee and notes', () async {
    final bank = await accounts.create(
      const AccountDraft(name: 'Bank', type: 'bank', currency: 'SAR', openingBalance: 0),
    );
    final food = await categories.create(const CategoryDraft(name: 'Food', type: 'expense'));
    await transactions.create(
      TransactionDraft(
        type: 'expense',
        accountId: bank,
        categoryId: food,
        amount: 1,
        payee: 'Starbucks',
        occurredAt: DateTime(2026),
      ),
    );
    await transactions.create(
      TransactionDraft(
        type: 'expense',
        accountId: bank,
        categoryId: food,
        amount: 1,
        note: 'مطعم البيك',
        occurredAt: DateTime(2026),
      ),
    );

    expect(await transactions.watch(const TransactionFilter(search: 'star')).first, hasLength(1));
    expect(await transactions.watch(const TransactionFilter(search: 'البيك')).first, hasLength(1));
  });
}
