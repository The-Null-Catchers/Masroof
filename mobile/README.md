# Masroof mobile

Flutter app for Android and iOS. Offline-first: every screen reads from a
local Drift database, writes are applied locally and queued, and a sync
engine pushes the queue and pulls server changes.

## Architecture

```
lib/
  core/            config, theme, money, network (Dio), storage, database (Drift), sync, widgets, l10n
  features/<name>/ data (repositories) · application (Riverpod providers/controllers) · presentation (screens)
  router/          GoRouter with auth redirects and the bottom-navigation shell
  l10n/            app_en.arb / app_ar.arb (+ generated/)
```

- **State:** Riverpod (`Notifier`, `StreamProvider`)
- **Navigation:** GoRouter (`StatefulShellRoute` for tabs)
- **Networking:** Dio with bearer token, `Accept-Language`, normalized `ApiException`
- **Secure storage:** API token in Keychain / Android Keystore (`flutter_secure_storage`)
- **Local DB:** Drift (SQLite) — accounts, categories, transactions, outbox, key/value

### Offline sync

1. Repositories write to Drift **and** append to `pending_operations` in one DB transaction.
   Account balances are adjusted locally with the same rules as the API.
2. Records get client-generated ULIDs, so creates are idempotent on the server.
3. `SyncEngine.sync()` replays the outbox in order:
   - network/5xx/429 → stop and retry later (queue kept)
   - 4xx rejection → drop the operation, discard rejected creates, then full refresh
4. It then pulls `GET /api/v1/sync?since=<cursor>` and applies upserts/deletions.

Sync runs after sign-in, after each local write, on pull-to-refresh, on app resume
and when connectivity returns.

## Money

Amounts are integers in minor units everywhere (`Money.tryParse`, `Money.toDecimal`).
The API receives exact decimal strings; floats are never used. Arabic-Indic digits
are accepted in input.

## Running

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift
flutter gen-l10n
flutter run --dart-define=MASROOF_API_URL=http://10.0.2.2:8000
```

Without `MASROOF_API_URL`, Android emulators use `http://10.0.2.2:8000` and other
targets `http://127.0.0.1:8000` (see `lib/core/config/app_config.dart`).

## Quality

```bash
find lib test -name "*.dart" ! -name "*.g.dart" ! -path "lib/l10n/generated/*" | xargs dart format -l 120
flutter analyze
flutter test
```

## Icons and splash

Launcher icons and the native splash are generated from `/branding`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
