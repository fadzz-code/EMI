# AGENTS.md — EMI (Elearning Mekongga Indonesia)

Dokumen ini berisi instruksi wajib untuk seluruh agent coding yang bekerja pada repository EMI.

## 1. Identitas Proyek

- Nama produk: **EMI — Elearning Mekongga Indonesia**
- Bahasa antarmuka pengguna: **Bahasa Indonesia**
- Backend: **Laravel 12 REST API**
- PHP: **8.2.x**
- Database: **PostgreSQL 16.x**
- Authentication: **Laravel Sanctum**
- Web: **Next.js + TypeScript + Tailwind CSS**
- Mobile: **Flutter + SQLite**
- Voice engine: **Python FastAPI**
- AI chatbot: **RAG menggunakan basis pengetahuan EMI**
- Media: **Object storage/S3-compatible storage**
- Primary key utama: **UUID**

Jangan mengubah nama produk menjadi “EMI Learning”.

---

## 2. Struktur Repository

Struktur target:

```text
EMI/
├── AGENTS.md
├── Docs/
│   ├── 01-ERD-Database.md
│   ├── 02-Role-Permission-Matrix.md
│   ├── 03-API-Specification.md
│   └── 04-Development-Plan.md
├── Emi-Backend/
├── Emi-Web/
├── Emi-Mobile/
├── Emi-Voice-Engine/
└── Emi-IoT/
```

Backend Laravel saat ini berada di:

```text
Emi-Backend/
```

---

## 3. Sumber Kebenaran

Sebelum mengubah kode, agent WAJIB membaca:

1. `Docs/01-ERD-Database.md`
2. `Docs/02-Role-Permission-Matrix.md`
3. `Docs/03-API-Specification.md`
4. `Docs/04-Development-Plan.md`
5. `AGENTS.md`

Urutan prioritas saat terjadi konflik:

1. Instruksi terbaru pengguna
2. `AGENTS.md`
3. `Docs/02-Role-Permission-Matrix.md`
4. `Docs/01-ERD-Database.md`
5. `Docs/03-API-Specification.md`
6. `Docs/04-Development-Plan.md`

Jika ada konflik yang tidak dapat diputuskan, jangan menebak. Laporkan konflik dan berhenti sebelum membuat perubahan besar.

---

## 4. Aturan Bisnis yang Tidak Boleh Diubah

Role hanya:

```text
admin
teacher
student
```

Aturan akun dan kelas:

1. Sekolah dan kelas hanya dibuat Admin.
2. Guru dan siswa mendaftar dengan memilih sekolah dan kelas.
3. Akun guru dan siswa harus disetujui Admin.
4. Admin tidak mendaftar melalui endpoint publik.
5. Satu akun guru hanya memiliki satu kelas aktif.
6. Satu kelas hanya memiliki satu guru aktif.
7. Satu siswa hanya memiliki satu kelas aktif.
8. Guru dan siswa tidak dapat memindahkan dirinya sendiri.
9. Admin dapat melihat dan mengelola seluruh sekolah dan kelas.
10. Guru hanya mengakses kelas aktifnya.
11. Siswa hanya mengakses kelas aktif dan data pribadinya.

Aturan modul:

1. Admin dapat membuat modul default.
2. Modul default disalin menjadi modul kelas.
3. Guru hanya mengedit salinan modul kelas.
4. Perubahan modul kelas tidak boleh mengubah template Admin.
5. Admin dapat mengelola modul seluruh kelas.

Aturan kuis:

1. Admin dapat membuat kuis default.
2. Kuis default disalin menjadi kuis kelas.
3. Guru hanya mengedit kuis kelasnya.
4. Tipe soal MVP: `multiple_choice` dan `short_answer`.
5. Soal dapat memiliki gambar.
6. Kunci jawaban tidak boleh pernah dikirim kepada siswa sebelum diizinkan.
7. Submit kuis harus idempotent.

Aturan kamus:

1. Kamus memiliki Bahasa Indonesia, Inggris, dan Mekongga.
2. Kamus memiliki kategori, contoh kalimat, dan audio referensi.
3. Import massal memakai CSV.
4. Audio massal memakai ZIP berisi MP3.
5. Kolom `audio_filename` harus cocok tepat dengan nama file MP3 dalam ZIP.
6. Import wajib memiliki preview dan daftar error sebelum konfirmasi.
7. Data invalid tidak boleh masuk ke database final.

Aturan AI:

1. Kamus dan basis pengetahuan chatbot berada di tabel terpisah.
2. Chatbot hanya memakai dokumen berstatus `verified`.
3. Chatbot tidak boleh mengarang fakta bahasa, sejarah, atau budaya.
4. Jika sumber tidak tersedia, jawab bahwa informasi belum tersedia.

