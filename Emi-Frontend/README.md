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

## Batasan

Implementasi ini belum membangun semua 51 screen dari Figma Screen Map. Layar
domain seperti sekolah, kelas, kamus, modul, kuis, laporan detail, dan profile
akan diintegrasikan bertahap dengan endpoint Laravel yang sudah tersedia.
