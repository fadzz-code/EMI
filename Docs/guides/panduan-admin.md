# Panduan Admin EMI

## 1. Tentang Role Admin

Admin adalah pengguna yang mengatur data utama di EMI. Admin membantu sekolah mengelola akun, sekolah, kelas, guru, siswa, kamus, basis AI, modul, kuis, latihan speaking, konten budaya, laporan progres, dan pengaturan sistem.

Admin biasanya dipakai oleh operator sekolah atau pengelola sistem. Tugas utama admin adalah memastikan data rapi, akun pengguna aktif, materi siap dipakai, dan progres belajar dapat dipantau.

## 2. Akun Demo Admin

Contoh email akun demo admin:

`admin.demo@emi.local`

Password mengikuti password demo yang diberikan pengelola sistem.

Jangan membagikan password demo di dokumen umum, chat grup terbuka, atau media yang tidak aman.

## 3. Cara Login

1. Buka halaman login.
2. Masukkan email dan password.
3. Klik Masuk.
4. Sistem akan membuka dashboard admin.

[Screenshot: Halaman Login]

## 4. Ringkasan Alur Kerja Admin

Login → Dashboard → Kelola akun/sekolah/kelas → Kelola kamus/basis AI/modul/kuis → Pantau progres → Pengaturan sistem.

Alur sederhana penggunaan admin:

1. Login sebagai admin.
2. Cek ringkasan data di dashboard.
3. Setujui akun guru atau siswa yang mendaftar.
4. Pastikan sekolah dan kelas sudah benar.
5. Masukkan guru dan siswa ke kelas yang sesuai.
6. Siapkan kamus, basis AI, modul, kuis, speaking, dan budaya.
7. Pantau progres kelas dan siswa.
8. Perbarui pengaturan sistem jika diperlukan.

## 5. Panduan Tiap Menu Admin

### Dashboard Admin

- URL: `/admin/dashboard`
- Tujuan: Melihat ringkasan kondisi EMI secara cepat.
- Yang dapat dilihat:
  - Ringkasan sekolah, kelas, siswa, dan progres.
  - Kartu laporan atau tren belajar jika tersedia.
- Yang dapat dilakukan:
  - Membuka menu admin lain dari kartu atau navigasi.
  - Mengecek apakah data utama sudah muncul setelah login.
- Langkah penggunaan:
  1. Login sebagai admin.
  2. Buka dashboard admin.
  3. Periksa ringkasan data yang tampil.
  4. Klik menu lain jika perlu mengelola data lebih lanjut.
- Hasil yang diharapkan: Admin melihat gambaran umum sistem.
- Catatan penting: Jika data kosong, pastikan sekolah, kelas, guru, siswa, dan progres demo sudah tersedia.
- Placeholder screenshot:
  [Screenshot: Dashboard Admin]

### Persetujuan Akun

- URL: `/admin/approvals`
- Tujuan: Meninjau pendaftaran akun guru dan siswa.
- Yang dapat dilihat:
  - Daftar permintaan pendaftaran.
  - Nama, email, role, status, sekolah, dan kelas tujuan.
  - Jumlah permintaan yang masih menunggu.
- Yang dapat dilakukan:
  - Mencari permintaan pendaftaran.
  - Memfilter berdasarkan role atau status.
  - Membuka detail permintaan.
  - Menyetujui atau menolak akun.
- Langkah penggunaan:
  1. Buka menu Persetujuan Akun.
  2. Cari nama atau email pengguna.
  3. Periksa role, sekolah, dan kelas tujuan.
  4. Klik Setujui jika data benar.
  5. Klik Tolak jika data tidak sesuai, lalu isi alasan jika diminta.
- Hasil yang diharapkan: Akun yang valid disetujui dan akun yang tidak valid ditolak.
- Catatan penting: Setujui akun hanya jika identitas dan kelas tujuan sudah benar.
- Placeholder screenshot:
  [Screenshot: Persetujuan Akun]

### Detail Persetujuan

- URL: `/admin/approvals/[requestId]`
- Tujuan: Melihat satu permintaan pendaftaran secara lebih lengkap.
- Yang dapat dilihat:
  - Identitas pemohon.
  - Role pengguna.
  - Sekolah atau kelas tujuan.
  - Status permintaan.
