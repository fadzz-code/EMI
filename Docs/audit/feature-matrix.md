# Feature Matrix EMI

## Ringkasan

Jumlah area fitur berdasarkan audit role:
- Admin: 23 area halaman/fitur
- Guru: 21 area halaman/fitur
- Siswa: 16 area halaman/fitur

Matrix ini bersumber dari `docs/audit/role-url-action-audit.md`. Item bertanda "Perlu verifikasi manual" perlu dicek langsung di browser/source lanjutan sebelum dijadikan panduan final.

## Matrix Admin

| Area Fitur | URL | Tujuan | Data yang Ditampilkan | Aksi/Tombol | Endpoint API | Data Seeder yang Dibutuhkan | Prioritas Testing | Catatan |
|---|---|---|---|---|---|---|---|---|
| Beranda Admin | `/admin/dashboard` | Ringkasan metrik admin | Summary dashboard, progress, tren/report cards | Navigasi cepat jika ada | `GET /admin/dashboard/summary`, report progress | Admin, sekolah, kelas, guru, siswa, progress | P0 | Detail kartu perlu verifikasi manual |
| Persetujuan Akun | `/admin/approvals` | Review request registrasi | Registration requests, role, status, pemohon, sekolah/kelas | Filter, search, approve, reject, buka detail | `GET /admin/registration-requests`, `POST /approve`, `POST /reject` | Pending teacher/student registration request | P0 | Test status pending dan request sudah diproses |
| Detail Persetujuan | `/admin/approvals/[requestId]` | Proses satu request | Detail pemohon dan target sekolah/kelas | Approve, reject, kembali | `GET /admin/registration-requests/{id}`, approve/reject | Request pending dan processed | P0 | Tombol untuk non-pending perlu verifikasi manual |
| Sekolah & Kelas | `/admin/schools-classes` | CRUD sekolah/kelas | Daftar sekolah/kelas, status, tahun ajaran | Tambah, edit, nonaktif/hapus | `GET/POST/PUT/DELETE /schools`, `/classes` | Sekolah aktif, kelas aktif/nonaktif | P0 | Label delete vs deactivate perlu verifikasi manual |
| Detail Kelas Admin | `/admin/classes/[classId]` | Assignment guru/siswa | Detail kelas, guru aktif, siswa | Assign/reassign guru, assign/move siswa | `GET /classes/{id}`, `POST /assign-teacher`, `POST /assign-student`, `GET /students` | Kelas, guru approved, siswa approved | P0 | Test konflik satu guru/siswa aktif |
| Guru & Siswa | `/admin/users` | Manajemen user | User, role, status, email, sekolah/kelas | Filter/search, detail, update, ubah status | `GET /users`, `PUT /users/{id}`, `PATCH /users/{id}/status` | Admin, guru, siswa berbagai status | P0 | Test token revoke saat inactive |
| Detail User | `/admin/users/[userId]` | Edit detail user | Profil, role, status, assignment/membership | Simpan, ubah status, kembali | `GET/PUT /users/{id}`, `PATCH /users/{id}/status` | Guru/siswa dengan kelas | P1 | Field read-only perlu verifikasi manual |
| Kamus Admin | `/admin/dictionary` | CRUD kategori/entri kamus | Entitas kamus, kategori, audio, contoh kalimat | Tambah kategori/kata, search, detail, hapus | `/admin/dictionary/categories`, `/admin/dictionary/entries`, `/media` | Kategori, kata, audio opsional, contoh kalimat | P0 | Hapus kemungkinan soft delete |
| Detail Kamus | `/admin/dictionary/[entryId]` | Edit entri kamus | Detail kata, kategori, audio, contoh kalimat | Edit/simpan, upload/lepas audio | `GET/PUT /admin/dictionary/entries/{id}`, `/media` | Entry kamus aktif dengan examples | P1 | Pastikan import examples tampil |
| Import Kamus | `/admin/dictionary/import` | Import CSV kosakata/contoh | Dua kartu import, template, preview, errors, history | Download template, upload, preview, confirm | `/admin/dictionary/imports/*` | CSV kosakata, CSV contoh, ZIP audio opsional | P0 | Test header/encoding/ZIP/duplicate strategy |
| Basis AI | `/admin/knowledge-base` | CRUD knowledge chatbot | Knowledge item, status, source, preview | Tambah, preview, edit, publish, archive, delete, filter | `/admin/ai/knowledge`, extract/import endpoints | Knowledge manual, URL publik, PDF opsional | P0 | URL private harus ditolak |
| Detail Basis AI | `/admin/knowledge-base/[knowledgeId]` | Detail knowledge item | Title/content/source/status/chunks | Edit/publish/archive/delete jika ada | `GET /admin/ai/knowledge/{id}` | Knowledge item draft/published | P1 | Perlu verifikasi manual isi detail |
| Modul Admin | `/admin/modules` | CRUD template modul | Module templates, status, lesson count | Tambah, edit, publish/archive/delete, apply | `/admin/module-templates`, publish/archive/apply | Template modul draft/published | P0 | Apply UI perlu verifikasi manual |
| Edit Modul Admin | `/admin/modules/[moduleId]/edit` | Kelola template dan lesson | Modul, lesson list, media | Simpan, publish, tambah/edit/hapus lesson, upload media | Module + lesson template endpoints, `/media` | Template modul dengan lessons | P0 | Test reorder lesson |
| Kuis Admin | `/admin/quizzes` | CRUD template kuis | Quiz templates, status, jumlah soal | Tambah, builder, publish/archive/delete, apply | `/admin/quiz-templates`, publish/archive/apply | Template kuis draft/published | P0 | Lock setelah apply perlu verifikasi manual |
| Builder Kuis Admin | `/admin/quizzes/[quizId]/builder` | Kelola soal template | Detail kuis, soal, opsi, kunci | Simpan, publish, tambah/edit/hapus soal, upload gambar | Quiz question endpoints, `/media` | Quiz template dengan soal/opsi | P0 | Test minimal opsi dan jawaban benar |
| Template Speaking Admin | `/admin/speaking/exercises` | CRUD template speaking | Template/exercise, status, reference audio | Tambah, edit, archive, upload audio | `/admin/speaking/exercises`, `/media` | Speaking template draft/published, audio | P1 | Draft/archived tidak muncul untuk guru |
| Budaya Mekongga Admin | `/admin/culture/templates` | CRUD budaya global/template | Konten budaya, status, media/link | Tambah, edit, publish, archive, delete | `/admin/culture/items`, `/admin/culture-templates`, `/media` | Culture item image/pdf/audio/link | P1 | Delete berdampak global; confirm manual |
| Edit Template Budaya | `/admin/culture/templates/[cultureTemplateId]/edit` | Edit template budaya | Template dan item | Simpan, publish, apply ke kelas, tambah/edit/hapus item | Culture template/item endpoints | Template budaya, kelas target | P1 | Route redirect perlu verifikasi manual |
| Progress Admin | `/admin/progress` | Laporan progress | Tabel sekolah/kelas/siswa, summary | Filter, export, detail | `/admin/reports/progress/*`, export endpoints | Progress module/lesson/quiz siswa | P0 | Test CSV export formula sanitization |
| Detail Progress Kelas | `/admin/progress/classes/[classId]` | Detail progress kelas | Siswa dan progress kelas | Print/export/detail siswa jika ada | Progress endpoint dengan `class_id` | Kelas dengan beberapa siswa/progress | P1 | Perlu verifikasi manual data kosong |
| Detail Progress Siswa | `/admin/progress/students/[studentId]` | Detail progress siswa | Profil, modul, kuis, skor | Print report jika ada | Progress endpoint dengan student filter | Siswa dengan progress dan attempts | P1 | Test best score |
| Pengaturan Admin | `/admin/settings` | Settings sistem aktif | App settings, profil, banner, security, activity log | Simpan app/profil/banner/security, ubah password | `/admin/settings`, `/auth/me`, `/auth/password` | Admin, banner image, activity logs | P0 | Toggle weekly email hanya tersimpan |

