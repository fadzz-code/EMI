# Roadmap Mobile Flutter EMI

## Keputusan Scope

Mobile EMI dibuat dengan Flutter dan memakai Laravel API yang sudah ada. Tidak ada backend baru. Prioritas realistis adalah Siswa dulu, lalu fitur AI/media, lalu Guru ringan. Admin penuh tetap web-first karena kompleks dan lebih aman dikelola lewat dashboard web.

Prioritas:

- P0: wajib untuk MVP awal.
- P1: penting setelah MVP stabil.
- P2: tambahan/opsional.

Kompleksitas:

- Small: 1-3 hari kerja efektif.
- Medium: beberapa hari sampai 1 minggu.
- Large: lebih dari 1 minggu atau butuh QA intensif.

## Fase 0 — Audit dan Keputusan Scope

| Item | Prioritas | Kompleksitas | Output |
|---|---|---|---|
| Audit API backend dari route/controller/resource/request | P0 | Medium | Matriks API final. |
| Tentukan role MVP | P0 | Small | Siswa sebagai MVP pertama. |
| Tentukan target Android | P0 | Small | Target Android minimum dan perangkat uji fisik. |
| Tentukan package Flutter | P0 | Small | Dio, Riverpod, go_router, flutter_secure_storage, just_audio. |
| Tentukan arsitektur folder | P0 | Small | Struktur `lib/app`, `lib/core`, `lib/shared`, `lib/features`. |
| Tentukan strategi media public/private | P0 | Medium | Public URL dan temporary URL via Laravel. |
| Tentukan strategi speaking audio | P1 | Medium | Format rekaman yang cocok dengan backend. |

## Fase 1 — Foundation Flutter

| Item | Prioritas | Kompleksitas | Catatan |
|---|---|---|---|
| Inisialisasi project Flutter | P0 | Small | Jangan dilakukan sebelum fase dokumen disetujui. |
| Environment dev/staging/production | P0 | Small | API base URL per environment. |
| Dio client | P0 | Medium | Base URL `/api/v1`, timeout, interceptor auth. |
| Secure token storage | P0 | Small | `flutter_secure_storage`. |
| Error handling | P0 | Medium | 401, 403, 404, 422, 429, 500, timeout. |
| Theme EMI | P0 | Medium | Warna, typography, button, card, empty/error state. |
| Routing dan role guard | P0 | Medium | Splash, login, dashboard role. |
| Model response API umum | P0 | Medium | `success`, `message`, `data`, `meta`, `errors`. |
| Logging aman | P0 | Small | Jangan log token/file path sensitif. |

## Fase 2 — Authentication

| Item | Prioritas | Kompleksitas | Endpoint |
|---|---|---|---|
| Splash | P0 | Small | Baca token lokal dan panggil `/auth/me`. |
| Login | P0 | Medium | `POST /api/v1/auth/login`. |
| Session persistence | P0 | Medium | Simpan token aman dan refresh state dari `/auth/me`. |
| Logout | P0 | Small | `POST /api/v1/auth/logout`, hapus token lokal. |
| Profile dasar | P0 | Small | `GET /api/v1/auth/me`. |
| Update profil dasar | P1 | Small | `PATCH /api/v1/auth/me`. |
| Register siswa/guru | P2 | Medium | `POST /api/v1/auth/register`, public school/class lookup. |
| Avatar | P2 | Medium | `/auth/me/avatar`, upload/delete. |

## Fase 3 — Mobile Siswa MVP

