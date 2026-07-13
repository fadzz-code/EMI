# Mobile API Coverage EMI

Sumber verifikasi:

- `Emi-Backend/routes/api.php`
- `Emi-Backend/app/Http/Controllers/Api`
- `Emi-Backend/app/Http/Resources`
- `Emi-Backend/app/Http/Requests`
- `Emi-Frontend/src/features/*/*service.ts`
- `Docs/audit/role-url-action-audit.md`
- `Docs/audit/feature-matrix.md`
- `Docs/current-project-handover.md`
- `Docs/mobile/mobile-development-plan.md`

Status:

- Ready: endpoint tersedia dan cukup langsung dipakai mobile.
- Ready with adjustment: endpoint tersedia, tetapi mobile perlu penyesuaian UI/client atau verifikasi response/media.
- Missing: endpoint tidak ditemukan di backend saat audit.
- Web-only: tersedia, tetapi lebih cocok tetap di web.
- Needs manual verification: tersedia/terindikasi, tetapi perlu uji manual atau cek data nyata sebelum final.

## Ringkasan Kesiapan

- Ready: 44 fitur/flow.
- Ready with adjustment: 21 fitur/flow.
- Missing: 3 fitur/flow.
- Web-only: 9 fitur/flow.
- Needs manual verification: 12 fitur/flow.

## Catatan Umum API

- Response JSON umum konsisten melalui `ApiResponse`: `success`, `message`, `data`, `meta`, `code`, `errors`.
- Validasi request berbasis Form Request umumnya mengembalikan 422 dengan `errors`.
- Pagination tersedia pada banyak list endpoint melalui `meta`, tetapi belum semua endpoint list memakai paginator.
- Upload file memakai multipart/form-data dengan field `file`.
- Media public dan private tersedia lewat endpoint backend.
- Native Flutter tidak bergantung pada CORS, tetapi tetap butuh HTTPS, Bearer token, dan signed URL valid.
- Tidak ditemukan ketergantungan langsung pada tampilan Next.js di kontrak API; Next.js hanya menjadi referensi pemakaian endpoint.

## Matriks API Shared

| Role | Fitur | Flow di web | Endpoint/API yang digunakan | Method | Auth diperlukan | Upload/media | Pagination/filter | Status kesiapan mobile | Gap | Rekomendasi |
|---|---|---|---|---|---|---|---|---|---|---|
| Shared | Login | Login form memanggil auth service | `/api/v1/auth/login` | POST | Tidak | Tidak | Tidak | Ready | Butuh `device_name`; token Sanctum dikembalikan | Pakai Dio + secure storage; kirim device name seperti `emi-flutter-android`. |
| Shared | Logout | Auth provider logout | `/api/v1/auth/logout` | POST | Ya | Tidak | Tidak | Ready | Tidak ada | Panggil API lalu hapus token lokal walau API gagal. |
| Shared | User profile/current user | Session restore dan role guard | `/api/v1/auth/me` | GET | Ya | Avatar metadata mungkin ada | Tidak | Ready | Tidak ada | Pakai saat splash/session check. |
| Shared | Update profile | Profile role siswa/guru/admin | `/api/v1/auth/me` | PATCH | Ya | Tidak | Tidak | Ready | Field terbatas oleh request | Pakai untuk profil dasar siswa/guru. |
| Shared | Change password | Admin settings web | `/api/v1/auth/password` | PUT | Ya | Tidak | Tidak | Ready with adjustment | Belum prioritas mobile | Tunda dari MVP siswa. |
| Shared | Avatar upload | Auth/me avatar | `/api/v1/auth/me/avatar` | POST | Ya | multipart/form-data | Tidak | Ready with adjustment | Perlu UI picker dan batas ukuran | Tunda sampai profil mobile matang. |
| Shared | Avatar delete | Auth/me avatar | `/api/v1/auth/me/avatar` | DELETE | Ya | Media | Tidak | Ready with adjustment | Perlu konfirmasi UI | Tunda dari MVP awal. |
| Shared | Register siswa/guru | Register web | `/api/v1/auth/register` | POST | Tidak | Tidak | Public school/class lookup | Ready with adjustment | Akun tetap pending approval | Tunda jika MVP hanya akun demo/login. |
| Shared | Public schools | Register web | `/api/v1/public/schools` | GET | Tidak | Tidak | Pagination/search tersedia | Ready | Tidak ada | Pakai jika register masuk mobile. |
| Shared | Public classes | Register web | `/api/v1/public/schools/{school_id}/classes` | GET | Tidak | Tidak | Pagination/search tersedia | Ready | Tidak ada | Pakai jika register masuk mobile. |
| Shared | Banner/login branding | Login/settings web | `/api/v1/public/login-branding` | GET | Tidak | Media banner public | Tidak | Ready | Tidak ada | Pakai untuk branding login mobile opsional. |
| Shared | Media public | Media preview | `/api/v1/public/media/{id}/content` | GET | Tidak | Stream file | Tidak | Ready with adjustment | Flutter perlu handle stream/URL | Gunakan untuk image/audio public. |
| Shared | Media detail | Media service web | `/api/v1/media/{id}` | GET | Ya | Media metadata | Tidak | Ready | Policy berlaku | Pakai jika perlu metadata. |
| Shared | Temporary media URL | Audio/private preview | `/api/v1/media/{id}/temporary-url` | POST | Ya | Signed URL | Tidak | Ready with adjustment | Perlu uji playback native | Pakai untuk private audio/lesson/speaking. |
| Shared | Generic media upload | Guru/admin content | `/api/v1/media` | POST | Ya | multipart/form-data | Tidak | Ready with adjustment | Perlu purpose/visibility valid | Pakai hanya untuk guru/admin atau avatar/content. |

