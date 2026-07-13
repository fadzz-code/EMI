# Serah Terima Project EMI

## 1. Informasi Aplikasi

- Nama aplikasi: EMI - E-Learning Mekongga Indonesia
- Domain frontend: https://emi-kolaka.id
- Domain API: https://api.emi-kolaka.id
- Status: Online di VPS
- Environment: Production

## 2. Akun Demo

Admin:

- admin.demo@emi.local

Guru:

- guru.rina@emi.local
- guru.arman@emi.local

Siswa:

- siswa.nanda@emi.local
- siswa.mira@emi.local
- siswa.rafi@emi.local

Password demo diberikan terpisah oleh pengelola sistem.

## 3. Ringkasan Fitur

### Admin

- Dashboard
- Persetujuan akun
- Sekolah dan kelas
- Guru dan siswa
- Kamus
- Import kamus
- Basis AI
- Modul
- Kuis
- Speaking exercises
- Budaya Mekongga
- Progress
- Pengaturan sistem

### Guru

- Dashboard
- Kelas
- Siswa
- Modul
- Kuis
- Hasil kuis
- Target speaking
- Hasil speaking
- Progress
- Profil

### Siswa

- Dashboard
- Modul belajar
- Kamus
- Kuis
- Latihan speaking
- Chatbot AI
- Budaya Mekongga
- Progress
- Profil

## 4. Dokumen Pendukung

- `Docs/guides/buku-panduan-emi.md`
- `Docs/guides/export/buku-panduan-emi.html`
- `Docs/guides/export/Buku-Panduan-EMI.pdf` jika ada
- `Docs/guides/panduan-admin.md`
- `Docs/guides/panduan-guru.md`
- `Docs/guides/panduan-siswa.md`
- `Docs/audit/role-url-action-audit.md`
- `Docs/audit/feature-matrix.md`
- `Docs/audit/demo-seeder-plan.md`

## 5. Catatan Data Demo

- Data demo dibuat untuk presentasi dan uji coba.
- Data demo dapat diperbarui dengan seeder.
- Jangan menjalankan `migrate:fresh` di VPS production.
- Untuk seed demo di VPS gunakan:

```bash
php artisan db:seed --class=DemoPresentationSeeder --force
```

## 6. Catatan Teknis Operasional

- Aplikasi berjalan di VPS.
- Frontend menggunakan Next.js.
- Backend menggunakan Laravel.
- Database menggunakan PostgreSQL.
- Queue Laravel berjalan melalui Supervisor.
- Speaking AI berjalan sebagai service terpisah.
- Nginx digunakan untuk domain dan HTTPS.

## 7. Maintenance Rutin

- Cek domain.
- Cek login semua role.
- Cek queue/speaking AI.
- Backup database secara berkala.
- Update konten kamus, budaya, modul, dan kuis sesuai kebutuhan.

## 8. Known Notes / Batasan

- Validasi konten bahasa dan budaya tetap membutuhkan pengelola/narasumber.
- Fitur speaking AI bergantung pada kualitas audio, koneksi internet, dan service AI.
- Beberapa screenshot panduan dapat diperbarui jika tampilan aplikasi berubah.
- Password tidak disimpan di dokumen repository.

## 9. Checklist Serah Terima

- [ ] Domain frontend bisa dibuka.
- [ ] Domain API bisa diakses.
- [ ] Login admin berhasil.
- [ ] Login guru berhasil.
- [ ] Login siswa berhasil.
- [ ] Data demo tampil.
- [ ] Panduan role tersedia.
- [ ] PDF/HTML panduan tersedia.
- [ ] Client menerima akun demo.
- [ ] Client menerima catatan maintenance.

## 10. Kontak Bantuan

- Nama:
- Nomor/Email:
- Jam layanan:
