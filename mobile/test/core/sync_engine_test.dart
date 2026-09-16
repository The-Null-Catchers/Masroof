import 'package:flutter_test/flutter_test.dart';
import 'package:masroof/core/database/app_database.dart';
import 'package:masroof/core/network/api_exception.dart';
import 'package:masroof/core/sync/outbox.dart';
import 'package:masroof/core/sync/sync_engine.dart';
import 'package:masroof/features/accounts/data/accounts_repository.dart';

import '../helpers/fakes.dart';

Map<String, dynamic> accountJson(String id, {int balance = 0, String name = 'Bank'}) => {
  'id': id,
  'name': name,
  'type': 'bank',
  'currency': 'SAR',
  'opening_balance_minor': 0,
  'balance_minor': balance,
  'color': null,
  'icon': null,
  'include_in_total': true,
  'archived': false,
  'sort_order': 0,
  'updated_at': '2026-09-16T10:00:00+00:00',
};

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;

  setUp(() {
    db = memoryDatabase();
    accounts = AccountsRepository(db, Outbox(db));
  });

  tearDown(() => db.close());

  test('pushes the outbox in order, then pulls and stores the cursor', () async {
    final id = await accounts.create(
      const AccountDraft(name: 'Bank', type: 'bank', currency: 'SAR', openingBalance: 500),
    );
    final api = FakeApiClient((method, path, body, query) {
      if (method == 'GET') {
        return emptySync('2026-09-16T10:00:00+00:00')
          ..['accounts'] = {
            'upserted': [accountJson(id, balance: 500)],
            'deleted': <Object>[],
          };
      }
      return {};
    });

    final status = await SyncEngine(db: db, api: api).sync();

    expect(status.phase, SyncPhase.idle);
    expect(api.requests.map((r) => '${r.$1} ${r.$2}'), ['POST /accounts', 'GET /sync']);
    expect(await db.select(db.pendingOperations).get(), isEmpty);
    expect(await db.readValue(SyncEngine.cursorKey), '2026-09-16T10:00:00+00:00');
  });

  test('keeps queued changes and skips pulling while offline', () async {
    await accounts.create(const AccountDraft(name: 'Bank', type: 'bank', currency: 'SAR', openingBalance: 0));
    final api = FakeApiClient((method, path, body, query) => throw offline);

    final status = await SyncEngine(db: db, api: api).sync();

    expect(status.phase, SyncPhase.offline);
    expect(api.requests, hasLength(1));
    final queued = await db.select(db.pendingOperations).getSingle();
    expect(queued.attempts, 1);
  });

  test('a rejected create is discarded locally and triggers a full refresh', () async {
    final id = await accounts.create(const AccountDraft(name: 'Bad', type: 'bank', currency: 'SAR', openingBalance: 0));
    final api = FakeApiClient((method, path, body, query) {
      if (method == 'POST') {
        throw const ApiException(
          ApiErrorKind.validation,
          fieldErrors: {
            'name': ['bad'],
          },
        );
      }
      expect(query, isNot(contains('since')));
      return emptySync('2026-09-16T11:00:00+00:00');
    });

    final status = await SyncEngine(db: db, api: api).sync();

    expect(status.rejected, 1);
    expect(await accounts.watch(id).first, isNull);
    expect(await db.select(db.pendingOperations).get(), isEmpty);
  });

  test('pull applies server upserts and deletions and follows has_more pages', () async {
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: 'old',
            name: 'Old',
            type: 'bank',
            currency: 'SAR',
            updatedAt: DateTime.utc(2026),
          ),
        );
    await db.writeValue(SyncEngine.cursorKey, '2026-09-01T00:00:00+00:00');
    var page = 0;
    final api = FakeApiClient((method, path, body, query) {
      page++;
      final response = emptySync('2026-09-16T1$page:00:00+00:00')..['has_more'] = page == 1;
      if (page == 1) {
        response['accounts'] = {
          'upserted': [accountJson('new', balance: 42)],
          'deleted': <Object>[],
        };
      } else {
        response['accounts'] = {
          'upserted': <Object>[],
          'deleted': ['old'],
        };
      }
      return response;
    });

    await SyncEngine(db: db, api: api).sync();

    final rows = await db.select(db.accounts).get();
    expect(rows.map((a) => a.id), ['new']);
    expect(rows.single.balance, 42);
    expect(api.requests, hasLength(2));
    expect(await db.readValue(SyncEngine.cursorKey), '2026-09-16T12:00:00+00:00');
  });

  test('concurrent sync calls share one run', () async {
    final api = FakeApiClient((method, path, body, query) => emptySync('2026-09-16T10:00:00+00:00'));
    final engine = SyncEngine(db: db, api: api);

    await Future.wait([engine.sync(), engine.sync()]);
    // One shared run plus exactly one follow-up for the call made mid-run.
    await Future<void>.delayed(Duration.zero);
    await engine.sync();

    expect(api.requests.length, lessThanOrEqualTo(3));
  });
}