## Matriks API Siswa

| Role | Fitur | Flow di web | Endpoint/API yang digunakan | Method | Auth diperlukan | Upload/media | Pagination/filter | Status kesiapan mobile | Gap | Rekomendasi |
|---|---|---|---|---|---|---|---|---|---|---|
| Siswa | Dashboard | `/student/dashboard` | `/api/v1/student/dashboard/summary` | GET | Student | Tidak | Filter period/scope tidak utama | Ready | Tidak ada | P0 mobile screen setelah login. |
| Siswa | Modul | List modul siswa | `/api/v1/student/modules` | GET | Student | Media dari resource | `search`, `status`, `per_page`, sort dipakai web | Ready | Tidak ada | P0 MVP. |
| Siswa | Detail modul | Detail modul + lessons | `/api/v1/student/modules/{id}` | GET | Student | Lessons/media metadata | Tidak | Ready | Tidak ada | P0 MVP. |
| Siswa | Start modul | Mulai modul | `/api/v1/student/modules/{id}/start` | POST | Student | Tidak | Tidak | Ready | Tidak ada | Jalankan saat user tekan mulai. |
| Siswa | Lesson detail | Baca lesson | `/api/v1/class-lessons/{id}` | GET | Auth + scoped | Media metadata | Tidak | Ready with adjustment | Endpoint shared, bukan `/student/lessons/{id}` | Pakai persis route backend dan cek 403 untuk lesson luar kelas. |
| Siswa | Lesson content URL | Buka konten/media lesson | `/api/v1/class-lessons/{id}/content-url` | GET | Auth + scoped | URL media/content | Tidak | Ready with adjustment | Private/public media perlu uji di HP | Pakai just_audio/webview/file launcher sesuai tipe media. |
| Siswa | Penyelesaian lesson | Tandai selesai | `/api/v1/student/lessons/{id}/progress` | PATCH | Student | Tidak | Tidak | Ready | Tidak ada | Kirim status/progress_percent. |
| Siswa | Progress modul | List progress modul | `/api/v1/student/progress/modules` | GET | Student | Tidak | Tidak jelas | Ready with adjustment | Perlu cek response untuk UI mobile | Pakai untuk sinkronisasi progress kecil. |
| Siswa | Kamus | Search/list kamus | `/api/v1/dictionary` | GET | Auth | Audio metadata | Pagination/search/filter tersedia | Ready | Tidak ada | P0 MVP. |
| Siswa | Detail kamus | Detail kata | `/api/v1/dictionary/{id}` | GET | Auth | Audio/media metadata | Tidak | Ready | Tidak ada | P0 MVP. |
| Siswa | Audio kamus | Putar audio dari media kamus | `/api/v1/public/media/{id}/content` atau media URL dari resource | GET | Tergantung media | Stream audio | Tidak | Ready with adjustment | Perlu verifikasi field URL dari `DictionaryEntryResource` | Uji just_audio untuk public/private audio. |
| Siswa | Daftar kuis | List kuis siswa | `/api/v1/student/quizzes` | GET | Student | Media pertanyaan via detail/attempt | Pagination/filter tersedia dari request | Ready | Tidak ada | P0 MVP. |
| Siswa | Detail kuis | Lihat instruksi kuis | `/api/v1/student/quizzes/{id}` | GET | Student | Mungkin media soal saat attempt | Tidak | Ready | Tidak ada | P0 MVP. |
| Siswa | Mulai attempt | Start quiz attempt | `/api/v1/class-quizzes/{id}/attempts` | POST | Student | Tidak | Tidak | Ready | Path shared | Bungkus di service `studentQuiz.startAttempt`. |
| Siswa | Ambil attempt | Mengerjakan/hasil attempt | `/api/v1/quiz-attempts/{id}` | GET | Auth + scoped | Media pertanyaan jika ada | Tidak | Ready | Tidak ada | Pakai untuk attempt dan result. |
| Siswa | Simpan jawaban | Pilih jawaban | `/api/v1/quiz-attempts/{id}/answers/{question_id}` | PUT | Student | Tidak | Tidak | Ready | Tidak ada | Autosave per soal atau saat next. |
| Siswa | Submit kuis | Kirim final | `/api/v1/quiz-attempts/{id}/submit` | POST | Student | Tidak | Tidak | Ready | Tidak ada | Tambah dialog konfirmasi. |
| Siswa | Hasil kuis | Result page/report | `/api/v1/quiz-attempts/{id}`, `/api/v1/student/reports/quiz-results` | GET | Student/Auth scoped | Tidak | Report paginated/filter | Ready | Dua sumber data | Pakai attempt detail untuk hasil langsung, report untuk riwayat. |
| Siswa | Speaking exercise | List target speaking | `/api/v1/student/speaking/exercises` | GET | Student | Reference audio metadata | Tidak ada pagination | Ready with adjustment | List memakai `get()`, bukan paginator | OK untuk awal; tambah pagination jika data besar. |
| Siswa | Detail speaking | Target detail | `/api/v1/student/speaking/exercises/{exercise}` | GET | Student | Reference audio metadata | Tidak | Ready | Tidak ada | P1 setelah MVP siswa stabil. |
| Siswa | Upload/rekam speaking | Rekam lalu submit | `/api/v1/student/speaking/exercises/{exercise}/attempts` | POST | Student | multipart/form-data `file` | Tidak | Ready with adjustment | Format audio Flutter perlu uji MIME/extension | P1; uji Android real device. |
| Siswa | Status analisis speaking | Polling attempt detail | `/api/v1/student/speaking/attempts/{attempt}` | GET | Student | Recording/reference metadata | Tidak | Ready with adjustment | Tidak ada endpoint khusus polling; pakai detail | Poll tiap 3-5 detik sampai completed/failed. |
| Siswa | Hasil speaking | List/detail hasil | `/api/v1/student/speaking/attempts`, `/api/v1/student/speaking/attempts/{attempt}` | GET | Student | Private recording media | Tidak ada pagination | Ready with adjustment | List memakai `get()`, perlu pagination jika banyak | P1; tampilkan failed state. |
| Siswa | Chatbot | Kirim pertanyaan | `/api/v1/student/chatbot/messages` | POST | Student | Tidak | Tidak | Ready | Audit lama menyebut `/message`, route benar `/messages` | P1/P0 tergantung demo mobile. |
| Siswa | Budaya Mekongga | Feed budaya | `/api/v1/student/culture` | GET | Student | Media/link/content | `class_id`, `per_page` dipakai web | Ready with adjustment | Tipe media perlu UI handler | P1 MVP tambahan. |
| Siswa | Progress | Laporan progress | `/api/v1/student/reports/progress`, `/api/v1/student/reports/quiz-results` | GET | Student | Tidak | Report filters tersedia via request | Ready | Tidak ada | P0 MVP. |
| Siswa | Profil | Profil/update | `/api/v1/auth/me` | GET/PATCH | Auth | Avatar opsional | Tidak | Ready | Tidak ada | P0 MVP. |

