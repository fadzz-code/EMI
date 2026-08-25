# Audit Role, URL, dan Aksi EMI

## Ringkasan Role

### Admin
Admin mengelola approval akun, sekolah/kelas, guru/siswa, kamus, basis AI, template modul, template kuis, template speaking, konten budaya global, laporan progres, dan pengaturan sistem. Admin juga punya akses upload media untuk kebutuhan konten dan banner login.

### Guru
Guru mengelola kelas yang ditugaskan, siswa di kelasnya, progres siswa, modul kelas, kuis kelas, budaya kelas, target speaking, hasil speaking, upload media pembelajaran, dan profil sendiri. Scope data bergantung pada kelas aktif guru.

### Siswa
Siswa mengakses dashboard belajar, modul/lesson, kamus, latihan speaking, kuis, budaya Mekongga, chatbot AI, laporan progres, hasil speaking, dan profil sendiri. Scope data bergantung pada membership kelas aktif siswa.

## Audit Admin

### Beranda Admin
- URL: `/admin/dashboard`
- Tujuan halaman: Ringkasan metrik admin.
- Data yang tampil: Ringkasan dashboard admin, progres sekolah/kelas/siswa, tren/report cards. Detail field perlu verifikasi manual.
- Aksi/tombol: Navigasi ke area admin lain jika ada di kartu dashboard. Perlu verifikasi manual.
- Form/input: Tidak terlihat dari route; kemungkinan filter ringkasan terbatas. Perlu verifikasi manual.
- Endpoint API terkait: `GET /api/v1/admin/dashboard/summary`, report progress endpoints melalui `progress-service`.
- Kondisi khusus: Role admin via protected route.
- Catatan: Cocok jadi halaman smoke test setelah login admin.

### Persetujuan Akun
- URL: `/admin/approvals`
- Tujuan halaman: Review request registrasi guru/siswa.
- Data yang tampil: Daftar registration requests, role, status, identitas pemohon, sekolah/kelas terkait, hitungan pending.
- Aksi/tombol: Filter role/status/search, buka detail, approve, reject.
- Form/input: Search, filter role/status, dialog alasan reject.
- Endpoint API terkait: `GET /api/v1/admin/registration-requests`, `POST /api/v1/admin/registration-requests/{id}/approve`, `POST /api/v1/admin/registration-requests/{id}/reject`.
- Kondisi khusus: Tombol approve/reject hanya relevan untuk request pending; detail implementasi tombol perlu verifikasi manual.
- Catatan: Manual test konflik kelas guru aktif dan request sudah diproses.

### Detail Persetujuan
- URL: `/admin/approvals/[requestId]`
- Tujuan halaman: Melihat detail request dan memproses approval/rejection.
- Data yang tampil: Identitas pemohon, role, sekolah/kelas tujuan, status request.
- Aksi/tombol: Approve, reject, kembali.
- Form/input: Dialog reject dengan alasan.
- Endpoint API terkait: `GET /api/v1/admin/registration-requests/{id}`, approve/reject endpoints.
- Kondisi khusus: Aksi harus nonaktif/tidak tampil jika request bukan pending. Perlu verifikasi manual.
- Catatan: Cek pesan error saat request sudah diproses user lain.

### Sekolah & Kelas
- URL: `/admin/schools-classes`
- Tujuan halaman: CRUD sekolah dan kelas.
- Data yang tampil: Daftar sekolah, daftar kelas, status aktif, relasi sekolah, tahun ajaran.
- Aksi/tombol: Tambah sekolah, tambah kelas, edit, nonaktif/hapus sesuai implementasi.
- Form/input: Nama sekolah, NPSN/alamat/status jika tersedia; nama kelas, sekolah, tingkat, tahun ajaran, status.
- Endpoint API terkait: `GET/POST/PUT/DELETE /api/v1/schools`, `GET/POST/PUT/DELETE /api/v1/classes`.
- Kondisi khusus: Deaktivasi sekolah/kelas bisa ditolak jika masih punya kelas/assignment aktif sesuai backend tests.
- Catatan: Perlu verifikasi manual untuk label tombol delete vs deactivate.

### Detail Kelas Admin
- URL: `/admin/classes/[classId]`
- Tujuan halaman: Detail kelas dan assignment guru/siswa.
- Data yang tampil: Detail kelas, sekolah, guru aktif, daftar siswa.
- Aksi/tombol: Assign/reassign guru, assign/move siswa, buka user/detail jika tersedia.
- Form/input: Pilih guru, pilih siswa.
- Endpoint API terkait: `GET /api/v1/classes/{id}`, `POST /api/v1/classes/{id}/assign-teacher`, `POST /api/v1/classes/{id}/assign-student`, `GET /api/v1/classes/{id}/students`.
- Kondisi khusus: Satu kelas hanya satu guru aktif; satu siswa satu membership aktif.
- Catatan: Manual test assignment history dan konflik aktif.

