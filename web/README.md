# Masroof web

Next.js 16 (App Router, Turbopack) dashboard for Masroof.

- **UI:** Tailwind CSS v4 + shadcn/ui (Radix, RTL enabled), Recharts, lucide icons
- **Data:** TanStack Query against a backend-for-frontend (`/api/backend/*`)
- **Auth:** `/api/auth/{login,register,logout}` exchange credentials for a Laravel Sanctum
  token stored in an **httpOnly, SameSite=Lax** cookie. The token never reaches browser JS.
  Mutating proxy requests are also rejected unless `Origin` matches the host.
- **i18n:** Arabic (default, RTL) and English dictionaries in `src/lib/i18n`; locale lives in the
  `masroof_locale` cookie so the server renders the correct `lang`/`dir` on first paint.
- **Route protection:** `src/proxy.ts` (Next 16 replacement for middleware).

## Develop

```bash
cp .env.example .env.local    # MASROOF_API_URL=http://127.0.0.1:8000
npm install
npm run dev
```

## Quality

```bash
npm run lint
npm run typecheck
npm run test
npm run build
```