## Matrix Guru

| Area Fitur | URL | Tujuan | Data yang Ditampilkan | Aksi/Tombol | Endpoint API | Data Seeder yang Dibutuhkan | Prioritas Testing | Catatan |
|---|---|---|---|---|---|---|---|---|
| Beranda Guru | `/teacher/dashboard` | Ringkasan guru | Summary kelas/siswa/progres | Navigasi cepat jika ada | `GET /teacher/dashboard/summary` | Guru assigned, kelas, siswa, progress | P0 | Test guru tanpa kelas |
| Kelas Guru | `/teacher/classes` | Daftar kelas guru | Kelas, sekolah, jumlah siswa/status | Buka detail/tabs | `GET /classes` scoped guru | Guru dengan 1+ kelas | P0 | IDOR kelas harus forbidden |
| Detail Kelas Guru | `/teacher/classes/[classId]` | Ringkasan kelas | Detail kelas, statistik | Navigasi siswa/modul/kuis/budaya | `GET /classes/{id}` | Kelas assigned | P0 | Ringkasan cepat |
| Siswa Kelas | `/teacher/classes/[classId]/students` | Daftar siswa kelas | Siswa dan progress ringkas | Buka detail siswa | `GET /classes/{id}/students` | Siswa dalam kelas guru | P0 | Pagination perlu verifikasi manual |
| Modul Kelas | `/teacher/classes/[classId]/modules` | Kelola modul kelas | Class modules, status, lessons | Tambah/apply, edit, publish/archive/delete | Class module endpoints | Class module draft/published | P0 | Guru harus assigned |
| Kuis Kelas | `/teacher/classes/[classId]/quizzes` | Kelola kuis kelas | Class quizzes, status, attempts | Tambah/apply, builder, results | Class quiz endpoints | Class quiz + template | P0 | Lock after attempts perlu verifikasi |
| Budaya Kelas | `/teacher/classes/[classId]/culture` | Kelola budaya kelas | Culture items, status, media/link | Edit, publish, archive, hapus | Class culture endpoints | Culture item kelas | P1 | Route redirect perlu verifikasi manual |
| Siswa Guru | `/teacher/students` | Daftar siswa ajar | Siswa, kelas, progress | Search/filter, detail | Teacher report/student endpoints | Guru dengan siswa | P0 | Endpoint exact perlu verifikasi manual |
| Detail Siswa Guru | `/teacher/students/[studentId]` | Detail progress siswa | Profil dan progress siswa | Buka laporan/detail jika ada | Teacher progress endpoints | Siswa dalam kelas guru | P1 | IDOR siswa perlu diuji |
| Laporan Progress Guru | `/teacher/reports/progress` | Laporan progress guru | Progress kelas/siswa | Filter, export jika ada | `/teacher/reports/progress/*` | Progress siswa | P0 | Export perlu verifikasi manual |
| Modul Guru | `/teacher/modules` | Kelola semua modul guru | Class modules lintas kelas | Edit, publish/archive/delete | Class module endpoints | Beberapa modul kelas | P0 | `/teacher/media` mungkin redirect ke sini |
| Edit Modul Guru | `/teacher/modules/[classModuleId]/edit` | Edit class module | Modul dan lessons | Simpan, publish, tambah/edit lesson | `GET/PUT /class-modules/{id}`, publish, lessons | Class module dengan lessons | P0 | Publish hanya jika belum published |
| Edit Lesson Guru | `/teacher/modules/[classModuleId]/lessons/[classLessonId]/edit` | Edit lesson | Lesson content/media | Simpan, publish, upload/lepas media | Class lesson endpoints, `/media` | Lesson dengan media opsional | P1 | Test MIME/size |
| Kuis Guru | `/teacher/quizzes` | Kelola semua kuis guru | Class quizzes | Buat kuis, builder, hasil | `GET/POST /class-quizzes` | Kelas guru, class quiz | P0 | Create disabled jika tidak ada kelas |
| Builder Kuis Guru | `/teacher/quizzes/[classQuizId]/builder` | Edit quiz/soal | Quiz detail, questions/options | Simpan, publish, edit/hapus soal, upload gambar | Class quiz/question endpoints, `/media` | Quiz dengan soal | P0 | Locked state setelah attempts |
| Hasil Kuis Guru | `/teacher/quizzes/[classQuizId]/results` | Lihat hasil kuis | Attempts, skor, jawaban | Lihat/Tutup Detail, search | Attempts/report endpoint | Submitted quiz attempts | P0 | Tidak ada edit nilai |
| Budaya Guru | `/teacher/culture` | Kelola budaya kelas guru | Culture items, status, media/link | Tambah/edit, publish, archive, hapus | Class culture endpoints, `/media` | Culture item kelas | P1 | Multi-class selector perlu verifikasi |
| Target Speaking Guru | `/teacher/speaking/exercises` | Kelola target speaking | Templates, target kelas, audio | Buat target, edit, archive | Teacher speaking endpoints, `/media` | Speaking template published, class target | P0 | Create disabled jika tanpa kelas |
| Hasil Speaking Guru | `/teacher/speaking/results` | Review speaking attempts | Attempts, skor AI, audio, transcript | Pilih attempt, simpan feedback | Teacher speaking attempts/review endpoints | Student speaking attempts | P0 | Audio private access wajib diuji |
| Media Guru | `/teacher/media` | Upload media/redirect | Form upload jika aktif | Upload Media | `POST /media` | File valid | P2 | Route kemungkinan redirect; verifikasi manual |
| Profil Guru | `/teacher/profile` | Update profil guru | Nama, email, status, phone | Simpan profil | `GET/PATCH /auth/me` | Guru approved | P1 | Password change tidak terlihat |