### Guru & Siswa
- URL: `/admin/users`
- Tujuan halaman: Manajemen user.
- Data yang tampil: Daftar user, role, status, email, sekolah/kelas terkait.
- Aksi/tombol: Filter/search, buka detail, update user, ubah status.
- Form/input: Search, filter role/status/school/class; form edit user.
- Endpoint API terkait: `GET /api/v1/users`, `GET /api/v1/users/{id}`, `PUT /api/v1/users/{id}`, `PATCH /api/v1/users/{id}/status`.
- Kondisi khusus: Admin safety: tidak boleh menonaktifkan admin terakhir/akun sendiri jika dicegah backend. Perlu verifikasi manual.
- Catatan: Cek token revoked saat user dinonaktifkan.

### Detail User
- URL: `/admin/users/[userId]`
- Tujuan halaman: Melihat dan mengubah detail user.
- Data yang tampil: Profil user, role, status, assignment/membership.
- Aksi/tombol: Simpan perubahan, ubah status, kembali.
- Form/input: Nama, telepon, data user lain sesuai form.
- Endpoint API terkait: `GET /api/v1/users/{id}`, `PUT /api/v1/users/{id}`, `PATCH /api/v1/users/{id}/status`.
- Kondisi khusus: Field tertentu bisa read-only tergantung role/status. Perlu verifikasi manual.
- Catatan: Pastikan email tidak bisa diganti sembarang jika backend melarang.

### Kamus Admin
- URL: `/admin/dictionary`
- Tujuan halaman: CRUD kategori dan entri kamus.
- Data yang tampil: Daftar entri, kategori, kata, terjemahan, status, audio, contoh kalimat.
- Aksi/tombol: Tambah kategori, tambah kata, search/filter, buka detail, hapus entri.
- Form/input: Kategori, kata Mekongga/Indonesia, definisi/terjemahan, status, audio upload.
- Endpoint API terkait: `GET/POST /api/v1/admin/dictionary/categories`, `GET/POST/PUT/DELETE /api/v1/admin/dictionary/entries`, `POST /api/v1/media` untuk audio.
- Kondisi khusus: Kategori dengan entri aktif tidak bisa dinonaktifkan; duplikat ditolak.
- Catatan: Hapus kemungkinan soft delete. Perlu verifikasi manual.

### Detail Kamus
- URL: `/admin/dictionary/[entryId]`
- Tujuan halaman: Melihat/mengubah detail entri kamus.
- Data yang tampil: Detail kata, kategori, audio, contoh kalimat.
- Aksi/tombol: Edit/simpan, upload/lepas audio jika tersedia.
- Form/input: Form entri kamus.
- Endpoint API terkait: `GET /api/v1/admin/dictionary/entries/{id}`, `PUT /api/v1/admin/dictionary/entries/{id}`, media upload.
- Kondisi khusus: Validasi duplikat kata/kategori.
- Catatan: Pastikan contoh kalimat hasil import tampil.

### Import Kamus
- URL: `/admin/dictionary/import`
- Tujuan halaman: Import CSV Kosakata dan CSV Contoh Kalimat.
- Data yang tampil: Dua kartu import, template download, preview row, errors, import history.
- Aksi/tombol: Download template, upload CSV/ZIP audio, preview, confirm import, lihat errors/history.
- Form/input: Jenis import, CSV, ZIP audio opsional, duplicate strategy.
- Endpoint API terkait: `GET /api/v1/admin/dictionary/imports/{import_type}/template`, `POST /api/v1/admin/dictionary/imports/preview`, `GET /api/v1/admin/dictionary/imports`, `GET /api/v1/admin/dictionary/imports/{id}`, `GET /api/v1/admin/dictionary/imports/{id}/errors`, `POST /api/v1/admin/dictionary/imports/{id}/confirm`.
- Kondisi khusus: Contoh kalimat wajib cocok `entry_code`; audio matching exact filename; confirm dispatch job.
- Catatan: Manual test CSV encoding/header, ZIP traversal, duplicate strategy.

### Basis AI
- URL: `/admin/knowledge-base`
- Tujuan halaman: CRUD knowledge base untuk chatbot.
- Data yang tampil: Daftar knowledge item, status draft/published/archived, source, preview.
- Aksi/tombol: Tambah Pengetahuan, preview, edit, publish, archive, delete, filter/search.
- Form/input: Title, content/manual text, source URL, PDF upload/extract/import, status.
- Endpoint API terkait: `GET/POST/PUT/DELETE /api/v1/admin/ai/knowledge`, `POST /api/v1/admin/ai/knowledge/{id}/publish`, `POST /api/v1/admin/ai/knowledge/{id}/archive`, `POST /api/v1/admin/ai/knowledge/extract-source`, `POST /api/v1/admin/ai/knowledge/extract-pdf-upload`, `POST /api/v1/admin/ai/knowledge/import-pdf`.
- Kondisi khusus: URL extraction menolak private/localhost; PDF empty gagal; published item dicari chatbot.
- Catatan: Manual test source URL publik dan PDF multi-page.

### Detail Basis AI
- URL: `/admin/knowledge-base/[knowledgeId]`
- Tujuan halaman: Detail knowledge item.
- Data yang tampil: Detail title/content/source/status/chunks jika ada.
- Aksi/tombol: Edit/publish/archive/delete jika tersedia. Perlu verifikasi manual.
- Form/input: Perlu verifikasi manual.
- Endpoint API terkait: `GET /api/v1/admin/ai/knowledge/{id}`, update/status/delete endpoints.
- Kondisi khusus: Status mempengaruhi visibilitas chatbot.
- Catatan: Perlu verifikasi manual isi detail.

### Modul Admin
- URL: `/admin/modules`
- Tujuan halaman: CRUD template modul dan lesson.
- Data yang tampil: Daftar module templates, status, lesson count.
- Aksi/tombol: Tambah modul, edit, publish/archive/delete, apply template jika tersedia.
- Form/input: Judul, deskripsi, kelas/level, status, urutan.
- Endpoint API terkait: `GET/POST/PUT/DELETE /api/v1/admin/module-templates`, `POST /api/v1/admin/module-templates/{id}/publish`, `POST /api/v1/admin/module-templates/{id}/archive`, `POST /api/v1/admin/module-templates/{id}/apply`.
- Kondisi khusus: Template published bisa diterapkan ke kelas.
- Catatan: Perlu verifikasi manual apply template dari UI.

### Edit Modul Admin
- URL: `/admin/modules/[moduleId]/edit`
- Tujuan halaman: Mengedit module template dan lesson template.
- Data yang tampil: Detail modul, daftar lesson.
- Aksi/tombol: Simpan modul, publish, tambah/edit/hapus lesson, upload media lesson.
- Form/input: Form modul, form lesson, file media/image, urutan lesson.
- Endpoint API terkait: Module template endpoints, `GET/POST /api/v1/admin/module-templates/{module_template_id}/lessons`, `PUT/DELETE /api/v1/admin/lesson-templates/{id}`, `PATCH /api/v1/admin/module-templates/{id}/lessons/reorder`, media upload.
- Kondisi khusus: Publish/archive status mempengaruhi apply.
- Catatan: Manual test reorder lesson.

### Kuis Admin
- URL: `/admin/quizzes`
- Tujuan halaman: CRUD template kuis.
- Data yang tampil: Daftar quiz templates, status, jumlah soal.
- Aksi/tombol: Tambah kuis, edit/builder, publish/archive/delete, apply template.
- Form/input: Judul, deskripsi, passing score, max attempts, show result, status.
- Endpoint API terkait: `GET/POST/PUT/DELETE /api/v1/admin/quiz-templates`, `POST /api/v1/admin/quiz-templates/{id}/publish`, `POST /api/v1/admin/quiz-templates/{id}/archive`, `POST /api/v1/admin/quiz-templates/{id}/apply`.
- Kondisi khusus: Template published bisa diterapkan ke kelas.
- Catatan: Perlu verifikasi manual lock setelah published/applied.

### Builder Kuis Admin
- URL: `/admin/quizzes/[quizId]/builder`
- Tujuan halaman: Mengelola soal template kuis.
- Data yang tampil: Detail kuis, daftar soal, pilihan jawaban, kunci.
- Aksi/tombol: Simpan kuis, publish, tambah/edit/hapus soal, tambah/hapus opsi, upload/lepas gambar.
- Form/input: Pertanyaan, tipe soal, opsi, jawaban benar, bobot, gambar.
- Endpoint API terkait: Quiz template endpoints, `GET/POST /api/v1/admin/quiz-templates/{quiz_template_id}/questions`, `PUT/DELETE /api/v1/admin/quiz-template-questions/{id}`, `PATCH /api/v1/admin/quiz-templates/{id}/questions/reorder`, media upload.
- Kondisi khusus: Soal bisa locked saat template published/applied. Perlu verifikasi manual.
- Catatan: Manual test minimal opsi dan satu jawaban benar.

### Template Speaking Admin
- URL: `/admin/speaking/exercises`
- Tujuan halaman: CRUD template speaking global.
- Data yang tampil: Daftar speaking exercise/template, status, reference audio.
- Aksi/tombol: Tambah, edit, archive, upload audio referensi.
- Form/input: Judul, instruksi, prompt/target text, status, reference audio.
- Endpoint API terkait: `GET/POST /api/v1/admin/speaking/exercises`, `GET /api/v1/admin/speaking/exercises/{exercise}`, `PUT/PATCH /api/v1/admin/speaking/exercises/{exercise}`, `PATCH /api/v1/admin/speaking/exercises/{exercise}/archive`, media upload.
- Kondisi khusus: Draft/archived tidak muncul sebagai template guru.
- Catatan: Jangan ubah fitur speaking; audit saja.

### Budaya Mekongga Admin
- URL: `/admin/culture/templates`
- Tujuan halaman: CRUD konten budaya global dan template budaya.
- Data yang tampil: Daftar konten budaya/template, status, media/link.
- Aksi/tombol: Tambah Konten Budaya, edit, terbitkan, arsipkan, hapus.
- Form/input: Judul, deskripsi, tipe konten, file/URL, urutan, status.
- Endpoint API terkait: `GET/POST/PUT/DELETE /api/v1/admin/culture/items`, `POST /api/v1/admin/culture/items/{group_id}/publish`, `POST /api/v1/admin/culture/items/{group_id}/archive`, `GET/POST /api/v1/admin/culture-templates`, media upload.
- Kondisi khusus: Delete admin global culture berdampak ke semua kelas menurut teks UI.
- Catatan: Manual test konfirmasi hapus.

