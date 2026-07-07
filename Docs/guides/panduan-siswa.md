# Panduan Siswa EMI

## 1. Tentang Role Siswa

Siswa adalah pengguna yang belajar di EMI. Siswa dapat membuka modul, membaca materi, mencari kata di kamus, latihan speaking, mengerjakan kuis, memakai chatbot, dan melihat progress belajar.

Siswa hanya melihat materi dari kelasnya. Jika modul atau kuis belum muncul, siswa bisa bertanya kepada guru.

## 2. Akun Demo Siswa

Contoh email akun demo siswa:

`siswa.nanda@emi.local`

`siswa.mira@emi.local`

`siswa.rafi@emi.local`

Password mengikuti password demo yang diberikan pengelola sistem.

Jangan membagikan password demo kepada orang lain.

## 3. Cara Login

1. Buka halaman login.
2. Masukkan email dan password siswa.
3. Klik Masuk.
4. Sistem akan membuka dashboard siswa.

[Screenshot: Halaman Login Siswa]

## 4. Ringkasan Alur Belajar Siswa

Login → Dashboard → Buka Modul → Baca Materi → Kerjakan Kuis → Latihan Speaking → Gunakan Kamus/Chatbot → Lihat Progress.

Alur belajar sederhana:

1. Login sebagai siswa.
2. Lihat ringkasan di dashboard.
3. Buka modul belajar.
4. Baca materi sampai selesai.
5. Kerjakan kuis jika tersedia.
6. Latihan speaking jika ada tugas.
7. Gunakan kamus atau chatbot saat butuh bantuan.
8. Lihat progress belajar.

## 5. Panduan Tiap Menu Siswa

### Dashboard Siswa

- URL: `/student/dashboard`
- Tujuan: Melihat ringkasan belajar.
- Yang dapat dilihat:
  - Ringkasan modul.
  - Ringkasan kuis.
  - Progress belajar.
  - Kelas aktif.
- Yang dapat dilakukan:
  - Membuka menu belajar lain.
  - Mengecek kegiatan belajar terbaru.
- Langkah penggunaan:
  1. Login sebagai siswa.
  2. Buka dashboard siswa.
  3. Lihat ringkasan modul, kuis, dan progress.
  4. Pilih menu yang ingin dibuka.
- Hasil yang diharapkan: Siswa tahu kegiatan belajar yang perlu dilanjutkan.
- Catatan penting: Jika kelas belum muncul, hubungi guru atau admin.
- Placeholder screenshot:
  [Screenshot: Dashboard Siswa]

### Modul Belajar

- URL: `/student/modules`
- Tujuan: Melihat daftar modul belajar.
- Yang dapat dilihat:
  - Daftar modul dari kelas.
  - Status progress modul.
  - Judul dan ringkasan modul jika tersedia.
- Yang dapat dilakukan:
  - Membuka detail modul.
  - Mencari atau memfilter modul jika tersedia.
- Langkah penggunaan:
  1. Buka menu Modul Belajar.
  2. Pilih modul yang ingin dipelajari.
  3. Klik modul untuk membuka detail.
- Hasil yang diharapkan: Siswa dapat memilih modul belajar.
- Catatan penting: Modul yang belum diterbitkan guru tidak terlihat oleh siswa.
- Placeholder screenshot:
  [Screenshot: Modul Belajar]

### Detail Modul

- URL: `/student/modules/[moduleId]`
- Tujuan: Melihat isi modul dan daftar materi.
- Yang dapat dilihat:
  - Judul modul.
  - Deskripsi modul.
  - Daftar lesson atau materi.
  - Progress modul.
- Yang dapat dilakukan:
  - Memulai modul.
  - Membuka materi.
  - Melanjutkan belajar.
- Langkah penggunaan:
  1. Buka menu Modul Belajar.
  2. Pilih modul.
  3. Klik Mulai Modul jika tersedia.
  4. Pilih materi yang ingin dibaca.
- Hasil yang diharapkan: Siswa dapat masuk ke materi modul.
- Catatan penting: Tombol mulai mungkin tidak aktif jika modul sudah pernah dimulai.
- Placeholder screenshot:
  [Screenshot: Detail Modul]