- Yang dapat dilakukan:
  - Menyetujui permintaan.
  - Menolak permintaan.
  - Kembali ke daftar persetujuan.
- Langkah penggunaan:
  1. Buka menu Persetujuan Akun.
  2. Klik salah satu permintaan.
  3. Periksa detail pemohon.
  4. Klik Setujui atau Tolak sesuai hasil pemeriksaan.
- Hasil yang diharapkan: Satu permintaan pendaftaran selesai diproses.
- Catatan penting: Jika permintaan sudah diproses, tombol setujui atau tolak mungkin tidak tersedia.
- Placeholder screenshot:
  [Screenshot: Detail Persetujuan]

### Sekolah & Kelas

- URL: `/admin/schools-classes`
- Tujuan: Mengelola data sekolah dan kelas.
- Yang dapat dilihat:
  - Daftar sekolah.
  - Daftar kelas.
  - Status aktif atau tidak aktif.
  - Tahun ajaran dan relasi sekolah.
- Yang dapat dilakukan:
  - Menambah sekolah.
  - Mengubah data sekolah.
  - Menambah kelas.
  - Mengubah data kelas.
  - Menonaktifkan atau menghapus data jika tersedia.
- Langkah penggunaan:
  1. Buka menu Sekolah & Kelas.
  2. Pilih bagian sekolah atau kelas.
  3. Klik Tambah untuk membuat data baru.
  4. Isi nama, tahun ajaran, status, dan data lain yang diminta.
  5. Klik Simpan.
- Hasil yang diharapkan: Data sekolah dan kelas tersimpan rapi.
- Catatan penting: Sekolah atau kelas yang masih dipakai mungkin tidak bisa dihapus langsung.
- Placeholder screenshot:
  [Screenshot: Sekolah & Kelas]

### Detail Kelas

- URL: `/admin/classes/[classId]`
- Tujuan: Melihat detail kelas dan mengatur guru serta siswa di kelas tersebut.
- Yang dapat dilihat:
  - Nama kelas.
  - Sekolah.
  - Guru aktif.
  - Daftar siswa.
- Yang dapat dilakukan:
  - Menugaskan guru ke kelas.
  - Mengganti guru kelas.
  - Menambahkan siswa ke kelas.
  - Memindahkan siswa jika tersedia.
  - Membuka detail user jika tersedia.
- Langkah penggunaan:
  1. Buka menu Sekolah & Kelas.
  2. Pilih kelas yang ingin dikelola.
  3. Periksa guru dan daftar siswa.
  4. Pilih guru atau siswa yang akan ditambahkan.
  5. Simpan perubahan.
- Hasil yang diharapkan: Kelas memiliki guru dan siswa yang sesuai.
- Catatan penting: Satu kelas hanya memiliki satu guru aktif, dan satu siswa hanya memiliki satu kelas aktif.
- Placeholder screenshot:
  [Screenshot: Detail Kelas]

### Guru & Siswa

- URL: `/admin/users`
- Tujuan: Mengelola akun guru dan siswa.
- Yang dapat dilihat:
  - Daftar pengguna.
  - Nama, email, role, status, sekolah, dan kelas.
- Yang dapat dilakukan:
  - Mencari pengguna.
  - Memfilter pengguna berdasarkan role, status, sekolah, atau kelas.
  - Membuka detail pengguna.
  - Mengubah data pengguna.
  - Mengubah status akun.
- Langkah penggunaan:
  1. Buka menu Guru & Siswa.
  2. Cari nama atau email pengguna.
  3. Buka detail pengguna jika perlu.
  4. Ubah data atau status sesuai kebutuhan.
  5. Simpan perubahan.
- Hasil yang diharapkan: Data akun guru dan siswa selalu benar dan terbaru.
- Catatan penting: Hati-hati saat menonaktifkan akun, karena pengguna mungkin tidak bisa login lagi.
- Placeholder screenshot:
  [Screenshot: Guru & Siswa]

### Detail User

- URL: `/admin/users/[userId]`
- Tujuan: Melihat dan mengubah detail satu pengguna.
- Yang dapat dilihat:
  - Profil pengguna.
  - Role.
  - Status akun.
  - Kelas atau assignment terkait.
- Yang dapat dilakukan:
  - Mengubah nama atau nomor telepon jika tersedia.
  - Mengubah status akun.
  - Menyimpan perubahan.
  - Kembali ke daftar pengguna.
