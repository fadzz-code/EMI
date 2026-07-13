# Arsitektur Mobile EMI

## Ringkasan

Aplikasi mobile EMI direkomendasikan dibuat dengan Flutter sebagai frontend mobile untuk role Admin, Guru, dan Siswa, dengan prioritas implementasi Siswa terlebih dahulu. Flutter hanya memakai Laravel API yang sudah ada di `/api/v1` dan tidak membuat backend baru.

Arsitektur target:

```text
Flutter Mobile
    ↓ HTTPS + Bearer token
Laravel API /api/v1
    ↓
PostgreSQL + storage + queue
    ↓ internal only
Python Speaking AI
```

## Keputusan Arsitektur

- Flutter menjadi aplikasi mobile lintas perangkat, terutama Android.
- Laravel tetap menjadi backend/API utama dan sumber business rule.
- PostgreSQL tetap digunakan melalui Laravel, bukan diakses langsung dari Flutter.
- Python Speaking AI tidak dipanggil langsung oleh Flutter.
- Flutter mengirim audio speaking ke Laravel.
- Laravel mengatur validasi audio, penyimpanan private media, queue, dan komunikasi dengan Speaking AI.
- Autentikasi menggunakan token API Laravel yang sudah ada, yaitu Sanctum Bearer token dari `POST /api/v1/auth/login`.
- Media dan file menggunakan URL dari backend:
  - public media: `GET /api/v1/public/media/{id}/content`.
  - private media: `POST /api/v1/media/{id}/temporary-url`, lalu buka URL sementara.
- Response API memakai bentuk umum `success`, `message`, `data`, `meta`, `code`, dan `errors`.

## Rekomendasi Stack Flutter

- Flutter stable.
- Dart.
- Dio untuk HTTP client.
- Riverpod untuk state management.
- go_router untuk routing dan role guard.
- flutter_secure_storage untuk token.
- freezed/json_serializable jika response model mulai banyak dan stabil.
- image_picker/file_picker untuk media upload non-audio jika fitur guru/admin masuk.
- record atau package rekaman audio setara untuk rekaman speaking.
- just_audio untuk pemutaran audio kamus, reference audio speaking, dan media audio lain.

Catatan paket:

- Jangan tambah package sebelum kebutuhan nyata muncul.
- MVP siswa bisa mulai dengan Dio + Riverpod + go_router + flutter_secure_storage + just_audio.
- `freezed/json_serializable` masuk saat model response mulai kompleks, bukan wajib di hari pertama.

## Auth dan Session

- Login: `POST /api/v1/auth/login` dengan `email`, `password`, dan `device_name`.
- Current user: `GET /api/v1/auth/me`.
- Logout: `POST /api/v1/auth/logout`.
- Token disimpan di `flutter_secure_storage`.
- Semua request protected memakai header `Authorization: Bearer <token>`.
- Splash screen membaca token lokal lalu validasi ke `/auth/me`.
- Role guard memisahkan akses Admin, Guru, dan Siswa.
- Untuk MVP siswa, role selain `student` bisa diarahkan ke pesan “Role belum tersedia di mobile”.

## Media dan Audio

- Kamus, lesson, culture, dan speaking reference audio harus memakai URL/metadata dari backend.
- Jika media public, pakai URL public content dari backend.
- Jika media private, minta temporary URL lewat backend.
- Upload speaking memakai multipart/form-data field `file` ke `POST /api/v1/student/speaking/exercises/{exercise}/attempts`.
- Flutter perlu mengirim format audio yang diterima backend: `webm`, `wav`, `mp3`, `m4a`, `mp4`, `ogg` atau MIME aman sesuai validasi backend.
- Flutter tidak boleh menyimpan token, file audio private, atau temporary URL lebih lama dari kebutuhan UI.

## Error Handling

- 401: hapus token lokal dan arahkan ke login.
- 403: tampilkan pesan tidak punya akses atau role belum tersedia.
- 404: tampilkan data tidak ditemukan.
- 422: tampilkan error field dari `errors`.
- 429: tampilkan pesan terlalu banyak percobaan.
- 500: tampilkan pesan layanan bermasalah dan opsi coba lagi.
- Timeout/jaringan: tampilkan state offline/gagal koneksi, bukan crash.

## Struktur Folder Flutter

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart
  core/
    api/
    auth/
    config/
    errors/
    storage/
  shared/
    widgets/
    models/
    utils/
  features/
    auth/
    dashboard/
    modules/
    dictionary/
    quizzes/
    speaking/
    chatbot/
    progress/
    profile/
```

Jika role Guru/Admin masuk setelah MVP:

```text
lib/
  features/
    teacher_classes/
    teacher_modules/
    teacher_quizzes/
    teacher_speaking/
    admin_dashboard/
    admin_users/
    admin_content/
```

## Prinsip Implementasi

- Jangan membuat backend baru.
- Jangan panggil database langsung dari Flutter.
- Jangan panggil Python Speaking AI langsung.
- Jangan menggantungkan logic Flutter pada halaman Next.js; pakai kontrak API Laravel.
- Mulai dari role Siswa karena paling cocok untuk mobile MVP.
- Admin penuh tetap web-first sampai ada kebutuhan operasional mobile yang jelas.

## Risiko Arsitektur

- Beberapa endpoint list belum memakai pagination konsisten, terutama speaking list yang masih `get()`.
- Beberapa flow guru/admin kompleks untuk layar kecil.
- Upload audio Flutter perlu uji MIME/extension nyata di Android.
- Temporary URL private media perlu diuji di native app.
- CORS bukan asumsi utama untuk native app, tetapi HTTPS, auth header, dan signed URL tetap harus diuji.