### Edit Template Budaya
- URL: `/admin/culture/templates/[cultureTemplateId]/edit`
- Tujuan halaman: Mengedit template budaya dan item budaya.
- Data yang tampil: Detail template, daftar item.
- Aksi/tombol: Simpan template, terbitkan template, terapkan ke kelas, tambah/edit/hapus item.
- Form/input: Nama/deskripsi/status template, pilih kelas, form item budaya.
- Endpoint API terkait: `GET/PUT/DELETE /api/v1/admin/culture-templates/{id}`, `POST /api/v1/admin/culture-templates/{id}/publish`, `POST /api/v1/admin/culture-templates/{id}/apply`, `POST /api/v1/admin/culture-templates/{culture_template_id}/items`, item endpoints.
- Kondisi khusus: Apply disabled jika template belum published.
- Catatan: Page route saat ini redirect? Perlu verifikasi manual karena `page.tsx` import `redirect`.

### Progress Admin
- URL: `/admin/progress`
- Tujuan halaman: Laporan progres sekolah/kelas/siswa.
- Data yang tampil: Ringkasan dashboard, tabel progress sekolah, kelas, siswa.
- Aksi/tombol: Filter periode/school/class, export CSV, buka detail kelas/siswa, print/report jika tersedia.
- Form/input: Filter laporan.
- Endpoint API terkait: `GET /api/v1/admin/reports/progress/schools`, `GET /api/v1/admin/reports/progress/classes`, `GET /api/v1/admin/reports/progress/students`, export endpoints.
- Kondisi khusus: Export sanitasi formula CSV di backend tests.
- Catatan: Manual test filter scope dan export.

### Detail Progress Kelas
- URL: `/admin/progress/classes/[classId]`
- Tujuan halaman: Detail progress kelas.
- Data yang tampil: Ringkasan kelas, siswa, progres modul/kuis.
- Aksi/tombol: Print/export/buka siswa jika tersedia.
- Form/input: Filter periode. Perlu verifikasi manual.
- Endpoint API terkait: Progress report endpoints dengan `class_id`.
- Kondisi khusus: Hanya admin.
- Catatan: Perlu verifikasi manual data kosong.

### Detail Progress Siswa
- URL: `/admin/progress/students/[studentId]`
- Tujuan halaman: Detail progress siswa.
- Data yang tampil: Profil siswa, progres modul, kuis, skor.
- Aksi/tombol: Print report jika tersedia.
- Form/input: Filter periode. Perlu verifikasi manual.
- Endpoint API terkait: `GET /api/v1/admin/reports/progress/students` dengan filter student.
- Kondisi khusus: Hanya admin.
- Catatan: Perlu verifikasi manual kalkulasi progress.

### Pengaturan Admin
- URL: `/admin/settings`
- Tujuan halaman: Mengelola Profil Admin, Banner Login, Ubah Password, dan Aktivitas terbaru.
- Data yang tampil: Profil Admin, preview Banner Login, dan Aktivitas terbaru.
- Aksi/tombol: Simpan Profil, upload banner, Aktifkan Banner, Simpan Banner, Ubah Password.
- Form/input: Full name, phone, banner file, enabled banner, password lama/baru/konfirmasi.
- Endpoint API terkait: `GET /api/v1/admin/settings` untuk `banner` dan `activity_logs`, `POST /api/v1/admin/settings/banner`, `GET/PATCH /api/v1/auth/me`, `PUT /api/v1/auth/password`, public `GET /api/v1/public/login-branding`.
- Kondisi khusus: Email/status read-only; banner public tidak expose setting internal.

## Audit Guru

### Beranda Guru
- URL: `/teacher/dashboard`
- Tujuan halaman: Ringkasan aktivitas guru.
- Data yang tampil: Summary kelas, siswa, modul/kuis/progres. Detail perlu verifikasi manual.
- Aksi/tombol: Navigasi cepat jika tersedia.
- Form/input: Tidak terlihat.
- Endpoint API terkait: `GET /api/v1/teacher/dashboard/summary`.
- Kondisi khusus: Data scope kelas aktif guru.
- Catatan: Test guru tanpa kelas aktif.

### Kelas Guru
- URL: `/teacher/classes`
- Tujuan halaman: Daftar kelas yang diampu.
- Data yang tampil: Kelas, sekolah, jumlah siswa, status.
- Aksi/tombol: Buka detail kelas, tab siswa/modul/kuis/budaya.
- Form/input: Search/filter jika tersedia. Perlu verifikasi manual.
- Endpoint API terkait: `GET /api/v1/classes` scoped guru.
- Kondisi khusus: Guru hanya melihat kelas sendiri.
- Catatan: IDOR kelas harus forbidden.

### Detail Kelas Guru
- URL: `/teacher/classes/[classId]`
- Tujuan halaman: Ringkasan kelas.
- Data yang tampil: Detail kelas, sekolah, statistik siswa/modul/kuis.
- Aksi/tombol: Navigasi ke Siswa, Modul, Kuis, Budaya.
- Form/input: Tidak utama.
- Endpoint API terkait: `GET /api/v1/classes/{id}` scoped guru.
- Kondisi khusus: Harus assigned teacher.
- Catatan: UI menyebut detail kelas sebagai ringkasan cepat.

