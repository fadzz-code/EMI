# 04 — Development Plan EMI

**Project:** EMI — Elearning Mekongga Indonesia  
**Status:** Development Plan v1.0  
**Dokumen Acuan:**

1. `01-ERD-Database.md`
2. `02-Role-Permission-Matrix.md`
3. `03-API-Specification.md`
4. Desain dan prototipe Figma yang telah disetujui client

---

# 1. Tujuan Dokumen

Dokumen ini mengatur urutan pembangunan sistem EMI agar pengembangan tidak dimulai secara acak.

Development Plan ini menjadi panduan untuk:

- menentukan prioritas fitur;
- membagi pekerjaan backend, frontend web, mobile, voice engine, AI, dan IoT;
- menetapkan dependency antarfitur;
- mengurangi revisi besar saat coding;
- memastikan implementasi sesuai desain Figma dan kesepakatan client;
- menentukan kapan sebuah tahap dianggap selesai.

---

# 2. Posisi Proyek Saat Ini

## Sudah selesai

- Requirement dan kebutuhan client
- Alur aplikasi Admin, Guru, dan Siswa
- Desain web
- Desain mobile
- Prototipe Figma
- Persetujuan client
- Rancangan ERD
- Role & Permission Matrix
- API Specification
- Template CSV import kamus

## Belum dikerjakan

- Database PostgreSQL
- Laravel migration
- Laravel model dan relationship
- Authentication
- Backend REST API
- Next.js frontend
- Flutter mobile
- Voice engine FastAPI
- Chatbot AI
- Offline sync
- ESP32
- Testing
- Deployment

Posisi proyek:

```text
Planning dan UI/UX selesai
        ↓
Technical documentation selesai
        ↓
Mulai implementasi backend
```

---

# 3. Tech Stack Final

## Backend

- Laravel
- Laravel Sanctum
- PostgreSQL
- Laravel Queue
- Laravel Policy
- Object Storage/S3-compatible storage

## Frontend Web

- Next.js
- React
- TypeScript
- Tailwind CSS
- TanStack Query
- React Hook Form
- Zod
- Axios atau native fetch

## Mobile

- Flutter
- Dart
- SQLite
- Secure Storage
- HTTP/Dio
- Pending sync queue

## Voice Engine

- Python
- FastAPI
- Whisper
- RapidFuzz
- Resemblyzer

## AI Chatbot

- OpenAI API atau Claude API
- RAG berdasarkan basis pengetahuan EMI
- PostgreSQL + pgvector jika digunakan

## IoT

- ESP32
- REST API atau MQTT pada fase lanjutan

## Tools

- Git
- GitHub/GitLab
- Postman atau Bruno
- Figma
- VS Code
- Docker opsional

---

# 4. Struktur Workspace

```text
EMI/
├── Docs/
│   ├── 01-ERD-Database.md
│   ├── 02-Role-Permission-Matrix.md
│   ├── 03-API-Specification.md
│   ├── 04-Development-Plan.md
│   ├── Postman/
│   └── Diagrams/
│
├── Emi-Backend/
│   └── Laravel REST API
│
├── Emi-Web/
│   └── Next.js
│
├── Emi-Mobile/
│   └── Flutter
│
├── Emi-Voice-Engine/
│   └── FastAPI
│
└── Emi-IoT/
    └── ESP32 firmware
```

---

# 5. Prinsip Pengembangan

1. PostgreSQL menjadi sumber data utama.
2. Backend Laravel dibangun sebelum integrasi frontend penuh.
3. Figma menjadi sumber kebenaran visual.
4. Figma-to-code hanya digunakan untuk mempercepat tampilan.
5. Kode hasil Figma-to-code harus direfaktor sebelum dipakai sebagai kode final.
6. Semua authorization divalidasi di backend.
7. Frontend tidak boleh menentukan hak akses.
8. Guru hanya mengakses satu kelas aktif.
9. Siswa hanya mengakses satu kelas aktif.
10. Admin dapat mengakses semua sekolah dan kelas.
11. Modul dan kuis default disalin menjadi versi kelas.
12. Flutter offline tidak menggantikan PostgreSQL.
13. Chatbot hanya menggunakan data terverifikasi.
14. ESP32 dikerjakan setelah sistem inti stabil.
15. Setiap fase harus diuji sebelum lanjut ke fase berikutnya.

