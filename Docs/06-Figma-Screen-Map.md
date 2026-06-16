# 06 — Figma Screen Map EMI

**Project:** EMI — Elearning Mekongga Indonesia
**Fase:** Fase 9 — Next.js Frontend Web
**Folder Frontend:** `Emi-Frontend/`
**Sumber Visual:** Figma Web Design
**Status:** Draft teknis untuk implementasi Figma → Next.js → Laravel API

## 1. Tujuan Dokumen

Dokumen ini memetakan screen Figma web EMI ke route Next.js, file App Router, role akses, status integrasi backend, endpoint Laravel aktual, catatan placeholder, dan kebutuhan UI state. Dokumen ini dipakai sebelum mengimplementasikan setiap screen Fase 9 agar frontend tidak mengarang endpoint atau fitur yang belum tersedia di backend.

Setiap screen wajib memiliki:

- frame Figma;
- route Next.js;
- file App Router;
- role akses;
- status integrasi;
- endpoint Laravel yang dipakai;
- catatan implementasi;
- loading, empty, error, dan success state bila screen memakai API.

## 2. Sumber Kebenaran

Urutan sumber kebenaran:

1. `Emi-Backend/routes/api.php`
2. `Docs/03-API-Specification.md`
3. `Docs/02-Role-Permission-Matrix.md`
4. `Docs/04-Development-Plan.md`
5. `Docs/05-Project-Handover.md`
6. Desain Figma
7. `Docs/06-Figma-Screen-Map.md`

Jika dokumen ini berbeda dari API Specification atau route aktual, ikuti source code backend dan API Specification. Dokumen ini adalah peta implementasi frontend, bukan kontrak API utama.

## 3. Aturan Status Integrasi

| Status | Arti |
|---|---|
| `INTEGRASI` | Backend tersedia pada Fase 1-8 dan harus dipakai. Tidak boleh mock permanen. |
| `PARTIAL` | Sebagian backend tersedia, tetapi ada bagian UI yang perlu placeholder atau verifikasi. |
| `PLACEHOLDER` | Backend belum tersedia. Tampilkan coming soon/disabled/preview terbatas. |
| `UI-ONLY` | Tidak butuh API langsung, hanya navigasi atau tampilan. |

## 4. Route Guard Global

Route guard frontend dipakai untuk UX dan navigasi awal. Authorization utama tetap berada di backend Laravel melalui Sanctum, role middleware, policy, dan service scope.

- `/login`, `/register`, `/pending-approval` untuk public/auth flow.
- `/admin/*` hanya Admin.
- `/teacher/*` hanya Guru.
- `/student/*` hanya Siswa.
- Token dan role harus divalidasi melalui endpoint backend, bukan hanya local state frontend.

Redirect setelah login:

| Role Backend | Redirect Frontend |
|---|---|
| `admin` | `/admin/dashboard` |
| `teacher` | `/teacher/dashboard` |
| `student` | `/student/dashboard` |

## 5. Mapping Auth

| Figma Frame | Figma URL | Route Next.js | App Router File | Role | Status | Endpoint/API Aktual | Catatan |
|---|---|---|---|---|---|---|---|
| `AUTH-01 — Login` | TODO: tempel link frame Figma | `/login` | `src/app/(auth)/login/page.tsx` | Public | `INTEGRASI` | `POST /api/v1/auth/login`<br>`GET /api/v1/auth/me` | Setelah login, panggil `me` untuk memastikan role dan redirect. |
| `AUTH-02 — Registrasi Pilih Role` | TODO: tempel link frame Figma | `/register` | `src/app/(auth)/register/page.tsx` | Public | `UI-ONLY` | Opsional: `GET /api/v1/public/schools` jika ingin menampilkan konteks sekolah. | Screen pemilihan role menuju registrasi Guru atau Siswa. |
| `AUTH-03 — Registrasi Guru` | TODO: tempel link frame Figma | `/register/teacher` | `src/app/(auth)/register/teacher/page.tsx` | Public | `INTEGRASI` | `POST /api/v1/auth/register`<br>`GET /api/v1/public/schools`<br>`GET /api/v1/public/schools/{school_id}/classes` | Kirim `requested_role=teacher`. |
| `AUTH-04 — Registrasi Siswa` | TODO: tempel link frame Figma | `/register/student` | `src/app/(auth)/register/student/page.tsx` | Public | `INTEGRASI` | `POST /api/v1/auth/register`<br>`GET /api/v1/public/schools`<br>`GET /api/v1/public/schools/{school_id}/classes` | Kirim `requested_role=student`. |
| `AUTH-05 — Menunggu Persetujuan Admin` | TODO: tempel link frame Figma | `/pending-approval` | `src/app/(auth)/pending-approval/page.tsx` | Public / pending user | `PARTIAL` | `POST /api/v1/auth/register` mengembalikan status pending.<br>`GET /api/v1/auth/me` hanya tersedia untuk user terautentikasi. | Pending user tidak menerima token login. Gunakan state setelah registrasi atau instruksi login ulang setelah approval. |

