# EMI Frontend Web

Frontend web untuk **EMI — Elearning Mekongga Indonesia** pada Fase 9.
Backend Laravel tetap menjadi source of truth untuk autentikasi, role,
authorization, progress, grading, dan laporan.

## Getting Started

Salin env contoh:

```bash
cp .env.example .env.local
```

Jalankan development server:

```bash
npm run dev
```

Buka [http://localhost:3000](http://localhost:3000).

## Environment

```bash
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1
NEXT_PUBLIC_APP_NAME="EMI — Elearning Mekongga Indonesia"
```

## Script

```bash
npm run dev
npm run lint
npm run build
```

## Fondasi Fase 9

- App Router, TypeScript, Tailwind CSS, ESLint.
- Native `fetch` API client untuk Laravel REST API.
- TanStack Query provider.
- Auth provider berbasis Sanctum bearer token di local storage.
- Login, logout, current user, register pending approval.
- Route guard berdasarkan role Admin, Guru, dan Siswa.
- Layout awal per role.
- Komponen UI reusable untuk form, card, state, table, dialog, upload, audio,
  dan pagination.

## Playwright E2E

Fondasi E2E memakai Chromium, satu worker, dan autentikasi UI tersimpan untuk Admin, Guru, dan Siswa.

1. Salin `.env.e2e.example` menjadi `.env.e2e`, lalu sesuaikan kredensial dengan akun lokal.
2. Siapkan data demo secara aman dan idempotent:

```bash
cd ../Emi-Backend
php artisan db:seed --class=DevDemoDataSeeder
```

3. Jalankan Laravel dan Next.js pada terminal terpisah:

```bash
# Terminal 1: Emi-Backend
php artisan serve --host=127.0.0.1 --port=8000

# Terminal 2: Emi-Frontend
npm run dev -- --hostname 127.0.0.1 --port 3000
```

4. Jalankan E2E dari `Emi-Frontend`:

```bash
npm run test:e2e
npm run test:e2e:admin
npm run test:e2e:teacher
npm run test:e2e:student
npm run test:e2e:cross-role
npm run test:e2e:headed
npm run test:e2e:report
```

Authentication state dibuat di `playwright/.auth/` dan tidak masuk Git. Hasil gagal disimpan di `test-results/`; report HTML berada di `playwright-report/`. Fase ini hanya mencakup login, dashboard role, logout, dan guest guard.

## Batasan

Test fitur panjang Admin, Guru, dan Siswa belum menjadi bagian fondasi E2E ini.