- Langkah penggunaan:
  1. Buka menu Guru & Siswa.
  2. Pilih pengguna.
  3. Periksa data profil dan kelas terkait.
  4. Ubah data yang diperlukan.
  5. Klik Simpan.
- Hasil yang diharapkan: Profil pengguna sesuai data terbaru.
- Catatan penting: Beberapa kolom seperti email atau status tertentu mungkin tidak bisa diubah bebas.
- Placeholder screenshot:
  [Screenshot: Detail User]

### Kamus

- URL: `/admin/dictionary`
- Tujuan: Mengelola kategori dan kata dalam kamus EMI.
- Yang dapat dilihat:
  - Daftar kata.
  - Kategori.
  - Terjemahan atau arti.
  - Status kata.
  - Audio dan contoh kalimat jika tersedia.
- Yang dapat dilakukan:
  - Menambah kategori.
  - Menambah kata.
  - Mencari atau memfilter kata.
  - Membuka detail kata.
  - Menghapus atau menonaktifkan entri jika tersedia.
- Langkah penggunaan:
  1. Buka menu Kamus.
  2. Pilih Tambah Kategori atau Tambah Kata.
  3. Isi kata, arti, kategori, dan status.
  4. Unggah audio jika tersedia.
  5. Klik Simpan.
- Hasil yang diharapkan: Kata kamus dapat dipakai sebagai bahan belajar siswa.
- Catatan penting: Kosakata dan contoh kalimat bahasa daerah perlu divalidasi narasumber.
- Placeholder screenshot:
  [Screenshot: Kamus]

### Detail Kamus

- URL: `/admin/dictionary/[entryId]`
- Tujuan: Melihat dan mengubah satu entri kamus.
- Yang dapat dilihat:
  - Kata.
  - Arti atau terjemahan.
  - Kategori.
  - Audio.
  - Contoh kalimat.
- Yang dapat dilakukan:
  - Mengubah data kata.
  - Mengunggah atau melepas audio jika tersedia.
  - Menyimpan perubahan.
- Langkah penggunaan:
  1. Buka menu Kamus.
  2. Pilih kata yang ingin diperiksa.
  3. Periksa arti, kategori, audio, dan contoh kalimat.
  4. Ubah data jika perlu.
  5. Klik Simpan.
- Hasil yang diharapkan: Detail kata kamus benar dan lengkap.
- Catatan penting: Jika contoh kalimat belum muncul, periksa hasil import contoh kalimat.
- Placeholder screenshot:
  [Screenshot: Detail Kamus]

### Import Kamus

- URL: `/admin/dictionary/import`
- Tujuan: Mengimpor banyak data kamus atau contoh kalimat sekaligus.
- Yang dapat dilihat:
  - Pilihan import kosakata.
  - Pilihan import contoh kalimat.
  - Template file.
  - Preview data.
  - Riwayat import dan daftar error jika ada.
- Yang dapat dilakukan:
  - Mengunduh template.
  - Mengunggah file CSV.
  - Mengunggah ZIP audio jika tersedia.
  - Melihat preview.
  - Mengonfirmasi import.
- Langkah penggunaan:
  1. Buka menu Import Kamus.
  2. Unduh template yang sesuai.
  3. Isi data di file CSV sesuai format template.
  4. Unggah file CSV.
  5. Cek preview dan error.
  6. Klik konfirmasi import jika data sudah benar.
- Hasil yang diharapkan: Data kamus atau contoh kalimat masuk ke sistem.
- Catatan penting: Jangan mengubah nama kolom template. Nama file audio harus sesuai jika memakai ZIP audio.
- Placeholder screenshot:
  [Screenshot: Import Kamus]

### Basis AI

- URL: `/admin/knowledge-base`
- Tujuan: Mengelola pengetahuan yang dipakai chatbot AI.
- Yang dapat dilihat:
  - Daftar pengetahuan.
  - Status draft, published, atau archived.
  - Sumber dan ringkasan isi.
- Yang dapat dilakukan:
  - Menambah pengetahuan.
  - Mengedit pengetahuan.
  - Melihat preview.
  - Menerbitkan pengetahuan.
  - Mengarsipkan atau menghapus pengetahuan jika tersedia.
  - Mengimpor dari teks, URL publik, atau PDF jika tersedia.