| Item | Prioritas | Kompleksitas | Endpoint utama | Catatan |
|---|---|---|---|---|
| Dashboard | P0 | Medium | `GET /student/dashboard/summary` | Screen utama siswa. |
| Modul list | P0 | Medium | `GET /student/modules` | Search/filter sederhana. |
| Detail modul | P0 | Medium | `GET /student/modules/{id}` | Tampilkan lessons dan progress. |
| Start modul | P0 | Small | `POST /student/modules/{id}/start` | Trigger saat mulai. |
| Lesson detail | P0 | Medium | `GET /class-lessons/{id}` | Endpoint shared/scoped. |
| Lesson content/media | P0 | Medium | `GET /class-lessons/{id}/content-url` | Perlu handler media. |
| Complete lesson | P0 | Small | `PATCH /student/lessons/{id}/progress` | Kirim completed/100. |
| Kamus list | P0 | Medium | `GET /dictionary` | Search kata. |
| Detail kamus | P0 | Small | `GET /dictionary/{id}` | Audio jika ada. |
| Audio kamus | P0 | Medium | Public/private media URL | Uji `just_audio`. |
| Kuis list | P0 | Medium | `GET /student/quizzes` | Status jadwal/attempt. |
| Detail kuis | P0 | Medium | `GET /student/quizzes/{id}` | Instruksi dan limit. |
| Mulai attempt | P0 | Medium | `POST /class-quizzes/{id}/attempts` | Simpan attempt id. |
| Attempt kuis | P0 | Large | `GET /quiz-attempts/{id}` | Navigasi soal. |
| Simpan jawaban | P0 | Medium | `PUT /quiz-attempts/{id}/answers/{question_id}` | Autosave/next. |
| Submit kuis | P0 | Medium | `POST /quiz-attempts/{id}/submit` | Dialog konfirmasi. |
| Hasil kuis | P0 | Medium | `GET /quiz-attempts/{id}` | Hormati `show_result`. |
| Progress | P0 | Medium | `GET /student/reports/progress`, `/student/reports/quiz-results` | Ringkasan belajar. |
| Profil | P0 | Small | `GET/PATCH /auth/me` | Data dasar siswa. |

Definition of Done Fase 3:

- Siswa bisa login.
- Dashboard muncul.
- Modul bisa dibuka sampai lesson selesai.
- Kamus bisa search dan detail.
- Kuis bisa dikerjakan sampai hasil.
- Progress berubah setelah lesson/kuis.
- Profil bisa dibuka.
- Token aman dan logout bekerja.

## Fase 4 — Fitur AI dan Media Siswa

| Item | Prioritas | Kompleksitas | Endpoint utama | Catatan |
|---|---|---|---|---|
| Chatbot | P1 | Medium | `POST /student/chatbot/messages` | Tampilkan jawaban dan sumber. |
| Budaya Mekongga | P1 | Medium | `GET /student/culture` | Handler link, image, PDF, audio. |
| Speaking exercise list | P1 | Medium | `GET /student/speaking/exercises` | Belum paginated. |
| Detail speaking | P1 | Small | `GET /student/speaking/exercises/{exercise}` | Target text + reference audio. |
| Audio reference | P1 | Medium | Media URL dari resource | `just_audio`, temporary URL jika private. |
| Rekaman audio | P1 | Large | Package `record` atau setara | Permission mikrofon wajib. |
| Upload speaking | P1 | Large | `POST /student/speaking/exercises/{exercise}/attempts` | multipart/form-data `file`. |
| Polling/status analisis | P1 | Medium | `GET /student/speaking/attempts/{attempt}` | Poll sampai completed/failed. |
| Hasil speaking | P1 | Medium | `GET /student/speaking/attempts`, `/{attempt}` | Skor AI + feedback guru. |
| Failed/timeout state | P1 | Medium | Attempt status | UX retry/ulang latihan. |

Definition of Done Fase 4:

- Chatbot bisa tanya jawab.
- Budaya bisa tampil dengan media dasar.
- Speaking bisa rekam di HP fisik.
- Upload diterima backend tanpa error MIME.
- Status AI tampil sampai selesai/gagal.
- Feedback guru bisa dibaca siswa.

## Fase 5 — Mobile Guru

Rekomendasi: Guru mobile dibuat versi ringan dulu. Fokus monitoring dan review, bukan builder penuh.

| Item | Prioritas | Kompleksitas | Endpoint utama | Catatan |
|---|---|---|---|---|
| Dashboard guru | P1 | Medium | `GET /teacher/dashboard/summary` | Ringkasan. |
| Kelas | P1 | Medium | `GET /classes` | Scoped guru. |
| Detail kelas | P1 | Small | `GET /classes/{id}` | Info kelas. |
| Siswa kelas | P1 | Medium | `GET /classes/{id}/students` | List siswa. |
| Detail siswa/progress | P1 | Medium | `GET /teacher/reports/progress/students?student_id={id}` | Tidak ada endpoint detail dedicated. |
| Progress | P1 | Medium | `GET /teacher/reports/progress/students` | Monitoring. |
| Hasil kuis | P1 | Medium | `GET /class-quizzes/{id}/attempts`, `/class-quizzes/{id}/report` | Review hasil. |
| Speaking review | P1 | Large | `GET /teacher/speaking/attempts`, `/{attempt}` | Audio private perlu temporary URL. |
| Feedback speaking | P1 | Medium | `PATCH /teacher/speaking/attempts/{attempt}/feedback` | Cocok mobile. |
| Target speaking | P2 | Medium | `/teacher/speaking/templates`, `/teacher/speaking/exercises` | Bisa create dari template. |
| Modul | P2 | Large | `/classes/{id}/modules`, `/class-modules/{id}` | Editor mobile berat. |
| Lesson | P2 | Large | `/class-lessons/{id}` | Editor mobile berat. |
| Kuis builder | P2 | Large | `/class-quizzes`, `/quiz-questions` | Sebaiknya web-first. |

