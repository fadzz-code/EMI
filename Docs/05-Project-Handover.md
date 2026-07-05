# EMI — Project Handover

Dokumen ini adalah pegangan onboarding untuk akun Codex baru atau pengembang baru yang akan melanjutkan proyek EMI. Sumber utama dokumen ini adalah repository aktual di `D:\!Kerjaan\EMI`, automated test, migration, route, dokumentasi teknis, dan Git history. Percakapan lama hanya boleh dipakai sebagai konteks tambahan, bukan sumber kebenaran utama.

## 1. Identitas Proyek

EMI — Elearning Mekongga Indonesia adalah aplikasi pembelajaran Bahasa Mekongga berbasis digital. Tujuannya adalah membantu sekolah, guru, dan siswa mempelajari kosakata, materi, kuis, dan progress belajar Bahasa Mekongga secara terstruktur.

Target pengguna utama:

- Admin, sebagai pengelola global sistem.
- Guru, sebagai pengelola pembelajaran kelas.
- Siswa, sebagai peserta belajar.

Konteks utama EMI adalah pelestarian dan pembelajaran Bahasa Mekongga. Konten budaya lokal direncanakan sebagai bagian penting ekosistem akhir, baik sebagai materi baca, sumber pembelajaran, maupun basis pengetahuan untuk fitur AI pada fase lanjutan. Sampai kondisi repository ini, konten budaya penuh belum diimplementasikan sebagai fitur backend aktif.

## 2. Gambaran Sistem

Ekosistem akhir EMI direncanakan terdiri dari:

| Komponen | Status Repository Saat Ini |
|---|---|
| Laravel REST API | Selesai untuk Fase 1-8 |
| PostgreSQL | Digunakan sebagai database utama backend |
| Object storage | Fondasi media tersedia melalui disk public/private dan konfigurasi S3-compatible |
| Web LMS Next.js | Fase aktif berikutnya, belum ada folder `Emi-Frontend` |
| Android Flutter | Direncanakan, belum dikerjakan |
| SQLite offline | Direncanakan untuk mobile, belum dikerjakan |
| Voice engine FastAPI | Direncanakan, belum dikerjakan |
| Speaking assessment | Direncanakan, belum aktif; dashboard mengembalikan capability `speaking_reports=false` |
| Chatbot RAG | Direncanakan, belum dikerjakan |
| ESP32 | Direncanakan fase lanjutan, belum dikerjakan |

Fitur backend yang sudah selesai berada pada domain autentikasi, approval, sekolah, kelas, pengguna, media, kamus, import kamus, modul, lesson, progress, kuis, dashboard, laporan, dan CSV export. Fitur yang belum dikerjakan tidak boleh dianggap tersedia hanya karena tercantum di roadmap atau ERD konseptual.

## 3. Role dan Hak Akses

Admin mengelola sistem secara global: approval akun, sekolah, kelas, guru, siswa, assignment, membership, media, kamus, template modul, template kuis, dashboard, dan laporan.

Guru hanya mengelola kelas dari assignment aktifnya. Guru dapat mengelola modul kelas, lesson kelas, kuis kelas, melihat hasil belajar, dan membuka laporan kelas sesuai scope assignment aktif.

Siswa hanya mengakses data dari membership aktifnya. Siswa dapat mengakses modul published, lesson, kamus, kuis, attempt, progress, dashboard, dan laporan miliknya sendiri.

Batasan wajib:

- Guru hanya mengelola assignment aktifnya.
- Siswa hanya mengakses membership aktifnya.
- UUID bukan authorization.
- IDOR harus dicegah di backend melalui middleware, policy, request validation, dan service scope.

## 4. Aturan Bisnis Penting