### Siswa Kelas Guru
- URL: `/teacher/classes/[classId]/students`
- Tujuan halaman: Daftar siswa dalam kelas.
- Data yang tampil: Siswa kelas, status/progres ringkas.
- Aksi/tombol: Buka detail siswa.
- Form/input: Search/filter jika tersedia.
- Endpoint API terkait: `GET /api/v1/classes/{id}/students`.
- Kondisi khusus: Scope kelas guru.
- Catatan: Perlu verifikasi manual pagination.

### Modul Kelas Guru
- URL: `/teacher/classes/[classId]/modules`
- Tujuan halaman: Kelola modul untuk kelas tertentu.
- Data yang tampil: Class modules, status, urutan, lessons.
- Aksi/tombol: Tambah/terapkan template modul, edit, publish/archive/delete, reorder jika ada.
- Form/input: Judul/deskripsi/status/urutan, pilih template.
- Endpoint API terkait: `GET/POST /api/v1/classes/{class_id}/modules`, `GET/PUT/DELETE /api/v1/class-modules/{id}`, `POST /api/v1/class-modules/{id}/publish`, `POST /api/v1/class-modules/{id}/archive`, reorder.
- Kondisi khusus: Guru harus assigned ke class.
- Catatan: Ada route global `/teacher/modules` juga.

### Kuis Kelas Guru
- URL: `/teacher/classes/[classId]/quizzes`
- Tujuan halaman: Kelola kuis untuk kelas tertentu.
- Data yang tampil: Class quizzes, status, attempt settings.
- Aksi/tombol: Tambah/terapkan template kuis, buka builder, lihat results.
- Form/input: Judul, jadwal, max attempts, visibility, passing score.
- Endpoint API terkait: `GET/POST /api/v1/class-quizzes`, `GET/PUT/DELETE /api/v1/class-quizzes/{id}`, publish/archive, question endpoints.
- Kondisi khusus: Guru scope class.
- Catatan: Perlu verifikasi manual locked after attempts.

### Budaya Kelas Guru
- URL: `/teacher/classes/[classId]/culture`
- Tujuan halaman: Kelola konten budaya kelas.
- Data yang tampil: Konten budaya kelas, status, file/URL.
- Aksi/tombol: Edit, publish, arsipkan, hapus.
- Form/input: Judul, deskripsi, tipe konten, file/URL, urutan, status.
- Endpoint API terkait: `GET/POST /api/v1/classes/{class_id}/culture`, `GET/PUT/DELETE /api/v1/class-culture-items/{id}`, publish/archive, media upload.
- Kondisi khusus: Page route mungkin redirect ke `/teacher/culture`; perlu verifikasi manual karena `page.tsx` import `redirect`.
- Catatan: Ada dua UI budaya guru: class-scoped dan global list.

### Siswa Guru
- URL: `/teacher/students`
- Tujuan halaman: Daftar siswa yang diajar guru.
- Data yang tampil: Siswa, kelas, sekolah, progres ringkas.
- Aksi/tombol: Search/filter, buka detail siswa.
- Form/input: Search/filter.
- Endpoint API terkait: Teacher/student report endpoints; likely `GET /api/v1/admin/reports/progress/students` tidak dipakai guru, frontend service perlu verifikasi manual.
- Kondisi khusus: Scope siswa dari kelas aktif guru.
- Catatan: Perlu verifikasi endpoint pasti dari `teacher-service` detail.

### Detail Siswa Guru
- URL: `/teacher/students/[studentId]`
- Tujuan halaman: Melihat detail progres siswa.
- Data yang tampil: Profil siswa, progress modul/kuis.
- Aksi/tombol: Buka laporan/detail jika tersedia.
- Form/input: Tidak utama.
- Endpoint API terkait: `GET /api/v1/teacher/reports/progress/students` atau endpoint report terkait. Perlu verifikasi manual.
- Kondisi khusus: Hanya siswa dari kelas guru.
- Catatan: IDOR siswa perlu diuji.

### Laporan Progress Guru
- URL: `/teacher/reports/progress`
- Tujuan halaman: Laporan progress kelas/siswa guru.
- Data yang tampil: Progress kelas dan siswa, filter periode.
- Aksi/tombol: Filter, export jika tersedia.
- Form/input: Filter class/student/period.
- Endpoint API terkait: `GET /api/v1/teacher/reports/progress/classes`, `GET /api/v1/teacher/reports/progress/students`, export jika ada.
- Kondisi khusus: Scope guru.
- Catatan: Perlu verifikasi manual export.

### Modul Guru
- URL: `/teacher/modules`
- Tujuan halaman: Kelola semua modul kelas milik guru.
- Data yang tampil: Class modules lintas kelas.
- Aksi/tombol: Edit, publish/archive/delete, buka lesson edit.
- Form/input: Filter kelas, form modul.
- Endpoint API terkait: Class module endpoints.
- Kondisi khusus: Guru hanya kelasnya.
- Catatan: Route `/teacher/media` redirect ke modules menurut page import.

### Edit Modul Guru
- URL: `/teacher/modules/[classModuleId]/edit`
- Tujuan halaman: Edit class module.
- Data yang tampil: Detail module dan lessons.
- Aksi/tombol: Simpan, publish, tambah/edit lesson.
- Form/input: Judul/deskripsi/status/urutan.
- Endpoint API terkait: `GET/PUT /api/v1/class-modules/{id}`, `POST /api/v1/class-modules/{id}/publish`, lessons endpoints.
- Kondisi khusus: Publish button hanya jika belum published.
- Catatan: Perlu verifikasi archive/delete UI.