## Matriks API Guru

| Role | Fitur | Flow di web | Endpoint/API yang digunakan | Method | Auth diperlukan | Upload/media | Pagination/filter | Status kesiapan mobile | Gap | Rekomendasi |
|---|---|---|---|---|---|---|---|---|---|---|
| Guru | Dashboard | `/teacher/dashboard` | `/api/v1/teacher/dashboard/summary` | GET | Teacher | Tidak | Tidak utama | Ready | Tidak ada | P1 setelah siswa MVP. |
| Guru | Kelas | List kelas guru | `/api/v1/classes` | GET | Auth + scoped | Tidak | `per_page`, sort/search | Ready | Shared endpoint scoped by role | Aman dipakai dengan role guard guru. |
| Guru | Detail kelas | Detail kelas | `/api/v1/classes/{id}` | GET | Auth + scoped | Tidak | Tidak | Ready | Tidak ada | P1. |
| Guru | Daftar siswa | Siswa per kelas | `/api/v1/classes/{id}/students` | GET | Auth + scoped | Tidak | Pagination/filter request ada | Ready with adjustment | Perlu uji pagination mobile | P1. |
| Guru | Detail siswa | Web pakai report filter | `/api/v1/teacher/reports/progress/students?student_id={id}` | GET | Teacher | Tidak | Filter student_id | Ready with adjustment | Tidak ada endpoint detail siswa dedicated | Pakai report filter atau rekomendasikan endpoint detail jika perlu. |
| Guru | Modul | List/CRUD module kelas | `/api/v1/classes/{class_id}/modules`, `/api/v1/class-modules/{id}` | GET/POST/PUT/DELETE | Auth + scoped | Media via lesson | Pagination/sort | Ready with adjustment | CRUD berat untuk mobile | Masukkan P1/P2, bukan siswa MVP. |
| Guru | Publish/archive modul | Publish/archive module | `/api/v1/class-modules/{id}/publish`, `/api/v1/class-modules/{id}/archive` | POST | Auth + scoped | Tidak | Tidak | Ready | Tidak ada | P2 mobile guru. |
| Guru | Lesson | Detail/update lesson | `/api/v1/class-lessons/{id}` | GET/PUT/DELETE | Auth + scoped | Media | Tidak | Ready with adjustment | Editor lesson mobile kompleks | Web-first atau P2. |
| Guru | Publish/archive lesson | Publish/archive lesson | `/api/v1/class-lessons/{id}/publish`, `/api/v1/class-lessons/{id}/archive` | POST | Auth + scoped | Tidak | Tidak | Ready | Tidak ada | P2. |
| Guru | Kuis | List/CRUD kuis kelas | `/api/v1/class-quizzes`, `/api/v1/class-quizzes/{id}` | GET/POST/PUT/DELETE | Auth + scoped | Media soal via `/media` | Pagination/filter | Ready with adjustment | Builder kompleks | P2 atau tablet-first. |
| Guru | Builder kuis | Soal/options | `/api/v1/class-quizzes/{class_quiz_id}/questions`, `/api/v1/quiz-questions/{id}` | GET/POST/PUT/DELETE | Auth + scoped | Question image via media | List no paginator | Ready with adjustment | UI mobile rumit | Web-first untuk MVP. |
| Guru | Hasil kuis | Attempts/report | `/api/v1/class-quizzes/{id}/attempts`, `/api/v1/class-quizzes/{id}/report`, `/api/v1/teacher/reports/quiz-results` | GET | Auth/Teacher scoped | Tidak | Pagination/filter | Ready | Tidak ada | P1 guru mobile. |
| Guru | Target speaking | CRUD target kelas | `/api/v1/teacher/speaking/exercises`, `/api/v1/teacher/speaking/exercises/{exercise}` | GET/POST/PUT/PATCH | Teacher | Reference audio copied dari template | Pagination/filter | Ready with adjustment | Upload reference audio guru tidak langsung; template-based | P1 guru mobile ringan. |
| Guru | Template speaking admin | Pilih template | `/api/v1/teacher/speaking/templates` | GET | Teacher | Reference audio metadata | Pagination | Ready | Tidak ada | P1. |
| Guru | Hasil speaking siswa | Review list/detail | `/api/v1/teacher/speaking/attempts`, `/api/v1/teacher/speaking/attempts/{attempt}` | GET | Teacher | Private audio | List no pagination | Ready with adjustment | List bisa besar; private audio perlu temporary URL | P1; tambah pagination jika data besar. |
| Guru | Feedback speaking | Simpan feedback | `/api/v1/teacher/speaking/attempts/{attempt}/feedback` | PATCH | Teacher | Tidak | Tidak | Ready | Tidak ada | P1. |
| Guru | Progress | Progress siswa | `/api/v1/teacher/reports/progress/students` | GET | Teacher | Tidak | Pagination/filter | Ready | Tidak ada | P1. |
| Guru | Export reports | CSV export | `/api/v1/teacher/reports/progress/students/export`, `/api/v1/teacher/reports/quiz-results/export` | GET | Teacher | Download file | Filter | Web-only | Kurang cocok mobile MVP | Tetap web. |
| Guru | Profil | Profile/update | `/api/v1/auth/me` | GET/PATCH | Auth | Avatar opsional | Tidak | Ready | Tidak ada | P1. |
| Guru | Budaya kelas | CRUD budaya | `/api/v1/classes/{class_id}/culture`, `/api/v1/class-culture-items/{id}` | GET/POST/PUT/DELETE | Auth + scoped | Media via `/media` | Pagination/sort | Ready with adjustment | Editor media mobile perlu uji | P2. |
| Guru | Media upload | Upload file konten | `/api/v1/media` | POST | Auth | multipart/form-data | Tidak | Ready with adjustment | Purpose/visibility wajib benar | P2. |