- Guru dan siswa mendaftar melalui endpoint publik dan harus di-approve Admin.
- Akun `pending`, `rejected`, atau `inactive` tidak boleh login.
- Satu guru hanya mempunyai satu assignment aktif.
- Satu kelas hanya mempunyai satu guru aktif.
- Satu siswa hanya mempunyai satu membership kelas aktif.
- Riwayat assignment guru dan membership siswa dipertahankan.
- Admin dapat melakukan reassignment dengan menutup relasi aktif lama lalu membuat relasi aktif baru.
- Template modul disalin ke kelas sebagai snapshot independen.
- Template kuis disalin ke kelas sebagai snapshot independen.
- Perubahan template tidak otomatis mengubah salinan kelas.
- Progress lesson dan module dihitung oleh backend.
- Grading kuis dihitung oleh backend.
- Submit kuis bersifat idempotent.
- `class_quizzes.show_result=false` harus menyembunyikan nilai dari siswa.
- Data historis tidak boleh hilang sembarangan; record yang sudah memiliki progress atau attempt umumnya diarsipkan, bukan dihapus keras.

## 5. Arsitektur Teknologi

| Teknologi | Peran | Status |
|---|---|---|
| Laravel | Backend REST API | Selesai untuk Fase 1-8 |
| PostgreSQL | Database utama | Digunakan; `.env.example` memakai `DB_CONNECTION=pgsql` |
| Laravel Sanctum | Authentication token | Selesai |
| Laravel Policy | Authorization ownership/scope | Selesai pada domain backend aktif |
| Queue Laravel | Import kamus dan pekerjaan async ringan | Tersedia sesuai implementasi import |
| Object storage/S3-compatible | Media public/private | Fondasi selesai, konfigurasi S3 tersedia |
| Next.js | Web LMS | Fase aktif Fase 9, belum dibuat |
| Flutter | Android app | Belum dikerjakan |
| SQLite | Offline cache mobile | Belum dikerjakan |
| FastAPI | Voice/speaking engine | Belum dikerjakan |
| RAG/knowledge base chatbot | AI chatbot | Belum dikerjakan |
| ESP32 | Integrasi IoT | Belum dikerjakan |

Backend Laravel tetap menjadi source of truth. Frontend tidak boleh membuat backend kedua, menyalin business rule secara permanen, atau mengganti validasi authorization backend.

## 6. Struktur Repository

Struktur aktual root repository:

```text
EMI/
├── AGENTS.md
├── Docs/
│   ├── Templates/
│   ├── Phases/
│   ├── 01-ERD-Database.md
│   ├── 02-Role-Permission-Matrix.md
│   ├── 03-API-Specification.md
│   ├── 04-Development-Plan.md
│   ├── 05-Project-Handover.md
│   └── progressbar.md
└── Emi-Backend/
```

`Emi-Frontend` belum tersedia dan direncanakan dibuat pada Fase 9.

Fungsi folder/file penting:

- `AGENTS.md`: aturan fase dan batas pengerjaan untuk Codex.
- `Docs`: dokumentasi ERD, role, API, roadmap, fase, template, progress, dan handover.
- `Emi-Backend`: aplikasi Laravel REST API.
- `Emi-Backend/app/Models`: model Eloquent domain aktif.
- `Emi-Backend/app/Http/Controllers`: controller API.
- `Emi-Backend/app/Http/Requests`: Form Request validasi.
- `Emi-Backend/app/Http/Resources`: API Resource untuk payload aman.
- `Emi-Backend/app/Policies`: policy authorization.
- `Emi-Backend/app/Services`: business logic dan query service.
- `Emi-Backend/database/migrations`: schema, constraint, index, dan tabel domain.
- `Emi-Backend/routes/api.php`: definisi route API v1.
- `Emi-Backend/tests`: unit dan feature test Fase 1-8.
- `Emi-Backend/config`: konfigurasi auth, database, filesystem, media, dictionary, quiz, dashboard, dan Laravel core.

## 7. Sumber Kebenaran

Urutan sumber kebenaran proyek:

1. Source code aktual.
2. Automated tests.
3. Migration.
4. `Emi-Backend/routes/api.php`.
5. `Docs/03-API-Specification.md`.
6. `Docs/01-ERD-Database.md`.
7. `Docs/02-Role-Permission-Matrix.md`.
8. `Docs/04-Development-Plan.md`.
9. `AGENTS.md`.
10. Git history dan tags.
11. Percakapan lama.