---

# 6. Strategi MVP

## Fitur MVP wajib

- Authentication
- Registrasi guru dan siswa
- Persetujuan akun oleh Admin
- Sekolah dan kelas
- Penetapan guru dan siswa ke kelas
- Data pengguna
- Modul dan materi
- Modul default dan salinan kelas
- Kuis pilihan ganda
- Kuis isian singkat
- Hasil kuis
- Progress belajar
- Kamus Indonesia–Inggris–Mekongga
- Import kamus CSV
- Import ZIP audio
- Konten budaya dasar
- Media upload
- Dashboard Admin, Guru, dan Siswa

## Fitur setelah MVP stabil

- Speaking assessment
- AI chatbot
- Offline sync lengkap
- Notifikasi lanjutan
- Export laporan lengkap
- ESP32

---

# 7. Roadmap Pengembangan

## Fase 0 — Finalisasi Dokumentasi dan Environment

### Tujuan

Menyiapkan fondasi proyek sebelum coding fitur.

### Pekerjaan

- Pastikan `01-ERD-Database.md` final
- Pastikan `02-Role-Permission-Matrix.md` final
- Pastikan `03-API-Specification.md` final
- Tambahkan `04-Development-Plan.md`
- Buat repository Git
- Buat branch strategy
- Buat `.gitignore`
- Buat `.env.example`
- Pastikan PHP, Composer, Node.js, PostgreSQL, Flutter, dan Python terpasang
- Tentukan object storage
- Tentukan layanan AI
- Tentukan naming convention

### Output

- Dokumentasi lengkap
- Repository siap
- Environment development siap

### Definition of Done

- Semua anggota tim dapat menjalankan project lokal
- Semua dokumen ada di folder `Docs`
- Tidak ada secret di repository

---

## Fase 1 — Setup PostgreSQL dan Laravel Core

### Tujuan

Membuat database fisik berdasarkan ERD.

### Pekerjaan

1. Buat database PostgreSQL `emi`
2. Konfigurasi `.env`
3. Instal Laravel Sanctum
4. Buat migration sesuai urutan dependency
5. Buat model Eloquent
6. Buat relationship
7. Buat constraint dan index
8. Tambahkan soft delete jika diperlukan
9. Buat factory
10. Buat seeder Admin
11. Buat seeder kategori awal
12. Jalankan migration
13. Uji rollback dan migrate ulang

### Prioritas migration

```text
users
schools
classes
registration_requests
teacher_class_assignments
student_class_memberships
media_files
dictionary_categories
dictionary_import_jobs
dictionary_entries
dictionary_import_errors
module_templates
lesson_templates
class_modules
class_lessons
lesson_progress
module_progress
quiz_templates
quiz_template_questions
quiz_template_options
class_quizzes
quiz_questions
quiz_options
quiz_attempts
quiz_answers
speaking_items
speaking_attempts
chatbot_categories
chatbot_knowledge_documents
chatbot_knowledge_chunks
chatbot_dictionary_links
chatbot_conversations
chatbot_messages
cultural_contents
mobile_devices
sync_operations
notifications
system_settings
audit_logs
iot_devices
iot_activity_logs
```

### Output

- Database PostgreSQL terbentuk
- Semua tabel dan relasi tersedia
- Admin awal dapat dibuat melalui seeder

### Definition of Done

- `php artisan migrate:fresh --seed` berhasil
- Constraint satu guru/satu kelas berjalan
- Constraint satu siswa/satu kelas berjalan
- Model relationship dapat diuji

---

## Fase 2 — Authentication, Role, dan Approval

### Tujuan