## 6. Mapping Admin

| Figma Frame | Figma URL | Route Next.js | App Router File | Role | Status | Endpoint/API Aktual | Catatan |
|---|---|---|---|---|---|---|---|
| `ADMIN-01 — Beranda Admin` | TODO: tempel link frame Figma | `/admin/dashboard` | `src/app/(admin)/admin/dashboard/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/dashboard/summary` | Tampilkan summary, trend, capability speaking false. |
| `ADMIN-02 — Persetujuan Akun` | TODO: tempel link frame Figma | `/admin/approvals` | `src/app/(admin)/admin/approvals/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/registration-requests`<br>`POST /api/v1/admin/registration-requests/{id}/approve`<br>`POST /api/v1/admin/registration-requests/{id}/reject` | Butuh table, filter, pagination, confirm dialog. |
| `ADMIN-03 — Detail Review Akun` | TODO: tempel link frame Figma | `/admin/approvals/[requestId]` | `src/app/(admin)/admin/approvals/[requestId]/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/registration-requests/{id}`<br>`POST /api/v1/admin/registration-requests/{id}/approve`<br>`POST /api/v1/admin/registration-requests/{id}/reject` | Detail request dan action approval/rejection. |
| `ADMIN-04 — Sekolah & Kelas` | TODO: tempel link frame Figma | `/admin/schools-classes` | `src/app/(admin)/admin/schools-classes/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/schools`<br>`POST /api/v1/schools`<br>`GET /api/v1/schools/{id}`<br>`PUT /api/v1/schools/{id}`<br>`DELETE /api/v1/schools/{id}`<br>`GET /api/v1/classes`<br>`POST /api/v1/classes`<br>`GET /api/v1/classes/{id}`<br>`PUT /api/v1/classes/{id}`<br>`DELETE /api/v1/classes/{id}` | Admin memakai endpoint umum dengan authorization backend. |
| `ADMIN-05 — Detail Kelas` | TODO: tempel link frame Figma | `/admin/classes/[classId]` | `src/app/(admin)/admin/classes/[classId]/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/classes/{id}`<br>`GET /api/v1/classes/{id}/students`<br>`POST /api/v1/classes/{id}/assign-teacher`<br>`POST /api/v1/classes/{id}/assign-student` | Assignment guru dan membership siswa via backend. |
| `ADMIN-06 — Data Guru & Siswa` | TODO: tempel link frame Figma | `/admin/users` | `src/app/(admin)/admin/users/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/users` | Gunakan filter role/status/school/class/search dan pagination. |
| `ADMIN-07 — Detail / Edit Pengguna` | TODO: tempel link frame Figma | `/admin/users/[userId]` | `src/app/(admin)/admin/users/[userId]/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/users/{id}`<br>`PUT /api/v1/users/{id}`<br>`PATCH /api/v1/users/{id}/status`<br>`POST /api/v1/classes/{id}/assign-teacher`<br>`POST /api/v1/classes/{id}/assign-student` | Assignment/membership dilakukan lewat endpoint kelas. |
| `ADMIN-08 — Import Kamus CSV + ZIP Audio` | TODO: tempel link frame Figma | `/admin/dictionary/import` | `src/app/(admin)/admin/dictionary/import/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/dictionary/imports/template`<br>`POST /api/v1/admin/dictionary/imports/preview`<br>`GET /api/v1/admin/dictionary/imports`<br>`GET /api/v1/admin/dictionary/imports/{id}`<br>`POST /api/v1/admin/dictionary/imports/{id}/confirm`<br>`GET /api/v1/admin/dictionary/imports/{id}/errors` | Upload CSV/ZIP, preview, confirm, error table. |
| `ADMIN-09 — Kelola Kamus Mekongga` | TODO: tempel link frame Figma | `/admin/dictionary` | `src/app/(admin)/admin/dictionary/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/dictionary/categories`<br>`POST /api/v1/admin/dictionary/categories`<br>`GET /api/v1/admin/dictionary/entries`<br>`POST /api/v1/admin/dictionary/entries`<br>`GET /api/v1/dictionary` | Admin CRUD dan public-style search tersedia. |
| `ADMIN-10 — Detail / Edit Kata Kamus` | TODO: tempel link frame Figma | `/admin/dictionary/[entryId]` | `src/app/(admin)/admin/dictionary/[entryId]/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/dictionary/entries/{id}`<br>`PUT /api/v1/admin/dictionary/entries/{id}`<br>`DELETE /api/v1/admin/dictionary/entries/{id}`<br>`POST /api/v1/media`<br>`GET /api/v1/media/{id}` | Audio harus lewat media yang valid untuk kamus. |
| `ADMIN-11 — Basis Pengetahuan AI` | TODO: tempel link frame Figma | `/admin/knowledge-base` | `src/app/(admin)/admin/knowledge-base/page.tsx` | Admin | `PLACEHOLDER` | Belum tersedia — placeholder/future phase | Tampilkan badge `Fase Lanjutan`; jangan buat API palsu. |
| `ADMIN-12 — Detail / Edit Pengetahuan AI` | TODO: tempel link frame Figma | `/admin/knowledge-base/[documentId]` | `src/app/(admin)/admin/knowledge-base/[documentId]/page.tsx` | Admin | `PLACEHOLDER` | Belum tersedia — placeholder/future phase | Knowledge base/RAG belum aktif. |
| `ADMIN-13 — Modul Pembelajaran / Modul Default` | TODO: tempel link frame Figma | `/admin/modules/templates` | `src/app/(admin)/admin/modules/templates/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/module-templates`<br>`POST /api/v1/admin/module-templates`<br>`GET /api/v1/admin/module-templates/{id}`<br>`POST /api/v1/admin/module-templates/{id}/publish`<br>`POST /api/v1/admin/module-templates/{id}/archive`<br>`POST /api/v1/admin/module-templates/{id}/apply` | Apply template ke class tersedia. |
| `ADMIN-14 — Editor Modul Default` | TODO: tempel link frame Figma | `/admin/modules/templates/[moduleTemplateId]/edit` | `src/app/(admin)/admin/modules/templates/[moduleTemplateId]/edit/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/module-templates/{id}`<br>`PUT /api/v1/admin/module-templates/{id}`<br>`DELETE /api/v1/admin/module-templates/{id}`<br>`GET /api/v1/admin/module-templates/{module_template_id}/lessons`<br>`POST /api/v1/admin/module-templates/{module_template_id}/lessons`<br>`PATCH /api/v1/admin/module-templates/{id}/lessons/reorder`<br>`GET /api/v1/admin/lesson-templates/{id}`<br>`PUT /api/v1/admin/lesson-templates/{id}`<br>`DELETE /api/v1/admin/lesson-templates/{id}`<br>`POST /api/v1/admin/lesson-templates/{id}/publish`<br>`POST /api/v1/admin/lesson-templates/{id}/archive`<br>`POST /api/v1/media` | Media lesson memakai media API sesuai purpose. |
| `ADMIN-15 — Kuis & LKPD / Kuis Default` | TODO: tempel link frame Figma | `/admin/quizzes/templates` | `src/app/(admin)/admin/quizzes/templates/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/quiz-templates`<br>`POST /api/v1/admin/quiz-templates`<br>`GET /api/v1/admin/quiz-templates/{id}`<br>`POST /api/v1/admin/quiz-templates/{id}/publish`<br>`POST /api/v1/admin/quiz-templates/{id}/archive`<br>`POST /api/v1/admin/quiz-templates/{id}/apply` | Kuis default dan apply tersedia. |
| `ADMIN-16 — Builder Soal Kuis Default` | TODO: tempel link frame Figma | `/admin/quizzes/templates/[quizTemplateId]/builder` | `src/app/(admin)/admin/quizzes/templates/[quizTemplateId]/builder/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/quiz-templates/{quiz_template_id}/questions`<br>`POST /api/v1/admin/quiz-templates/{quiz_template_id}/questions`<br>`PATCH /api/v1/admin/quiz-templates/{id}/questions/reorder`<br>`GET /api/v1/admin/quiz-template-questions/{id}`<br>`PUT /api/v1/admin/quiz-template-questions/{id}`<br>`DELETE /api/v1/admin/quiz-template-questions/{id}`<br>`POST /api/v1/media` | Gambar soal lewat media purpose question image. |
| `ADMIN-17 — Progress Siswa` | TODO: tempel link frame Figma | `/admin/reports/progress` | `src/app/(admin)/admin/reports/progress/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/reports/progress/schools`<br>`GET /api/v1/admin/reports/progress/classes`<br>`GET /api/v1/admin/reports/progress/students`<br>`GET /api/v1/admin/reports/progress/schools/export`<br>`GET /api/v1/admin/reports/progress/classes/export`<br>`GET /api/v1/admin/reports/progress/students/export` | Sediakan tab sekolah/kelas/siswa dan CSV export. |
| `ADMIN-18 — Detail Progress Kelas / Siswa` | TODO: tempel link frame Figma | `/admin/reports/progress/detail` | `src/app/(admin)/admin/reports/progress/detail/page.tsx` | Admin | `INTEGRASI` | `GET /api/v1/admin/reports/progress/classes`<br>`GET /api/v1/admin/reports/progress/students`<br>`GET /api/v1/admin/reports/quiz-results`<br>`GET /api/v1/admin/reports/quiz-results/export` | Gunakan filter class/student/quiz sesuai report. |
| `ADMIN-19 — Pengaturan Sistem` | TODO: tempel link frame Figma | `/admin/settings` | `src/app/(admin)/admin/settings/page.tsx` | Admin | `PARTIAL` | Belum tersedia — placeholder/future phase untuk system settings.<br>Tersedia: `GET /api/v1/auth/me`<br>`PATCH /api/v1/auth/me`<br>`PUT /api/v1/auth/password`<br>`POST /api/v1/auth/me/avatar`<br>`DELETE /api/v1/auth/me/avatar` | Batasi ke profil/password/avatar sampai system settings API aktif. |

