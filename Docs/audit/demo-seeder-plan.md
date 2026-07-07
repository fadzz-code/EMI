# Demo Seeder Plan EMI

## Prinsip Seeder

- Idempotent: semua record demo dibuat dengan `updateOrCreate` atau `firstOrCreate` memakai key stabil seperti email, kode sekolah, kode kelas, kode kamus, slug, atau title unik.
- Tidak destruktif: seeder tidak melakukan truncate, delete massal, reset sequence, atau menghapus data existing.
- Aman untuk lokal dan VPS: seeder hanya menambah/memperbarui data demo bernama jelas, misalnya prefix `DEMO-` atau email domain `demo.emi.local`.
- Tidak truncate data production: seeder harus bisa dijalankan ulang tanpa mengganggu data production/manual input.
- Password demo tidak hardcoded sebagai rahasia: gunakan konsep env seperti `EMI_DEMO_PASSWORD`, dengan fallback lokal non-secret hanya jika environment mengizinkan.
- Media demo harus ringan: hindari menyimpan file besar di repo; gunakan placeholder teks, external URL kosong aman, atau file kecil yang sudah ada bila nanti tersedia.
- Data bahasa/budaya yang belum pasti diberi catatan `perlu validasi narasumber`.
- Seeder progress dibuat opsional dan defensif karena menyentuh state belajar/attempt.

## Akun Demo

| Role | Nama | Email Demo | Status | Relasi | Tujuan Demo | Catatan |
|---|---|---|---|---|---|---|
| Admin | Admin Demo EMI | `admin.demo@emi.local` | approved | - | Login admin, settings, CRUD, approval, reports | Password dari `EMI_DEMO_PASSWORD` |
| Guru | Guru Rina Mekongga | `guru.rina@emi.local` | approved | Guru kelas VII-A | Flow guru lengkap | Nama fiktif untuk demo |
| Guru | Guru Arman Kolaka | `guru.arman@emi.local` | approved | Guru kelas VIII-B atau tanpa kelas cadangan | Test multi-guru/empty-state | Jika dipakai empty-state, jangan assign kelas |
| Siswa | Nanda Saputra | `siswa.nanda@emi.local` | approved | Siswa kelas VII-A | Belum mulai | Progress kosong |
| Siswa | Mira Lestari | `siswa.mira@emi.local` | approved | Siswa kelas VII-A | Sedang belajar | Progress sebagian |
| Siswa | Rafi Pratama | `siswa.rafi@emi.local` | approved | Siswa kelas VII-A | Attempt kuis/speaking | Progress lengkap demo |
| Guru Pending | Guru Pending Demo | `guru.pending@emi.local` | pending | Request ke kelas VIII-B | Approval admin | Jika registration request model mendukung |
| Siswa Rejected | Siswa Rejected Demo | `siswa.rejected@emi.local` | rejected | Request ke kelas VII-A | Status filter admin | Jika model mendukung |
| Siswa Inactive | Siswa Inactive Demo | `siswa.inactive@emi.local` | inactive | Kelas VIII-B | User status testing | Pastikan tidak bisa login |

## Sekolah dan Kelas

### Sekolah

| Kode | Nama Sekolah | Lokasi | Status | Tujuan Demo | Catatan |
|---|---|---|---|---|---|
| `DEMO-SMP-KOLAKA-01` | SMP Negeri Demo Kolaka | Kolaka, Sulawesi Tenggara | active | Sekolah utama demo | Nama fiktif, bukan klaim data resmi |
| `DEMO-SMP-WUNDULAKO-01` | SMP Demo Wundulako | Wundulako, Kolaka | active | Sekolah pembanding/filter | Nama fiktif, bukan klaim data resmi |

### Kelas

| Kode | Nama Kelas | Sekolah | Tahun Ajaran | Guru | Siswa | Status | Tujuan Demo |
|---|---|---|---|---|---|---|---|
| `DEMO-VII-A-2026` | VII-A Mekongga | SMP Negeri Demo Kolaka | 2026/2027 | Guru Rina Mekongga | Nanda, Mira, Rafi | active | Kelas utama semua fitur |
| `DEMO-VIII-B-2026` | VIII-B Budaya | SMP Demo Wundulako | 2026/2027 | Guru Arman Kolaka atau kosong | Siswa inactive opsional | active | Test filter, assignment, empty/progress ringan |

## Kamus dan Contoh Kalimat