Percakapan lama bukan sumber kebenaran utama karena dapat berisi keputusan sementara, keputusan yang sudah dibatalkan, atau kondisi sebelum implementasi terbaru.

## 8. Ringkasan Fase 1-8

### Fase 1: Laravel Core

Fase ini membangun fondasi Laravel dan database inti: users, schools, classes, registration requests, teacher assignments, student memberships, personal access tokens, audit logs, constraint UUID, relationship model, factory, dan seeder Admin. Constraint utama mencakup role/status user, unique email, unique kelas per sekolah dan tahun ajaran, satu assignment guru aktif, satu guru aktif per kelas, dan satu membership siswa aktif.

### Fase 2: Authentication dan Approval

Fase ini menyelesaikan public lookup sekolah/kelas, registrasi guru/siswa, login Sanctum, logout, profil, update profil, update password, approval dan rejection pendaftaran oleh Admin, rate limit login/register, serta response error standar. Guru dan siswa baru berstatus `pending` sampai Admin memproses request.

### Fase 3: Sekolah, Kelas, dan Pengguna

Fase ini menyelesaikan CRUD sekolah dan kelas, daftar siswa kelas, manajemen user, assign/reassign guru, assign/reassign siswa, status user, policy scope, pagination/filter, dan audit log untuk perubahan penting. Guru dan siswa hanya melihat data sesuai kelas aktifnya.

### Fase 4: Media dan Object Storage

Fase ini menambahkan `media_files`, upload media, validasi MIME/ukuran, checksum, public/private visibility, metadata aman, temporary URL, local signed download, delete aman, usage tracking, avatar upload/replace/remove, dan authorization untuk media privat seperti speaking recording. File tidak disimpan langsung di PostgreSQL; database menyimpan metadata.

### Fase 5: Kamus dan Import

Fase ini menyelesaikan kategori kamus, entri kamus Indonesia-Inggris-Mekongga, pencarian, audio public, CSV template, preview import CSV, ZIP audio, validasi header/encoding, exact filename matching, duplicate strategy `skip|update|reject`, queue import, error per baris, import history, dan audit log.

### Fase 6: Modul, Materi, dan Progress

Fase ini menyelesaikan module template, lesson template, apply template ke kelas sebagai snapshot, class module, class lesson, publish/archive, ordering, konten text/image/audio/pdf/link/video-url, akses materi, lesson progress, module progress, dan perhitungan progress backend. Siswa hanya mengakses modul dan lesson published pada membership aktif.

### Fase 7: Kuis dan Penilaian

Fase ini menyelesaikan quiz template, quiz template question/option, apply snapshot ke class quiz, class quiz, quiz question/option, multiple choice, short answer, fuzzy matching, jadwal open/close, max attempts, active attempt constraint, save draft answer, idempotent submit, auto grading, expiry, result visibility, dan report kuis kelas. Kunci jawaban dan correct option tidak dikirim ke siswa.

### Fase 8: Dashboard dan Laporan

Fase ini menyelesaikan dashboard Admin/Guru/Siswa, laporan progress sekolah/kelas/siswa, laporan hasil kuis, best final attempt aggregation, hidden result behavior, trend dashboard, periode laporan, sorting whitelist, pagination, role scope, CSV streaming export, sanitasi CSV formula injection, dan dokumentasi API. Speaking report belum aktif dan diekspos sebagai capability `speaking_reports=false`.

## 9. Status Backend

Status verifikasi aktual:

- `php artisan test`: 75 tests passed, 740 assertions.
- `composer audit`: no security vulnerability advisories found.
- `php artisan route:list --path=api/v1`: 145 routes.
- Database utama: PostgreSQL (`DB_CONNECTION=pgsql` pada `.env.example`).
- Primary key domain: UUID.
- Authentication: Laravel Sanctum.
- Role middleware: `role:admin`, `role:teacher`, `role:student`.
- Authorization: policy, service scope, dan ownership check.
- Response API: format `success`, `message`, `data`, `code`, `errors`, dan `meta` pagination.
- Audit log: tersedia untuk tindakan administratif penting dan export report.
- Media handling: metadata di DB, file di disk public/private atau S3-compatible, signed URL untuk private access.
- Pagination: tersedia pada daftar utama dan report.
- Sorting whitelist: digunakan pada domain seperti kamus, laporan, dashboard/report.
- IDOR protection: diuji pada scope guru/siswa, media, module, quiz, dashboard, dan report.

