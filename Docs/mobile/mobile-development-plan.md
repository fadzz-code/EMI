# Rencana Pengembangan Mobile App EMI

## 1. Tujuan Mobile App

Mobile app EMI dibuat sebagai frontend mobile untuk pengguna siswa. Backend tetap memakai Laravel API yang sudah ada. Mobile app tidak menjadi sumber business rule baru, tetapi hanya memberi pengalaman belajar yang lebih nyaman di HP untuk login, belajar modul, membuka kamus, mengerjakan kuis, memakai chatbot, melihat progress, dan nantinya latihan speaking.

## 2. Keputusan Arsitektur

- Backend tetap Laravel.
- Database tetap PostgreSQL.
- Python Speaking AI tetap internal melalui Laravel, bukan dipanggil langsung dari mobile.
- Mobile hanya konsumsi API Laravel.
- Tidak membuat backend baru.

Keputusan ini menjaga Laravel sebagai sumber data dan aturan utama, sesuai status proyek saat ini: mobile belum dimulai dan harus konsumsi Laravel API, bukan backend terpisah.

## 3. Tech Stack yang Direkomendasikan

- React Native.
- Expo.
- TypeScript.
- NativeWind atau styling sederhana.
- TanStack Query atau fetch wrapper sederhana.
- SecureStore untuk token.
- Expo AV / Audio untuk audio dan speaking.

Alasan:

- Hemat memory dibanding workflow emulator berat.
- Bisa test langsung di HP fisik lewat Expo Go atau development build.
- Tidak perlu emulator berat untuk validasi awal.
- Developer sudah familiar React/Next.js, jadi pola komponen, hooks, TypeScript, dan API client lebih mudah dipindahkan.
- Expo mempercepat setup permission, audio, build preview, dan testing perangkat fisik.

## 4. Scope MVP Mobile

Fokus MVP adalah role Siswa dulu.

Fitur MVP:

- Login.
- Dashboard Siswa.
- Modul Belajar.
- Detail Modul.
- Detail Lesson.
- Kamus.
- Detail Kamus + audio.
- Kuis.
- Detail Kuis.
- Attempt Kuis.
- Hasil Kuis.
- Budaya Mekongga.
- Chatbot AI.
- Progress Belajar.
- Profil Siswa.

Speaking masuk setelah MVP stabil:

- List latihan speaking.
- Detail target speaking.
- Play suara asli.
- Rekam suara.
- Submit audio.
- Polling hasil AI.
- Lihat feedback guru.

## 5. Fitur yang Ditunda

- Admin mobile ditunda.
- Guru mobile ditunda atau hanya versi ringan.
- Push notification ditunda.
- Offline sync ditunda.
- Build Play Store ditunda sampai MVP stabil.

## 6. Screen Flow Mobile Siswa

Flow utama:

Splash → Login → Dashboard → Modul/Kamus/Kuis/Speaking/Chatbot/Progress/Profil

Detail flow:

- Splash:
  - Cek token di SecureStore.
  - Jika token ada, panggil `/api/v1/auth/me`.
  - Jika user siswa valid, masuk Dashboard.
  - Jika token kosong/invalid, masuk Login.

- Login:
  - Input email dan password.
  - Submit ke API login Laravel.
  - Simpan token ke SecureStore.
  - Ambil profil user.
  - Arahkan siswa ke Dashboard.

- Dashboard:
  - Tampilkan ringkasan belajar dari dashboard siswa.
  - Beri pintasan ke Modul, Kamus, Kuis, Speaking, Chatbot, Progress, dan Profil.

- Modul:
  - List modul published untuk kelas siswa.
  - Buka Detail Modul.
  - Start modul jika belum dimulai.
  - Buka lesson.
  - Tandai lesson selesai.

- Kamus:
  - Search/list kata.
  - Buka detail kata.
  - Putar audio jika tersedia.

- Kuis:
  - List kuis siswa.
  - Buka Detail Kuis.
  - Start attempt.
  - Jawab soal.
  - Submit.
  - Lihat Hasil Kuis.

