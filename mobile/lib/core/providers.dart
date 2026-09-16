import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/accounts/data/accounts_repository.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/categories/data/categories_repository.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/transactions/data/transactions_repository.dart';
import 'database/app_database.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';
import 'sync/outbox.dart';
import 'sync/sync_engine.dart';

/// Overridden in main() and in tests.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokens: ref.watch(tokenStorageProvider),
    locale: () => ref.read(settingsControllerProvider).locale.languageCode,
    onUnauthorized: () => ref.read(authControllerProvider.notifier).onSessionExpired(),
  );
});

final outboxProvider = Provider<Outbox>((ref) => Outbox(ref.watch(databaseProvider)));

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(db: ref.watch(databaseProvider), api: ref.watch(apiClientProvider));
  ref.onDispose(engine.dispose);
  return engine;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.status;
});

final pendingChangesProvider = StreamProvider<int>((ref) => ref.watch(outboxProvider).watchCount());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStorageProvider),
    db: ref.watch(databaseProvider),
  ),
);

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(ref.watch(databaseProvider), ref.watch(outboxProvider)),
);

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(ref.watch(databaseProvider), ref.watch(outboxProvider)),
);

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(ref.watch(databaseProvider), ref.watch(outboxProvider)),
);
