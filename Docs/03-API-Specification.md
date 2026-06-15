# 03 — API Specification EMI

**Project:** EMI — Elearning Mekongga Indonesia  
**Backend:** Laravel REST API  
**Frontend Web:** Next.js  
**Mobile:** Flutter  
**Database:** PostgreSQL  
**Authentication:** Laravel Sanctum  
**API Version:** v1  
**Status Dokumen:** Draft Final v1.0  

---

## 1. Tujuan Dokumen

Dokumen ini menjadi kontrak teknis antara:

- Laravel sebagai backend API;
- Next.js sebagai frontend web;
- Flutter sebagai aplikasi mobile;
- FastAPI sebagai voice engine;
- layanan AI chatbot;
- PostgreSQL sebagai sumber data utama.

Seluruh implementasi controller, request validation, policy, service, dan integrasi frontend harus mengacu pada dokumen ini.

---

## 2. Aturan Umum API

### 2.1 Base URL

Development:

```text
http://localhost:8000/api/v1
```

Production:

```text
https://api.emi.example.com/api/v1
```

### 2.2 Format Data

- Request dan response menggunakan JSON.
- Upload file menggunakan `multipart/form-data`.
- Primary key menggunakan UUID.
- Nama properti JSON menggunakan `snake_case`.
- Waktu menggunakan ISO 8601 dan UTC.

Contoh:

```json
{
  "created_at": "2026-06-15T08:30:00Z"
}
```

### 2.3 Header Umum

```http
Accept: application/json
Content-Type: application/json
Authorization: Bearer {token}
```

Untuk upload:

```http
Content-Type: multipart/form-data
Authorization: Bearer {token}
```

Untuk operasi yang rawan dikirim ulang, gunakan:

```http
X-Idempotency-Key: {uuid}
```

Header tersebut direkomendasikan untuk:

- submit kuis;
- import kamus;
- sinkronisasi offline;
- pembuatan speaking attempt.

---

## 3. Format Response

### 3.1 Response Berhasil

```json
{
  "success": true,
  "message": "Data berhasil diambil.",
  "data": {}
}
```

### 3.2 Response Berhasil dengan Pagination

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

### 3.3 Response Validasi Gagal

```json
{
  "success": false,
  "message": "Data yang diberikan tidak valid.",
  "code": "VALIDATION_ERROR",
  "errors": {
    "email": [
      "Email wajib diisi."
    ]
  }
}
```

### 3.4 Response Tidak Diizinkan

```json
{
  "success": false,
  "message": "Anda tidak memiliki izin untuk melakukan tindakan ini.",
  "code": "FORBIDDEN"
}
```

### 3.5 Response Data Tidak Ditemukan

```json
{
  "success": false,
  "message": "Data tidak ditemukan.",
  "code": "NOT_FOUND"
}
```

---

## 4. HTTP Status Code

| Status | Penggunaan |
|---|---|
| `200` | Request berhasil |
| `201` | Data berhasil dibuat |
| `202` | Proses asynchronous diterima |
| `204` | Berhasil tanpa response body |
| `400` | Request tidak valid secara proses |
| `401` | Belum login atau token tidak valid |
| `403` | Tidak memiliki izin |
| `404` | Data tidak ditemukan |
| `409` | Konflik atau data duplikat |
| `422` | Validasi gagal |
| `429` | Terlalu banyak request |
| `500` | Kesalahan server |
| `503` | Layanan eksternal sedang tidak tersedia |

---

## 5. Role dan Scope Akses

Role:

```text
admin
teacher
student
```

Aturan utama:

- Admin dapat mengakses seluruh sekolah, kelas, pengguna, modul, kuis, kamus, progress, speaking, dan basis pengetahuan AI.
- Guru hanya dapat mengakses satu kelas aktif yang terhubung dengan akunnya.
- Siswa hanya dapat mengakses kelas dan data pribadinya.
- Guru dan siswa tidak dapat berpindah kelas sendiri.
- Satu kelas hanya memiliki satu guru aktif.
- Satu akun guru hanya memiliki satu kelas aktif.
- Satu siswa hanya memiliki satu kelas aktif.
- Semua pembatasan wajib divalidasi di backend dengan Policy, bukan hanya disembunyikan di frontend.