- Speaking:
  - Ditunda setelah MVP stabil.
  - List target speaking.
  - Buka detail target.
  - Putar suara asli.
  - Rekam suara.
  - Submit audio ke Laravel.
  - Polling hasil attempt.
  - Lihat skor AI dan feedback guru.

- Chatbot:
  - Input pertanyaan.
  - Kirim ke API chatbot Laravel.
  - Tampilkan jawaban dan sumber/referensi bila ada.

- Progress:
  - Tampilkan progress modul, lesson, dan hasil kuis siswa.

- Profil:
  - Tampilkan profil siswa.
  - Update nama/telepon jika API mengizinkan.
  - Logout menghapus token.

## 7. Kebutuhan API

| Fitur | API yang dibutuhkan | Status | Catatan |
|---|---|---|---|
| Login | `POST /api/v1/auth/login` | tersedia | Butuh `email`, `password`, `device_name`; return Bearer token. |
| Logout | `POST /api/v1/auth/logout` | tersedia | Revoke token aktif. |
| Me/Profile | `GET /api/v1/auth/me`, `PATCH /api/v1/auth/me` | tersedia | Role dan relasi kelas aktif dipakai untuk guard siswa. |
| Dashboard Siswa | `GET /api/v1/student/dashboard/summary` | tersedia | Screen pertama setelah login. |
| Modul Belajar | `GET /api/v1/student/modules` | tersedia | Modul assigned/published untuk siswa. |
| Detail Modul | `GET /api/v1/student/modules/{id}` | tersedia | Termasuk lessons/progress. |
| Start Modul | `POST /api/v1/student/modules/{id}/start` | tersedia | Dipakai saat siswa mulai modul. |
| Detail Lesson | `GET /api/v1/student/modules/{id}` atau `GET /api/v1/class-lessons/{id}/content-url` | perlu audit | Route detail lesson exact untuk mobile perlu dipastikan dari response module dan service web. |
| Progress Lesson | `PATCH /api/v1/student/lessons/{id}/progress` | tersedia | Tandai/update progress lesson. |
| Kamus | `GET /api/v1/dictionary` | tersedia | Search/list kamus. |
| Detail Kamus + audio | `GET /api/v1/dictionary/{id}` | tersedia | Audio/media perlu cek URL public/private. |
| Kuis | `GET /api/v1/student/quizzes` | tersedia | List kuis assigned. |
| Detail Kuis | `GET /api/v1/student/quizzes/{id}` | tersedia | Detail kuis sebelum attempt. |
| Start Attempt Kuis | `POST /api/v1/class-quizzes/{id}/attempts` | tersedia | Shared path dengan role student. |
| Attempt Kuis | `GET /api/v1/quiz-attempts/{id}`, `PUT /api/v1/quiz-attempts/{id}/answers/{question_id}` | tersedia | Ambil attempt dan simpan jawaban. |
| Submit Kuis | `POST /api/v1/quiz-attempts/{id}/submit` | tersedia | Submit final attempt. |
| Hasil Kuis | `GET /api/v1/quiz-attempts/{id}`, `GET /api/v1/student/reports/quiz-results` | tersedia | Perlu putuskan layar memakai attempt detail atau report list. |
| Budaya Mekongga | `GET /api/v1/student/culture` | tersedia | Published culture untuk kelas siswa. |
| Chatbot AI | `POST /api/v1/student/chatbot/messages` | tersedia | Audit lama menyebut `/student/chatbot/message`; route inventory terbaru memakai `/messages`. |
| Progress Belajar | `GET /api/v1/student/reports/progress`, `GET /api/v1/student/progress/modules`, `GET /api/v1/student/reports/quiz-results` | tersedia | Untuk ringkasan progress siswa. |
| Profil Siswa | `GET /api/v1/auth/me`, `PATCH /api/v1/auth/me` | tersedia | Password change tidak masuk MVP kecuali diminta. |
| Media public | `GET /api/v1/public/media/{id}/content` | tersedia | Untuk public image/audio/document. |
| Media private temporary URL | `POST /api/v1/media/{id}/temporary-url` | tersedia | Untuk private lesson/audio/recording playback jika authorized. |
| List Speaking | `GET /api/v1/student/speaking/exercises` | tersedia | Setelah MVP stabil. |
| Detail Speaking | `GET /api/v1/student/speaking/exercises/{exercise}` | tersedia | Setelah MVP stabil. |
| Submit Speaking | `POST /api/v1/student/speaking/exercises/{exercise}/attempts` | tersedia | Multipart audio; perlu testing HP. |
| Hasil Speaking | `GET /api/v1/student/speaking/attempts`, `GET /api/v1/student/speaking/attempts/{attempt}` | tersedia | Bisa dipakai polling status dan detail hasil. |

## 8. Auth dan Token

- Login menggunakan API Laravel `POST /api/v1/auth/login`.
- Token disimpan di SecureStore.
- Token dikirim sebagai `Authorization: Bearer <token>`.
- Logout memanggil API logout lalu menghapus token lokal.
- Jangan simpan token di AsyncStorage biasa jika bisa pakai SecureStore.
- Saat app dibuka ulang, Splash membaca token lalu validasi dengan `/api/v1/auth/me`.
- Jika role bukan siswa, tampilkan pesan akses tidak tersedia untuk mobile MVP.

## 9. Media dan Audio

- Gambar/audio dari backend menggunakan URL media yang sudah disediakan.
- Public media bisa memakai `/api/v1/public/media/{id}/content`.
- Private media perlu temporary URL lewat `/api/v1/media/{id}/temporary-url` jika response belum memberi URL siap pakai.
- Speaking upload menggunakan file audio dari mobile.
- Mobile tidak memanggil Python AI langsung.
- Laravel tetap menjadi perantara ke Python Speaking AI.
- Upload audio mobile perlu validasi MIME, ukuran file, permission mikrofon, dan format hasil rekaman dari Expo AV / Audio.

## 10. Struktur Project Mobile

Struktur repo yang direkomendasikan:

```text
EMI/
├── Emi-Backend/
├── Emi-Frontend/
├── Emi-Speaking-AI/
├── Emi-Mobile/
└── Docs/
```

Struktur awal `Emi-Mobile`:

```text
src/
├── app/
├── components/
├── features/
├── lib/
├── services/
├── hooks/
├── types/
└── constants/
```

Catatan struktur:

- `src/app/`: routing/navigation screen entry.
- `src/components/`: komponen UI reusable sederhana.
- `src/features/`: domain siswa seperti auth, dashboard, modules, dictionary, quizzes, culture, chatbot, progress, profile, speaking.
- `src/lib/`: helper umum, API client, storage.
- `src/services/`: wrapper endpoint Laravel.
- `src/hooks/`: hooks data/query kecil.
- `src/types/`: tipe response API.
- `src/constants/`: API URL, route names, warna dasar.

## 11. Urutan Implementasi

1. Setup Expo project.
2. Setup environment API URL.
3. Setup auth login/logout/me.
4. Setup navigation.
5. Dashboard siswa.
6. Modul dan lesson.
7. Kamus.
8. Kuis.
9. Chatbot.
10. Progress.
11. Profil.
12. Speaking.
13. Testing di HP fisik.
14. Build APK preview.

## 12. Risiko dan Catatan

- API belum semua nyaman untuk mobile.
- Token harus aman.
- Upload audio mobile perlu testing khusus.
- Speaking butuh izin mikrofon.
- File besar perlu batasan.
- Network HP berbeda dengan lokal.
- Endpoint detail lesson perlu dipastikan agar mobile tidak bergantung pada asumsi response web.
- Endpoint chatbot di audit lama dan route inventory beda nama; pakai route inventory terbaru sampai source membuktikan lain.
- Media public/private perlu diuji di HP, terutama audio kamus, lesson media, dan speaking reference audio.
- Siswa tanpa kelas aktif harus punya empty-state yang jelas.

## 13. Checklist Persiapan

- [ ] API production/staging aktif.
- [ ] Akun demo siswa tersedia.
- [ ] Route inventory dicek.
- [ ] Desain mobile sederhana dibuat.
- [ ] Expo project dibuat.
- [ ] Login mobile berhasil.
- [ ] Token tersimpan aman.
- [ ] Modul siswa tampil.
- [ ] Kuis siswa berjalan.
- [ ] Speaking mobile diuji.