Aturan mobile:

1. PostgreSQL adalah sumber data utama.
2. SQLite hanya untuk cache dan pending sync.
3. Chatbot dan analisis speaking tetap membutuhkan koneksi internet.
4. Setiap operasi offline memakai `client_operation_id` unik.

---

## 5. Aturan Teknis Backend

### 5.1 Gaya Arsitektur

Gunakan:

```text
Route
→ Form Request
→ Controller tipis
→ Service
→ Model/Repository bila benar-benar diperlukan
→ Resource
```

Wajib gunakan:

- Form Request untuk validasi
- Policy untuk authorization dan ownership
- Service untuk business logic kompleks
- API Resource untuk response entity
- Database transaction untuk operasi multi-tabel
- Queue untuk proses berat
- Feature test untuk alur kritis

Jangan menaruh business logic kompleks di route closure, controller, atau model event tersembunyi.

### 5.2 Database

- Gunakan UUID untuk primary key domain.
- Gunakan `HasUuids` pada model domain.
- Gunakan foreign key PostgreSQL.
- Gunakan index pada field pencarian/filter.
- Gunakan partial unique index PostgreSQL untuk assignment aktif.
- Gunakan `string` + database `CHECK` constraint untuk status/role yang dapat berkembang.
- Jangan menggunakan integer auto-increment untuk tabel domain baru.
- Jangan mengubah tabel `cache` dan `jobs` bawaan tanpa alasan.
- Jangan menjalankan migration destruktif pada data production.
- Untuk local development, `migrate:fresh --seed` diperbolehkan.

### 5.3 Naming

Database memakai `snake_case`, nama tabel plural, dan foreign key singular.

PHP memakai `PascalCase` untuk class dan `camelCase` untuk method/variable.

Model tabel `classes` harus bernama:

```text
SchoolClass
```

karena `class` merupakan kata khusus dan nama `Class` tidak boleh digunakan.

### 5.4 Response API

Gunakan format berhasil:

```json
{
  "success": true,
  "message": "Pesan dalam Bahasa Indonesia.",
  "data": {}
}
```

Gunakan format error:

```json
{
  "success": false,
  "message": "Pesan kesalahan dalam Bahasa Indonesia.",
  "code": "ERROR_CODE",
  "errors": {}
}
```

### 5.5 Security

- Jangan percaya `user_id`, `student_id`, `teacher_id`, atau `class_id` dari frontend tanpa validasi.
- Ambil identitas user dari token.
- Gunakan Policy untuk mencegah IDOR.
- Password harus di-hash.
- Jangan commit `.env`.
- Jangan hardcode API key.
- Jangan expose rekaman speaking secara publik.
- Gunakan signed URL untuk media privat.
- Validasi MIME type dan ukuran upload.
- Cegah ZIP Slip pada import ZIP.
- Jangan mengirim kunci jawaban kepada siswa.
- Gunakan rate limit untuk login, chatbot, speaking, dan import.

---

## 6. Kondisi Repository Saat Ini

Environment yang sudah dikonfirmasi:

```text
Laravel Framework 12.59.0
PHP 8.2.12
Composer 2.8.12
PostgreSQL 16.14
pdo_pgsql aktif
pgsql aktif
Koneksi Laravel ke PostgreSQL berhasil
```

Migration yang sudah tersedia:

```text
0001_01_01_000000_create_users_table.php
0001_01_01_000001_create_cache_table.php
0001_01_01_000002_create_jobs_table.php
create_schools_table.php
create_classes_table.php
create_registration_requests_table.php
create_teacher_class_assignments_table.php
create_student_class_memberships_table.php
```

Migration domain tersebut baru dibuat dan belum boleh dianggap selesai sebelum schema diimplementasikan serta diuji.

---

## 7. Milestone Aktif: Phase 1A — Core Database

Untuk Phase 1A, scope yang diperbolehkan:

1. Memperbarui migration `users`.
2. Mengisi migration:
   - `schools`
   - `classes`
   - `registration_requests`
   - `teacher_class_assignments`
   - `student_class_memberships`
3. Membuat model dan relationship.
4. Membuat factory dasar.
5. Membuat Admin seeder.
6. Membuat test constraint core.
7. Menjalankan formatter dan test.
8. Memperbarui dokumentasi hanya jika implementasi berbeda dari dokumen.

Dilarang pada Phase 1A:

- membuat endpoint API;
- membuat controller auth;
- membuat frontend;
- membuat tabel modul, kuis, kamus, speaking, chatbot, sync, atau IoT;
- menginstal package yang tidak diperlukan;
- mengubah desain bisnis;
- menghapus migration cache/jobs bawaan.

---

## 8. Spesifikasi Schema Phase 1A

### 8.1 `users`

Kolom:

```text
id                  uuid primary key
full_name           varchar
email               varchar unique
email_verified_at   timestamp nullable
password            varchar
role                varchar
status              varchar default pending
phone               varchar nullable
approved_by         uuid nullable foreign users.id
approved_at         timestamp nullable
rejected_reason     text nullable
last_login_at       timestamp nullable
remember_token      varchar nullable
created_at
updated_at
```

Nilai role:

```text
admin
teacher
student
```

Nilai status:

```text
pending
approved
rejected
inactive
```

Constraint:

- email unique
- role CHECK
- status CHECK
- `approved_by` memakai `nullOnDelete`

Admin hasil seeder:

```text
role = admin
status = approved
approved_at = now()
```

### 8.2 `schools`

Kolom:

```text
id          uuid primary key
name        varchar
address     text nullable
phone       varchar nullable
status      varchar default active
created_by  uuid foreign users.id
created_at
updated_at
```

Status:

```text
active
inactive
```

Index:

- `name`
- `status`

### 8.3 `classes`

Nama model:

```text
SchoolClass
```

Nama tabel:

```text
classes
```

Kolom:

```text
id              uuid primary key
school_id       uuid foreign schools.id
name            varchar
grade_level     varchar nullable
academic_year   varchar
status          varchar default active
created_by      uuid foreign users.id
created_at
updated_at
```

Constraint:

```text
UNIQUE (school_id, name, academic_year)
```

Status:

```text
active
inactive
```

Index:

- `school_id`
- `academic_year`
- `status`

### 8.4 `registration_requests`

Kolom:

```text
id              uuid primary key
user_id         uuid foreign users.id
school_id       uuid foreign schools.id
class_id        uuid foreign classes.id
requested_role  varchar
status          varchar default pending
reviewed_by     uuid nullable foreign users.id
review_note     text nullable
reviewed_at     timestamp nullable
created_at
updated_at
```

Constraint:

- `user_id` unique
- requested role CHECK: `teacher`, `student`
- status CHECK: `pending`, `approved`, `rejected`
- `reviewed_by` memakai `nullOnDelete`

### 8.5 `teacher_class_assignments`

Kolom:

```text
id           uuid primary key
teacher_id   uuid foreign users.id
class_id     uuid foreign classes.id
assigned_by  uuid foreign users.id
is_active    boolean default true
assigned_at  timestamp
ended_at     timestamp nullable
created_at
updated_at
```

Partial unique indexes PostgreSQL:

```sql
CREATE UNIQUE INDEX unique_active_teacher_assignment
ON teacher_class_assignments (teacher_id)
WHERE is_active = true;
```

```sql
CREATE UNIQUE INDEX unique_active_teacher_per_class
ON teacher_class_assignments (class_id)
WHERE is_active = true;
```

Index tambahan:

- `teacher_id`
- `class_id`
- `is_active`

### 8.6 `student_class_memberships`

Kolom:

```text
id           uuid primary key
student_id   uuid foreign users.id
class_id     uuid foreign classes.id
assigned_by  uuid foreign users.id
is_active    boolean default true
joined_at    timestamp
ended_at     timestamp nullable
created_at
updated_at
```

Partial unique index PostgreSQL:

```sql
CREATE UNIQUE INDEX unique_active_student_class
ON student_class_memberships (student_id)
WHERE is_active = true;
```

Index tambahan:

- `student_id`
- `class_id`
- `is_active`

---

## 9. Foreign Key Delete Rules Phase 1A

Gunakan aturan berikut:

- `users.approved_by` → `nullOnDelete`
- `schools.created_by` → `restrictOnDelete`
- `classes.school_id` → `restrictOnDelete`
- `classes.created_by` → `restrictOnDelete`
- `registration_requests.user_id` → `cascadeOnDelete`
- `registration_requests.school_id` → `restrictOnDelete`
- `registration_requests.class_id` → `restrictOnDelete`
- `registration_requests.reviewed_by` → `nullOnDelete`
- assignment/membership user dan class → `restrictOnDelete`
- `assigned_by` → `restrictOnDelete`

Aplikasi menggunakan status `inactive`, bukan hard delete untuk user, sekolah, dan kelas.

---

## 10. Model Phase 1A

Buat model:

```text
User
School
SchoolClass
RegistrationRequest
TeacherClassAssignment
StudentClassMembership
```

Semua model domain:

- memakai `HasFactory`;
- memakai `HasUuids`;
- memiliki `$fillable` atau `$guarded` yang aman;
- memiliki casts untuk timestamp dan boolean;
- memiliki relationship dengan return type Eloquent.

Relationship minimum:

### User