## 7. Mapping Guru

| Figma Frame | Figma URL | Route Next.js | App Router File | Role | Status | Endpoint/API Aktual | Catatan |
|---|---|---|---|---|---|---|---|
| `TEACHER-01 — Beranda Kelas` | TODO: tempel link frame Figma | `/teacher/dashboard` | `src/app/(teacher)/teacher/dashboard/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/teacher/dashboard/summary` | Empty state jika guru belum punya assignment aktif. |
| `TEACHER-02 — Data Siswa` | TODO: tempel link frame Figma | `/teacher/students` | `src/app/(teacher)/teacher/students/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/classes/{id}/students`<br>`GET /api/v1/teacher/reports/progress/students` | Class id harus berasal dari assignment aktif atau profile context. |
| `TEACHER-03 — Detail Siswa & Progress` | TODO: tempel link frame Figma | `/teacher/students/[studentId]` | `src/app/(teacher)/teacher/students/[studentId]/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/teacher/reports/progress/students`<br>`GET /api/v1/teacher/reports/quiz-results` | Filter `student_id`; backend menolak siswa luar kelas. |
| `TEACHER-04 — Modul Kelas` | TODO: tempel link frame Figma | `/teacher/modules` | `src/app/(teacher)/teacher/modules/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/classes/{class_id}/modules`<br>`POST /api/v1/classes/{class_id}/modules`<br>`PATCH /api/v1/classes/{class_id}/modules/reorder`<br>`GET /api/v1/class-modules/{id}` | Class id dari assignment aktif. |
| `TEACHER-05 — Editor Modul` | TODO: tempel link frame Figma | `/teacher/modules/[classModuleId]/edit` | `src/app/(teacher)/teacher/modules/[classModuleId]/edit/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/class-modules/{id}`<br>`PUT /api/v1/class-modules/{id}`<br>`DELETE /api/v1/class-modules/{id}`<br>`POST /api/v1/class-modules/{id}/publish`<br>`POST /api/v1/class-modules/{id}/archive`<br>`PATCH /api/v1/class-modules/{id}/lessons/reorder` | Backend policy menjaga scope kelas guru. |
| `TEACHER-06 — Tambah / Edit Materi Modul` | TODO: tempel link frame Figma | `/teacher/modules/[classModuleId]/lessons/[classLessonId]/edit` | `src/app/(teacher)/teacher/modules/[classModuleId]/lessons/[classLessonId]/edit/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/class-modules/{class_module_id}/lessons`<br>`POST /api/v1/class-modules/{class_module_id}/lessons`<br>`GET /api/v1/class-lessons/{id}`<br>`PUT /api/v1/class-lessons/{id}`<br>`DELETE /api/v1/class-lessons/{id}`<br>`POST /api/v1/class-lessons/{id}/publish`<br>`POST /api/v1/class-lessons/{id}/archive`<br>`GET /api/v1/class-lessons/{id}/content-url`<br>`POST /api/v1/media` | Untuk tambah materi, route alternatif boleh `/teacher/modules/[classModuleId]/lessons/new`. |
| `TEACHER-07 — Kuis Kelas` | TODO: tempel link frame Figma | `/teacher/quizzes` | `src/app/(teacher)/teacher/quizzes/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/class-quizzes`<br>`POST /api/v1/class-quizzes`<br>`GET /api/v1/class-quizzes/{id}`<br>`PUT /api/v1/class-quizzes/{id}`<br>`DELETE /api/v1/class-quizzes/{id}`<br>`POST /api/v1/class-quizzes/{id}/publish`<br>`POST /api/v1/class-quizzes/{id}/archive` | Filter kelas dari assignment aktif. |
| `TEACHER-08 — Builder Soal Kuis dengan Gambar` | TODO: tempel link frame Figma | `/teacher/quizzes/[classQuizId]/builder` | `src/app/(teacher)/teacher/quizzes/[classQuizId]/builder/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/class-quizzes/{class_quiz_id}/questions`<br>`POST /api/v1/class-quizzes/{class_quiz_id}/questions`<br>`PATCH /api/v1/class-quizzes/{id}/questions/reorder`<br>`GET /api/v1/quiz-questions/{id}`<br>`PUT /api/v1/quiz-questions/{id}`<br>`DELETE /api/v1/quiz-questions/{id}`<br>`POST /api/v1/media` | Jangan tampilkan kunci jawaban ke siswa; builder hanya Guru/Admin. |
| `TEACHER-09 — Hasil Kuis` | TODO: tempel link frame Figma | `/teacher/quizzes/[classQuizId]/results` | `src/app/(teacher)/teacher/quizzes/[classQuizId]/results/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/teacher/reports/quiz-results`<br>`GET /api/v1/class-quizzes/{id}/attempts`<br>`GET /api/v1/class-quizzes/{id}/report`<br>`GET /api/v1/teacher/reports/quiz-results/export` | Report Fase 8 memakai best final attempt. |
| `TEACHER-10 — Progress Siswa Kelas` | TODO: tempel link frame Figma | `/teacher/reports/progress` | `src/app/(teacher)/teacher/reports/progress/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/teacher/reports/progress/students`<br>`GET /api/v1/teacher/reports/progress/students/export` | Scope otomatis assignment aktif guru. |
| `TEACHER-11 — Hasil Speaking` | TODO: tempel link frame Figma | `/teacher/speaking/results` | `src/app/(teacher)/teacher/speaking/results/page.tsx` | Guru | `PLACEHOLDER` | Belum tersedia — placeholder/future phase | Dashboard capability `speaking_reports=false`; tampilkan coming soon. |
| `TEACHER-12 — Media Kelas` | TODO: tempel link frame Figma | `/teacher/media` | `src/app/(teacher)/teacher/media/page.tsx` | Guru | `PARTIAL` | Tersedia: `POST /api/v1/media`<br>`GET /api/v1/media/{id}`<br>`POST /api/v1/media/{id}/temporary-url`<br>`DELETE /api/v1/media/{id}`<br>Belum tersedia — placeholder/future phase untuk daftar media umum. | Gunakan dari konteks module/lesson/quiz; tidak ada endpoint list media umum. |
| `TEACHER-13 — Profil Guru` | TODO: tempel link frame Figma | `/teacher/profile` | `src/app/(teacher)/teacher/profile/page.tsx` | Guru | `INTEGRASI` | `GET /api/v1/auth/me`<br>`PATCH /api/v1/auth/me`<br>`PUT /api/v1/auth/password`<br>`POST /api/v1/auth/me/avatar`<br>`DELETE /api/v1/auth/me/avatar` | Profil semua role memakai endpoint auth. |

## 8. Mapping Siswa

| Figma Frame | Figma URL | Route Next.js | App Router File | Role | Status | Endpoint/API Aktual | Catatan |
|---|---|---|---|---|---|---|---|
| `STUDENT-01 — Beranda Belajar` | TODO: tempel link frame Figma | `/student/dashboard` | `src/app/(student)/student/dashboard/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/student/dashboard/summary` | Dashboard menghormati membership aktif dan hidden quiz result. |
| `STUDENT-02 — Modul Belajar` | TODO: tempel link frame Figma | `/student/modules` | `src/app/(student)/student/modules/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/student/modules`<br>`GET /api/v1/student/progress/modules` | Hanya module published kelas aktif. |
| `STUDENT-03 — Detail Materi` | TODO: tempel link frame Figma | `/student/modules/[classModuleId]/lessons/[classLessonId]` | `src/app/(student)/student/modules/[classModuleId]/lessons/[classLessonId]/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/student/modules/{id}`<br>`GET /api/v1/class-lessons/{id}`<br>`GET /api/v1/class-lessons/{id}/content-url`<br>`POST /api/v1/student/modules/{id}/start`<br>`PATCH /api/v1/student/lessons/{id}/progress` | Gunakan endpoint student module untuk konteks dan lesson endpoint untuk detail/content. |
| `STUDENT-04 — Kamus Mekongga` | TODO: tempel link frame Figma | `/student/dictionary` | `src/app/(student)/student/dictionary/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/dictionary` | Search/filter/pagination dari API kamus. |
| `STUDENT-05 — Detail Kata Kamus` | TODO: tempel link frame Figma | `/student/dictionary/[entryId]` | `src/app/(student)/student/dictionary/[entryId]/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/dictionary/{id}`<br>`GET /api/v1/public/media/{id}/content` | Audio playback memakai URL/resource aman dari backend. |
| `STUDENT-06 — Latihan Speaking` | TODO: tempel link frame Figma | `/student/speaking` | `src/app/(student)/student/speaking/page.tsx` | Siswa | `PLACEHOLDER` | Belum tersedia — placeholder/future phase | Speaking belum aktif. |
| `STUDENT-07 — Hasil Speaking` | TODO: tempel link frame Figma | `/student/speaking/results` | `src/app/(student)/student/speaking/results/page.tsx` | Siswa | `PLACEHOLDER` | Belum tersedia — placeholder/future phase | Speaking report belum aktif. |
| `STUDENT-08 — Kuis & LKPD` | TODO: tempel link frame Figma | `/student/quizzes` | `src/app/(student)/student/quizzes/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/student/quizzes`<br>`GET /api/v1/student/quizzes/{id}` | Jadwal, max attempt, result visibility dari backend. |
| `STUDENT-09 — Pengerjaan Kuis` | TODO: tempel link frame Figma | `/student/quizzes/[classQuizId]/attempt` | `src/app/(student)/student/quizzes/[classQuizId]/attempt/page.tsx` | Siswa | `INTEGRASI` | `POST /api/v1/class-quizzes/{id}/attempts`<br>`GET /api/v1/quiz-attempts/{id}`<br>`PUT /api/v1/quiz-attempts/{id}/answers/{question_id}`<br>`POST /api/v1/quiz-attempts/{id}/submit` | Submit memakai idempotency key. |
| `STUDENT-10 — Hasil Kuis` | TODO: tempel link frame Figma | `/student/quizzes/[classQuizId]/result` | `src/app/(student)/student/quizzes/[classQuizId]/result/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/quiz-attempts/{id}`<br>`GET /api/v1/student/reports/quiz-results` | Hormati `show_result`; jangan tampilkan skor jika hidden. |
| `STUDENT-11 — Budaya Mekongga` | TODO: tempel link frame Figma | `/student/culture` | `src/app/(student)/student/culture/page.tsx` | Siswa | `PLACEHOLDER` | Belum tersedia — placeholder/future phase | Cultural content belum aktif pada route aktual. |
| `STUDENT-12 — Chatbot AI` | TODO: tempel link frame Figma | `/student/chatbot` | `src/app/(student)/student/chatbot/page.tsx` | Siswa | `PLACEHOLDER` | Belum tersedia — placeholder/future phase | Chatbot/RAG belum aktif. |
| `STUDENT-13 — Progress Belajar` | TODO: tempel link frame Figma | `/student/progress` | `src/app/(student)/student/progress/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/student/reports/progress`<br>`GET /api/v1/student/progress/modules`<br>`GET /api/v1/student/reports/quiz-results` | Gabungkan progress module dan report ringkasan. |
| `STUDENT-14 — Profil Saya` | TODO: tempel link frame Figma | `/student/profile` | `src/app/(student)/student/profile/page.tsx` | Siswa | `INTEGRASI` | `GET /api/v1/auth/me`<br>`PATCH /api/v1/auth/me`<br>`PUT /api/v1/auth/password`<br>`POST /api/v1/auth/me/avatar`<br>`DELETE /api/v1/auth/me/avatar` | Profil semua role memakai endpoint auth. |