Fase 1-8 telah diimplementasikan dan diuji pada backend.

## 10. Domain API

Kelompok endpoint aktif:

- Authentication dan profil.
- Public lookup sekolah/kelas dan public media content.
- Registration approval.
- Sekolah.
- Kelas.
- Pengguna.
- Assignment guru dan membership siswa.
- Media dan avatar.
- Kamus.
- Import kamus.
- Module template.
- Lesson template.
- Class module.
- Class lesson.
- Student progress.
- Quiz template.
- Quiz question.
- Class quiz.
- Quiz attempt dan grading.
- Dashboard.
- Laporan progress dan hasil kuis.
- CSV export laporan.

Daftar lengkap route dapat dilihat di:

- `Emi-Backend/routes/api.php`
- `Docs/03-API-Specification.md`
- command `php artisan route:list --path=api/v1`

Tidak perlu menyalin seluruh 145 route ke dokumen onboarding ini.

## 11. Pola Backend

Pola implementasi backend:

```text
Route
-> Middleware
-> Form Request
-> Controller
-> Policy
-> Service
-> Model
-> API Resource
```

Controller dibuat relatif tipis. Validasi request berada di Form Request dan validasi proses berada di service. Authorization memakai kombinasi middleware role, policy, dan scope service. Business logic utama berada di service. Model menjaga relationship dan casting. Migration serta constraint database menjadi lapisan perlindungan terakhir.

## 12. Kontrak Response API

Response sukses:

```json
{
  "success": true,
  "message": "Pesan Bahasa Indonesia.",
  "data": {}
}
```

Response gagal:

```json
{
  "success": false,
  "message": "Pesan kesalahan.",
  "code": "ERROR_CODE",
  "errors": {}
}
```

Pagination:

```json
{
  "success": true,
  "message": "Data berhasil diambil.",
  "data": [],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total": 100,
    "last_page": 5
  }
}
```

Error umum yang ditangani global antara lain `UNAUTHENTICATED`, `FORBIDDEN`, `VALIDATION_ERROR`, dan `NOT_FOUND`. Domain service menambahkan error code spesifik seperti konflik assignment, invalid media, invalid import, content locked, invalid quiz schedule, invalid report period, dan report scope forbidden.

## 13. Status Git

Status Git saat onboarding dokumen ini dimulai:

- Branch aktif: `feature/nextjs-web`.
- Working tree sebelum perubahan: bersih.
- File `Docs/05-Project-Handover.md`: sudah tracked dan kosong sebelum diisi.
- Commit terakhir pada branch: `06fe4ed docs: add project handover for phase 9`.
- `master` sudah berisi merge Fase 8: `c0d83cf merge: complete fase 8 dashboard and reports`.
- Tag fase terakhir: `fase-8-complete`.
- Fase aktif: Fase 9, yaitu Next.js frontend web.

Tag fase yang tersedia:

```text
fase-1-complete
fase-2-complete
fase-3-complete
fase-4-complete
fase-5-clean
fase-5-complete
fase-6-complete
fase-7-complete
fase-8-complete
phase-1A-complete
```

## 14. Arah Visual

Arah visual EMI untuk Fase 9:

- Bahasa UI dominan Indonesia.
- Nama produk: EMI — Elearning Mekongga Indonesia.
- Gaya Neo-Brutalism / Pop-Edutech.
- Latar utama putih.
- Warna utama biru, kuning, dan orange hangat.
- Border gelap tebal.
- Drop shadow tebal.
- Motif geometris lembut.
- Responsive untuk desktop dan mobile.
- Konsisten untuk Admin, Guru, dan Siswa.
- Gunakan reusable components.
- Gunakan design tokens.
- Figma menjadi referensi visual utama.

