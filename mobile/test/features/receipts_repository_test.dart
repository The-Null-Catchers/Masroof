import 'package:flutter_test/flutter_test.dart';
import 'package:masroof/core/sync/outbox.dart';
import 'package:masroof/features/accounts/data/accounts_repository.dart';
import 'package:masroof/features/receipts/data/receipts_repository.dart';
import 'package:masroof/features/transactions/data/transactions_repository.dart';

import '../helpers/fakes.dart';

Map<String, dynamic> receiptJson(String status) => {
  'data': {
    'id': 'r1',
    'status': status,
    'error': null,
    'extracted': status == 'processed'
        ? {
            'merchant': 'Bravo Supermarket',
            'total': '24.40',
            'total_minor': 2440,
            'currency': 'ILS',
            'date': '2026-09-15',
            'suggested_category_id': 'c1',
            'confidence': 1,
            'display_total': '24.40 ₪',
          }
        : null,
  },
};

void main() {
  test('uploads the photo and polls until OCR finishes', () async {
    var polls = 0;
    final api = FakeApiClient((method, path, body, query) {
      if (method == 'UPLOAD') return receiptJson('uploaded');
      polls++;
      return receiptJson(polls < 2 ? 'processing' : 'processed');
    });

    final receipt = await ReceiptsRepository(api).scan('/tmp/receipt.jpg', interval: Duration.zero);

    expect(api.requests.map((r) => '${r.$1} ${r.$2}'), ['UPLOAD /receipts', 'GET /receipts/r1', 'GET /receipts/r1']);
    expect(receipt.merchant, 'Bravo Supermarket');
    expect(receipt.total, '24.40');
    expect(receipt.currency, 'ILS');
    expect(receipt.date, DateTime(2026, 9, 15));
    expect(receipt.suggestedCategoryId, 'c1');
  });

  test('failed OCR resolves without extracted fields', () async {
    final api = FakeApiClient((method, path, body, query) => receiptJson('failed'));

    final receipt = await ReceiptsRepository(api).scan('/tmp/receipt.jpg', interval: Duration.zero);

    expect(receipt.failed, isTrue);
    expect(receipt.total, isNull);
  });

  test('a transaction created from a receipt queues the receipt link for sync', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final outbox = Outbox(db);
    final accountId = await AccountsRepository(
      db,
      outbox,
    ).create(const AccountDraft(name: 'Wallet', type: 'cash', currency: 'ILS', openingBalance: 10000));

    final id = await TransactionsRepository(db, outbox).create(
      TransactionDraft(
        type: 'expense',
        accountId: accountId,
        amount: 2440,
        occurredAt: DateTime.utc(2026, 9, 15, 12),
        receiptId: 'r1',
      ),
    );

    final queued = await (db.select(db.pendingOperations)..where((o) => o.entityId.equals(id))).getSingle();
    expect(queued.payload, contains('"receipt_id":"r1"'));
  });
}