## Matriks API Admin

Rekomendasi umum: Admin penuh tetap web-first untuk MVP mobile. Hampir semua endpoint tersedia, tetapi operasi Admin kompleks, berisiko pada layar kecil, dan membutuhkan tabel/form panjang, upload/import, serta aksi destruktif.

| Role | Fitur | Flow di web | Endpoint/API yang digunakan | Method | Auth diperlukan | Upload/media | Pagination/filter | Status kesiapan mobile | Gap | Rekomendasi |
|---|---|---|---|---|---|---|---|---|---|---|
| Admin | Dashboard | `/admin/dashboard` | `/api/v1/admin/dashboard/summary` | GET | Admin | Tidak | Period/scope | Ready | Detail kartu perlu uji | Bisa P2 ringkasan mobile saja. |
| Admin | Persetujuan akun | Approvals list/detail | `/api/v1/admin/registration-requests`, `/{id}`, `/{id}/approve`, `/{id}/reject` | GET/POST | Admin | Tidak | Pagination/filter/search | Ready | Perlu confirm UX | Layak mobile ringan P2. |
| Admin | Sekolah dan kelas | CRUD sekolah/kelas | `/api/v1/schools`, `/api/v1/classes` | GET/POST/PUT/DELETE | Auth + scoped | Tidak | Pagination/filter | Ready with adjustment | Shared scoped endpoint; form panjang | Web-first. |
| Admin | Assignment guru/siswa | Detail kelas assignment | `/api/v1/classes/{id}/assign-teacher`, `/api/v1/classes/{id}/assign-student`, `/api/v1/classes/{id}/students` | POST/GET | Auth + scoped | Tidak | Student list paginated | Ready with adjustment | Konflik assignment butuh UX hati-hati | Web-first. |
| Admin | Guru dan siswa | User management | `/api/v1/users`, `/api/v1/users/{id}`, `/api/v1/users/{id}/status` | GET/PUT/PATCH | Auth + scoped | Tidak | Pagination/filter/search | Ready | Safety rules perlu uji | Web-first; mobile read-only opsional. |
| Admin | Kamus categories | CRUD kategori | `/api/v1/admin/dictionary/categories`, `/{id}` | GET/POST/PUT/DELETE | Admin | Tidak | Pagination/filter | Ready | Tidak ada | Web-first, mobile opsional. |
| Admin | Kamus entries | CRUD entri | `/api/v1/admin/dictionary/entries`, `/{id}` | GET/POST/PUT/DELETE | Admin | Audio media via `/media` | Pagination/filter/search | Ready with adjustment | Upload audio mobile perlu picker | Web-first. |
| Admin | Import kamus | CSV/ZIP import | `/api/v1/admin/dictionary/imports/{import_type}/template`, `/preview`, `/imports`, `/{id}`, `/{id}/errors`, `/{id}/confirm` | GET/POST | Admin | CSV/ZIP multipart | Pagination | Web-only | File import kompleks, ZIP, preview | Tetap web. |
| Admin | Basis AI | Knowledge CRUD | `/api/v1/admin/ai/knowledge`, `/{id}`, publish/archive | GET/POST/PUT/DELETE | Admin | PDF upload/extract endpoints | Pagination/filter | Ready with adjustment | Editor konten panjang | Web-first. |
| Admin | PDF/link extraction | Extract/import knowledge | `/api/v1/admin/ai/knowledge/extract-source`, `/extract-pdf-upload`, `/import-pdf` | POST | Admin | PDF multipart/URL | Tidak | Web-only | Operasi berat dan butuh review konten | Tetap web. |
| Admin | Modul templates | Template CRUD/apply | `/api/v1/admin/module-templates`, `/{id}`, publish/archive/apply | GET/POST/PUT/DELETE | Admin | Lesson media | Pagination/filter | Ready with adjustment | Editor modul/lesson kompleks | Web-first. |
| Admin | Lesson templates | Lesson template CRUD | `/api/v1/admin/module-templates/{id}/lessons`, `/api/v1/admin/lesson-templates/{id}` | GET/POST/PUT/DELETE | Admin | Media | Pagination | Ready with adjustment | Editor konten mobile berat | Web-first. |
| Admin | Kuis templates | Template CRUD/apply | `/api/v1/admin/quiz-templates`, `/{id}`, publish/archive/apply | GET/POST/PUT/DELETE | Admin | Question image | Pagination/filter | Ready with adjustment | Builder kompleks | Web-first. |
| Admin | Kuis questions | Question builder | `/api/v1/admin/quiz-templates/{id}/questions`, `/api/v1/admin/quiz-template-questions/{id}` | GET/POST/PUT/DELETE | Admin | Image media | List no paginator | Web-only | Builder cocok desktop | Tetap web. |
| Admin | Speaking exercises | Global target speaking CRUD | `/api/v1/admin/speaking/exercises`, `/{exercise}`, archive | GET/POST/PUT/PATCH | Admin | Reference audio via media id | Pagination/filter | Ready with adjustment | Reference audio upload flow lewat `/media` | P2 jika perlu admin mobile ringan. |
| Admin | Budaya global | Global culture items | `/api/v1/admin/culture/items`, `/{group_id}`, publish/archive | GET/POST/PUT/DELETE | Admin | Media/link | Service list tidak jelas pagination | Ready with adjustment | Delete berdampak global | Web-first. |
| Admin | Culture templates | Template budaya | `/api/v1/admin/culture-templates`, `/{id}`, publish/apply/items | GET/POST/PUT/DELETE | Admin | Media/link | Pagination | Ready with adjustment | Apply template butuh UX | Web-first. |
| Admin | Progress reports | Reports | `/api/v1/admin/reports/progress/schools`, `/classes`, `/students`, `/reports/quiz-results` | GET | Admin | Tidak | Pagination/filter | Ready | Tidak ada | Mobile read-only P2. |
| Admin | Export reports | CSV export | `/api/v1/admin/reports/*/export` | GET | Admin | Download CSV | Filter | Web-only | CSV export kurang cocok mobile | Tetap web. |
| Admin | Settings | App/security/banner | `/api/v1/admin/settings`, `/settings/application`, `/settings/banner`, `/settings/security` | GET/PUT/POST | Admin | Banner upload multipart | Tidak | Ready with adjustment | Risiko setting production dari HP | Tetap web kecuali read-only. |
| Admin | Profile/password | Profil admin | `/api/v1/auth/me`, `/api/v1/auth/password` | GET/PATCH/PUT | Auth | Avatar opsional | Tidak | Ready | Tidak ada | Jika admin mobile ada, hanya profile dasar. |