| Kode | Mekongga | Indonesia | English | Kategori | Contoh Kalimat Mekongga | Contoh Kalimat Indonesia | Status Validasi |
|---|---|---|---|---|---|---|---|
| `DEMO-KOS-001` | `mombesara` | salam / menyapa | greeting | Sapaan | `Mombesara lako guru.` | `Salam kepada guru.` | Perlu validasi narasumber |
| `DEMO-KOS-002` | `mekambo` | belajar | study / learn | Kegiatan Belajar | `Aku mekambo bahasa Mekongga.` | `Saya belajar bahasa Mekongga.` | Perlu validasi narasumber |
| `DEMO-KOS-003` | `morini` | terima kasih | thank you | Sopan Santun | `Morini, ibu guru.` | `Terima kasih, ibu guru.` | Perlu validasi narasumber |

Catatan kamus:
- Tiga data di atas dipilih untuk menghubungkan modul sapaan, speaking, kuis, dan chatbot.
- Audio kamus opsional. Jika belum tersedia, entry tetap dibuat tanpa audio.
- Contoh kalimat harus dibuat sebagai sentence examples terhubung ke dictionary entry melalui kode/ID entry.

## Basis AI

| Slug/Key | Judul | Status | Ringkasan Konten | Tujuan Demo | Catatan Validasi |
|---|---|---|---|---|---|
| `demo-apa-itu-bahasa-mekongga` | Apa itu bahasa Mekongga? | published | Bahasa Mekongga adalah bahasa daerah masyarakat Mekongga di wilayah Kolaka dan sekitarnya. EMI membantu siswa mengenal kosakata, sapaan, dan konteks budaya secara bertahap. | Jawaban chatbot dasar | Perlu validasi narasumber untuk definisi final |
| `demo-budaya-mekongga` | Apa saja budaya Mekongga? | published | Budaya Mekongga mencakup tradisi lisan, nilai kebersamaan, sopan santun, penghormatan kepada orang tua/guru, serta kegiatan adat masyarakat setempat. | Chatbot budaya | Perlu validasi narasumber |
| `demo-sapaan-mekongga` | Contoh sapaan bahasa Mekongga | published | Contoh materi sapaan: menyapa guru, teman, dan keluarga dengan bahasa yang sopan. Gunakan kosakata demo seperti mombesara untuk latihan awal jika sudah divalidasi. | Chatbot sapaan + speaking | Kata perlu validasi narasumber |
| `demo-sopan-santun-mekongga` | Nilai sopan santun masyarakat Mekongga | published | Pembelajaran bahasa perlu memperhatikan kesopanan, konteks lawan bicara, dan penghormatan kepada orang yang lebih tua. | Chatbot nilai budaya | Perlu validasi narasumber |
| `demo-cara-belajar-emi` | Cara belajar bahasa Mekongga di EMI | published | Siswa dapat mulai dari modul, membaca materi, mencari kata di kamus, mengerjakan kuis, latihan speaking, lalu memantau progres belajar. | Menjelaskan alur aplikasi | Validasi produk internal |
| `demo-draft-knowledge` | Draft: Catatan Narasumber | draft | Placeholder untuk materi yang belum disetujui narasumber. | Test status draft tidak muncul chatbot | Jangan tampil di chatbot |
| `demo-archived-knowledge` | Arsip: Materi Lama | archived | Materi lama yang tidak dipakai. | Test status archived | Jangan tampil di chatbot |

## Modul dan Materi

### Modul 1: Sapaan Dasar Bahasa Mekongga

| Materi | Judul | Ringkasan | Terhubung ke Kamus/Budaya/Kuis | Media |
|---|---|---|---|---|
| 1 | Mengenal Sapaan | Pengantar sapaan dalam konteks sekolah dan keluarga. | `DEMO-KOS-001` | Teks saja |
| 2 | Menyapa Guru dan Teman | Contoh dialog sederhana untuk menyapa guru/teman. | `DEMO-KOS-001`, speaking latihan 1 | Teks saja; audio kecil jika tersedia |
| 3 | Ungkapan Terima Kasih | Cara mengucapkan terima kasih dan merespons dengan sopan. | `DEMO-KOS-003`, kuis 1 | Teks saja |

### Modul 2: Bahasa dan Budaya Sehari-hari

| Materi | Judul | Ringkasan | Terhubung ke Kamus/Budaya/Kuis | Media |
|---|---|---|---|---|
| 1 | Belajar Bahasa Daerah di EMI | Alur belajar: modul, kamus, kuis, speaking, chatbot. | Knowledge `demo-cara-belajar-emi` | Teks saja |
| 2 | Nilai Sopan Santun | Mengaitkan bahasa dengan sikap menghormati guru, orang tua, dan teman. | Knowledge sopan santun, budaya 1 | Teks saja |
| 3 | Mengenal Budaya Mekongga | Pengantar budaya dan tradisi lisan masyarakat Mekongga. | Budaya 1 dan 2, kuis 2 | Teks atau link kosong aman |