---

# 6. Authentication API

## 6.1 Daftar Sekolah Publik

```http
GET /public/schools
```

**Akses:** Publik  
**Tujuan:** Menampilkan sekolah aktif pada form registrasi.

Query:

```text
search
page
per_page
```

## 6.2 Daftar Kelas Publik Berdasarkan Sekolah

```http
GET /public/schools/{school_id}/classes
```

**Akses:** Publik  
**Tujuan:** Menampilkan kelas aktif pada form registrasi.

## 6.3 Registrasi Guru atau Siswa

```http
POST /auth/register
```

**Akses:** Publik

Request:

```json
{
  "full_name": "Andi Pratama",
  "email": "andi@example.com",
  "password": "password-kuat",
  "password_confirmation": "password-kuat",
  "requested_role": "student",
  "school_id": "uuid-school",
  "class_id": "uuid-class"
}
```

Validasi:

- `requested_role` hanya `teacher` atau `student`;
- Admin tidak dapat mendaftar dari endpoint publik;
- kelas harus berasal dari sekolah yang dipilih;
- email harus unik;
- akun dibuat dengan status `pending`;
- dibuat satu record `registration_requests`.

Response `201`:

```json
{
  "success": true,
  "message": "Pendaftaran berhasil. Akun menunggu persetujuan Admin.",
  "data": {
    "user_id": "uuid",
    "status": "pending"
  }
}
```

## 6.4 Login

```http
POST /auth/login
```

Request:

```json
{
  "email": "andi@example.com",
  "password": "password-kuat",
  "device_name": "Chrome Windows"
}
```

Aturan:

- hanya akun `approved` yang dapat login;
- akun `pending`, `rejected`, atau `inactive` ditolak;
- response menghasilkan token Sanctum.

Response:

```json
{
  "success": true,
  "message": "Login berhasil.",
  "data": {
    "token": "plain-text-token",
    "token_type": "Bearer",
    "user": {
      "id": "uuid",
      "full_name": "Andi Pratama",
      "email": "andi@example.com",
      "role": "student",
      "status": "approved"
    }
  }
}
```

## 6.5 Logout

```http
POST /auth/logout
```

**Akses:** Semua user login  
**Proses:** Mencabut token yang sedang digunakan.

## 6.6 Profil User Login

```http
GET /auth/me
```

**Akses:** Semua user login

Response juga memuat:

- sekolah aktif;
- kelas aktif;
- role;
- permission ringkas;
- avatar;
- status akun.

## 6.7 Ubah Profil

```http
PATCH /auth/me
```

Field yang dapat diubah:

```json
{
  "full_name": "Nama Baru",
  "phone": "081234567890"
}
```

User tidak boleh mengubah sendiri:

- role;
- status;
- sekolah;
- kelas.

## 6.8 Ubah Password

```http
PUT /auth/password
```

Request:

```json
{
  "current_password": "password-lama",
  "password": "password-baru",
  "password_confirmation": "password-baru"
}
```

---

# 7. Registration Approval API

## 7.1 Daftar Permintaan Pendaftaran

```http
GET /admin/registration-requests
```

**Akses:** Admin

Filter:

```text
status=pending|approved|rejected
requested_role=teacher|student
school_id
class_id
search
page
per_page
```

## 7.2 Detail Permintaan

```http
GET /admin/registration-requests/{id}
```

**Akses:** Admin

## 7.3 Setujui Permintaan

```http
POST /admin/registration-requests/{id}/approve
```

**Akses:** Admin

Request opsional:

```json
{
  "review_note": "Data telah diverifikasi."
}
```