## Endpoint Missing atau Perlu Rekomendasi Baru

| Area | Endpoint yang dicari | Status | Catatan | Rekomendasi |
|---|---|---|---|---|
| Auth | Refresh token khusus | Missing | Sanctum personal access token dipakai; current user ada di `/auth/me`. | Tidak wajib. Pakai `/auth/me` untuk validasi session. |
| Siswa lesson | `/api/v1/student/lessons/{id}` | Missing | Web memakai `/class-lessons/{id}` dan `/class-lessons/{id}/content-url`. | Flutter pakai endpoint shared yang sudah ada. |
| Guru student detail dedicated | `/api/v1/teacher/students/{id}` | Missing | Web memakai report students dengan `student_id`. | Tambah endpoint dedicated hanya jika UI guru butuh detail lebih kaya. |

## Verifikasi Fase Dashboard/Modul

- `GET /api/v1/student/dashboard/summary` terverifikasi lewat backend: controller `StudentDashboardController::summary`, role `student`, response `class`, `empty_state`, `learning`, `quizzes`, `upcoming_deadlines`, `recent_activity`, `capabilities`, `speaking_summary`, `generated_at`.
- `GET /api/v1/student/modules` terverifikasi lewat backend: controller `StudentModuleController::index`, resource `StudentModuleResource`, role `student`, filter `search`, `status`, `page`, `per_page`, `sort_by`, `sort_direction`, pagination `meta`.
- `GET /api/v1/student/modules/{id}` terverifikasi untuk detail modul: controller `StudentModuleController::show`, resource `StudentModuleResource`, memuat `lessons` published urut `sort_order`, response `id`, `title`, `description`, `status`, `sort_order`, `progress`, `lessons`.
- `GET /api/v1/class-lessons/{id}` terverifikasi untuk detail lesson: controller `ClassLessonController::show`, resource `ClassLessonResource`, auth scoped via policy/Gate, response `content_type`, `content_body` untuk text, `external_url` untuk video/link, `media` metadata.
- `GET /api/v1/class-lessons/{id}/content-url` terverifikasi untuk URL konten/media lesson: controller `ClassLessonController::contentUrl`, service `LessonContentAccessService`.
- `PATCH /api/v1/student/lessons/{id}/progress` terverifikasi untuk penyelesaian lesson: controller `StudentProgressController::updateLesson`, request `UpdateLessonProgressRequest`, body `status`, `progress_percent`, response `LessonProgressResource`.
- `POST /api/v1/student/modules/{id}/start` tersedia untuk mulai modul, tetapi fase ini tidak memicu otomatis agar tidak mengubah progress tanpa aksi eksplisit user.
- Media lesson di module detail hanya mengirim metadata `id`, `mime_type`, `visibility`; URL konten harus lewat `GET /api/v1/class-lessons/{id}/content-url` atau media endpoint terkait.