Membuat sistem akun sesuai alur client.

### Pekerjaan

- Register guru
- Register siswa
- Public school lookup
- Public class lookup
- Login
- Logout
- Profil user
- Approval akun
- Rejection akun
- Status pending/approved/rejected/inactive
- Assignment guru
- Membership siswa
- Middleware role
- Policy dasar
- Feature test auth

### Aturan wajib

- Admin tidak registrasi melalui endpoint publik
- Guru dan siswa harus disetujui
- Guru hanya satu kelas aktif
- Kelas hanya satu guru aktif
- Siswa hanya satu kelas aktif
- User pending tidak dapat login

### Output

- API authentication selesai
- Approval flow selesai

### Definition of Done

- Semua endpoint auth lolos test
- User lintas role tidak dapat mengakses endpoint terlarang
- Approval menggunakan transaction

---

## Fase 3 — Sekolah, Kelas, dan Pengguna

### Tujuan

Menyelesaikan data master utama.

### Pekerjaan

- CRUD sekolah
- CRUD kelas
- Detail kelas
- Data guru
- Data siswa
- Assign guru
- Pindahkan siswa
- Aktifkan/nonaktifkan akun
- Filter dan pagination
- Audit log untuk perubahan penting

### Output

- Admin dapat mengelola sekolah dan kelas
- Guru dapat melihat kelas sendiri
- Siswa hanya melihat kelas sendiri

### Definition of Done

- Policy scope kelas diuji
- Guru tidak dapat melihat kelas lain
- Siswa tidak dapat melihat data siswa lain

---

## Fase 4 — Media dan Object Storage

### Tujuan

Menyiapkan upload file sebelum fitur konten.

### Pekerjaan

- Konfigurasi object storage
- Upload file
- Validasi MIME
- Validasi ukuran
- Metadata `media_files`
- Delete file aman
- Signed URL
- Folder logical storage
- Upload avatar
- Upload gambar soal
- Upload PDF
- Upload audio
- Upload rekaman speaking

### Output

- Media service reusable

### Definition of Done

- File publik dan privat dibedakan
- Rekaman siswa tidak dapat diakses publik
- File yang masih dipakai tidak terhapus sembarangan

---

## Fase 5 — Kamus dan Import CSV + ZIP Audio

### Tujuan

Membangun fitur kamus sesuai permintaan client.

### Pekerjaan

- CRUD kategori kamus
- CRUD kata kamus
- Pencarian tiga bahasa
- Filter kategori
- Audio playback
- Upload CSV
- Upload ZIP audio
- Preview import
- Validasi header
- Validasi UTF-8
- Validasi kategori
- Matching `audio_filename`
- Error per baris
- Duplicate strategy
- Queue import
- Riwayat import
- Audit log

### Template CSV

```text
indonesia
english
mekongga
kategori
contoh_mekongga
contoh_indonesia
audio_filename
```

### Output

- Admin dapat import kamus massal
- Guru dan siswa dapat mencari kamus

### Definition of Done

- File audio cocok berdasarkan nama file
- Data invalid tidak masuk database
- Preview tersedia sebelum konfirmasi
- Import dapat diulang tanpa duplikasi tidak terkendali

---

## Fase 6 — Modul dan Materi

### Tujuan

Membangun sistem pembelajaran utama.

### Pekerjaan

- CRUD module template
- CRUD lesson template
- Apply template ke kelas
- Copy module/lesson
- CRUD class module
- CRUD class lesson
- Publish/archive
- Text, image, audio, video, PDF, link
- Module ordering
- Lesson ordering
- Student access
- Progress lesson
- Progress module

### Aturan wajib

- Guru tidak mengubah template Admin
- Guru hanya mengubah salinan kelas
- Siswa hanya melihat modul published kelasnya
- Admin dapat mengelola modul semua kelas

### Output

- Modul default dan modul kelas bekerja

### Definition of Done

- Copy template tidak mengubah sumber
- Progress siswa dihitung benar
- Policy kelas lolos test