### Detail Lesson

- URL: `/student/lessons/[lessonId]`
- Tujuan: Membaca materi belajar.
- Yang dapat dilihat:
  - Judul materi.
  - Isi materi.
  - Media jika tersedia.
  - Status progress materi.
- Yang dapat dilakukan:
  - Membaca materi.
  - Membuka media jika ada.
  - Menandai materi selesai.
- Langkah penggunaan:
  1. Buka detail modul.
  2. Pilih salah satu materi.
  3. Baca materi sampai selesai.
  4. Klik Tandai Selesai jika tersedia.
- Hasil yang diharapkan: Materi tercatat sudah dipelajari.
- Catatan penting: Pastikan koneksi internet stabil saat membuka media.
- Placeholder screenshot:
  [Screenshot: Detail Lesson]

### Kamus

- URL: `/student/dictionary`
- Tujuan: Mencari kata dalam kamus Mekongga.
- Yang dapat dilihat:
  - Daftar kata.
  - Kategori kata.
  - Arti kata.
  - Audio jika tersedia.
  - Contoh kalimat jika tersedia.
- Yang dapat dilakukan:
  - Mencari kata.
  - Memfilter kategori jika tersedia.
  - Membuka detail kata.
- Langkah penggunaan:
  1. Buka menu Kamus.
  2. Ketik kata yang ingin dicari.
  3. Pilih kata dari daftar.
  4. Buka detail untuk melihat arti lengkap.
- Hasil yang diharapkan: Siswa menemukan arti kata yang dicari.
- Catatan penting: Jika kata belum ada, tanyakan kepada guru.
- Placeholder screenshot:
  [Screenshot: Kamus]

### Detail Kamus

- URL: `/student/dictionary/[entryId]`
- Tujuan: Melihat detail satu kata kamus.
- Yang dapat dilihat:
  - Kata.
  - Arti.
  - Kategori.
  - Audio jika tersedia.
  - Contoh kalimat.
- Yang dapat dilakukan:
  - Membaca arti kata.
  - Memutar audio jika tersedia.
  - Kembali ke daftar kamus.
- Langkah penggunaan:
  1. Buka menu Kamus.
  2. Pilih kata.
  3. Baca arti dan contoh kalimat.
  4. Putar audio jika tersedia.
- Hasil yang diharapkan: Siswa memahami arti kata dan contoh pemakaiannya.
- Catatan penting: Tidak semua kata memiliki audio.
- Placeholder screenshot:
  [Screenshot: Detail Kamus]

### Latihan Speaking

- URL: `/student/speaking`
- Tujuan: Berlatih mengucapkan kata atau kalimat.
- Yang dapat dilihat:
  - Daftar latihan speaking.
  - Instruksi latihan.
  - Audio contoh jika tersedia.
  - Riwayat latihan jika tersedia.
- Yang dapat dilakukan:
  - Memilih latihan.
  - Mulai rekaman.
  - Berhenti rekaman.
  - Mengirim hasil rekaman.
- Langkah penggunaan:
  1. Buka menu Latihan Speaking.
  2. Pilih latihan.
  3. Izinkan akses mikrofon jika diminta browser.
  4. Klik mulai rekaman.
  5. Ucapkan kalimat dengan jelas.
  6. Klik berhenti lalu kirim.
- Hasil yang diharapkan: Rekaman speaking terkirim untuk dinilai atau ditinjau.
- Catatan penting: Latihan speaking membutuhkan mikrofon dan koneksi internet stabil.
- Placeholder screenshot:
  [Screenshot: Latihan Speaking]

### Hasil Speaking

- URL: `/student/speaking/results`
- Tujuan: Melihat hasil latihan speaking.
- Yang dapat dilihat:
  - Riwayat latihan speaking.
  - Skor jika tersedia.
  - Feedback jika tersedia.
  - Status analisis.
- Yang dapat dilakukan:
  - Membuka detail hasil jika tersedia.
  - Membaca feedback dari guru atau sistem.