## Matrix Siswa

| Area Fitur | URL | Tujuan | Data yang Ditampilkan | Aksi/Tombol | Endpoint API | Data Seeder yang Dibutuhkan | Prioritas Testing | Catatan |
|---|---|---|---|---|---|---|---|---|
| Beranda Siswa | `/student/dashboard` | Ringkasan belajar | Summary modul/kuis/progres/kelas | Navigasi cepat jika ada | `GET /student/dashboard/summary` | Siswa dengan kelas dan progress | P0 | Test siswa tanpa kelas aktif |
| Modul Belajar | `/student/modules` | Daftar modul | Published modules, progress | Buka detail | `GET /student/modules` | Published class modules | P0 | Archived module tidak tampil |
| Detail Modul | `/student/modules/[moduleId]` | Detail modul | Modul, lessons, progress | Mulai Modul, buka lesson | Student module/progress endpoints | Module not_started/in_progress | P0 | Mulai disabled jika bukan not_started |
| Detail Lesson | `/student/lessons/[lessonId]` | Baca materi | Konten lesson, media, status | Tandai Selesai | Lesson detail/progress endpoints | Lesson published dengan media | P0 | Test akses media |
| Kamus | `/student/dictionary` | Search kamus | Kata, kategori, arti, audio, examples | Search/filter, detail | `GET /dictionary` | Entry kamus active | P0 | Audio/example perlu dicek |
| Detail Kamus | `/student/dictionary/[entryId]` | Detail kata | Kata, arti, audio, examples | Putar audio, kembali | `GET /dictionary/{id}` | Entry active dengan audio/examples | P1 | Inactive harus tidak tampil |
| Latihan Speaking | `/student/speaking` | Submit speaking | Exercises, reference audio, attempts | Pilih, record start/stop, submit | Student speaking endpoints | Published exercises, microphone | P0 | Browser permission critical |
| Hasil Speaking | `/student/speaking/results` | Riwayat speaking | Attempts, skor, feedback | Buka detail jika ada | `GET /student/speaking/attempts` | Speaking attempts success/failed | P1 | Failed AI state perlu diuji |
| Kuis | `/student/quizzes` | Daftar kuis | Published quizzes, jadwal, attempts | Buka detail/lanjut/hasil | `GET /student/quizzes` | Published class quizzes | P0 | Expired/attempt limit |
| Detail Kuis | `/student/quizzes/[quizId]` | Mulai kuis | Detail quiz, limit, jadwal | Mulai Kuis | Student quiz detail/start endpoints | Quiz available | P0 | Disabled jika limit reached |
| Attempt Kuis | `/student/quizzes/[quizId]/attempt` | Mengerjakan kuis | Pertanyaan, opsi, navigasi | Pilih jawaban, prev/next, submit | Save answer + submit endpoints | Active quiz attempt, questions | P0 | Refresh saat attempt perlu diuji |
| Hasil Kuis | `/student/quizzes/[quizId]/result` | Lihat hasil | Skor, status lulus, jawaban jika visible | Kembali | Quiz result/report endpoints | Submitted attempt | P0 | `show_result` mempengaruhi detail |
| Budaya Mekongga | `/student/culture` | Lihat budaya | Culture items media/link | Buka media/link | `GET /student/culture` | Published culture items | P1 | Test PDF/audio/link |
| Chatbot AI | `/student/chatbot` | Tanya chatbot | Chat, references, suggested questions | Kirim, suggested question, toggle reference | `POST /student/chatbot/message` | Published AI knowledge + dictionary | P0 | Fallback tanpa match |
| Progres Belajar | `/student/progress` | Laporan siswa | Progress modul/lesson/quiz | Filter/print jika ada | `/student/reports/progress`, `/student/reports/quiz-results` | Progress + quiz attempts | P0 | Best score calculation |
| Profil Siswa | `/student/profile` | Update profil | Nama, email, status, kelas, phone | Simpan profil | `GET/PATCH /auth/me` | Siswa approved | P1 | Password change tidak terlihat |

