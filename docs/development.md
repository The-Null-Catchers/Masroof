# Development

## Prerequisites

| Tool | Version | Used by |
|------|---------|---------|
| Docker or Podman | recent | PostgreSQL, Redis, Mailpit, PHP image |
| PHP | 8.5 (or use the `masroof-php:dev` image) | backend |
| Node.js | 22 | web |
| Flutter | 3.47 (stable), JDK 17, Android SDK | mobile |
| Python 3 + Pillow | any | regenerating brand assets |

## 1. Services

```bash
docker compose -f compose.dev.yaml up -d      # PostgreSQL (masroof + masroof_test), Redis, Mailpit
```

## 2. Backend (Laravel)

PHP can run on the host or through the dev image, which already has every extension and Tesseract:

```bash
docker build --target dev -t masroof-php:dev -f docker/php/Dockerfile .
alias mphp=scripts/php           # runs a command in the image with backend/ mounted (host network)
```

```bash
cd backend
cp .env.example .env
../scripts/php composer install
../scripts/php php artisan key:generate
../scripts/php php artisan migrate --seed       # demo data + admin user
../scripts/php php artisan serve --host=127.0.0.1 --port=8000
../scripts/php php artisan queue:work          # separate terminal: OCR, exports, alerts
../scripts/php php artisan schedule:work       # optional: recurring + notifications
```

Demo accounts (never seeded in production):

| Email | Password | Role |
|-------|----------|------|
| `demo@masroof.app` | `password1` | User with three months of data (ILS, USD, JOD) |
| `admin@masroof.app` | `password1` | Admin |

Set `MASROOF_OCR_DRIVER=mock` if Tesseract is not installed on the host.
API docs: <http://127.0.0.1:8000/docs/api>. Mail: <http://127.0.0.1:8025> when `MAIL_MAILER=smtp`,
`MAIL_PORT=1025`.

Quality checks:

```bash
../scripts/php vendor/bin/pint                 # format
../scripts/php vendor/bin/phpstan analyse --memory-limit=1G
../scripts/php php artisan test                # uses the masroof_test database
../scripts/php composer docs:openapi           # regenerate docs/openapi.json after API changes
```

Useful commands: `masroof:verify-balances [--fix]`, `masroof:process-recurring`,
`masroof:send-notifications`, `masroof:admin <email> [--revoke]`, `masroof:prune-receipts`,
`masroof:prune-exports`.

## 3. Web (Next.js)

```bash
cd web
cp .env.example .env.local        # MASROOF_API_URL=http://127.0.0.1:8000
npm install
npm run dev                       # http://localhost:3000
```

Checks: `npm run format:check`, `npm run lint`, `npm run typecheck`, `npm test`, `npm run build`.

> Next.js 16 differs from older versions (`src/proxy.ts` replaces middleware, async
> `params`/`cookies`). Read `node_modules/next/dist/docs/` before changing framework-level code.

## 4. Mobile (Flutter)

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift code
flutter gen-l10n
flutter run                                                  # emulator uses http://10.0.2.2:8000
flutter run --dart-define=MASROOF_API_URL=http://192.168.1.20:8000   # physical device
```

Checks:

```bash
find lib test -name '*.dart' ! -name '*.g.dart' ! -path 'lib/l10n/generated/*' | xargs dart format -l 120
flutter analyze
flutter test
flutter build apk --release        # debug-signed unless android/key.properties exists
```

Release signing: create `android/key.properties` (git-ignored) with `storeFile`, `storePassword`,
`keyAlias` and `keyPassword`, or set `MASROOF_KEYSTORE_PATH`, `MASROOF_KEYSTORE_PASSWORD`,
`MASROOF_KEY_ALIAS` and `MASROOF_KEY_PASSWORD`.

## Conventions

* **Money:** integer minor units everywhere; decimal strings at the API boundary; never floats.
* **Localization:** every user-facing string exists in Arabic and English (`lang/`,
  `web/src/lib/i18n`, `mobile/lib/l10n`). Arabic is the default. Wrap numbers in bidi isolates.
* **Ownership:** policies and scoped queries; another user's record is a 404, never a 403.
* **Transactions:** always through `TransactionService` (balances, locks, alerts).
* **Insights:** deterministic rules only.
* **Commits:** small, logical, conventional prefixes (`feat(web):`, `fix(backend):`, `docs:`).
  Never commit `.env` files, keystores, build outputs or IDE state.

## CI

`.github/workflows/ci.yml` runs only the jobs affected by a change:

| Job | Steps |
|-----|-------|
| Backend | Composer install, Pint, Larastan, PHPUnit (PostgreSQL + Redis services), OpenAPI spec freshness |
| Web | `npm ci`, Prettier, ESLint, typecheck, Vitest, production build |
| Mobile | codegen freshness, format, analyze, tests, release APK + AAB uploaded as artifacts |
| Docker | `docker compose config`, API and web production image builds |

Repository secrets for signed Android builds: `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. Optional variable
`MASROOF_API_URL` bakes the production API into mobile builds.
