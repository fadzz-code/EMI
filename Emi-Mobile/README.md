# EMI Mobile

Flutter Android frontend untuk EMI. Aplikasi ini memakai Laravel API EMI yang sudah ada dan tidak membuat backend baru.

## Requirement

- Flutter 3.44.6 atau kompatibel.
- Dart 3.12.2 atau kompatibel.
- Android SDK dengan emulator/device Android.
- Backend Laravel EMI aktif untuk login production atau development.

## Setup

```bash
flutter pub get
```

## Run Development

Laravel lokal dari Android emulator memakai `10.0.2.2`:

```bash
flutter run -d emulator-5554 --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Run Production

```bash
flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id
```

Production wajib HTTPS.

## Emulator

```bash
flutter devices
```

## Build Release

APK release production:

```bash
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id
```

AAB release hanya dijalankan jika signing aman tersedia di `android/key.properties` dan keystore lokal tidak dilacak Git:

```bash
flutter build appbundle --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id
```

Signing file lokal yang diharapkan:

```text
Emi-Mobile/android/key.properties
```

Property yang wajib ada, tanpa menyimpan nilainya di Git:

```properties
storeFile=<path-ke-keystore-lokal>
storePassword=<password-keystore>
keyAlias=<alias-key>
keyPassword=<password-key>
```

Lokasi keystore lokal yang disarankan: `Emi-Mobile/android/app/upload-keystore.jks` atau path aman di luar repo. File yang wajib tetap ignored: `android/key.properties`, `android/app/*.jks`, `android/app/*.keystore`, `build/`, `local.properties`.

Jika signing belum tersedia, APK release bisa terbangun unsigned dan tidak bisa diinstall ke perangkat; AAB/Play-ready build berstatus `BLOCKED_BY_SIGNING`.

## Analyze

```bash
flutter analyze
```

## Test

```bash
flutter test
```

## Struktur

```text
lib/
  app/
    router/
    theme/
  core/
    config/
    errors/
    network/
    storage/
  shared/
    models/
    widgets/
  features/
    splash/
    auth/
    dashboard/
    modules/
    profile/
```

## Route Admin

- `/admin/dashboard`
- `/admin/users`
- `/admin/users/:id`
- `/admin/classes`
- `/admin/classes/:id`
- `/admin/modules`
- `/admin/modules/:id`
- `/admin/dictionary`
- `/admin/dictionary/:id`
- `/admin/quizzes`
- `/admin/quizzes/:id`
- `/admin/culture`
- `/admin/culture/:id`
- `/admin/speaking`
- `/admin/speaking/:id`
- `/admin/reports`
- `/admin/reports/:id`
- `/admin/settings`
- `/admin/settings/:id`

## Route Siswa

- `/student/dashboard`
- `/student/modules`
- `/student/modules/:moduleId`
- `/student/lessons/:lessonId`
- `/student/dictionary`
- `/student/dictionary/:entryId`
- `/student/quizzes`
- `/student/quizzes/:quizId`
- `/student/quizzes/:quizId/attempt`
- `/student/progress`
- `/student/chatbot`
- `/student/culture`
- `/student/culture/:cultureId`
- `/student/speaking`
- `/student/speaking/:exerciseId`
- `/student/profile`

## Dependency Tambahan

- `just_audio`: pemutaran audio kosakata dan speaking dari URL/backend atau file lokal.
- `image_picker`: pemilihan avatar dari galeri Android memakai picker sistem.
- `record`: rekaman speaking lokal Android ke `m4a`/AAC.
- `permission_handler`: izin mikrofon untuk speaking.
- `path_provider`: lokasi file sementara rekaman speaking.

## Permission Android

- `android.permission.RECORD_AUDIO` dipakai untuk rekaman Speaking.

## Aturan Keamanan

- Token disimpan melalui `flutter_secure_storage`.
- Password tidak disimpan.
- Authorization/token/password tidak boleh dilog.
- Flutter hanya memanggil Laravel API `/api/v1`.
- Flutter tidak memanggil Python Speaking AI langsung.

## Offline Mobile

- Offline mendukung Modul/Lesson yang diunduh manual, Kamus yang diunduh manual, dan antrean sinkronisasi progress lesson.
- Backend online tetap menjadi sumber data utama; unduhan hanya dilakukan manual saat perangkat online.
- Data offline disimpan per pemilik akun. Logout mempertahankan data pemilik tersebut, sedangkan hapus unduhan atau hapus data akun lokal menghapus data terkait pemilik.
- Kuis, Chatbot, Budaya, Speaking, Profil/Account, fitur Admin, login, dan perubahan password/avatar tidak didukung offline.
- Sinkronisasi tidak berjalan di background; pengguna harus membuka aplikasi dan terhubung ke jaringan.

### Checklist Manual Android Fisik

- Module: unduh modul saat online, buka lesson setelah jaringan dimatikan, selesaikan lesson, lalu buka aplikasi saat online dan verifikasi progress tersinkron.
- Dictionary: unduh kamus saat online, cari dan buka entri setelah jaringan dimatikan, lalu hapus unduhan dan verifikasi data tidak lagi tersedia offline.
- Account: verifikasi data offline terpisah antar akun, tetap ada setelah logout, dan terhapus hanya lewat hapus unduhan atau hapus data akun lokal.
- Network: verifikasi status offline/error tanpa crash, tidak ada sinkronisasi background, dan sinkronisasi berjalan setelah aplikasi dibuka kembali saat online.

**MANUAL DEVICE TEST: DEFERRED.**

## Fitur Selesai Fase Foundation

- Environment development/production.
- Theme EMI foundation dari `Docs/mobile/desain.md`.
- Dio client dengan auth interceptor.
- Secure token storage abstraction.
- Auth login/current user/logout.
- Session persistence.
- Role guard siswa dan Admin.
- Admin Shell, Dashboard Admin, sidebar Admin, dan list/detail read-only fitur inti Admin.
- Splash.
- Login.
- Dashboard siswa data nyata.
- Daftar modul siswa.
- Detail modul siswa.
- Detail lesson siswa.
- Penyelesaian lesson.
- Daftar kamus siswa.
- Detail kamus siswa.
- Audio kosakata.
- Daftar kuis siswa.
- Detail kuis siswa.
- Attempt kuis siswa.
- Simpan jawaban kuis.
- Submit dan hasil kuis.
- Progress belajar siswa.
- Profil siswa data nyata.
- Edit profil.
- Ganti password.
- Upload dan hapus avatar.
- Chatbot siswa.
- Sidebar navigasi siswa.
- Daftar dan detail Budaya Mekongga.
- Daftar, detail, rekam, submit, status, hasil AI, feedback guru, dan riwayat Speaking siswa.
- Unsupported role.
- Tests dasar.

## Fitur Belum

- Guru mobile.
- Admin CRUD form panjang/destruktif, import, export, media library list, dan speaking feedback khusus Admin.

## Known Gaps Release

- Signing release belum tersedia di repo; AAB/Play-ready build butuh keystore dari pengelola.
- Launcher icon, adaptive icon, splash, dan logo masih temporary/default karena Figma MCP 403.
- Manual production login dan data nyata butuh kredensial siswa.
- Speaking list/attempt belum paginated dari backend.
- Speaking reference audio private dan audio attempt memakai fallback temporary URL via `/api/v1/media/{id}/temporary-url` jika backend tidak mengirim playback URL.
- Media private perlu verifikasi temporary URL di Android dengan data production.

## Manual QA Checklist

- Install dan launch app production.
- Splash lalu login page tampil tanpa crash.
- Login akun siswa production.
- Buka bottom nav: Beranda, Modul, Kamus, Kuis, Profil.
- Buka sidebar: Progress, Chatbot, Budaya, Speaking.
- Verifikasi Modul/Lesson/Progress lesson.
- Verifikasi Kamus audio.
- Verifikasi Kuis attempt/submit/result.
- Verifikasi Profil edit/password/avatar, termasuk picker cancel.
- Verifikasi Chatbot dan Budaya data nyata.
- Verifikasi Speaking: izin mikrofon, record, preview, submit, status AI, feedback guru.
- Cek tidak ada overflow, loading tanpa akhir, route ganda, atau crash.

## Catatan Desain

Beberapa token masih `Temporary Foundation` karena Figma API sempat terkena rate limit 429: typography exact, logo, icon library, loading/empty/error component.