## Kebutuhan Seeder Berdasarkan Matrix

- Akun admin/guru/siswa: minimal 1 admin approved, 2 guru approved, 3 siswa approved; tambah user pending/rejected/inactive untuk approval/status testing.
- Sekolah: minimal 1 sekolah aktif dan 1 sekolah nonaktif jika UI filter/status perlu dites.
- Kelas: minimal 2 kelas aktif di sekolah sama/beda tahun ajaran.
- Assignment guru ke kelas: 1 guru assigned ke kelas A; 1 guru tanpa kelas untuk empty-state.
- Siswa dalam kelas: beberapa siswa di kelas A, minimal 1 siswa tanpa progress dan 1 siswa dengan progress lengkap.
- Kamus: kategori aktif, beberapa entry aktif, entry inactive untuk negative test, audio opsional.
- Contoh kalimat: contoh kalimat terkait `entry_code` untuk memastikan relasi import tampil di admin/siswa.
- Basis AI/chatbot knowledge: item draft, published, archived; minimal 1 published yang bisa dijawab chatbot.
- Modul: template modul admin draft/published, class module published/draft untuk guru/siswa.
- Materi: beberapa lesson dengan konten teks dan media/image; progress not_started/in_progress/completed.
- Kuis: template kuis admin, class quiz published, class quiz expired/attempt-limit untuk kondisi tombol.
- Soal kuis: multiple choice dengan minimal 2 opsi dan 1 jawaban benar; submitted attempt untuk hasil/report.
- Latihan speaking: admin template published/draft, teacher target published, reference audio, student attempts success/failed.
- Template budaya/culture: global culture item/template, class culture item published/draft/archived dengan image/pdf/audio/link.
- Progress/attempt: lesson progress, module progress, quiz attempts submitted, speaking attempts reviewed/unreviewed untuk laporan.
- Media: file image, audio, pdf kecil valid untuk upload dan preview; hindari file besar di repo.
- Settings: banner login image, activity log settings, security toggles saved.

## Prioritas Manual Testing

### 1. Admin flow
- [ ] P0 Login admin dan dashboard terbuka.
- [ ] P0 Approve/reject request guru/siswa pending.
- [ ] P0 CRUD sekolah/kelas dan assignment guru/siswa.
- [ ] P0 Manajemen user: filter, detail, status active/inactive.
- [ ] P0 Kamus: tambah kategori/kata, detail, audio, contoh kalimat.
- [ ] P0 Import kamus kosakata dan contoh kalimat: template, preview, confirm, history/errors.
- [ ] P0 Basis AI: create, publish, chatbot-ready knowledge.
- [ ] P0 Modul admin: create template, lesson, publish/apply.
- [ ] P0 Kuis admin: create template, soal, publish/apply.
- [ ] P0 Progress admin: filter, detail, export.
- [ ] P0 Pengaturan admin: app settings, profile, banner login, security, password, activity log.
- [ ] P1 Speaking template admin: create/edit/archive/reference audio.
- [ ] P1 Budaya admin: create/publish/archive/delete/apply template.
- [ ] P2 Detail Basis AI dan edge state empty/error.

### 2. Guru flow
- [ ] P0 Login guru assigned dan dashboard terbuka.
- [ ] P0 Kelas guru scoped benar; IDOR kelas lain forbidden.
- [ ] P0 Daftar/detail siswa dan laporan progress guru.
- [ ] P0 Modul guru: edit/publish lesson, siswa bisa melihat.
- [ ] P0 Kuis guru: create/builder/publish/results.
- [ ] P0 Target speaking guru: create dari template, publish, archive.
- [ ] P0 Hasil speaking guru: review attempt dan simpan feedback.
- [ ] P1 Budaya guru: create/edit/publish/archive/delete item kelas.
- [ ] P1 Profil guru update.
- [ ] P2 Media guru/redirect `/teacher/media`.

### 3. Siswa flow
- [ ] P0 Login siswa dan dashboard terbuka.
- [ ] P0 Modul: mulai modul, buka lesson, tandai selesai.
- [ ] P0 Kamus: search, detail, audio, contoh kalimat.
- [ ] P0 Speaking: lihat target, record, submit, lihat hasil.
- [ ] P0 Kuis: detail, start attempt, jawab, submit, result.
- [ ] P0 Chatbot: pertanyaan dictionary dan basis AI, fallback.
- [ ] P0 Progress siswa: modul/lesson/quiz tercermin.
- [ ] P1 Budaya siswa: media/link tampil.
- [ ] P1 Profil siswa update.
- [ ] P2 Empty state siswa tanpa kelas/progress.