- Langkah penggunaan:
  1. Buka menu Hasil Speaking.
  2. Pilih hasil latihan.
  3. Lihat skor, status, dan feedback.
  4. Gunakan feedback untuk latihan berikutnya.
- Hasil yang diharapkan: Siswa tahu hasil latihan speaking.
- Catatan penting: Jika analisis gagal, coba latihan ulang atau tanyakan kepada guru.
- Placeholder screenshot:
  [Screenshot: Hasil Speaking]

### Kuis

- URL: `/student/quizzes`
- Tujuan: Melihat daftar kuis yang bisa dikerjakan.
- Yang dapat dilihat:
  - Daftar kuis.
  - Jadwal kuis jika tersedia.
  - Jumlah percobaan.
  - Status kuis.
- Yang dapat dilakukan:
  - Membuka detail kuis.
  - Melanjutkan kuis jika tersedia.
  - Melihat hasil kuis jika tersedia.
- Langkah penggunaan:
  1. Buka menu Kuis.
  2. Pilih kuis yang ingin dikerjakan.
  3. Buka detail kuis.
  4. Ikuti instruksi di halaman kuis.
- Hasil yang diharapkan: Siswa dapat memilih kuis yang tersedia.
- Catatan penting: Kuis bisa memiliki jadwal dan batas percobaan.
- Placeholder screenshot:
  [Screenshot: Kuis]

### Detail Kuis

- URL: `/student/quizzes/[quizId]`
- Tujuan: Melihat informasi kuis sebelum mulai.
- Yang dapat dilihat:
  - Judul kuis.
  - Instruksi.
  - Jumlah soal.
  - Batas percobaan.
  - Jadwal jika tersedia.
- Yang dapat dilakukan:
  - Membaca instruksi kuis.
  - Memulai kuis.
- Langkah penggunaan:
  1. Buka menu Kuis.
  2. Pilih kuis.
  3. Baca instruksi dengan teliti.
  4. Klik Mulai Kuis jika siap.
- Hasil yang diharapkan: Siswa siap mengerjakan kuis.
- Catatan penting: Jangan mulai kuis jika koneksi internet sedang tidak stabil.
- Placeholder screenshot:
  [Screenshot: Detail Kuis]

### Attempt Kuis

- URL: `/student/quizzes/[quizId]/attempt`
- Tujuan: Mengerjakan soal kuis.
- Yang dapat dilihat:
  - Pertanyaan.
  - Pilihan jawaban.
  - Navigasi soal.
- Yang dapat dilakukan:
  - Memilih jawaban.
  - Pindah ke soal sebelumnya.
  - Pindah ke soal berikutnya.
  - Mengirim jawaban kuis.
- Langkah penggunaan:
  1. Baca pertanyaan dengan teliti.
  2. Pilih jawaban yang paling tepat.
  3. Klik Berikutnya untuk lanjut.
  4. Periksa jawaban sebelum selesai.
  5. Klik Submit atau Kirim jika sudah yakin.
- Hasil yang diharapkan: Jawaban kuis terkirim.
- Catatan penting: Jangan menutup halaman saat kuis sedang dikerjakan.
- Placeholder screenshot:
  [Screenshot: Attempt Kuis]

### Hasil Kuis

- URL: `/student/quizzes/[quizId]/result`
- Tujuan: Melihat hasil kuis.
- Yang dapat dilihat:
  - Skor kuis.
  - Status lulus jika tersedia.
  - Jawaban benar atau salah jika diizinkan guru.
- Yang dapat dilakukan:
  - Membaca hasil kuis.
  - Kembali ke daftar kuis.
  - Mengulang jika masih ada kesempatan dan diizinkan.
- Langkah penggunaan:
  1. Selesaikan kuis.
  2. Buka halaman hasil.
  3. Lihat skor dan status.
  4. Baca pembahasan jika tersedia.
  5. Kembali ke daftar kuis jika selesai.
- Hasil yang diharapkan: Siswa mengetahui nilai kuis.
- Catatan penting: Detail jawaban mungkin disembunyikan oleh pengaturan kuis.
- Placeholder screenshot:
  [Screenshot: Hasil Kuis]