Link Figma tidak dicantumkan di repository ini, jadi jangan mengarang URL Figma.

## 15. Scope Fase 9

Fase 9 berfokus pada frontend web Next.js.

Target:

- Membuat folder `Emi-Frontend`.
- Setup Next.js App Router.
- TypeScript.
- Tailwind CSS.
- ESLint.
- Struktur `src`.
- Environment configuration.
- API client.
- Authentication frontend.
- Protected route.
- Role-based layout.
- Reusable components.
- Admin UI.
- Guru UI.
- Siswa UI.
- Integrasi API Fase 1-8.
- Loading state.
- Empty state.
- Error state.
- Responsive layout.
- Accessibility dasar.
- Kesesuaian dengan Figma.

Backend Laravel tetap menjadi source of truth. Frontend hanya mengonsumsi API, menampilkan state, dan mengelola UX. Jangan membuat mock API permanen sebagai pengganti backend.

## 16. Fitur yang Belum Dikerjakan

Fitur berikut belum selesai pada repository aktual:

- Flutter Android.
- Offline synchronization.
- SQLite mobile cache.
- FastAPI voice engine.
- Speaking assessment.
- AI chatbot/RAG.
- Knowledge base chatbot lengkap.
- ESP32.
- Deployment production penuh.

Speaking report belum tersedia. Bila dashboard mengembalikan capability speaking, nilainya masih `false` dan `speaking_summary` masih `null`.

## 17. Aturan Pengerjaan Codex

- Baca `AGENTS.md` terlebih dahulu.
- Audit repository sebelum edit.
- Kerjakan hanya fase yang disebut eksplisit.
- Jangan mengarang endpoint, file, fitur, atau hasil test.
- Gunakan `Docs/03-API-Specification.md` dan `routes/api.php`.
- Jangan membuat backend kedua di frontend.
- Jangan mengubah backend tanpa kebutuhan jelas dan instruksi fase.
- Jangan melampaui scope fase.
- Jangan menonaktifkan test atau security.
- Jangan menyimpan credential, token, password, atau isi `.env`.
- Jangan membuat mock API permanen sebagai pengganti backend.
- Jangan commit, merge, push, tag, atau pindah branch tanpa instruksi.
- Jalankan lint, build, dan test yang relevan setelah perubahan.

## 18. Checklist Onboarding

1. Buka root repository `D:\!Kerjaan\EMI`.
2. Baca `AGENTS.md`.
3. Baca `Docs/05-Project-Handover.md`.
4. Baca dokumen teknis lain di `Docs`.
5. Periksa branch dan Git status.
6. Periksa Git history dan tags.
7. Jalankan backend test.
8. Jalankan Composer audit.
9. Periksa API routes.
10. Pahami fase aktif dan batas scope.
11. Periksa referensi Figma dari sumber yang diberikan user/client.
12. Baru mulai mengubah kode.

## 19. Perintah Penting

Perintah Git aman:

```bash
git branch --show-current
git status
git log --oneline --graph --decorate -15
git tag
```

Perintah backend:

```bash
cd Emi-Backend
php artisan test
composer audit
php artisan route:list --path=api/v1
```

Perintah berikut menghapus data database development/testing yang ditargetkan konfigurasi aktif. Jangan jalankan sebagai onboarding rutin tanpa memahami konsekuensinya:

```bash
php artisan migrate:fresh --seed
```

## 20. Kesiapan Fase 9

Checklist kesiapan:

- Fase 1-8 selesai.
- Backend lulus test: 75 tests passed, 740 assertions.
- Composer audit bersih.
- API route tersedia: 145 route API v1.
- Fase 8 sudah masuk `master`.
- Branch `feature/nextjs-web` aktif.
- `Docs/05-Project-Handover.md` sudah tersedia sebagai dokumen onboarding.
- Folder `Emi-Frontend` belum dibuat.
- Codex akun baru atau pengembang baru harus onboarding terlebih dahulu.
- Figma menjadi referensi visual utama saat Fase 9 dimulai.