### Edit Lesson Guru
- URL: `/teacher/modules/[classModuleId]/lessons/[classLessonId]/edit`
- Tujuan halaman: Edit lesson kelas.
- Data yang tampil: Konten lesson, media.
- Aksi/tombol: Simpan, publish, upload media, lepas media.
- Form/input: Title, content/body, media file, status.
- Endpoint API terkait: `GET/PUT /api/v1/class-lessons/{id}`, `POST /api/v1/class-lessons/{id}/publish`, media upload.
- Kondisi khusus: Guru assigned.
- Catatan: Manual test file size/mime.

### Kuis Guru
- URL: `/teacher/quizzes`
- Tujuan halaman: Kelola semua class quizzes guru.
- Data yang tampil: Daftar kuis kelas, status, jadwal, attempts.
- Aksi/tombol: Buat Kuis, buka builder, lihat hasil.
- Form/input: Form create quiz: class, title, schedule/settings.
- Endpoint API terkait: `GET/POST /api/v1/class-quizzes`.
- Kondisi khusus: Disable create jika tidak ada class default.
- Catatan: UI create lalu buka builder.

### Builder Kuis Guru
- URL: `/teacher/quizzes/[classQuizId]/builder`
- Tujuan halaman: Edit class quiz dan soal.
- Data yang tampil: Quiz detail, questions/options.
- Aksi/tombol: Simpan, publish, edit/hapus soal, tambah opsi, upload gambar.
- Form/input: Metadata quiz, question form, options.
- Endpoint API terkait: Class quiz and quiz question endpoints, media upload.
- Kondisi khusus: Jika locked, tombol edit/hapus soal disabled; publish hanya jika belum locked/published.
- Catatan: Manual test attempt existing menyebabkan lock.

### Hasil Kuis Guru
- URL: `/teacher/quizzes/[classQuizId]/results`
- Tujuan halaman: Melihat hasil kuis siswa.
- Data yang tampil: Attempts, skor, status, detail jawaban.
- Aksi/tombol: Lihat/Tutup Detail.
- Form/input: Search nama/email siswa.
- Endpoint API terkait: `GET /api/v1/class-quizzes/{id}/attempts` atau report quiz endpoints. Perlu verifikasi manual.
- Kondisi khusus: Scope class quiz guru.
- Catatan: Tidak terlihat aksi edit nilai.

### Budaya Guru
- URL: `/teacher/culture`
- Tujuan halaman: Kelola konten budaya kelas guru.
- Data yang tampil: Daftar culture items, status, media/link.
- Aksi/tombol: Kelola Media/Tambah, edit, publish, arsipkan, hapus dari kelas.
- Form/input: Judul, deskripsi, tipe konten, file/URL, urutan, status.
- Endpoint API terkait: Class culture endpoints, media upload.
- Kondisi khusus: Delete hanya dari kelas ini.
- Catatan: Perlu verifikasi class selector bila guru multi-class.

### Target Speaking Guru
- URL: `/teacher/speaking/exercises`
- Tujuan halaman: Kelola target speaking kelas dan gunakan template admin.
- Data yang tampil: Template speaking global, target speaking kelas, status, reference audio.
- Aksi/tombol: Buat Target, edit, archive, pilih template.
- Form/input: Class, template, judul, instruksi, prompt, status, reference audio.
- Endpoint API terkait: `GET /api/v1/teacher/speaking/templates`, `GET/POST /api/v1/teacher/speaking/exercises`, `PUT/PATCH /api/v1/teacher/speaking/exercises/{exercise}`, archive endpoint, media upload.
- Kondisi khusus: Tombol create disabled jika guru tidak punya class.
- Catatan: Jangan ubah fitur speaking; manual test template draft tidak boleh dipakai.

### Hasil Speaking Guru
- URL: `/teacher/speaking/results`
- Tujuan halaman: Review speaking attempts siswa.
- Data yang tampil: Attempts, skor AI, audio, transcript/feedback.
- Aksi/tombol: Pilih attempt, simpan feedback guru.
- Form/input: Feedback/review guru.
- Endpoint API terkait: `GET /api/v1/teacher/speaking/attempts`, review endpoint terkait. Perlu verifikasi manual route exact.
- Kondisi khusus: Guru hanya review siswa di kelasnya.
- Catatan: Test audio private access.

### Media Guru
- URL: `/teacher/media`
- Tujuan halaman: Upload media guru atau redirect.
- Data yang tampil: Jika halaman aktif, form upload media.
- Aksi/tombol: Upload Media.
- Form/input: File, purpose/visibility/metadata jika tersedia.
- Endpoint API terkait: `POST /api/v1/media`.
- Kondisi khusus: Page route import `redirect`; kemungkinan redirect ke modules.
- Catatan: Perlu verifikasi manual apakah URL masih reachable.