Proses transaction:

1. lock registration request;
2. pastikan status masih `pending`;
3. pastikan kelas aktif;
4. untuk guru, pastikan kelas belum memiliki guru aktif;
5. ubah `users.status` menjadi `approved`;
6. buat `teacher_class_assignments` atau `student_class_memberships`;
7. ubah request menjadi `approved`;
8. simpan reviewer dan waktu;
9. kirim notifikasi.

## 7.4 Tolak Permintaan

```http
POST /admin/registration-requests/{id}/reject
```

Request:

```json
{
  "review_note": "Data sekolah tidak sesuai."
}
```

`review_note` wajib diisi.

---

# 8. School API

```http
GET    /schools
POST   /schools
GET    /schools/{id}
PUT    /schools/{id}
DELETE /schools/{id}
```

**Akses:**

- Admin: CRUD penuh;
- Guru: melihat sekolah sendiri;
- Siswa: melihat sekolah sendiri.

Request membuat sekolah:

```json
{
  "name": "SMP Negeri 1",
  "address": "Kolaka",
  "phone": "0405xxxx",
  "status": "active"
}
```

Penghapusan disarankan menggunakan soft delete atau status `inactive`.

---

# 9. Class API

```http
GET    /classes
POST   /classes
GET    /classes/{id}
PUT    /classes/{id}
DELETE /classes/{id}
```

**Akses:**

- Admin: CRUD penuh;
- Guru: melihat kelas sendiri;
- Siswa: melihat kelas sendiri.

Request membuat kelas:

```json
{
  "school_id": "uuid",
  "name": "Kelas 7A",
  "grade_level": "7",
  "academic_year": "2026/2027",
  "status": "active"
}
```

Constraint:

```text
UNIQUE (school_id, name, academic_year)
```

## 9.1 Tetapkan atau Ganti Guru Kelas

```http
POST /classes/{id}/assign-teacher
```

Request:

```json
{
  "teacher_id": "uuid"
}
```

## 9.2 Pindahkan Siswa

```http
POST /classes/{id}/assign-student
```

Request:

```json
{
  "student_id": "uuid"
}
```

## 9.3 Daftar Siswa dalam Kelas

```http
GET /classes/{id}/students
```

**Akses:** Admin atau Guru kelas sendiri.

---

# 10. User Management API

```http
GET   /users
GET   /users/{id}
PUT   /users/{id}
PATCH /users/{id}/status
```

Filter daftar pengguna:

```text
role
status
school_id
class_id
search
page
per_page
```

Aturan akses:

- Admin dapat melihat dan mengubah semua user;
- Guru hanya dapat melihat siswa kelasnya;
- Siswa hanya dapat melihat profil sendiri melalui `/auth/me`.

---

# 11. Media API

## 11.1 Upload Media

```http
POST /media
```

`multipart/form-data`:

```text
file
purpose
entity_type
entity_id
```

Nilai `purpose`:

```text
avatar
dictionary_audio
module_media
quiz_image
culture_media
speaking_recording
knowledge_document
```

Backend wajib:

- memvalidasi MIME type;
- membatasi ukuran file;
- membuat nama file unik;
- menyimpan ke object storage;
- menyimpan metadata ke `media_files`;
- memvalidasi ownership `entity_id`.

## 11.2 Hapus Media

```http
DELETE /media/{id}
```

## 11.3 Signed URL Media Privat

```http
GET /media/{id}/signed-url
```

Digunakan terutama untuk rekaman speaking siswa dan file privat.

---

# 12. Dictionary Category API

```http
GET    /dictionary-categories
POST   /dictionary-categories
PUT    /dictionary-categories/{id}
DELETE /dictionary-categories/{id}
```

- Semua user login dapat membaca kategori.
- Hanya Admin dapat menambah, mengubah, dan menghapus.

---

# 13. Dictionary Entry API