### Budaya Mekongga

- URL: `/student/culture`
- Tujuan: Melihat konten budaya Mekongga.
- Yang dapat dilihat:
  - Konten budaya.
  - Teks, media, atau link jika tersedia.
- Yang dapat dilakukan:
  - Membaca konten budaya.
  - Membuka media atau link jika tersedia.
- Langkah penggunaan:
  1. Buka menu Budaya Mekongga.
  2. Pilih konten yang ingin dilihat.
  3. Baca isi konten.
  4. Buka media atau link jika tersedia.
- Hasil yang diharapkan: Siswa mengenal budaya Mekongga dari materi yang disediakan.
- Catatan penting: Ikuti arahan guru saat mempelajari konten budaya.
- Placeholder screenshot:
  [Screenshot: Budaya Mekongga]

### Chatbot AI

- URL: `/student/chatbot`
- Tujuan: Bertanya tentang materi, kamus, atau informasi belajar.
- Yang dapat dilihat:
  - Kolom chat.
  - Jawaban chatbot.
  - Referensi atau sumber jika tersedia.
  - Saran pertanyaan jika tersedia.
- Yang dapat dilakukan:
  - Menulis pertanyaan.
  - Mengirim pertanyaan.
  - Membuka referensi jika tersedia.
  - Memilih saran pertanyaan jika tersedia.
- Langkah penggunaan:
  1. Buka menu Chatbot AI.
  2. Ketik pertanyaan dengan jelas dan sopan.
  3. Klik Kirim.
  4. Baca jawaban chatbot.
  5. Tanyakan kepada guru jika jawaban belum jelas.
- Hasil yang diharapkan: Siswa mendapat bantuan belajar.
- Catatan penting: Chatbot membantu belajar, tetapi arahan guru tetap utama.
- Placeholder screenshot:
  [Screenshot: Chatbot AI]

### Progress Belajar

- URL: `/student/progress`
- Tujuan: Melihat perkembangan belajar sendiri.
- Yang dapat dilihat:
  - Progress modul.
  - Progress materi.
  - Skor kuis.
  - Ringkasan belajar.
- Yang dapat dilakukan:
  - Melihat progress sendiri.
  - Memfilter periode jika tersedia.
  - Mencetak laporan jika tersedia.
- Langkah penggunaan:
  1. Buka menu Progress Belajar.
  2. Lihat ringkasan progress.
  3. Periksa modul, materi, dan kuis yang sudah dikerjakan.
  4. Gunakan informasi ini untuk melanjutkan belajar.
- Hasil yang diharapkan: Siswa tahu bagian mana yang sudah selesai dan belum selesai.
- Catatan penting: Progress bisa butuh waktu untuk berubah setelah belajar.
- Placeholder screenshot:
  [Screenshot: Progress Belajar]

### Profil Siswa

- URL: `/student/profile`
- Tujuan: Melihat dan memperbarui profil siswa.
- Yang dapat dilihat:
  - Nama siswa.
  - Email.
  - Role dan status.
  - Kelas aktif.
  - Nomor telepon jika tersedia.
- Yang dapat dilakukan:
  - Mengubah nama jika tersedia.
  - Mengubah nomor telepon jika tersedia.
  - Menyimpan profil.
- Langkah penggunaan:
  1. Buka menu Profil Siswa.
  2. Periksa data profil.
  3. Ubah data yang boleh diubah.
  4. Klik Simpan Profil.
- Hasil yang diharapkan: Profil siswa sesuai data terbaru.
- Catatan penting: Email dan status biasanya hanya bisa dilihat. Ubah password tidak terlihat di halaman profil siswa.
- Placeholder screenshot:
  [Screenshot: Profil Siswa]

## 6. FAQ Siswa

### Mengapa saya tidak bisa login?

Pastikan email dan password benar. Jika masih gagal, tanyakan kepada guru atau admin apakah akun sudah aktif.

### Mengapa modul belum muncul?