Definition of Done Fase 5:

- Guru bisa lihat dashboard, kelas, siswa, progress.
- Guru bisa review hasil kuis.
- Guru bisa review speaking dan memberi feedback.
- Builder modul/kuis tetap web-first kecuali diminta khusus.

## Fase 6 — Admin Mobile atau Web-first

Keputusan audit: Admin penuh tidak wajib masuk MVP mobile. Admin lebih cocok web-first karena banyak form panjang, tabel, import CSV/ZIP, builder modul/kuis, pengaturan sistem, dan aksi berisiko.

| Opsi | Prioritas | Kompleksitas | Keputusan |
|---|---|---|---|
| Admin dashboard ringkas | P2 | Medium | Bisa dibuat jika client butuh monitoring cepat. |
| Approval akun ringan | P2 | Medium | Layak mobile karena flow terbatas. |
| User management read-only | P2 | Medium | Opsional. |
| Progress report read-only | P2 | Medium | Opsional. |
| Settings production | P2 | Large | Tetap web-first. |
| Dictionary import CSV/ZIP | P2 | Large | Tetap web-first. |
| Basis AI/PDF import | P2 | Large | Tetap web-first. |
| Module/quiz builder | P2 | Large | Tetap web-first. |
| Culture template management | P2 | Large | Tetap web-first. |

Rekomendasi:

- MVP tidak memasukkan Admin.
- Jika wajib ada Admin mobile, batasi ke dashboard, approval akun, dan laporan read-only.
- Semua operasi destruktif/kompleks tetap di web.

## Fase 7 — QA dan Release

| Item | Prioritas | Kompleksitas | Catatan |
|---|---|---|---|
| Testing Android fisik | P0 | Medium | Minimal 2 perangkat Android berbeda. |
| Permission mikrofon | P1 | Medium | Wajib untuk speaking. |
| Permission file/media | P1 | Medium | Untuk upload/avatar/content jika dipakai. |
| Jaringan lambat | P0 | Medium | Timeout, retry, loading state. |
| Upload gagal | P1 | Medium | Audio/media retry dan pesan error. |
| Token kedaluwarsa/invalid | P0 | Medium | Auto logout dan arahkan login. |
| 403 role guard | P0 | Small | User bukan role MVP diberi pesan jelas. |
| Empty state siswa tanpa kelas | P0 | Small | Jangan crash. |
| Data besar/pagination | P1 | Medium | List modul, kamus, kuis, reports. |
| Build APK | P0 | Medium | Preview internal. |
| Build AAB | P1 | Medium | Untuk release store/internal. |
| Release internal | P1 | Medium | Distribusi terbatas sebelum publik. |

## Urutan Implementasi Disarankan

1. Fase 0 disetujui.
2. Fase 1 foundation.
3. Fase 2 authentication.
4. Fase 3 siswa MVP.
5. QA Android untuk Fase 3.
6. Fase 4 AI/media siswa.
7. QA speaking di HP fisik.
8. Build APK preview.
9. Fase 5 guru ringan bila dibutuhkan.
10. Fase 6 admin hanya jika client minta dan scope dibatasi.
11. Build AAB/release internal.

## Risiko Utama

- Speaking audio Flutter bisa beda MIME dari browser; wajib uji perangkat fisik.
- Temporary URL private media bisa gagal jika signed URL atau network domain tidak sesuai.
- Beberapa list belum paginated, terutama speaking; bisa jadi masalah saat data besar.
- Admin/guru builder kompleks bisa membuat scope mobile membengkak.
- Native app tidak kena CORS seperti web, tetapi tetap perlu HTTPS production stabil.

## Rekomendasi MVP Final

MVP Mobile Flutter EMI:

- Role: Siswa saja.
- Platform awal: Android.
- Fitur P0: Login, dashboard, modul/lesson, kamus/audio, kuis/attempt/result, progress, profil.
- Fitur P1: Chatbot, budaya, speaking.
- Guru/Admin: ditunda; web tetap kanal utama.