```http
GET    /dictionary-entries
POST   /dictionary-entries
GET    /dictionary-entries/{id}
PUT    /dictionary-entries/{id}
DELETE /dictionary-entries/{id}
```

Filter:

```text
search
category_id
status
has_audio
page
per_page
```

Request tambah kata:

```json
{
  "category_id": "uuid",
  "indonesia_word": "makan",
  "english_word": "eat",
  "mekongga_word": "monga",
  "example_mekongga": "Inoi monga kade",
  "example_indonesia": "Saya sedang makan nasi",
  "pronunciation_note": null,
  "audio_media_id": "uuid"
}
```

- Semua user login dapat membaca.
- Hanya Admin dapat mengelola.

---

# 14. Dictionary Import API

## 14.1 Validasi CSV dan ZIP Audio

```http
POST /admin/dictionary-imports/validate
```

**Akses:** Admin  
**Content-Type:** `multipart/form-data`

Field:

```text
csv_file
audio_zip
```

`audio_zip` boleh kosong bila tidak ada audio.

Header CSV:

```text
indonesia
english
mekongga
kategori
contoh_mekongga
contoh_indonesia
audio_filename
```

Proses:

1. validasi encoding UTF-8;
2. validasi nama header;
3. validasi kolom wajib;
4. validasi kategori;
5. deteksi baris duplikat;
6. ekstrak ZIP secara aman;
7. cegah ZIP Slip/path traversal;
8. validasi MP3;
9. cocokkan `audio_filename` secara exact;
10. buat `dictionary_import_jobs`;
11. simpan preview dan error;
12. belum menyimpan kosakata final.

Response:

```json
{
  "success": true,
  "message": "Validasi import selesai.",
  "data": {
    "import_job_id": "uuid",
    "status": "validated",
    "summary": {
      "total_rows": 100,
      "valid_rows": 95,
      "invalid_rows": 5,
      "matched_audio": 90,
      "unmatched_audio": 5
    },
    "preview": [],
    "errors": []
  }
}
```

## 14.2 Konfirmasi Import

```http
POST /admin/dictionary-imports/{id}/confirm
```

Request:

```json
{
  "duplicate_strategy": "skip"
}
```

Nilai:

```text
skip
update
fail
```

Response `202`:

```json
{
  "success": true,
  "message": "Import sedang diproses.",
  "data": {
    "import_job_id": "uuid",
    "status": "processing"
  }
}
```

## 14.3 Endpoint Pendukung Import

```http
GET /admin/dictionary-imports
GET /admin/dictionary-imports/{id}
GET /admin/dictionary-imports/{id}/errors
```

---

# 15. Module Template API

```http
GET    /module-templates
POST   /module-templates
GET    /module-templates/{id}
PUT    /module-templates/{id}
DELETE /module-templates/{id}
```

- Admin: CRUD penuh;
- Guru: hanya melihat template published.

Request modul default:

```json
{
  "title": "Kosakata Dasar",
  "description": "Pengenalan kosakata Mekongga.",
  "category": "learning_material",
  "thumbnail_media_id": "uuid",
  "order_number": 1,
  "status": "draft"
}
```

## 15.1 Materi Template

```http
POST   /module-templates/{id}/lessons
PUT    /lesson-templates/{id}
DELETE /lesson-templates/{id}
```

Nilai `content_type`:

```text
text
image
audio
video
pdf
external_link
```

## 15.2 Terapkan Modul Default ke Kelas

```http
POST /module-templates/{id}/apply
```

Request:

```json
{
  "class_ids": [
    "uuid-class-1",
    "uuid-class-2"
  ]
}
```

Sistem menyalin template ke `class_modules` dan `class_lessons` agar guru dapat mengubah salinan tanpa mengubah template global.

---

# 16. Class Module API

```http
GET    /class-modules
POST   /class-modules
GET    /class-modules/{id}
PUT    /class-modules/{id}
DELETE /class-modules/{id}
POST   /class-modules/{id}/publish
```

