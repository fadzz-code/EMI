# Flutter Environment Check

## Environment

| Item | Hasil | Status |
|---|---|---|
| Flutter | `Flutter 3.38.4`, stable | Selesai |
| Dart | `Dart 3.10.3` | Selesai |
| Android device | `emulator-5554`, Android 16 API 36 | Selesai |
| ADB | `D:\Android\Sdk\platform-tools\adb.exe devices` mendeteksi `emulator-5554` | Selesai |
| Flutter doctor | Command berjalan, tetapi output CLI di environment ini terpotong/tidak normal | Terblokir sebagian |

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
- `flutter doctor -v` perlu dicek manual ulang di terminal lokal karena output tool hanya menampilkan potongan `Framework revision`.
- Tidak ada emulator baru dibuat.