- Langkah penggunaan:
  1. Buka menu Basis AI.
  2. Klik Tambah Pengetahuan.
  3. Isi judul dan isi pengetahuan.
  4. Simpan sebagai draft atau terbitkan jika sudah siap.
  5. Cek status pengetahuan di daftar.
- Hasil yang diharapkan: Chatbot memiliki bahan jawaban yang benar dan siap dipakai.
- Catatan penting: Hanya pengetahuan yang diterbitkan yang dipakai chatbot. Materi budaya atau bahasa harus direview dulu.
- Placeholder screenshot:
  [Screenshot: Basis AI]

### Detail Basis AI

- URL: `/admin/knowledge-base/[knowledgeId]`
- Tujuan: Melihat detail satu pengetahuan AI.
- Yang dapat dilihat:
  - Judul.
  - Isi.
  - Sumber.
  - Status.
  - Potongan isi jika tersedia.
- Yang dapat dilakukan:
  - Mengubah isi.
  - Menerbitkan.
  - Mengarsipkan.
  - Menghapus jika tersedia.
- Langkah penggunaan:
  1. Buka menu Basis AI.
  2. Pilih salah satu pengetahuan.
  3. Periksa isi dan statusnya.
  4. Ubah atau terbitkan jika sudah sesuai.
  5. Simpan perubahan.
- Hasil yang diharapkan: Pengetahuan AI sesuai materi yang disetujui.
- Catatan penting: Detail tombol dan isi halaman perlu dicek ulang saat review final.
- Placeholder screenshot:
  [Screenshot: Detail Basis AI]

### Modul

- URL: `/admin/modules`
- Tujuan: Mengelola template modul belajar.
- Yang dapat dilihat:
  - Daftar template modul.
  - Status modul.
  - Jumlah materi atau lesson.
- Yang dapat dilakukan:
  - Menambah modul.
  - Mengedit modul.
  - Menerbitkan modul.
  - Mengarsipkan atau menghapus modul jika tersedia.
  - Menerapkan template ke kelas jika tersedia.
- Langkah penggunaan:
  1. Buka menu Modul.
  2. Klik Tambah Modul.
  3. Isi judul, deskripsi, level atau kelas, status, dan urutan.
  4. Simpan modul.
  5. Buka halaman edit untuk menambah materi.
- Hasil yang diharapkan: Template modul siap dipakai guru atau kelas.
- Catatan penting: Modul perlu diterbitkan sebelum digunakan secara luas.
- Placeholder screenshot:
  [Screenshot: Modul]

### Edit Modul

- URL: `/admin/modules/[moduleId]/edit`
- Tujuan: Mengubah modul dan mengelola materi di dalamnya.
- Yang dapat dilihat:
  - Detail modul.
  - Daftar lesson atau materi.
  - Media materi jika tersedia.
- Yang dapat dilakukan:
  - Mengubah judul dan deskripsi modul.
  - Menambah materi.
  - Mengedit materi.
  - Menghapus materi jika tersedia.
  - Mengatur urutan materi.
  - Mengunggah media materi.
  - Menerbitkan modul.
- Langkah penggunaan:
  1. Buka menu Modul.
  2. Pilih modul yang ingin diedit.
  3. Perbarui data modul.
  4. Tambah atau ubah materi.
  5. Simpan perubahan.
  6. Terbitkan jika modul sudah final.
- Hasil yang diharapkan: Modul memiliki materi lengkap dan urutan yang benar.
- Catatan penting: Cek ulang isi materi sebelum diterbitkan.
- Placeholder screenshot:
  [Screenshot: Edit Modul]

### Kuis

- URL: `/admin/quizzes`
- Tujuan: Mengelola template kuis.
- Yang dapat dilihat:
  - Daftar template kuis.
  - Status kuis.
  - Jumlah soal.
  - Pengaturan nilai atau percobaan jika tersedia.
- Yang dapat dilakukan:
  - Menambah kuis.
  - Membuka builder kuis.
  - Menerbitkan kuis.
  - Mengarsipkan atau menghapus kuis jika tersedia.
  - Menerapkan template ke kelas jika tersedia.
- Langkah penggunaan:
  1. Buka menu Kuis.
  2. Klik Tambah Kuis.
  3. Isi judul, deskripsi, nilai kelulusan, dan pengaturan percobaan.
  4. Simpan kuis.
  5. Buka builder untuk menambah soal.
- Hasil yang diharapkan: Template kuis siap diisi soal dan digunakan.
- Catatan penting: Kuis yang sudah diterapkan ke kelas mungkin memiliki batasan perubahan.
- Placeholder screenshot:
  [Screenshot: Kuis]

### Builder Kuis

- URL: `/admin/quizzes/[quizId]/builder`
- Tujuan: Mengelola soal dan pilihan jawaban kuis.
- Yang dapat dilihat:
  - Detail kuis.
  - Daftar soal.
  - Opsi jawaban.
  - Kunci jawaban.
  - Gambar soal jika tersedia.
- Yang dapat dilakukan:
  - Menambah soal.
  - Mengubah soal.
  - Menghapus soal jika tersedia.
  - Menambah atau menghapus opsi jawaban.
  - Menentukan jawaban benar.
  - Mengunggah gambar soal.
  - Menerbitkan kuis.
- Langkah penggunaan:
  1. Buka menu Kuis.
  2. Pilih kuis dan buka builder.
  3. Tambahkan pertanyaan.
  4. Isi opsi jawaban.
  5. Tandai jawaban benar.
  6. Simpan dan terbitkan jika sudah siap.
- Hasil yang diharapkan: Kuis memiliki soal dan kunci jawaban yang benar.
- Catatan penting: Minimal opsi dan jawaban benar perlu dicek sebelum kuis diterbitkan.
- Placeholder screenshot:
  [Screenshot: Builder Kuis]

### Speaking Exercises

- URL: `/admin/speaking/exercises`
- Tujuan: Mengelola template latihan speaking.
- Yang dapat dilihat:
  - Daftar latihan speaking.
  - Status latihan.
  - Audio referensi jika tersedia.
- Yang dapat dilakukan:
  - Menambah latihan speaking.
  - Mengedit latihan.
  - Mengarsipkan latihan.
  - Mengunggah audio referensi.
- Langkah penggunaan:
  1. Buka menu Speaking Exercises.
  2. Klik Tambah.
  3. Isi judul, instruksi, dan teks latihan.
  4. Unggah audio referensi jika ada.
  5. Simpan atau terbitkan sesuai kebutuhan.
- Hasil yang diharapkan: Guru dapat memakai template speaking yang sudah siap.
- Catatan penting: Draft atau arsip tidak seharusnya dipakai sebagai template aktif. Audio perlu izin dan validasi.
- Placeholder screenshot:
  [Screenshot: Speaking Exercises]

### Budaya Mekongga

- URL: `/admin/culture/templates`
- Tujuan: Mengelola konten budaya Mekongga dan template budaya.
- Yang dapat dilihat:
  - Daftar konten budaya.
  - Status konten.
  - Media atau link jika tersedia.
- Yang dapat dilakukan:
  - Menambah konten budaya.
  - Mengedit konten.
  - Menerbitkan konten.
  - Mengarsipkan konten.
  - Menghapus konten jika tersedia.
- Langkah penggunaan:
  1. Buka menu Budaya Mekongga.
  2. Klik Tambah Konten Budaya.
  3. Isi judul, deskripsi, tipe konten, dan urutan.
  4. Tambahkan file atau URL jika tersedia.
  5. Simpan dan terbitkan jika sudah disetujui.
- Hasil yang diharapkan: Konten budaya tersedia sebagai bahan belajar.
- Catatan penting: Konten budaya harus divalidasi narasumber. Penghapusan konten global dapat berdampak ke banyak kelas.
- Placeholder screenshot:
  [Screenshot: Budaya Mekongga]

### Progress Admin

- URL: `/admin/progress`
- Tujuan: Melihat laporan progres sekolah, kelas, dan siswa.
- Yang dapat dilihat:
  - Ringkasan progres.
  - Tabel progres sekolah.
  - Tabel progres kelas.
  - Tabel progres siswa.
- Yang dapat dilakukan:
  - Memfilter laporan.
  - Melihat detail kelas.
  - Melihat detail siswa.
  - Export CSV atau print jika tersedia.
- Langkah penggunaan:
  1. Buka menu Progress Admin.
  2. Pilih filter periode, sekolah, atau kelas jika tersedia.
  3. Periksa ringkasan dan tabel progres.
  4. Klik detail kelas atau siswa untuk informasi lebih lengkap.
  5. Export laporan jika dibutuhkan.
- Hasil yang diharapkan: Admin dapat memantau perkembangan belajar.
- Catatan penting: Data progres tergantung aktivitas siswa di modul, kuis, dan latihan.
- Placeholder screenshot:
  [Screenshot: Progress Admin]

### Detail Progress Kelas

- URL: `/admin/progress/classes/[classId]`
- Tujuan: Melihat progres satu kelas.
- Yang dapat dilihat:
  - Ringkasan kelas.
  - Daftar siswa.
  - Progres modul dan kuis.
- Yang dapat dilakukan:
  - Memfilter periode jika tersedia.
  - Membuka detail siswa.
  - Print atau export jika tersedia.
- Langkah penggunaan:
  1. Buka menu Progress Admin.
  2. Pilih kelas yang ingin dilihat.
  3. Periksa daftar siswa dan progresnya.
  4. Buka detail siswa jika perlu.
  5. Export atau cetak laporan jika tersedia.
- Hasil yang diharapkan: Admin mengetahui progres belajar satu kelas.
- Catatan penting: Jika data kosong, cek apakah siswa sudah masuk kelas dan sudah belajar.
- Placeholder screenshot:
  [Screenshot: Detail Progress Kelas]

### Detail Progress Siswa

- URL: `/admin/progress/students/[studentId]`
- Tujuan: Melihat progres satu siswa.
- Yang dapat dilihat:
  - Profil siswa.
  - Progres modul.
  - Progres kuis.
  - Skor atau hasil belajar.
- Yang dapat dilakukan:
  - Memfilter periode jika tersedia.
  - Mencetak laporan jika tersedia.
  - Kembali ke laporan kelas atau daftar progress.
- Langkah penggunaan:
  1. Buka menu Progress Admin.
  2. Pilih siswa dari daftar atau detail kelas.
  3. Periksa modul, kuis, dan skor siswa.
  4. Cetak laporan jika diperlukan.
- Hasil yang diharapkan: Admin memahami perkembangan belajar siswa tertentu.
- Catatan penting: Perhitungan progres dan skor perlu dicek saat review final.
- Placeholder screenshot:
  [Screenshot: Detail Progress Siswa]

### Pengaturan Admin

- URL: `/admin/settings`
- Tujuan: Mengatur informasi aplikasi, profil admin, banner login, password, dan keamanan.
- Yang dapat dilihat:
  - Nama aplikasi.
  - Subtitle atau slogan.
  - Tahun ajaran.
  - Timezone.
  - Profil admin.
  - Preview banner login.
  - Activity log jika tersedia.
  - Pengaturan keamanan.
- Yang dapat dilakukan:
  - Menyimpan pengaturan aplikasi.
  - Mengubah profil admin.
  - Mengunggah banner login.
  - Mengaktifkan atau menonaktifkan banner.
  - Mengubah password.
  - Menyimpan pengaturan keamanan.
- Langkah penggunaan:
  1. Buka menu Pengaturan Admin.
  2. Pilih bagian yang ingin diubah.
  3. Isi data baru atau unggah banner.
  4. Klik Simpan pada bagian terkait.
  5. Cek hasilnya, terutama banner di halaman login.
- Hasil yang diharapkan: Pengaturan sistem tersimpan dan tampilan login sesuai kebutuhan sekolah.
- Catatan penting: Email dan status admin mungkin hanya bisa dilihat, bukan diubah. Toggle email mingguan mungkin hanya menyimpan pilihan, bukan mengirim email sungguhan.
- Placeholder screenshot:
  [Screenshot: Pengaturan Admin]

## 6. FAQ Admin

### Bagaimana jika guru belum bisa login?

Periksa apakah akun guru sudah disetujui di menu Persetujuan Akun. Jika sudah disetujui, cek status akun di menu Guru & Siswa. Pastikan juga guru memakai email dan password yang benar.

### Bagaimana cara menambahkan siswa ke kelas?

Buka Sekolah & Kelas, pilih kelas, lalu tambahkan siswa dari halaman Detail Kelas. Pastikan akun siswa sudah aktif atau disetujui.