Akses:

- Admin: seluruh kelas;
- Guru: kelas sendiri;
- Siswa: modul published kelas sendiri.

Materi kelas:

```http
POST   /class-modules/{id}/lessons
PUT    /class-lessons/{id}
DELETE /class-lessons/{id}
```

---

# 17. Learning Progress API

```http
POST /class-lessons/{id}/progress/start
POST /class-lessons/{id}/progress/complete
GET  /progress/me
GET  /classes/{id}/progress
GET  /students/{id}/progress
GET  /classes/{id}/progress/export
```

Aturan:

- Backend mengambil `student_id` dari token.
- Siswa tidak boleh mengirim student ID bebas.
- Menyelesaikan lesson harus memperbarui agregasi `module_progress`.
- Guru hanya melihat kelas sendiri.

Format export:

```text
format=csv|xlsx|pdf
```

---

# 18. Quiz Template API

```http
GET    /quiz-templates
POST   /quiz-templates
GET    /quiz-templates/{id}
PUT    /quiz-templates/{id}
DELETE /quiz-templates/{id}
```

Soal template:

```http
POST   /quiz-templates/{id}/questions
PUT    /quiz-template-questions/{id}
DELETE /quiz-template-questions/{id}
```

Request pilihan ganda:

```json
{
  "question_type": "multiple_choice",
  "question_text": "Apa arti kata monga?",
  "image_media_id": null,
  "points": 10,
  "order_number": 1,
  "options": [
    {
      "option_text": "Makan",
      "is_correct": true,
      "order_number": 1
    },
    {
      "option_text": "Minum",
      "is_correct": false,
      "order_number": 2
    }
  ]
}
```

Request isian singkat:

```json
{
  "question_type": "short_answer",
  "question_text": "Tuliskan bahasa Mekongga dari kata makan.",
  "correct_answer_text": "monga",
  "use_fuzzy_matching": true,
  "fuzzy_threshold": 85,
  "points": 10,
  "order_number": 2
}
```

Terapkan ke kelas:

```http
POST /quiz-templates/{id}/apply
```

---

# 19. Class Quiz API

```http
GET    /class-quizzes
POST   /class-quizzes
GET    /class-quizzes/{id}
PUT    /class-quizzes/{id}
DELETE /class-quizzes/{id}
POST   /class-quizzes/{id}/publish
```

Request:

```json
{
  "class_id": "uuid",
  "title": "Kuis Minggu 1",
  "description": "Evaluasi.",
  "instructions": "Kerjakan dengan teliti.",
  "duration_minutes": 20,
  "max_attempts": 1,
  "show_result": true,
  "open_at": "2026-06-20T00:00:00Z",
  "close_at": "2026-06-25T23:59:59Z",
  "status": "draft"
}
```

Soal kelas:

```http
POST   /class-quizzes/{id}/questions
PUT    /quiz-questions/{id}
DELETE /quiz-questions/{id}
```

Untuk siswa, response kuis tidak boleh memuat:

- `correct_answer_text`;
- `is_correct`;
- kunci jawaban;
- skor per opsi sebelum kuis selesai.

---

# 20. Quiz Attempt API

## 20.1 Mulai Percobaan

```http
POST /class-quizzes/{id}/attempts
```

Validasi:

- kuis published;
- jadwal aktif;
- siswa berada di kelas kuis;
- attempt belum melewati batas;
- tidak ada attempt aktif lain.

## 20.2 Simpan Draft Jawaban

```http
PUT /quiz-attempts/{id}/answers/{question_id}
```

Pilihan ganda:

```json
{
  "selected_option_id": "uuid"
}
```

Isian:

```json
{
  "answer_text": "monga"
}
```

## 20.3 Submit Kuis

```http
POST /quiz-attempts/{id}/submit
```

Gunakan `X-Idempotency-Key`.

Proses:

- lock attempt;
- cegah submit ganda;
- nilai pilihan ganda;
- hitung similarity isian bila aktif;
- simpan skor;
- ubah status;
- simpan waktu submit.

## 20.4 Hasil dan Daftar Attempt

```http
GET /quiz-attempts/{id}
GET /class-quizzes/{id}/attempts
```

---

# 21. Speaking Item API

```http
GET    /speaking-items
POST   /speaking-items
GET    /speaking-items/{id}
PUT    /speaking-items/{id}
DELETE /speaking-items/{id}
```

Request:

```json
{
  "dictionary_entry_id": "uuid",
  "class_lesson_id": null,
  "target_text": "monga",
  "native_audio_media_id": "uuid",
  "phonetic_breakdown": "mon-ga",
  "difficulty_level": "beginner",
  "status": "published"
}
```

- Admin dapat mengelola global.
- Guru hanya dapat mengelola item terkait lesson kelas sendiri bila fitur ini diaktifkan.

---

# 22. Speaking Attempt API

## 22.1 Kirim Rekaman

```http
POST /speaking-items/{id}/attempts
```

`multipart/form-data`:

```text
recording
client_operation_id
```

Proses:

1. validasi akses siswa;
2. simpan rekaman privat;
3. buat attempt status `pending`;
4. kirim job ke FastAPI;
5. response `202`.

## 22.2 Status dan Hasil

```http
GET /speaking-attempts/{id}
```