## 9. Route Redirect dan Fallback

| Route | Perilaku |
|---|---|
| `/` | Redirect ke `/login` jika belum login; redirect ke dashboard role jika sudah login |
| `/admin` | Redirect ke `/admin/dashboard` |
| `/teacher` | Redirect ke `/teacher/dashboard` |
| `/student` | Redirect ke `/student/dashboard` |
| `/unauthorized` | Halaman akses ditolak |
| Route tidak dikenal | Not found page |

## 10. Shared Layout

### Auth Layout

Dipakai untuk login, register, dan pending approval. Layout ini tidak boleh menampilkan sidebar role.

### Admin Layout

Dipakai untuk `/admin/*`. Berisi sidebar/topbar Admin, guard role Admin, dan navigasi fitur global.

### Teacher Layout

Dipakai untuk `/teacher/*`. Berisi sidebar/topbar Guru, guard role Guru, dan konteks kelas assignment aktif.

### Student Layout

Dipakai untuk `/student/*`. Berisi sidebar/topbar Siswa, guard role Siswa, dan konteks kelas membership aktif.

## 11. Shared Components

Komponen wajib:

- Button
- Input
- Select
- Textarea
- Card
- Badge
- Table
- Modal
- Confirm Dialog
- Sidebar
- Topbar
- Pagination
- Empty State
- Loading State
- Error State
- Alert
- Toast
- Audio Player
- Upload Component
- File Preview
- Search Bar
- Filter Panel
- Form Field
- Page Header
- Stats Card