### Profil Guru
- URL: `/teacher/profile`
- Tujuan halaman: Update profil guru.
- Data yang tampil: Nama, email, role/status, phone.
- Aksi/tombol: Simpan profil.
- Form/input: Full name, phone; email/status read-only.
- Endpoint API terkait: `GET /api/v1/auth/me`, `PATCH /api/v1/auth/me`.
- Kondisi khusus: Profile scoped user sendiri.
- Catatan: Tidak terlihat ubah password di profil guru; password via settings hanya admin UI.

## Audit Siswa

### Beranda Siswa
- URL: `/student/dashboard`
- Tujuan halaman: Ringkasan aktivitas belajar siswa.
- Data yang tampil: Summary modul, kuis, progres, kelas aktif.
- Aksi/tombol: Navigasi cepat jika tersedia.
- Form/input: Tidak utama.
- Endpoint API terkait: `GET /api/v1/student/dashboard/summary`.
- Kondisi khusus: Butuh membership kelas aktif.
- Catatan: Test siswa tanpa kelas aktif.

### Modul Belajar
- URL: `/student/modules`
- Tujuan halaman: Daftar modul belajar siswa.
- Data yang tampil: Modul published untuk kelas siswa, progress status.
- Aksi/tombol: Buka detail modul.
- Form/input: Search/filter jika tersedia. Perlu verifikasi manual.
- Endpoint API terkait: `GET /api/v1/student/modules`.
- Kondisi khusus: Hanya modul published/visible untuk kelas siswa.
- Catatan: Module archived jangan tampil.

### Detail Modul Siswa
- URL: `/student/modules/[moduleId]`
- Tujuan halaman: Detail modul dan daftar lesson.
- Data yang tampil: Judul/deskripsi modul, lesson list, progress.
- Aksi/tombol: Mulai Modul, buka lesson.
- Form/input: Tidak utama.
- Endpoint API terkait: `GET /api/v1/student/modules/{id}`, progress update endpoint.
- Kondisi khusus: Tombol Mulai disabled jika progress bukan `not_started`.
- Catatan: Perlu verifikasi exact endpoint progress dari service.

### Detail Lesson Siswa
- URL: `/student/lessons/[lessonId]`
- Tujuan halaman: Membaca lesson.
- Data yang tampil: Konten lesson, media/content URL, status progress.
- Aksi/tombol: Tandai Selesai.
- Form/input: Tidak ada.
- Endpoint API terkait: `GET /api/v1/student/lessons/{id}` atau `GET /api/v1/class-lessons/{id}/content-url`, update lesson progress endpoint. Perlu verifikasi manual.
- Kondisi khusus: Lesson harus bagian dari modul kelas siswa.
- Catatan: Test akses media private/public.

### Kamus Siswa
- URL: `/student/dictionary`
- Tujuan halaman: Search kamus Mekongga.
- Data yang tampil: Daftar kata, kategori, arti, audio indicator, contoh kalimat.
- Aksi/tombol: Search/filter, buka detail.
- Form/input: Search, filter category/status jika tersedia.
- Endpoint API terkait: `GET /api/v1/dictionary`.
- Kondisi khusus: Hanya entri active/public.
- Catatan: Manual test audio playback dan contoh kalimat.

### Detail Kamus Siswa
- URL: `/student/dictionary/[entryId]`
- Tujuan halaman: Detail kata kamus.
- Data yang tampil: Kata, arti, kategori, audio, contoh kalimat.
- Aksi/tombol: Putar audio jika ada, kembali.
- Form/input: Tidak ada.
- Endpoint API terkait: `GET /api/v1/dictionary/{id}`.
- Kondisi khusus: Entry inactive harus tidak tampil/404.
- Catatan: Perlu verifikasi fallback audio.

### Latihan Speaking Siswa
- URL: `/student/speaking`
- Tujuan halaman: Latihan speaking dan submit audio.
- Data yang tampil: Speaking exercises published untuk kelas/global, reference audio, attempts.
- Aksi/tombol: Pilih exercise, mulai/stop recording, submit attempt.
- Form/input: Browser audio recorder/file recorded.
- Endpoint API terkait: `GET /api/v1/student/speaking/exercises`, `GET /api/v1/student/speaking/attempts`, `POST /api/v1/student/speaking/attempts`.
- Kondisi khusus: Butuh permission microphone; submit disabled tanpa recording atau saat recording/submitting.
- Catatan: Manual test browser permission dan audio MIME.

### Hasil Speaking Siswa
- URL: `/student/speaking/results`
- Tujuan halaman: Melihat riwayat hasil speaking.
- Data yang tampil: Attempts, skor AI, feedback, status.
- Aksi/tombol: Buka detail jika tersedia.
- Form/input: Tidak utama.
- Endpoint API terkait: `GET /api/v1/student/speaking/attempts`.
- Kondisi khusus: Siswa hanya attempt miliknya.
- Catatan: Test failed AI attempt display.

### Kuis Siswa
- URL: `/student/quizzes`
- Tujuan halaman: Daftar kuis untuk siswa.
- Data yang tampil: Kuis class published, jadwal, attempt count, status.
- Aksi/tombol: Buka detail, lanjut/lihat hasil jika tersedia.
- Form/input: Filter jika ada. Perlu verifikasi manual.
- Endpoint API terkait: `GET /api/v1/student/quizzes`.
- Kondisi khusus: Kuis expired/attempt limit mempengaruhi tombol.
- Catatan: Manual test schedule max attempts.