Status demo:
- Template modul admin: published.
- Class module untuk kelas VII-A: published supaya siswa bisa melihat.
- Untuk kelas VIII-B: buat 1 module draft opsional untuk test guru/admin.

## Kuis dan Soal

### Kuis 1: Sapaan Dasar

| No | Pertanyaan | Opsi | Jawaban Benar | Pembahasan Singkat | Terkait Materi |
|---|---|---|---|---|---|
| 1 | Apa tujuan mempelajari sapaan dalam bahasa daerah? | A. Agar bisa menyapa dengan sopan; B. Agar tidak perlu belajar kosakata; C. Agar hanya menghafal tanpa praktik; D. Agar menghindari percakapan | A | Sapaan membantu memulai percakapan dengan sopan. | Modul 1 Materi 1 |
| 2 | Kosakata demo `morini` pada rancangan ini digunakan untuk arti apa? | A. Terima kasih; B. Selamat tinggal; C. Makan; D. Rumah | A | Arti ini masih perlu validasi narasumber, tetapi dipakai sebagai data demo terhubung. | Modul 1 Materi 3 |
| 3 | Saat menyapa guru, sikap yang tepat adalah ... | A. Sopan dan jelas; B. Berteriak; C. Mengabaikan; D. Bercanda berlebihan | A | Bahasa dipakai bersama sikap sopan. | Modul 1 Materi 2 |

### Kuis 2: Bahasa dan Budaya Mekongga

| No | Pertanyaan | Opsi | Jawaban Benar | Pembahasan Singkat | Terkait Materi |
|---|---|---|---|---|---|
| 1 | EMI membantu siswa belajar bahasa Mekongga melalui ... | A. Modul, kamus, kuis, speaking, chatbot; B. Hanya membaca daftar nilai; C. Hanya absensi; D. Hanya upload foto | A | Alur EMI mencakup beberapa fitur belajar. | Modul 2 Materi 1 |
| 2 | Mengapa nilai sopan santun penting dalam belajar bahasa daerah? | A. Karena bahasa dipakai sesuai konteks dan lawan bicara; B. Karena membuat kuis lebih sulit; C. Karena mengganti semua materi; D. Karena tidak perlu praktik | A | Bahasa dan budaya saling terkait. | Modul 2 Materi 2 |
| 3 | Konten budaya di EMI dapat membantu siswa ... | A. Mengenal konteks masyarakat dan tradisi; B. Menghapus kamus; C. Menghindari speaking; D. Mengganti profil | A | Budaya memberi konteks penggunaan bahasa. | Modul 2 Materi 3 |

Status demo:
- Template kuis admin: published.
- Class quiz kelas VII-A: published dan bisa dikerjakan siswa.
- Buat 1 quiz expired atau attempt-limit opsional jika aman untuk test kondisi tombol.

## Speaking

| Kode | Judul Latihan | Prompt/Instruksi | Target Demo | Status | Reference Audio |
|---|---|---|---|---|---|
| `DEMO-SPK-001` | Sapaan kepada Guru | Ucapkan sapaan sederhana kepada guru dengan suara jelas dan sopan. | Menghubungkan modul sapaan dan kamus `DEMO-KOS-001` | published | Tidak wajib; gunakan tanpa file audio besar |
| `DEMO-SPK-002` | Ungkapan Terima Kasih | Ucapkan ungkapan terima kasih kepada guru atau teman. | Menghubungkan kamus `DEMO-KOS-003` dan sopan santun | published | Tidak wajib; jika ada, pakai file audio pendek < 1 MB |
| `DEMO-SPK-DRAFT` | Draft Latihan Narasumber | Placeholder latihan yang belum disetujui. | Test draft tidak muncul siswa | draft | Tidak ada |

Strategi aman reference audio:
- Jangan commit file audio besar.
- Jika backend membutuhkan media file untuk demo, gunakan file audio sangat kecil dari storage lokal yang dibuat saat seeder jalan, atau biarkan `reference_audio` null.
- Narasi audio harus divalidasi narasumber sebelum demo client resmi.

## Budaya