## 12. Fitur Integrasi Penuh

Fitur berikut harus memakai API backend Fase 1-8:

- Login
- Registrasi guru
- Registrasi siswa
- Approval akun
- Sekolah
- Kelas
- User management
- Assignment guru
- Membership siswa
- Media upload
- Avatar
- Kamus
- Import CSV kamus
- Import ZIP audio
- Modul template
- Lesson template
- Modul kelas
- Lesson kelas
- Progress lesson
- Progress module
- Kuis template
- Kuis kelas
- Attempt kuis
- Grading
- Dashboard
- Laporan progress
- Laporan hasil kuis
- CSV export

## 13. Fitur Placeholder / Future Phase

Fitur berikut tidak boleh dianggap selesai pada Fase 9:

- Speaking assessment
- Hasil speaking
- AI chatbot/RAG
- Basis pengetahuan AI
- Budaya Mekongga penuh bila backend belum tersedia
- Offline sync
- ESP32

Untuk fitur tersebut, frontend harus memakai:

- coming soon;
- disabled state;
- badge `Fase Lanjutan`;
- atau UI preview terbatas.

Jangan membuat API palsu.

## 14. Checklist Sebelum Implementasi Screen

Untuk setiap screen, Codex harus memastikan:

1. Frame Figma mana yang dipakai.
2. Route Next.js apa.
3. Role apa.
4. API backend apa.
5. Apakah endpoint tersedia.
6. Status `INTEGRASI`, `PARTIAL`, `PLACEHOLDER`, atau `UI-ONLY`.
7. Loading state.
8. Empty state.
9. Error state.
10. Success state.
11. Validasi form.
12. Permission khusus.

## 15. Checklist Visual QA

Checklist visual:

- layout;
- spacing;
- warna;
- tipografi;
- border;
- shadow;
- radius;
- komponen form;
- sidebar/topbar;
- tabel/card;
- loading/empty/error state;
- responsive behavior;
- kesesuaian dengan Figma.

## 16. Catatan Update Berikutnya

Dokumen ini harus diperbarui setelah:

- link frame Figma final tersedia;
- route frontend berubah;
- endpoint backend berubah;
- fitur placeholder menjadi aktif;
- screen baru ditambahkan;
- screen lama dihapus;
- hasil Visual QA menemukan perubahan penting.
