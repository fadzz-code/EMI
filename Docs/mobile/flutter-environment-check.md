# Flutter Environment Check

## Environment

| Item | Hasil | Status |
|---|---|---|
| Flutter | `Flutter 3.44.6`, stable | Selesai |
| Dart | `Dart 3.12.2` | Selesai |
| Android SDK | Android SDK 36.1.0 / Android 16 API 36 | Selesai |
| Android device | `emulator-5554`, Android 16 API 36 | Selesai |
| ADB | `D:\Android\Sdk\platform-tools\adb.exe devices` mendeteksi `emulator-5554` | Selesai |
| Flutter doctor | `flutter doctor -v` berjalan; output tool terpotong, tetapi Flutter/devices tersedia | Terblokir sebagian |

## Commands

```bash
flutter --version
dart --version
flutter doctor -v
flutter devices
D:\Android\Sdk\platform-tools\adb.exe devices
```

## Catatan

- `flutter devices` mendeteksi emulator Android 16 API 36.
- Release audit memakai Flutter 3.44.6 dan Dart 3.12.2.
- `flutter doctor -v` perlu dicek manual ulang di terminal lokal karena output tool hanya menampilkan potongan `Framework revision`.
- Tidak ada emulator baru dibuat.