---

## Fase 7 — Kuis dan Penilaian

### Tujuan

Membangun evaluasi belajar.

### Pekerjaan

- CRUD quiz template
- CRUD template question
- Multiple choice
- Short answer
- Question image
- Apply quiz ke kelas
- CRUD class quiz
- Open/close schedule
- Duration
- Max attempts
- Start attempt
- Save draft answer
- Submit attempt
- Auto grading
- Fuzzy matching
- Result
- Teacher report

### Aturan wajib

- Kunci jawaban tidak dikirim ke siswa
- Siswa hanya mengerjakan kuis kelas sendiri
- Jadwal dan max attempt divalidasi di backend
- Submit menggunakan idempotency

### Output

- Kuis kelas berfungsi end-to-end

### Definition of Done

- Multiple choice dinilai benar
- Isian singkat dinilai sesuai threshold
- Submit ganda tidak menggandakan data
- Hasil dapat dilihat sesuai permission

---

## Fase 8 — Backend Dashboard dan Laporan

### Tujuan

Menyediakan data ringkasan untuk UI.

### Pekerjaan

- Admin dashboard summary
- Teacher dashboard summary
- Student dashboard summary
- Progress per sekolah
- Progress per kelas
- Progress per siswa
- Hasil kuis
- Hasil speaking
- Export CSV/XLSX/PDF bila diperlukan

### Output

- API dashboard siap dipakai frontend

### Definition of Done

- Query tidak lambat pada dataset uji
- Data sesuai role
- Tidak ada data lintas kelas bocor

---

## Fase 9 — Next.js Frontend Web

### Tujuan

Mengubah desain Figma menjadi aplikasi web.

### Strategi

```text
Figma
↓
Figma-to-code React
↓
Refactor ke Next.js
↓
Komponen reusable
↓
Mock data
↓
Integrasi Laravel API
```

### Pekerjaan awal

- Setup Next.js
- TypeScript
- Tailwind
- Environment API URL
- Auth provider
- Query client
- Form validation
- Route guards
- Layout Admin
- Layout Guru
- Layout Siswa
- Shared component

### Shared component

- Button
- Input
- Select
- Card
- Badge
- Table
- Modal
- Sidebar
- Topbar
- Pagination
- Empty state
- Loading state
- Error state
- Audio player
- Upload component

### Urutan implementasi screen

#### Admin

1. Login
2. Beranda Admin
3. Persetujuan Akun
4. Detail Review
5. Sekolah & Kelas
6. Detail Kelas
7. Data Guru & Siswa
8. Import Kamus
9. Kelola Kamus
10. Basis Pengetahuan
11. Modul Default
12. Kuis Default
13. Progress
14. Pengaturan

#### Guru

1. Beranda Kelas
2. Data Siswa
3. Detail Siswa
4. Modul Kelas
5. Editor Modul
6. Kuis Kelas
7. Builder Soal
8. Hasil Kuis
9. Progress
10. Speaking
11. Media
12. Profil

#### Siswa

1. Beranda
2. Modul
3. Detail Materi
4. Kamus
5. Detail Kata
6. Speaking
7. Kuis
8. Pengerjaan Kuis
9. Hasil Kuis
10. Budaya
11. Chatbot
12. Progress
13. Profil

### Definition of Done

- Tampilan sesuai Figma
- Responsive
- Tidak menggunakan mock data pada fitur yang dinyatakan selesai
- Loading, empty, success, dan error state tersedia
- Semua role guard bekerja

---

## Fase 10 — Flutter Mobile

### Tujuan

Membangun aplikasi Android EMI.

### Pekerjaan

- Setup Flutter
- Auth
- Secure token
- API client
- State management
- Mobile design system
- Bottom navigation
- Modul
- Kamus
- Kuis
- Progress
- Speaking
- Chatbot
- Profil
- Download materi
- SQLite cache
- Pending sync queue
- Status online/offline

### Prioritas role mobile

Konfirmasi scope dengan client:

- prioritas utama siswa;
- guru dan admin mobile dapat dikerjakan bila masuk kontrak MVP.

### Definition of Done

- Login dan token aman
- Data kelas sesuai user
- Cache modul dan kamus berjalan
- Pending sync tidak menggandakan data

---

## Fase 11 — Voice Engine

### Tujuan

Menganalisis pelafalan siswa.

### Pekerjaan

- Setup FastAPI
- Upload audio internal
- Whisper transcription
- Text normalization
- RapidFuzz similarity
- Resemblyzer similarity
- Score weighting
- Feedback generation
- Callback ke Laravel
- Queue
- Retry
- Engine versioning
- Logging

### Alur

```text
Flutter/Next.js
↓
Laravel
↓
Object Storage
↓
FastAPI
↓
Laravel menyimpan hasil
```

### Definition of Done

- Rekaman privat
- Status pending/processing/completed/failed
- Retry tersedia
- Hasil disimpan di PostgreSQL

---

## Fase 12 — AI Chatbot

### Tujuan

Menyediakan chatbot berbasis sumber EMI.

### Pekerjaan

- CRUD kategori pengetahuan
- CRUD dokumen
- Verification flow
- Chunking
- Embedding
- pgvector opsional
- Retrieval
- Prompt guardrail
- Source citation
- Conversation history
- Rate limiting
- Fallback jawaban

### Aturan wajib

- Hanya dokumen verified
- Kamus dan knowledge base dipisahkan
- Jawaban tanpa sumber harus ditolak dengan sopan
- Model tidak boleh mengarang fakta bahasa atau budaya

### Definition of Done

- Jawaban menyertakan sumber internal
- Dokumen draft tidak digunakan
- Fallback bekerja

---

## Fase 13 — Offline Sync

### Tujuan

Menyinkronkan data mobile secara aman.

### Pekerjaan

- Device registration
- Pull changes
- Push operations
- Idempotency
- Conflict handling
- Sync logs
- Retry
- Last sync timestamp
- Deleted entity list

### Data yang dapat offline

- Modul yang diunduh
- Materi
- Gambar/PDF/audio
- Kamus cache
- Draft jawaban
- Progress pending

### Data yang membutuhkan online

- Chatbot
- Voice analysis
- Upload rekaman
- Update server terbaru

### Definition of Done

- Operasi yang dikirim ulang tidak duplikat
- Sync per user dan kelas
- Conflict response jelas

---

## Fase 14 — ESP32

### Tujuan

Integrasi perangkat audio pada fase lanjutan.

### Pekerjaan

- Device registration
- Device credential
- Heartbeat
- Content fetch
- Audio playback
- Recording opsional
- Activity log
- Firmware update strategy

### Syarat mulai

- Backend core stabil
- Media API stabil
- Authentication device tersedia
- Kebutuhan hardware telah dikunci

---

## Fase 15 — Testing

### Jenis testing

#### Backend

- Unit test
- Feature test
- Policy test
- Validation test
- Import test
- Queue test

#### Frontend

- Component test
- Integration test
- E2E test
- Responsive test

#### Mobile

- Widget test
- Integration test
- Offline test
- Sync test

#### Security

- Authorization
- IDOR
- File upload
- ZIP Slip
- Rate limiting
- Token revocation
- Data privacy

#### User Acceptance Testing

- Admin
- Guru
- Siswa
- Client

### Definition of Done

- Tidak ada bug blocker
- Semua critical flow lolos
- Client menyetujui hasil UAT

---

## Fase 16 — Deployment

### Backend

- Production server
- PostgreSQL
- Queue worker
- Scheduler
- SSL
- Object storage
- Backup
- Monitoring

### Web

- Build Next.js
- Environment production
- Domain
- SSL
- Error tracking

### Mobile

- Release build
- Signing key
- Internal testing
- Play Store

### Voice Engine

- Python server/container
- Model storage
- Worker
- Resource monitoring

### Checklist