## Gap API Paling Penting

1. Speaking list siswa dan hasil speaking belum paginated; aman untuk demo kecil, berisiko jika data besar.
2. Teacher speaking attempts belum paginated; review banyak siswa bisa berat di mobile.
3. Endpoint detail siswa guru dedicated belum ada; saat ini pakai report filter `student_id`.
4. Endpoint lesson siswa dedicated tidak ada; mobile harus memakai `/class-lessons/{id}` yang shared/scoped.
5. Audio Flutter perlu validasi MIME/extension nyata terhadap `StoreSpeakingAttemptRequest`.
6. Media private playback perlu uji temporary URL di Android native.
7. Admin import kamus CSV/ZIP cocok web-only; tidak layak MVP mobile.
8. Admin quiz/module builders terlalu kompleks untuk mobile MVP walau API tersedia.
9. Beberapa list controller mengembalikan collection tanpa `meta`, jadi Flutter harus mendukung response list non-paginated.
10. Audit lama menyebut `/student/chatbot/message`, tetapi route backend benar adalah `/student/chatbot/messages`.

## Rekomendasi Scope Mobile MVP

P0 Siswa:

- Login/logout/session.
- Dashboard siswa.
- Modul/detail modul/lesson/progress lesson.
- Kamus/detail/audio.
- Kuis/detail/attempt/submit/result.
- Progress.
- Profil.

P1 Siswa setelah P0 stabil:

- Chatbot.
- Budaya Mekongga.
- Speaking record/upload/status/result/reference audio.

P2:

- Guru mobile ringan.
- Admin mobile read-only atau approval ringan.
- Admin full tetap web-first.
