import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:masroof/app.dart';
import 'package:masroof/core/database/app_database.dart';
import 'package:masroof/core/network/api_exception.dart';
import 'package:masroof/core/network/cached_resource.dart';
import 'package:masroof/core/providers.dart';
import 'package:masroof/core/storage/token_storage.dart';
import 'package:masroof/features/analytics/data/analytics.dart';
import 'package:masroof/features/budgets/data/budget.dart';
import 'package:masroof/features/goals/data/goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

Map<String, dynamic> budgetJson({String status = 'warning', double percent = 72}) => {
  'id': 'b1',
  'name': 'Transport',
  'period': 'monthly',
  'currency': 'ILS',
  'amount': '500.00',
  'amount_minor': 50000,
  'starts_on': null,
  'ends_on': null,
  'alert_thresholds': [50, 75, 90, 100],
  'category_ids': ['c1'],
  'archived': false,
  'progress': {
    'period': {'start': '2026-09-01', 'end': '2026-09-30'},
    'spent': '360.00',
    'spent_minor': 36000,
    'remaining': '140.00',
    'remaining_minor': 14000,
    'percent': percent,
    'days_left': 15,
    'safe_to_spend_daily': '9.33',
    'safe_to_spend_daily_minor': 933,
    'expected_spent_minor': 25000,
    'projected_spent_minor': 60000,
    'reached_thresholds': [50],
    'status': status,
  },
};

Map<String, dynamic> goalJson() => {
  'id': 'g1',
  'name': 'Laptop',
  'kind': 'laptop',
  'currency': 'JOD',
  'target_amount': '900.500',
  'target_amount_minor': 900500,
  'current_amount': '300.000',
  'current_amount_minor': 300000,
  'target_date': '2027-03-16',
  'account_id': null,
  'icon': null,
  'color': '#2563EB',
  'notes': null,
  'achieved': false,
  'achieved_at': null,
  'archived': false,
  'progress': {
    'percent': 33.3,
    'remaining': '600.500',
    'remaining_minor': 600500,
    'monthly_needed': '100.084',
    'monthly_needed_minor': 100084,
    'average_monthly_contribution_minor': 150000,
    'expected_completion_date': '2026-12-20',
  },
};

void main() {
  setUpAll(() async => initializeDateFormatting());

  group('models parse API payloads', () {
    test('budget', () {
      final budget = Budget.fromJson(budgetJson());
      expect(budget.amountMinor, 50000);
      expect(budget.progress.safeToSpendDailyMinor, 933);
      expect(budget.progress.status, 'warning');
      expect(budget.categoryIds, ['c1']);
    });

    test('goal', () {
      final goal = Goal.fromJson(goalJson());
      expect(goal.currentAmountMinor, 300000);
      expect(goal.monthlyNeededMinor, 100084);
      expect(goal.expectedCompletionDate, '2026-12-20');
    });

    test('analytics summary with nullable changes', () {
      final summary = AnalyticsSummary.fromJson({
        'currency': 'ILS',
        'period': {'start': '2026-09-01', 'end': '2026-09-30'},
        'previous_period': {'start': '2026-08-01', 'end': '2026-08-31'},
        'income': 920000,
        'expense': 520664,
        'savings': 399336,
        'savings_rate': 43.4,
        'average_daily_spending': 32541,
        'previous': {'income': 0, 'expense': 0, 'savings': 0, 'savings_rate': null},
        'changes': {'income': null, 'expense': 5.4},
        'categories': [
          {
            'category_id': null,
            'name': null,
            'default_key': null,
            'color': null,
            'icon': null,
            'is_fixed': false,
            'total': 100,
            'count': 1,
            'previous_total': 0,
            'change': null,
            'share': 1.0,
          },
        ],
        'fixed_vs_variable': {'fixed': 280000, 'variable': 240664},
        'largest_expenses': [
          {
            'id': 't1',
            'amount': 280000,
            'merchant': 'Landlord',
            'note': null,
            'category': 'Rent',
            'default_key': 'rent',
            'occurred_at': '2026-09-02T07:00:00+00:00',
          },
        ],
        'top_merchants': [
          {'merchant': 'Zaytouna Cafe', 'count': 3, 'total': 23500},
        ],
      });
      expect(summary.incomeChange, isNull);
      expect(summary.expenseChange, 5.4);
      expect(summary.categories.single.categoryId, isNull);
      expect(summary.topMerchants.single.count, 3);
      expect(summary.largestExpenses.single.defaultKey, 'rent');
    });
  });

  group('CachedResource', () {
    late AppDatabase db;

    setUp(() => db = memoryDatabase());
    tearDown(() => db.close());

    test('serves cached data first, then fresh data, and falls back to cache offline', () async {
      var online = true;
      var version = 1;
      final api = FakeApiClient((method, path, body, query) {
        if (!online) throw offline;
        return {'data': 'v${version++}'};
      });
      final cache = CachedResource(db, api);

      final first = await cache.watch('/budgets').toList();
      expect(first.map((v) => (v.json['data'], v.stale)), [('v1', false)]);

      final second = await cache.watch('/budgets').toList();
      expect(second.map((v) => (v.json['data'], v.stale)), [('v1', true), ('v2', false)]);

      online = false;
      final third = await cache.watch('/budgets').toList();
      expect(third.map((v) => (v.json['data'], v.stale)), [('v2', true)]);
    });

    test('rethrows when offline with nothing cached, and invalidates by prefix', () async {
      final cache = CachedResource(db, FakeApiClient((method, path, body, query) => throw offline));
      await expectLater(cache.watch('/goals').toList(), throwsA(isA<ApiException>()));

      await db.writeValue('cache:/goals', jsonEncode({'data': []}));
      await db.writeValue('cache:/budgets', jsonEncode({'data': []}));
      await cache.invalidate('/goals');
      expect(await db.readValue('cache:/goals'), isNull);
      expect(await db.readValue('cache:/budgets'), isNotNull);
    });
  });

  testWidgets('Plan tab shows budgets and goals in Arabic', (tester) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final tokens = MemoryTokenStorage();
    await tokens.write('token');
    await db.writeValue(
      'auth.user',
      jsonEncode({
        'id': 'u1',
        'name': 'ليلى حداد',
        'email': 'layla@example.com',
        'locale': 'ar',
        'currency': 'ILS',
        'timezone': 'Asia/Hebron',
        'week_start': 6,
        'email_verified': true,
        'settings': {'onboarding_completed': true},
      }),
    );
    SharedPreferences.setMockInitialValues({'settings.locale': 'ar'});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final api = FakeApiClient((method, path, body, query) {
      return switch (path) {
        '/budgets' => {
          'data': [budgetJson(status: 'exceeded', percent: 113.3)],
        },
        '/goals' => {
          'data': [goalJson()],
        },
        _ => throw offline,
      };
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          tokenStorageProvider.overrideWithValue(tokens),
          apiClientProvider.overrideWithValue(api),
        ],
        child: const MasroofApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('التخطيط'));
    await tester.pumpAndSettle();

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('تجاوزت الميزانية'), findsOneWidget);
    expect(find.textContaining('9.33'), findsOneWidget);

    await tester.tap(find.text('أهداف الادخار'));
    await tester.pumpAndSettle();
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.textContaining('100.084'), findsOneWidget);
  });
}