### Mengapa data contoh kalimat tidak muncul?

Contoh kalimat biasanya berasal dari input atau import kamus. Periksa menu Detail Kamus dan riwayat Import Kamus. Pastikan contoh kalimat terhubung ke kata yang benar.

### Bagaimana cara mengubah banner login?

Buka Pengaturan Admin, cari bagian banner login, unggah gambar baru, aktifkan banner jika ada pilihan, lalu simpan. Setelah itu cek halaman login.

### Bagaimana cara melihat progress siswa?

Buka Progress Admin, pilih filter sekolah atau kelas jika perlu, lalu buka Detail Progress Siswa dari tabel laporan.

### Apakah admin bisa membuat materi belajar?

Admin dapat membuat template modul, kuis, speaking, dan konten budaya. Guru dapat memakai atau menyesuaikan materi tersebut untuk kelas.

### Apa beda draft, published, dan archived?

Draft berarti belum siap dipakai. Published berarti sudah diterbitkan. Archived berarti disimpan sebagai arsip dan tidak dipakai sebagai konten aktif.

## 7. Troubleshooting Admin

### Tidak bisa login

1. Pastikan email benar.
2. Pastikan password sesuai password demo yang diberikan pengelola sistem.
3. Pastikan akun admin masih aktif.
4. Jika tetap gagal, hubungi pengelola sistem.

### Data tidak muncul

1. Refresh halaman.
2. Periksa filter yang sedang aktif.
3. Pastikan data memang sudah dibuat, misalnya sekolah, kelas, atau user.
4. Jika data tetap kosong, minta pengelola sistem memeriksa data demo atau koneksi sistem.

### Import CSV gagal

1. Gunakan template CSV dari sistem.
2. Jangan mengubah nama kolom.
3. Pastikan format file tetap CSV.
4. Periksa pesan error di halaman import.
5. Perbaiki baris yang salah, lalu upload ulang.

### Banner tidak berubah

1. Pastikan file banner berhasil diunggah.
2. Pastikan banner sudah diaktifkan jika ada pilihan Aktifkan Banner.
3. Klik Simpan Banner.
4. Refresh halaman login.
5. Jika masih belum berubah, coba buka ulang browser atau hubungi pengelola sistem.

### Kuis/modul tidak terlihat siswa

1. Pastikan modul atau kuis sudah diterbitkan.
2. Pastikan modul atau kuis sudah diterapkan ke kelas siswa.
3. Pastikan siswa sudah masuk kelas yang benar.
4. Pastikan konten tidak dalam status draft atau archived.

### Guru atau siswa salah kelas

1. Buka Detail Kelas.
2. Periksa guru aktif dan daftar siswa.
3. Pindahkan atau sesuaikan assignment jika tersedia.
4. Simpan perubahan.

### Chatbot tidak menjawab sesuai materi

1. Buka Basis AI.
2. Pastikan pengetahuan yang benar sudah diterbitkan.
3. Periksa isi pengetahuan.
4. Jika materi budaya atau bahasa belum divalidasi, jangan dipakai sebagai jawaban final.

## 8. Catatan untuk Operator

Beberapa data bahasa dan budaya perlu validasi narasumber sebelum digunakan untuk demo resmi atau penggunaan sekolah. Ini termasuk kosakata Mekongga, arti kata, contoh kalimat, sapaan, teks speaking, deskripsi budaya, foto, audio, dan video budaya.

Gunakan data demo hanya sebagai contoh alur sistem. Jangan menganggap semua contoh bahasa dan budaya sebagai materi final sebelum disetujui narasumber.

Jika memakai sekolah, nama orang, foto, audio, atau video nyata, pastikan sudah ada izin penggunaan.

Bagian yang perlu review manual sebelum panduan final:

- Detail kartu dan tombol di Dashboard Admin.
- Tombol yang tampil untuk request persetujuan yang sudah diproses.
- Label hapus atau nonaktif pada sekolah dan kelas.
- Kolom read-only di Detail User.
- Tampilan detail Basis AI.
- Alur apply template modul, kuis, dan budaya ke kelas.
- Kondisi lock pada kuis yang sudah diterbitkan atau sudah dipakai.
- Tampilan export atau print laporan progress.
- Perhitungan progress dan skor siswa.
- Perilaku banner login setelah disimpan.
