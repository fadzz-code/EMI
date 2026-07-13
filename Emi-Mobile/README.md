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
- `/student/profile`

## Dependency Tambahan

- `just_audio`: pemutaran audio kosakata dari URL backend.
- `image_picker`: pemilihan avatar dari galeri Android memakai picker sistem.

## Aturan Keamanan

- Token disimpan melalui `flutter_secure_storage`.
- Password tidak disimpan.
- Authorization/token/password tidak boleh dilog.
- Flutter hanya memanggil Laravel API `/api/v1`.
- Flutter tidak memanggil Python Speaking AI langsung.

## Fitur Selesai Fase Foundation

- Environment development/production.
- Theme EMI foundation dari `Docs/mobile/desain.md`.
- Dio client dengan auth interceptor.
- Secure token storage abstraction.
- Auth login/current user/logout.
- Session persistence.
- Role guard siswa.
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
- Unsupported role.
- Tests dasar.

## Fitur Belum

- Chatbot.
- Budaya.
- Speaking.
- Guru mobile.
- Admin mobile.

## Catatan Desain

Beberapa token masih `Temporary Foundation` karena Figma API sempat terkena rate limit 429: typography exact, logo, icon library, loading/empty/error component.