Response selesai:

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "completed",
    "target_text": "monga",
    "transcript_text": "monga",
    "text_similarity_score": 95,
    "audio_similarity_score": 88,
    "final_score": 91.5,
    "feedback_text": "Pelafalan sudah baik."
  }
}
```

Endpoint lain:

```http
GET  /speaking-attempts/me
GET  /classes/{id}/speaking-attempts
POST /speaking-attempts/{id}/notes
```

---

# 23. Cultural Content API

```http
GET    /cultural-contents
POST   /cultural-contents
GET    /cultural-contents/{id}
PUT    /cultural-contents/{id}
DELETE /cultural-contents/{id}
POST   /cultural-contents/{id}/publish
```

- Semua user login dapat membaca konten published.
- Admin mengelola konten global.

---

# 24. Chatbot Knowledge API

Kategori:

```http
GET    /knowledge-categories
POST   /knowledge-categories
PUT    /knowledge-categories/{id}
DELETE /knowledge-categories/{id}
```

Dokumen:

```http
GET    /knowledge-documents
POST   /knowledge-documents
GET    /knowledge-documents/{id}
PUT    /knowledge-documents/{id}
DELETE /knowledge-documents/{id}
POST   /knowledge-documents/{id}/verify
POST   /knowledge-documents/{id}/reindex
POST   /knowledge-documents/{id}/dictionary-links
```

Request dokumen:

```json
{
  "category_id": "uuid",
  "title": "Sejarah Mekongga",
  "content": "Isi dokumen terverifikasi...",
  "source_name": "Pak Karuddin",
  "source_description": "Wawancara dan dokumen budaya."
}
```

Hanya dokumen berstatus `verified` yang boleh digunakan chatbot.

---

# 25. Chatbot Conversation API

```http
GET    /chatbot/conversations
POST   /chatbot/conversations
GET    /chatbot/conversations/{id}/messages
POST   /chatbot/conversations/{id}/messages
DELETE /chatbot/conversations/{id}
```

Request pesan:

```json
{
  "message": "Apa arti kata monga?"
}
```

Aturan:

- cari konteks di kamus dan knowledge chunks;
- gunakan hanya dokumen verified;
- simpan sumber jawaban;
- bila sumber tidak cukup, jawab bahwa informasi belum tersedia;
- jangan membuat fakta bahasa atau budaya tanpa sumber EMI.

Response:

```json
{
  "success": true,
  "data": {
    "message_id": "uuid",
    "answer": "Kata monga berarti makan.",
    "sources": [
      {
        "type": "dictionary_entry",
        "id": "uuid",
        "title": "monga"
      }
    ]
  }
}
```

---

# 26. Mobile Device API

```http
POST   /mobile-devices
GET    /mobile-devices/me
DELETE /mobile-devices/{id}
```

Request:

```json
{
  "device_uuid": "uuid-device",
  "device_name": "Samsung A54",
  "platform": "android",
  "app_version": "1.0.0"
}
```

---

# 27. Offline Sync API

## 27.1 Pull Perubahan Server

```http
GET /sync/pull
```

Query:

```text
since=2026-06-15T00:00:00Z
device_id=uuid
```

Data dibatasi sesuai role dan kelas user.

## 27.2 Push Operasi Offline

```http
POST /sync/push
```

Request:

```json
{
  "device_id": "uuid",
  "operations": [
    {
      "client_operation_id": "uuid",
      "entity_type": "lesson_progress",
      "operation_type": "upsert",
      "payload": {
        "class_lesson_id": "uuid",
        "status": "completed",
        "completed_at": "2026-06-15T09:00:00Z"
      }
    }
  ]
}
```

Aturan:

- `client_operation_id` unik;
- retry tidak boleh menduplikasi data;
- backend memvalidasi ownership;
- konflik ditangani per operasi.

Fitur yang tetap memerlukan koneksi:

- chatbot AI;
- analisis speaking;
- upload rekaman;
- sinkronisasi dan pembaruan server.

---

# 28. Notification API

```http
GET   /notifications
PATCH /notifications/{id}/read
POST  /notifications/read-all
```

User hanya dapat mengakses notifikasi sendiri.

---

# 29. Report API

```http
GET /reports/admin-dashboard
GET /reports/teacher-dashboard
GET /reports/student-dashboard
GET /reports/system
```

Dashboard Admin:

- jumlah sekolah;
- jumlah kelas;
- jumlah guru dan siswa;
- akun pending;
- modul dan kuis aktif;
- progress sistem;
- import terbaru.

Dashboard Guru hanya memuat kelas sendiri. Dashboard Siswa hanya memuat data pribadi.

---

# 30. System Setting API

```http
GET /system-settings
PUT /system-settings/{setting_key}
```

**Akses:** Admin

Contoh setting:

```text
app_name
registration_enabled
academic_year
max_upload_size
dictionary_audio_extensions
speaking_score_weights
```

API key dan secret tidak boleh dikirim ke frontend.

---

# 31. Audit Log API

```http
GET /audit-logs
GET /audit-logs/{id}
```

**Akses:** Admin

Aksi yang wajib dicatat:

- approval/rejection akun;
- perubahan status akun;
- perpindahan kelas;
- import kamus;
- penghapusan data;
- publish modul/kuis;
- verifikasi knowledge document;
- perubahan system setting.

---

# 32. IoT API — Tahap Lanjutan

```http
POST /iot/devices/register
POST /iot/devices/{id}/heartbeat
GET  /iot/devices/{id}/content
POST /iot/devices/{id}/activity
```

Autentikasi perangkat harus menggunakan credential perangkat, bukan token user.

---

# 33. Filtering, Sorting, dan Pagination

Query standar:

```text
page=1
per_page=20
search=kata
sort_by=created_at
sort_direction=desc
```

Batas:

```text
per_page minimum: 1
per_page maksimum: 100
```

Field sorting harus memakai whitelist.

---

# 34. Validasi File

| Jenis | Format | Batas awal |
|---|---|---|
| Avatar | JPG, JPEG, PNG, WEBP | 2 MB |
| Gambar soal/budaya | JPG, JPEG, PNG, WEBP | 5 MB |
| Audio kamus | MP3 | 10 MB |
| Rekaman speaking | MP3, WAV, M4A, WEBM | 20 MB |
| PDF modul | PDF | 25 MB |
| CSV kamus | CSV UTF-8 | 10 MB |
| ZIP audio | ZIP berisi MP3 | 250 MB |

Batas final dapat diubah melalui `system_settings`.

---

# 35. Security Requirements

1. Gunakan HTTPS di production.
2. Gunakan Laravel Sanctum.
3. Hash password menggunakan fasilitas Laravel.
4. Gunakan Form Request untuk validasi.
5. Gunakan Policy untuk ownership dan scope kelas.
6. Jangan percaya ID pengguna atau kelas dari frontend tanpa validasi.
7. Gunakan signed URL untuk media privat.
8. Cegah ZIP Slip saat ekstraksi ZIP.
9. Validasi MIME type dan ekstensi.
10. Gunakan rate limit untuk login, chatbot, speaking, dan import.
11. Jangan mengirim kunci jawaban ke siswa.
12. Jangan mengirim secret/API key ke frontend.
13. Gunakan transaction untuk approval, assignment, import, dan submit kuis.
14. Gunakan queue untuk import, embedding, chatbot berat, dan voice analysis.
15. Simpan audit log untuk tindakan administratif penting.

---

# 36. Laravel Route Group yang Disarankan

```php
Route::prefix('v1')->group(function () {
    Route::prefix('public')->group(function () {
        // sekolah dan kelas publik
    });

    Route::prefix('auth')->group(function () {
        // register dan login
    });

    Route::middleware('auth:sanctum')->group(function () {
        // endpoint semua user login

        Route::middleware('role:admin')->prefix('admin')->group(function () {
            // approval, import, setting, audit
        });
    });
});
```

Role middleware saja tidak cukup. Ownership tetap harus diperiksa dengan Policy.

---

# 37. Service Layer yang Disarankan

```text
AuthService
RegistrationApprovalService
SchoolService
ClassAssignmentService
MediaService
DictionaryService
DictionaryImportService
ModuleTemplateService
ClassModuleService
LearningProgressService
QuizTemplateService
ClassQuizService
QuizAttemptService
SpeakingService
KnowledgeBaseService
ChatbotService
OfflineSyncService
ReportService
AuditLogService
```

Controller sebaiknya tipis dan tidak menampung business logic kompleks.

---

# 38. Prioritas Implementasi API

## Fase 1 — Core Account dan Kelas

1. Auth
2. Public school/class lookup
3. Registration
4. Approval
5. Users
6. Schools
7. Classes
8. Teacher/student assignment

## Fase 2 — Konten Pembelajaran

9. Media
10. Dictionary categories
11. Dictionary entries
12. Dictionary import
13. Module templates
14. Class modules
15. Progress

## Fase 3 — Evaluasi

16. Quiz templates
17. Class quizzes
18. Quiz attempts
19. Reports

## Fase 4 — Fitur Cerdas

20. Speaking
21. Knowledge base
22. Chatbot
23. Cultural contents

## Fase 5 — Mobile Lanjutan

24. Mobile devices
25. Offline sync
26. Notifications

## Fase 6 — IoT

27. ESP32/IoT API

---

# 39. Definition of Done API

Satu endpoint dianggap selesai bila:

- route tersedia;
- authentication diterapkan;
- authorization Policy diterapkan;
- request validation tersedia;
- service logic tersedia;
- transaction digunakan bila diperlukan;
- response mengikuti format standar;
- error response konsisten;
- feature test tersedia;
- dokumentasi request/response diperbarui;
- sudah diuji melalui Postman atau automated test;
- tidak membocorkan data lintas kelas atau user.

---

# 40. Catatan Final

API memakai istilah teknis Bahasa Inggris pada route dan nama field agar konsisten dalam pengembangan. Seluruh teks yang tampil kepada pengguna di Next.js dan Flutter tetap menggunakan Bahasa Indonesia.

Dokumen harus diperbarui ketika:

- ERD berubah;
- aturan role berubah;
- endpoint ditambah atau dihapus;
- format request/response berubah;
- client menyetujui fitur baru.