Modul muncul jika guru sudah menerbitkan modul untuk kelas. Jika belum ada modul, tanyakan kepada guru.

### Bagaimana cara menyelesaikan materi?

Buka modul, pilih materi, baca sampai selesai, lalu klik Tandai Selesai jika tombol tersedia.

### Bagaimana cara mengerjakan kuis?

Buka menu Kuis, pilih kuis, baca instruksi, klik Mulai Kuis, jawab soal, lalu kirim jawaban.

### Mengapa latihan speaking membutuhkan izin mikrofon?

EMI perlu mikrofon untuk merekam suara saat latihan speaking. Pilih Izinkan saat browser meminta izin.

### Bagaimana cara melihat nilai kuis?

Setelah kuis selesai dikirim, buka halaman Hasil Kuis atau kembali ke daftar Kuis dan pilih hasil kuis.

### Bagaimana cara bertanya ke chatbot?

Buka Chatbot AI, ketik pertanyaan dengan jelas dan sopan, lalu klik Kirim.

### Mengapa hasil speaking belum keluar?

Hasil speaking bisa membutuhkan waktu. Jika lama tidak muncul atau gagal, coba ulangi latihan atau tanya guru.

## 7. Troubleshooting Siswa

### Tidak bisa login

1. Periksa email.
2. Periksa password.
3. Pastikan koneksi internet aktif.
4. Jika masih gagal, hubungi guru atau admin.

### Modul kosong

1. Refresh halaman.
2. Pastikan siswa sudah masuk kelas.
3. Tanyakan kepada guru apakah modul sudah diterbitkan.
4. Cek lagi setelah guru menyiapkan modul.

### Materi tidak bisa dibuka

1. Pastikan koneksi internet stabil.
2. Coba refresh halaman.
3. Buka ulang modul.
4. Jika masih gagal, laporkan ke guru.

### Kuis tidak bisa dimulai

1. Periksa jadwal kuis.
2. Pastikan kuis sudah diterbitkan guru.
3. Pastikan batas percobaan belum habis.
4. Coba refresh halaman.
5. Jika masih gagal, hubungi guru.

### Mikrofon tidak aktif

1. Klik Izinkan saat browser meminta akses mikrofon.
2. Pastikan mikrofon perangkat menyala.
3. Tutup aplikasi lain yang memakai mikrofon.
4. Coba refresh halaman speaking.
5. Jika tetap gagal, gunakan perangkat lain atau minta bantuan guru.

### Speaking gagal dianalisis

1. Pastikan suara jelas.
2. Pastikan internet stabil.
3. Coba rekam ulang.
4. Jangan menutup halaman saat proses kirim.
5. Jika masih gagal, tanyakan kepada guru.

### Chatbot tidak menjawab sesuai harapan

1. Tulis pertanyaan lebih jelas.
2. Gunakan kata yang sederhana.
3. Coba tanyakan satu hal saja dalam satu pesan.
4. Jika jawaban masih belum jelas, tanyakan kepada guru.

### Progress belum berubah

1. Pastikan materi sudah ditandai selesai.
2. Pastikan kuis sudah dikirim.
3. Refresh halaman progress.
4. Tunggu beberapa saat.
5. Jika masih belum berubah, laporkan ke guru.

### Audio kamus tidak berbunyi

1. Pastikan volume perangkat menyala.
2. Coba putar ulang audio.
3. Pastikan internet stabil.
4. Jika audio tetap tidak berbunyi, tanyakan kepada guru.

## 8. Catatan untuk Siswa

Ikuti arahan guru saat belajar di EMI. Jika ada materi yang belum dipahami, tanyakan kepada guru.

Pastikan koneksi internet stabil, terutama saat membuka materi, mengerjakan kuis, dan mengirim rekaman speaking.

Izinkan akses mikrofon saat latihan speaking. Tanpa izin mikrofon, suara tidak bisa direkam.

Gunakan bahasa yang sopan saat bertanya ke chatbot. Chatbot membantu belajar, tetapi jawaban guru tetap menjadi arahan utama.

Bagian yang perlu review manual sebelum panduan final:


