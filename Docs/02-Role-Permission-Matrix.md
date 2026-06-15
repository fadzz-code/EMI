Role & Permission Matrix EMI v1.0

Role yang digunakan tetap:

Admin
Guru
Siswa

Keterangan:

Penuh: dapat melihat, menambah, mengubah, dan menghapus sesuai fungsi.
Kelas sendiri: hanya data kelas yang terhubung dengan akun guru.
Pribadi: hanya data milik siswa tersebut.
Lihat: hanya dapat membaca.
Tidak: tidak memiliki akses.
1. Aturan akses utama
Admin

Admin dapat:

mengelola seluruh sekolah dan kelas;
menyetujui atau menolak akun;
mengelola seluruh guru dan siswa;
masuk ke semua kelas;
membuat modul dan kuis default;
membuat atau mengubah modul dan kuis kelas;
mengelola kamus dan import CSV + ZIP audio;
mengelola basis pengetahuan AI;
melihat seluruh progress, hasil kuis, dan speaking;
mengelola pengaturan sistem.
Guru

Guru dapat:

mengakses satu kelas yang terhubung ke akunnya;
melihat siswa kelasnya;
membuat dan mengedit modul kelasnya;
mengambil modul default dari Admin;
membuat dan mengedit kuis kelasnya;
mengambil kuis default dari Admin;
melihat progress, nilai kuis, dan speaking siswa kelasnya;
mengelola media kelasnya.

Guru tidak dapat:

membuat sekolah atau kelas;
menyetujui akun;
melihat kelas lain;
mengubah kamus global;
mengubah basis pengetahuan AI;
mengubah modul atau kuis default Admin.
Siswa

Siswa dapat:

mengakses kelasnya sendiri;
melihat modul kelasnya;
mengerjakan kuis kelasnya;
membuka kamus;
latihan speaking;
menggunakan chatbot;
melihat progress pribadi;
mengunduh materi untuk penggunaan offline.

Siswa tidak dapat:

berpindah kelas sendiri;
melihat data siswa lain;
membuat atau mengubah modul;
membuat atau mengubah kuis;
mengelola kamus dan basis pengetahuan AI.
2. Autentikasi dan akun
Fitur	Admin	Guru	Siswa
Login	Ya	Ya, setelah disetujui	Ya, setelah disetujui
Logout	Ya	Ya	Ya
Melihat profil sendiri	Ya	Ya	Ya
Mengubah profil sendiri	Ya	Ya	Ya
Mengubah kata sandi sendiri	Ya	Ya	Ya
Mendaftar akun	Tidak diperlukan	Ya	Ya
Memilih sekolah dan kelas saat daftar	Tidak	Ya	Ya
Menyetujui pendaftaran	Penuh	Tidak	Tidak
Menolak pendaftaran	Penuh	Tidak	Tidak
Mengaktifkan/nonaktifkan akun	Penuh	Tidak	Tidak
Mengubah kelas pengguna	Penuh	Tidak	Tidak
Melihat seluruh akun	Penuh	Kelas sendiri	Pribadi

Aturan backend:

Guru dan siswa hanya dapat login jika users.status = approved.

Jika status masih pending:

403 — Akun masih menunggu persetujuan Admin.
3. Sekolah dan kelas
Fitur	Admin	Guru	Siswa
Melihat daftar sekolah	Penuh	Sekolah sendiri	Sekolah sendiri
Membuat sekolah	Penuh	Tidak	Tidak
Mengubah sekolah	Penuh	Tidak	Tidak
Menghapus/nonaktifkan sekolah	Penuh	Tidak	Tidak
Melihat seluruh kelas	Penuh	Kelas sendiri	Kelas sendiri
Membuat kelas	Penuh	Tidak	Tidak
Mengubah kelas	Penuh	Tidak	Tidak
Menonaktifkan kelas	Penuh	Tidak	Tidak
Menetapkan guru ke kelas	Penuh	Tidak	Tidak
Memindahkan siswa	Penuh	Tidak	Tidak
Melihat detail kelas	Penuh	Kelas sendiri	Informasi dasar kelas sendiri

Aturan penting:

1 akun guru = 1 kelas aktif
1 kelas = 1 guru aktif
1 siswa = 1 kelas aktif

Admin tetap dapat memindahkan siswa atau mengganti guru dengan menutup assignment lama dan membuat assignment baru.

4. Data guru dan siswa
Fitur	Admin	Guru	Siswa
Melihat seluruh guru	Penuh	Profil sendiri	Tidak
Melihat seluruh siswa	Penuh	Kelas sendiri	Tidak
Melihat detail siswa	Penuh	Kelas sendiri	Pribadi
Mengubah data guru	Penuh	Profil terbatas	Tidak
Mengubah data siswa	Penuh	Tidak	Profil terbatas
Menonaktifkan akun	Penuh	Tidak	Tidak
Melihat aktivitas belajar	Penuh	Kelas sendiri	Pribadi
Memberi catatan kepada siswa	Penuh	Kelas sendiri	Tidak
Melihat catatan guru	Penuh	Kelas sendiri	Opsional, jika dipublikasikan

Guru tidak boleh mengubah:

sekolah siswa;
kelas siswa;
status akun siswa;
role pengguna.
5. Modul default Admin
Fitur	Admin	Guru	Siswa
Melihat modul default	Penuh	Lihat	Tidak langsung
Membuat modul default	Penuh	Tidak	Tidak
Mengubah modul default	Penuh	Tidak	Tidak
Menghapus/arsip modul default	Penuh	Tidak	Tidak
Menambah materi template	Penuh	Tidak	Tidak
Menerapkan modul ke kelas	Penuh	Kelas sendiri melalui salinan	Tidak
Melihat pratinjau	Penuh	Ya	Tidak

Aturan:

module_templates
      ↓ disalin
class_modules

Guru tidak mengedit module_templates. Guru hanya mengedit hasil salinan pada class_modules.

6. Modul kelas
Fitur	Admin	Guru	Siswa
Melihat modul semua kelas	Penuh	Kelas sendiri	Kelas sendiri
Membuat modul kelas	Penuh	Kelas sendiri	Tidak
Mengubah modul kelas	Penuh	Kelas sendiri	Tidak
Menghapus/arsip modul kelas	Penuh	Kelas sendiri	Tidak
Menambah materi	Penuh	Kelas sendiri	Tidak
Upload PDF/audio/gambar/video	Penuh	Kelas sendiri	Tidak
Menerbitkan modul	Penuh	Kelas sendiri	Tidak
Membaca materi	Penuh	Kelas sendiri	Kelas sendiri
Menandai materi selesai	Tidak	Tidak	Pribadi
Mengunduh materi offline	Tidak wajib	Tidak wajib	Pribadi

Validasi Laravel:

Guru hanya dapat mengubah class_modules
jika class_modules.class_id sama dengan kelas aktif guru.
7. Progress modul
Fitur	Admin	Guru	Siswa
Melihat progress seluruh siswa	Penuh	Tidak	Tidak
Melihat progress per sekolah	Penuh	Tidak	Tidak
Melihat progress per kelas	Penuh	Kelas sendiri	Tidak
Melihat progress per siswa	Penuh	Kelas sendiri	Pribadi
Menandai materi selesai	Tidak	Tidak	Pribadi
Membatalkan status selesai	Penuh	Opsional kelas sendiri	Pribadi
Mengunduh laporan progress	Penuh	Kelas sendiri	Ringkasan pribadi
Memberi catatan progress	Penuh	Kelas sendiri	Tidak

Progress siswa tidak boleh dikirim menggunakan student_id bebas dari frontend. Backend harus mengambil identitas siswa dari token login.

8. Kuis default Admin
Fitur	Admin	Guru	Siswa
Melihat kuis default	Penuh	Lihat	Tidak langsung
Membuat kuis default	Penuh	Tidak	Tidak
Mengubah kuis default	Penuh	Tidak	Tidak
Mengarsipkan kuis default	Penuh	Tidak	Tidak
Menambah pilihan ganda	Penuh	Tidak	Tidak
Menambah isian singkat	Penuh	Tidak	Tidak
Menambahkan gambar soal	Penuh	Tidak	Tidak
Menerapkan ke kelas	Penuh	Kelas sendiri melalui salinan	Tidak

Kuis default disalin menjadi kuis kelas:

quiz_templates
      ↓ disalin
class_quizzes
9. Kuis kelas
Fitur	Admin	Guru	Siswa
Melihat kuis seluruh kelas	Penuh	Kelas sendiri	Kelas sendiri
Membuat kuis kelas	Penuh	Kelas sendiri	Tidak
Mengubah kuis kelas	Penuh	Kelas sendiri	Tidak
Menghapus/arsipkan kuis	Penuh	Kelas sendiri	Tidak
Menambah pilihan ganda	Penuh	Kelas sendiri	Tidak
Menambah isian singkat	Penuh	Kelas sendiri	Tidak
Upload gambar soal	Penuh	Kelas sendiri	Tidak
Mengatur durasi	Penuh	Kelas sendiri	Tidak
Mengatur waktu buka/tutup	Penuh	Kelas sendiri	Tidak
Menerbitkan kuis	Penuh	Kelas sendiri	Tidak
Mengerjakan kuis	Tidak	Tidak	Kelas sendiri
Mengumpulkan jawaban	Tidak	Tidak	Pribadi
Melihat hasil kuis	Penuh	Kelas sendiri	Pribadi
Melihat jawaban siswa	Penuh	Kelas sendiri	Pribadi
Memberi catatan	Penuh	Kelas sendiri	Tidak

Aturan pengerjaan:

Siswa hanya boleh mengerjakan kuis jika:
- kuis berstatus published;
- siswa berada di class_id kuis;
- waktu kuis masih aktif;
- attempt belum melewati max_attempts.
10. Kamus Mekongga
Fitur	Admin	Guru	Siswa
Melihat kamus	Penuh	Lihat	Lihat
Mencari kata	Penuh	Ya	Ya
Filter kategori	Penuh	Ya	Ya
Mendengarkan audio	Penuh	Ya	Ya
Melihat contoh kalimat	Penuh	Ya	Ya
Menambah kata manual	Penuh	Tidak	Tidak
Mengubah kata	Penuh	Tidak	Tidak
Menghapus kata	Penuh	Tidak	Tidak
Import CSV	Penuh	Tidak	Tidak
Upload ZIP audio	Penuh	Tidak	Tidak
Melihat preview import	Penuh	Tidak	Tidak
Melihat error import	Penuh	Tidak	Tidak
Mengulangi import gagal	Penuh	Tidak	Tidak
Menyimpan kata offline	Tidak wajib	Tidak wajib	Pribadi

Endpoint import harus hanya dapat digunakan Admin.

POST /api/admin/dictionary/import/validate
POST /api/admin/dictionary/import/confirm
11. Basis pengetahuan AI
Fitur	Admin	Guru	Siswa
Melihat daftar dokumen	Penuh	Tidak	Tidak
Menambah dokumen	Penuh	Tidak	Tidak
Mengubah dokumen	Penuh	Tidak	Tidak
Menghapus/arsip dokumen	Penuh	Tidak	Tidak
Menandai terverifikasi	Penuh	Tidak	Tidak
Menghubungkan dengan kamus	Penuh	Tidak	Tidak
Membuat embedding/chunk	Sistem/Admin	Tidak	Tidak
Menggunakan chatbot	Ya	Ya	Ya
Melihat sumber jawaban	Ya	Ya	Ya
Melihat percakapan pengguna lain	Penuh bila diperlukan	Tidak	Tidak

Chatbot hanya menggunakan dokumen dengan status:

verified

Jika data tidak ditemukan, jawaban sistem:

Informasi tersebut belum tersedia di basis pengetahuan EMI.
12. Konten budaya Mekongga
Fitur	Admin	Guru	Siswa
Melihat konten budaya	Penuh	Lihat	Lihat
Membuat konten	Penuh	Opsional kelas sendiri	Tidak
Mengubah konten global	Penuh	Tidak	Tidak
Upload gambar/video	Penuh	Opsional kelas sendiri	Tidak
Menerbitkan konten	Penuh	Tidak atau perlu review	Tidak
Mengarsipkan konten	Penuh	Tidak	Tidak
Menyimpan konten offline	Tidak wajib	Tidak wajib	Pribadi

Untuk versi awal, konten budaya global sebaiknya dikelola Admin.

13. Speaking practice
Fitur	Admin	Guru	Siswa
Melihat daftar speaking item	Penuh	Lihat	Lihat
Membuat speaking item	Penuh	Kelas sendiri opsional	Tidak
Mengubah target dan audio native	Penuh	Kelas sendiri opsional	Tidak
Mendengarkan audio native	Ya	Ya	Ya
Merekam suara	Tidak	Tidak	Pribadi
Mengirim penilaian	Tidak	Tidak	Pribadi
Melihat hasil seluruh siswa	Penuh	Tidak	Tidak
Melihat hasil kelas	Penuh	Kelas sendiri	Tidak
Melihat hasil sendiri	Tidak	Tidak	Pribadi
Mendengarkan rekaman siswa	Penuh	Kelas sendiri	Pribadi
Memberi catatan speaking	Penuh	Kelas sendiri	Tidak

Rekaman siswa termasuk data privat. URL file tidak boleh dapat diakses publik tanpa authorization atau signed URL.

14. Media dan file
Fitur	Admin	Guru	Siswa
Upload media global	Penuh	Tidak	Tidak
Upload media kelas	Penuh	Kelas sendiri	Tidak
Melihat media kelas	Penuh	Kelas sendiri	Sesuai materi
Menghapus media	Penuh	File kelas sendiri	Tidak
Upload rekaman speaking	Tidak	Tidak	Pribadi
Download materi	Ya	Ya	Kelas sendiri
Mengakses media kelas lain	Ya	Tidak	Tidak

File harus disimpan pada object storage dengan folder logis:

dictionary/audio/
modules/
quizzes/images/
culture/
speaking/recordings/
users/avatars/
15. Offline dan sinkronisasi mobile
Fitur	Admin	Guru	Siswa
Cache modul offline	Opsional	Opsional	Ya
Cache kamus	Opsional	Opsional	Ya
Download audio native	Opsional	Opsional	Ya
Menyimpan jawaban pending	Tidak	Tidak	Ya
Sinkronisasi progress	Tidak	Tidak	Pribadi
Sinkronisasi jawaban kuis	Tidak	Tidak	Pribadi
Sinkronisasi speaking	Tidak	Tidak	Pribadi
Melihat status sinkronisasi	Tidak wajib	Tidak wajib	Pribadi
Melihat seluruh sync logs	Penuh	Tidak	Tidak

Laravel harus memvalidasi bahwa data pending benar-benar milik user yang sedang login.

16. Laporan dan progress
Fitur	Admin	Guru	Siswa
Laporan seluruh sekolah	Penuh	Tidak	Tidak
Laporan per sekolah	Penuh	Tidak	Tidak
Laporan per kelas	Penuh	Kelas sendiri	Tidak
Laporan per siswa	Penuh	Kelas sendiri	Pribadi
Riwayat modul	Penuh	Kelas sendiri	Pribadi
Riwayat kuis	Penuh	Kelas sendiri	Pribadi
Riwayat speaking	Penuh	Kelas sendiri	Pribadi
Unduh laporan	Penuh	Kelas sendiri	Ringkasan pribadi
Cetak laporan	Penuh	Kelas sendiri	Ringkasan pribadi
17. Pengaturan dan audit
Fitur	Admin	Guru	Siswa
Mengubah nama aplikasi	Penuh	Tidak	Tidak
Mengubah tahun ajaran	Penuh	Tidak	Tidak
Membuka/menutup registrasi	Penuh	Tidak	Tidak
Mengatur batas upload	Penuh	Tidak	Tidak
Melihat audit log	Penuh	Tidak	Tidak
Mengelola notifikasi sistem	Penuh	Tidak	Tidak
Mengatur notifikasi pribadi	Ya	Ya	Ya
18. Daftar permission key untuk Laravel

Gunakan penamaan permission konsisten seperti berikut.

Pengguna dan approval
users.view_all
users.view_class
users.view_self
users.update
users.deactivate

registrations.view
registrations.approve
registrations.reject
Sekolah dan kelas
schools.view
schools.create
schools.update
schools.delete

classes.view_all
classes.view_own
classes.create
classes.update
classes.delete
classes.assign_teacher
classes.assign_student
Modul
module_templates.view
module_templates.create
module_templates.update
module_templates.delete
module_templates.apply

class_modules.view_all
class_modules.view_own
class_modules.create
class_modules.update
class_modules.delete
class_modules.publish
Kuis
quiz_templates.view
quiz_templates.create
quiz_templates.update
quiz_templates.delete
quiz_templates.apply

class_quizzes.view_all
class_quizzes.view_own
class_quizzes.create
class_quizzes.update
class_quizzes.delete
class_quizzes.publish

quiz_attempts.create
quiz_attempts.view_self
quiz_attempts.view_class
quiz_attempts.view_all
Kamus
dictionary.view
dictionary.create
dictionary.update
dictionary.delete
dictionary.import
dictionary.play_audio
AI
knowledge.view
knowledge.create
knowledge.update
knowledge.delete
knowledge.verify

chatbot.use
chatbot.view_own_history
chatbot.view_all_history
Progress dan speaking
progress.view_all
progress.view_class
progress.view_self
progress.export

speaking.attempt
speaking.view_all
speaking.view_class
speaking.view_self
speaking.add_note
19. Laravel middleware yang disarankan
Route::middleware(['auth:sanctum'])->group(function () {
    // Semua user yang sudah login
});

Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    // Admin only
});

Route::middleware(['auth:sanctum', 'role:teacher'])->group(function () {
    // Guru only
});

Route::middleware(['auth:sanctum', 'role:student'])->group(function () {
    // Siswa only
});

Middleware role saja belum cukup. Gunakan policy untuk mengecek kepemilikan data.

Contoh logika policy modul kelas:

public function update(User $user, ClassModule $module): bool
{
    if ($user->role === 'admin') {
        return true;
    }

    if ($user->role !== 'teacher') {
        return false;
    }

    return $user->activeTeacherAssignment?->class_id === $module->class_id;
}

Contoh policy siswa:

public function view(User $user, QuizAttempt $attempt): bool
{
    if ($user->role === 'admin') {
        return true;
    }

    if ($user->role === 'teacher') {
        return $user->activeTeacherAssignment?->class_id
            === $attempt->classQuiz->class_id;
    }

    return $attempt->student_id === $user->id;
}