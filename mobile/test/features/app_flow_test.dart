import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:masroof/app.dart';
import 'package:drift/drift.dart' show Value;
import 'package:masroof/core/database/app_database.dart';
import 'package:masroof/core/providers.dart';
import 'package:masroof/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

void main() {
  late AppDatabase db;
  late MemoryTokenStorage tokens;

  setUpAll(() async => initializeDateFormatting());

  setUp(() {
    db = memoryDatabase();
    tokens = MemoryTokenStorage();
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, {required String locale, FakeApiClient? api}) async {
    SharedPreferences.setMockInitialValues({'settings.locale': locale});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          tokenStorageProvider.overrideWithValue(tokens),
          apiClientProvider.overrideWithValue(api ?? FakeApiClient((method, path, body, query) => throw offline)),
        ],
        child: const MasroofApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signInLocally({bool onboarded = true}) async {
    await tokens.write('test-token');
    await db.writeValue(
      'auth.user',
      jsonEncode({
        'id': '01j00000000000000000000000',
        'name': 'Sara Ahmed',
        'email': 'sara@example.com',
        'locale': 'ar',
        'currency': 'ILS',
        'timezone': 'Asia/Hebron',
        'week_start': 6,
        'email_verified': true,
        'settings': {'onboarding_completed': onboarded},
      }),
    );
  }

  testWidgets('signed-out users see the Arabic login screen laid out right-to-left', (tester) async {
    await pumpApp(tester, locale: 'ar');

    expect(find.text('مرحبًا بعودتك'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('مرحبًا بعودتك'))), TextDirection.rtl);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('language-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Welcome back'))), TextDirection.ltr);
  });

  testWidgets('offline user can add an account and an expense and sees the balance update', (tester) async {
    await signInLocally();
    await pumpApp(tester, locale: 'en');

    expect(find.text('Hello, Sara'), findsOneWidget);
    expect(find.text("Let's set up your money"), findsOneWidget);

    // Create an account.
    await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Account name'), 'Wallet');
    await tester.enterText(find.widgetWithText(TextFormField, 'Opening balance'), '200');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Wallet'), findsWidgets);
    expect(find.textContaining('200.00'), findsWidgets);

    // Seed a category (normally provisioned by the server on registration).
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: '01j00000000000000000000001',
            name: 'الطعام',
            type: 'expense',
            defaultKey: const Value('food'),
            updatedAt: DateTime.utc(2026),
          ),
        );

    // Record an expense.
    await tester.tap(find.text('Add transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount-field')), '45.50');
    await tester.tap(find.text('Select a category').first);
    await tester.pumpAndSettle();
    // Built-in category is shown in the UI language, not the stored name.
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();

    expect(find.textContaining('154.50'), findsWidgets);
    expect(find.text('Food'), findsWidgets);
    // Both writes are queued for sync while offline.
    expect(await db.select(db.pendingOperations).get(), hasLength(2));
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('users who have not onboarded are guided through onboarding', (tester) async {
    await signInLocally(onboarded: false);
    Map<String, dynamic>? submitted;
    final api = FakeApiClient((method, path, body, query) {
      if (method == 'POST' && path == '/onboarding') {
        submitted = body as Map<String, dynamic>;
        return {
          'data': {
            'id': '01j00000000000000000000000',
            'name': 'Sara Ahmed',
            'email': 'sara@example.com',
            'locale': 'en',
            'currency': 'JOD',
            'timezone': 'Asia/Amman',
            'week_start': 6,
            'email_verified': true,
            'settings': {'onboarding_completed': true},
          },
        };
      }
      throw offline;
    });
    await pumpApp(tester, locale: 'en', api: api);

    expect(find.text('What should we call you?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JOD'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '850.5');
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build an emergency fund'));
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(submitted, containsPair('currency', 'JOD'));
    expect(submitted, containsPair('monthly_income_estimate', '850.500'));
    expect(submitted, containsPair('main_goal', 'emergency_fund'));
    expect(find.text('Hello, Sara'), findsOneWidget);
  });
}