- Migration production
- Seeder aman
- Admin production
- API key aman
- Backup aktif
- Log rotation
- Health check
- Rollback plan

---

# 8. Branch Strategy

Rekomendasi sederhana:

```text
main
develop
feature/*
fix/*
release/*
```

Contoh:

```text
feature/authentication
feature/dictionary-import
feature/class-module
feature/quiz-attempt
```

Aturan:

- Jangan coding langsung di `main`
- Satu fitur satu branch
- Commit kecil dan jelas
- Merge setelah test

---

# 9. Commit Convention

Contoh:

```text
feat: add registration approval endpoint
fix: prevent teacher accessing another class
docs: update API specification
refactor: extract dictionary import service
test: add quiz submission feature test
```

---

# 10. Urutan Pekerjaan Praktis dari Posisi Sekarang

Urutan yang harus dilakukan setelah file ini selesai:

```text
1. Simpan 04-Development-Plan.md
2. Pastikan PostgreSQL terpasang
3. Buat database emi
4. Konfigurasi .env Laravel
5. Instal Laravel Sanctum
6. Buat migration fase core
7. Buat model dan relationship
8. Buat seeder Admin
9. Jalankan migrate:fresh --seed
10. Buat authentication API
11. Buat approval akun
12. Buat school dan class API
13. Lanjutkan fitur sesuai roadmap
```

---

# 11. Milestone Proyek

## Milestone 1 — Backend Core

Selesai bila:

- Database aktif
- Auth aktif
- Approval aktif
- Sekolah dan kelas aktif
- Role dan Policy aktif

## Milestone 2 — Learning Core

Selesai bila:

- Kamus aktif
- Import CSV + ZIP aktif
- Modul aktif
- Progress aktif
- Kuis aktif

## Milestone 3 — Web MVP

Selesai bila:

- Admin web aktif
- Guru web aktif
- Siswa web aktif
- API terintegrasi
- Figma diterapkan

## Milestone 4 — Mobile MVP

Selesai bila:

- Flutter siswa aktif
- Modul, kamus, kuis, progress aktif
- Cache dasar aktif

## Milestone 5 — Intelligent Features

Selesai bila:

- Speaking aktif
- Chatbot aktif
- Knowledge base aktif

## Milestone 6 — Production

Selesai bila:

- UAT selesai
- Deployment selesai
- Monitoring dan backup aktif

---

# 12. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Scope terlalu besar | Fokus MVP dan fase bertahap |
| Hasil Figma-to-code berantakan | Refactor sebelum integrasi |
| Data lintas kelas bocor | Laravel Policy dan feature test |
| Import audio gagal | Preview, error log, exact filename mapping |
| Chatbot berhalusinasi | Verified knowledge dan fallback |
| Offline sync duplikat | `client_operation_id` unik |
| Voice engine lambat | Queue dan asynchronous processing |
| File besar membebani server | Object storage dan batas upload |
| Perubahan client mendadak | Design freeze dan change request |
| ESP32 menghambat core | Kerjakan pada fase terakhir |

---

# 13. Definition of Done Proyek

Proyek EMI dianggap selesai bila:

- fitur sesuai kontrak telah dibangun;
- desain sesuai Figma;
- role Admin, Guru, dan Siswa berjalan;
- database dan backup stabil;
- import kamus berjalan;
- modul dan kuis berjalan;
- progress akurat;
- media aman;
- speaking dan chatbot sesuai scope;
- mobile sesuai scope;
- semua critical test lolos;
- dokumentasi diperbarui;
- client menyetujui UAT;
- production deployment berhasil.

---

# 14. Catatan Perubahan

Setiap perubahan fitur wajib memperbarui dokumen yang terdampak:

- perubahan tabel → `01-ERD-Database.md`
- perubahan akses → `02-Role-Permission-Matrix.md`
- perubahan endpoint → `03-API-Specification.md`
- perubahan urutan/scope → `04-Development-Plan.md`

Dokumen dan implementasi harus selalu tetap sinkron.