| Kode | Judul | Tipe | Ringkasan | Status | Media/URL | Validasi |
|---|---|---|---|---|---|---|
| `DEMO-CUL-001` | Sopan Santun dalam Percakapan | text | Konten singkat tentang pentingnya menyapa dengan hormat kepada guru, orang tua, dan teman. | published | Tidak ada | Perlu validasi narasumber |
| `DEMO-CUL-002` | Mengenal Budaya Mekongga di Kolaka | text | Pengantar budaya Mekongga sebagai konteks belajar bahasa daerah di EMI. | published | Tidak ada | Perlu validasi narasumber |
| `DEMO-CUL-DRAFT` | Draft Media Budaya | text | Placeholder untuk konten yang menunggu media/narasumber. | draft | Kosong aman | Jangan tampil siswa |

Catatan budaya:
- Jika fitur culture membutuhkan media, gunakan teks dulu atau URL kosong aman.
- Jangan menggunakan link eksternal acak.
- Media foto/video budaya harus berizin sebelum dipakai demo client.

## Progress Demo

| Siswa | Status Demo | Modul/Lesson | Kuis | Speaking | Tujuan Testing |
|---|---|---|---|---|---|
| Nanda Saputra | Belum mulai | Tidak ada progress atau semua `not_started` | Belum attempt | Belum attempt | Empty/awal belajar |
| Mira Lestari | Sedang belajar | Modul 1 started, 1 lesson completed, lesson lain in_progress/not_started | Attempt kuis belum submitted atau skor sebagian jika model mendukung | Belum review | Dashboard/progress parsial |
| Rafi Pratama | Sudah attempt | Modul 1 completed, Modul 2 in_progress | Submitted attempt Kuis 1 dengan skor lulus; Kuis 2 opsional belum selesai | Speaking attempt success + feedback guru | Reports, quiz result, speaking result |

Catatan progress:
- `DemoProgressSeeder` sebaiknya opsional dan hanya dijalankan di environment demo/local.
- Jangan membuat attempt palsu yang melanggar constraint aktif attempt.
- Jika model scoring kompleks, gunakan service existing bila nanti implementasi memungkinkan, bukan insert manual berisiko.

## Catatan Implementasi Seeder

Seeder yang nanti perlu dibuat:
- `DemoPresentationSeeder`: orchestrator utama; menjalankan seeder demo berurutan dan bisa dipanggil manual.
- `DemoAccountSeeder`: akun admin/guru/siswa dan status pending/rejected/inactive.
- `DemoSchoolClassSeeder`: sekolah, kelas, teacher assignments, student memberships.
- `DemoDictionarySeeder`: kategori, entry kamus, sentence examples, audio null/opsional.
- `DemoKnowledgeSeeder`: AI knowledge items draft/published/archived dan chunking jika service existing perlu dipanggil.
- `DemoLearningSeeder`: module templates, lessons, class modules, class lessons.
- `DemoQuizSeeder`: quiz templates, questions/options, class quizzes.
- `DemoSpeakingSeeder`: admin speaking templates, teacher class speaking exercises, optional attempts fixture.
- `DemoCultureSeeder`: global culture items/templates, class culture items if needed.
- `DemoProgressSeeder`: lesson/module progress, quiz attempts, speaking attempts; hanya jika aman dan constraint jelas.

Urutan aman:
1. Accounts
2. Schools/classes/assignments/memberships
3. Dictionary/examples
4. Knowledge
5. Learning modules/lessons
6. Quizzes/questions/class quizzes
7. Speaking templates/exercises
8. Culture
9. Progress/attempts
10. Settings/banner opsional

## Risiko dan Validasi

- Kosakata Mekongga, contoh kalimat, sapaan, dan arti kata perlu validasi narasumber. Data dalam plan ini hanya rancangan demo.
- Deskripsi budaya Mekongga perlu validasi narasumber agar tidak salah merepresentasikan adat/budaya.
- Nama sekolah dalam plan bersifat fiktif untuk menghindari klaim data resmi; jika memakai sekolah nyata, perlu persetujuan.
- Reference audio speaking sebaiknya dibuat setelah teks divalidasi; jangan pakai rekaman tanpa izin.
- Progress/attempt seed berisiko melanggar constraint jika insert manual; gunakan service/domain flow existing saat implementasi.
- Seeder tidak boleh dijalankan otomatis di production tanpa flag/env eksplisit seperti `EMI_ENABLE_DEMO_SEEDER=true`.
- Password demo harus berasal dari env seperti `EMI_DEMO_PASSWORD`; jangan tulis password rahasia di repo.
- Media budaya/foto/video perlu izin penggunaan sebelum demo client.
