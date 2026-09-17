import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:masroof/core/network/api_exception.dart';
import 'package:masroof/features/notifications/data/notifications_repository.dart';
import 'package:masroof/features/recurring/data/recurring.dart';
import 'package:masroof/features/reports/data/reports_repository.dart';

import '../helpers/fakes.dart';

void main() {
  group('ReportsRepository', () {
    late Directory dir;

    setUp(() async => dir = await Directory.systemTemp.createTemp('masroof-reports'));
    tearDown(() => dir.delete(recursive: true));

    test('polls until the export completes and saves the file', () async {
      var polls = 0;
      final api = FakeApiClient((method, path, body, query) {
        if (method == 'POST') {
          expect(body, {'type': 'monthly', 'format': 'pdf'});
          return {
            'data': {'id': 'e1', 'status': 'pending'},
          };
        }
        polls++;
        return {
          'data': {
            'id': 'e1',
            'status': polls < 2 ? 'processing' : 'completed',
            'file_name': 'monthly-report-2026-09-17.pdf',
          },
        };
      })..downloads['/reports/exports/e1/download'] = '%PDF-1.4'.codeUnits;

      final repo = ReportsRepository(api, directory: () async => dir, pollInterval: Duration.zero);
      final file = await repo.generate(type: 'monthly', format: 'pdf');

      expect(polls, 2);
      expect(file.path.endsWith('monthly-report-2026-09-17.pdf'), isTrue);
      expect(await file.readAsString(), '%PDF-1.4');
    });

    test('throws when the export fails', () async {
      final api = FakeApiClient(
        (method, path, body, query) => {
          'data': {'id': 'e2', 'status': method == 'POST' ? 'pending' : 'failed'},
        },
      );
      final repo = ReportsRepository(api, directory: () async => dir, pollInterval: Duration.zero);

      expect(repo.generate(type: 'budgets', format: 'xlsx'), throwsA(isA<ApiException>()));
    });
  });

  test('notifications repository parses inbox and preferences', () async {
    final api = FakeApiClient((method, path, body, query) {
      if (path == '/notifications') {
        return {
          'data': [
            {
              'id': 'n1',
              'type': 'budget_threshold',
              'title': 'Food budget at 90%',
              'body': 'You have spent …',
              'action': '/budgets',
              'read': false,
              'created_at': '2026-09-17T07:00:00+00:00',
            },
          ],
          'meta': {'unread_count': 1},
        };
      }
      return {
        'data': {
          'budget_threshold': {'in_app': true, 'email': false},
        },
      };
    });
    final repo = NotificationsRepository(api);

    final inbox = await repo.inbox();
    expect(inbox.unread, 1);
    expect(inbox.items.single.action, '/budgets');

    final prefs = await repo.updatePreference('budget_threshold', inApp: true, email: false);
    expect(prefs['budget_threshold'], (inApp: true, email: false));
    expect(api.requests.last.$3, {
      'preferences': {
        'budget_threshold': {'in_app': true, 'email': false},
      },
    });
  });

  test('recurring rule parses category and schedule', () {
    final rule = RecurringRule.fromJson({
      'id': 'r1',
      'name': 'Rent',
      'type': 'expense',
      'account_id': 'a1',
      'category_id': 'c1',
      'transfer_account_id': null,
      'currency': 'ILS',
      'amount': '2800.00',
      'amount_minor': 280000,
      'merchant': 'Landlord',
      'frequency': 'monthly',
      'interval': 1,
      'starts_on': '2026-10-02',
      'ends_on': null,
      'next_occurrence_on': '2026-10-02',
      'mode': 'auto',
      'remind_days_before': 1,
      'paused': false,
      'category': {'id': 'c1', 'name': 'الإيجار', 'default_key': 'rent', 'icon': 'home', 'color': '#7C3AED'},
    });
    expect(rule.categoryKey, 'rent');
    expect(rule.nextOccurrenceOn, '2026-10-02');
    expect(rule.amountMinor, 280000);
  });
}