- `approvedBy`
- `approvedUsers`
- `createdSchools`
- `createdClasses`
- `registrationRequest`
- `teacherClassAssignments`
- `studentClassMemberships`
- `activeTeacherClassAssignment`
- `activeStudentClassMembership`

### School

- `creator`
- `classes`
- `registrationRequests`

### SchoolClass

- `school`
- `creator`
- `registrationRequests`
- `teacherAssignments`
- `studentMemberships`
- `activeTeacherAssignment`
- `activeStudentMemberships`

### RegistrationRequest

- `user`
- `school`
- `schoolClass`
- `reviewedBy`

### TeacherClassAssignment

- `teacher`
- `schoolClass`
- `assignedBy`

### StudentClassMembership

- `student`
- `schoolClass`
- `assignedBy`

---

## 11. Seeder Phase 1A

Buat:

```text
database/seeders/AdminSeeder.php
```

Konfigurasi admin diambil dari environment:

```text
EMI_ADMIN_NAME
EMI_ADMIN_EMAIL
EMI_ADMIN_PASSWORD
```

Tambahkan ke `.env.example` tanpa secret nyata.

Seeder harus:

- memakai `updateOrCreate` berdasarkan email;
- hash password menggunakan `Hash::make`;
- membuat role `admin`;
- membuat status `approved`;
- mengisi `approved_at`;
- tidak mencetak password ke log;
- dipanggil dari `DatabaseSeeder`.

Jika `EMI_ADMIN_PASSWORD` kosong, seeder harus memberikan exception yang jelas atau melewati pembuatan admin dengan pesan aman. Jangan hardcode password production.

---

## 12. Factory Phase 1A

Buat atau perbarui factory:

- `UserFactory`
- `SchoolFactory`
- `SchoolClassFactory`
- `RegistrationRequestFactory`
- `TeacherClassAssignmentFactory`
- `StudentClassMembershipFactory`

State minimum User:

```text
admin()
teacher()
student()
pending()
approved()
rejected()
inactive()
```

Factory harus menghasilkan data konsisten dengan CHECK constraint.

---

## 13. Test Phase 1A

Gunakan PHPUnit atau test framework yang sudah tersedia.

Test minimum:

1. Admin seeder membuat admin approved.
2. Email user unique.
3. Class unique per school, name, academic year.
4. Satu guru tidak dapat memiliki dua assignment aktif.
5. Satu kelas tidak dapat memiliki dua guru aktif.
6. Guru dapat memiliki assignment baru setelah assignment lama dinonaktifkan.
7. Satu siswa tidak dapat memiliki dua membership aktif.
8. Siswa dapat memiliki membership baru setelah membership lama dinonaktifkan.
9. Relationship core dapat diakses.
10. Role/status invalid ditolak oleh database.

Gunakan `RefreshDatabase`.

---

## 14. Command Verifikasi Phase 1A

Agent wajib menjalankan:

```bash
php artisan migrate:fresh
php artisan db:seed
php artisan test
```

Jika Laravel Pint tersedia:

```bash
vendor/bin/pint
```

Kemudian ulangi:

```bash
php artisan test
```

Jika command gagal:

1. jangan menyembunyikan error;
2. identifikasi akar masalah;
3. perbaiki hanya dalam scope;
4. ulangi test;
5. laporkan error yang belum terselesaikan.

---

## 15. Format Laporan Agent

Setelah selesai, agent harus melaporkan:

### File diubah

- daftar file

### Implementasi

- ringkasan schema
- model/relationship
- seeder
- factory
- test

### Command dijalankan

- command
- status berhasil/gagal

### Risiko atau catatan

- keputusan teknis
- perbedaan terhadap dokumentasi
- pekerjaan lanjutan

Jangan hanya menulis “selesai”.

---

## 16. Aturan Perubahan

Sebelum mengedit:

1. baca file terkait;
2. lihat status Git;
3. jangan menimpa perubahan pengguna;
4. buat perubahan kecil dan terfokus;
5. jangan melakukan refactor di luar scope;
6. jangan rename file tanpa kebutuhan;
7. jangan menghapus dokumentasi;
8. jangan commit otomatis kecuali diminta.

---

## 17. Definition of Done Phase 1A

Phase 1A selesai hanya jika:

- seluruh migration core terisi;
- migration berjalan pada PostgreSQL;
- partial unique index aktif;
- model dan relationship dibuat;
- factory dibuat;
- AdminSeeder dibuat;
- `.env.example` diperbarui;
- `migrate:fresh --seed` berhasil;
- test minimum lulus;
- formatter dijalankan;
- agent memberikan laporan lengkap.

Setelah Phase 1A selesai, berhenti. Jangan otomatis lanjut ke authentication API.