### Detail Kuis Siswa
- URL: `/student/quizzes/[quizId]`
- Tujuan halaman: Detail kuis sebelum mulai.
- Data yang tampil: Judul, instruksi, jumlah soal, attempt limit, jadwal.
- Aksi/tombol: Mulai Kuis.
- Form/input: Tidak ada.
- Endpoint API terkait: `GET /api/v1/student/quizzes/{id}`, `POST /api/v1/class-quizzes/{id}/attempts` atau student start endpoint. Perlu verifikasi manual.
- Kondisi khusus: Tombol disabled jika `attempt_limit_reached`.
- Catatan: Test expired quiz.

### Attempt Kuis Siswa
- URL: `/student/quizzes/[quizId]/attempt`
- Tujuan halaman: Mengerjakan kuis.
- Data yang tampil: Pertanyaan, opsi, navigasi soal.
- Aksi/tombol: Pilih jawaban, Sebelumnya, Berikutnya, Submit.
- Form/input: Pilihan jawaban per soal.
- Endpoint API terkait: Save answer endpoint, submit attempt endpoint. Perlu verifikasi exact route dari service/backend.
- Kondisi khusus: Submit setelah answer; autosave/mutation per pilihan.
- Catatan: Manual test refresh saat attempt berjalan.

### Hasil Kuis Siswa
- URL: `/student/quizzes/[quizId]/result`
- Tujuan halaman: Melihat hasil kuis.
- Data yang tampil: Skor, status lulus, jawaban benar/salah jika visible.
- Aksi/tombol: Kembali ke daftar/detail.
- Form/input: Tidak ada.
- Endpoint API terkait: `GET /api/v1/student/reports/quiz-results` atau attempt detail endpoint. Perlu verifikasi manual.
- Kondisi khusus: `show_result` pada quiz mempengaruhi detail hasil.
- Catatan: Test hidden result.

### Budaya Mekongga Siswa
- URL: `/student/culture`
- Tujuan halaman: Melihat konten budaya kelas/published.
- Data yang tampil: Culture items, media/link/content.
- Aksi/tombol: Buka media/link jika tersedia.
- Form/input: Tidak ada.
- Endpoint API terkait: `GET /api/v1/student/culture`.
- Kondisi khusus: Hanya published culture untuk kelas siswa.
- Catatan: Test file/pdf/audio/link content.

### Chatbot AI Siswa
- URL: `/student/chatbot`
- Tujuan halaman: Tanya jawab berbasis kamus dan basis AI.
- Data yang tampil: Chat messages, sumber/reference, suggested questions.
- Aksi/tombol: Kirim pertanyaan, klik suggested question, toggle reference.
- Form/input: Textarea/input pertanyaan.
- Endpoint API terkait: `POST /api/v1/student/chatbot/message`.
- Kondisi khusus: Dictionary intent short-circuit; basis AI hanya published.
- Catatan: Manual test fallback tanpa knowledge match.

### Progres Belajar Siswa
- URL: `/student/progress`
- Tujuan halaman: Laporan progres siswa.
- Data yang tampil: Progress modul/lesson, skor kuis, ringkasan.
- Aksi/tombol: Filter/print jika tersedia. Perlu verifikasi manual.
- Form/input: Filter periode jika ada.
- Endpoint API terkait: `GET /api/v1/student/reports/progress`, `GET /api/v1/student/reports/quiz-results`.
- Kondisi khusus: Data user sendiri.
- Catatan: Manual test kalkulasi best score.

### Profil Siswa
- URL: `/student/profile`
- Tujuan halaman: Update profil siswa.
- Data yang tampil: Nama, email, role/status, kelas aktif, phone.
- Aksi/tombol: Simpan profil.
- Form/input: Full name, phone; email/status read-only.
- Endpoint API terkait: `GET /api/v1/auth/me`, `PATCH /api/v1/auth/me`.
- Kondisi khusus: User hanya update profil sendiri.
- Catatan: Tidak terlihat ubah password di profil siswa.

## Catatan Umum
- Public/auth URL yang ada: `/`, `/login`, `/register`, `/register/student`, `/register/teacher`, `/pending-approval`, `/unauthorized`.
- Navigasi role utama bersumber dari `Emi-Frontend/src/lib/routes.ts`; mobile drawer memakai item yang sama dengan desktop dan quick bottom nav memakai subset.
- Redirect role root: `/admin` ke `/admin/dashboard`, `/teacher` ke `/teacher/dashboard`, `/student` ke `/student/dashboard`.
- Endpoint protected memakai Sanctum; admin group memakai `auth:sanctum` + `role:admin`; guru/siswa scope dikontrol controller/policy/service.
- Fitur read-only yang sebelumnya ada pada Pengaturan Admin sudah aktif; yang masih perlu verifikasi manual: beberapa halaman detail/progress/export, exact endpoint attempt kuis, route redirect budaya/media guru, dan tombol yang muncul berdasarkan status locked/published/pending.
- Manual testing penting: IDOR antar role, akses media public/private, status draft/published/archived, max attempt kuis, CSV formula/export, upload MIME/size, browser microphone permission, dan empty-state saat user tidak punya kelas aktif.
- Jangan masukkan data demo/secret pada dokumentasi user-facing; placeholder login sudah production-safe.
