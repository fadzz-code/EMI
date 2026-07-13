# Mobile Implementation Progress EMI

| Fase | Pekerjaan | Status | Bukti verifikasi | Langkah berikutnya |
|---|---|---|---|---|
| Desain | Audit Figma MCP | Selesai | Figma MCP berhasil membaca file `Untitled`, file key `tZcPOdYQhry2xHzm1B0UIC`, page `Page 1` node `0:1`; akses drill-down berikutnya terkena rate limit 429 | Retry drill-down node saat rate limit selesai |
| Desain | Identifikasi file EMI | Selesai | File Figma `Untitled` dari URL audit lama `https://www.figma.com/design/tZcPOdYQhry2xHzm1B0UIC/Untitled` berhasil diakses | Konfirmasi apakah ada file Figma EMI lain yang lebih baru |
| Desain | Identifikasi frame mobile | Selesai | MCP mencatat frame mobile Admin `105:*`, Guru `105:*`, Siswa `107:*`/`109:*`, Auth `117:*`; detail dicatat di `Docs/mobile/desain.md` | Audit ulang detail node prioritas siswa |
| Desain | Identifikasi frame web | Selesai | `Docs/ui-ux-figma-audit.md` mencatat desktop auth/admin/guru/siswa dan MCP output menunjukkan desktop 1280px frames | Gunakan web hanya untuk referensi alur, bukan token mobile final |
| Desain | Audit design tokens | Sedang dikerjakan | Warna, border, shadow, radius, spacing awal terbaca dari MCP; typography exact belum terbaca karena rate limit | Audit typography, icon, logo, component set saat MCP tersedia |
| Desain | Audit neobrutalism | Selesai | Bukti node: FAB `105:656`, button `105:1570`, top app bar `105:745`, bottom sheet `105:403`, sidebar desktop templates; border tebal dan offset shadow tercatat | Pakai bukti ini sebagai dasar gaya Flutter |
| Desain | Pemetaan komponen | Sedang dikerjakan | Component map awal dibuat di `Docs/mobile/desain.md`; sebagian node detail masih `Needs Figma Verification` | Lengkapi setelah drill-down MCP tersedia |
| Desain | Pemetaan screen | Selesai | Screen map siswa mobile dibuat untuk login, dashboard, modul, lesson, kamus, kuis, progress, profil, chatbot, budaya, speaking | Tambah node detail per screen saat implementasi screen dimulai |
| Desain | Dokumentasi desain.md | Selesai | `Docs/mobile/desain.md` dibuat dengan sumber Figma, token, component map, screen map, rules, blocker | Jadikan dokumen wajib untuk prompt Flutter berikutnya |
| Environment | Flutter SDK | Selesai | `flutter --version` menampilkan Flutter 3.44.6 stable | Gunakan versi kompatibel ini untuk foundation |
| Environment | Dart SDK | Selesai | `dart --version` menampilkan Dart 3.12.2 | Gunakan null safety Dart 3.12.2 |
| Environment | Android SDK | Selesai | `flutter doctor -v` menampilkan Android SDK 36.1.0 dan Android 16 API 36 | Lanjut QA emulator |
| Environment | Emulator | Selesai | `flutter devices` mendeteksi `emulator-5554` Android 16 API 36 | Gunakan emulator ini untuk run |
| Environment | Flutter doctor | Selesai | `flutter doctor -v` selesai dengan `No issues found!` | Ulang jika SDK berubah |
| Flutter | Init Emi-Mobile | Selesai | `flutter create --platforms=android --org id.emikolaka --project-name emi_mobile Emi-Mobile` berhasil membuat project Android | Lanjut feature foundation |
| Flutter | Dependencies | Selesai | `flutter pub add` menambahkan Riverpod, Dio, go_router, secure storage, connectivity, freezed/json annotation, build runner, mocktail | Jangan tambah audio/camera/file packages di fase ini |
| Flutter | Environment config | Selesai | `AppEnvironment` mendukung development/production dan normalisasi `/api/v1` | Pakai `--dart-define` untuk run |
| Flutter | Theme | Selesai | `EmiTheme`, `EmiColors`, spacing, radius, hard shadow dibuat dari `Docs/mobile/desain.md` | Revisi typography setelah Figma tersedia |
| Flutter | Dio | Selesai | Dio provider dengan base URL, timeout, Accept JSON, auth interceptor | Tambah endpoint per fitur fase berikutnya |
| Flutter | Secure storage | Selesai | `TokenStorage` dan `SecureTokenStorage` dibuat; password tidak disimpan | Pakai untuk session auth saja |
| Flutter | Auth | Selesai | Login `/auth/login`, current user `/auth/me`, logout `/auth/logout` diimplementasikan | Manual production login belum diuji |
| Flutter | Current user | Selesai | `SessionUser` mengikuti `UserResource`: id, full_name, email, phone, role, status, active_school, active_class | Tambah field hanya jika backend mengirim |
| Flutter | Session | Selesai | Splash restore session membaca token lalu validasi `/auth/me` | Uji manual token invalid |
| Flutter | Routing | Selesai | go_router route `/splash`, `/login`, `/student/dashboard`, `/student/profile`, `/unsupported-role` | Fitur berikutnya tambah route siswa |
| Flutter | Role guard | Selesai | Role student masuk dashboard; guru/admin/unknown masuk unsupported role | Admin/guru mobile ditunda |
| Flutter | Splash | Selesai | Splash temporary foundation dibuat karena frame Figma splash missing | Ganti jika desain splash tersedia |
| Flutter | Login | Selesai | Email/password/show-hide/loading/error/keyboard-safe dibuat | Manual production login belum diuji |
| Flutter | Dashboard foundation | Selesai | Dashboard siswa menampilkan nama, role, class, CTA profil, logout, dan catatan fitur fase berikutnya | Implement dashboard API penuh fase berikutnya |
| Flutter | Profile foundation | Selesai | Profil siswa menampilkan field current user yang tersedia | Edit profile ditunda meski endpoint ada |
| Verification | clean | Selesai | `flutter clean` berhasil setelah upgrade Flutter 3.44.6 | Jalankan ulang jika build cache bermasalah |
| Verification | pub get | Selesai | `flutter pub get` berhasil | Jalankan ulang jika dependency berubah |
| Verification | build runner | Selesai | `dart run build_runner build --delete-conflicting-outputs` berhasil; hanya ada warning package newer versions | Jalankan ulang jika generated model berubah |
| Verification | format | Selesai | `dart format .` berhasil | Wajib ulang tiap fase |
| Verification | analyze | Selesai | `flutter analyze` clean, tidak ada issues | Wajib ulang tiap fase |
| Verification | test | Selesai | `flutter test` lulus 11 tests | Tambah tests saat fitur bertambah |
| Verification | emulator run | Selesai | `flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` berhasil build debug APK, install ke emulator, dan app berjalan; command timeout karena Flutter CLI tetap attach ke app | Uji login manual dengan akun demo tanpa menyimpan kredensial |
| Verification | NDK config | Selesai | `android/app/build.gradle.kts` memakai `ndkVersion = "28.2.13676358"`; `android/local.properties` tidak menyimpan `ndk.dir`; blocker Clang tidak muncul lagi setelah Flutter 3.44.6 | Pertahankan tanpa path lokal NDK di source |
| Verification | splash | Selesai | Splash temporary tampil sebelum route login | Ganti jika desain splash tersedia |
| Verification | login UI | Selesai | Login tampil setelah splash; field email/password bisa dipakai; show/hide password bekerja; tidak terlihat crash atau overflow pada emulator | Lanjut login manual saat kredensial demo tersedia |
| Verification | manual production login | Belum | Tidak dilakukan sesuai instruksi jangan login otomatis dan tidak ada kredensial demo yang boleh dicatat | Uji dengan akun demo dari pengelola |

## Yang sudah selesai

- Flutter Android project dibuat di `Emi-Mobile`.
- Foundation architecture feature-first dibuat.
- Environment development/production tersedia.
- Theme neobrutalism foundation dibuat dari token Figma yang sudah terdokumentasi.
- Dio client dan secure token storage dibuat.
- Auth login/current user/logout dibuat sesuai kontrak Laravel.
- Session persistence dan role guard dibuat.
- Splash, login, dashboard siswa foundation, profile siswa foundation, unsupported role dibuat.
- Tests dasar dibuat dan lulus.
- Flutter upgrade ke 3.44.6 stable dan Dart 3.12.2 terverifikasi.
- `flutter clean`, `flutter pub get`, build runner, format, analyze, test, dan run emulator production berhasil.
- Splash dan login foundation tampil di emulator; field email/password dan show/hide password terverifikasi tanpa login otomatis.

## Yang belum selesai

- Login production manual dengan akun demo.
- Kuis dan progress lengkap.
- Chatbot, budaya, speaking.
- Guru mobile.
- Admin mobile.
- Typography/logo/icon final dari Figma.

## Update fase Dashboard Siswa dan Modul

Status: Selesai sebagian.

- Figma MCP berhasil membaca file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, canvas `MOBILE EMI` node `0:1`.
- Frame Dashboard Siswa: `SCREEN 1 — Beranda Belajar` node `1:4221`.
- Frame Daftar Modul Siswa: `SCREEN 3 — Modul Belajar` node `1:4473`.
- Dashboard siswa memakai endpoint nyata `GET /api/v1/student/dashboard/summary`.
- Daftar modul siswa memakai endpoint nyata `GET /api/v1/student/modules` dengan filter status dan pull-to-refresh.
- UI mengikuti token Figma yang terbaca: background `#FFF9F2`/`#FEF8F1`, surface `#FFFFFF`, border `#1D1B17`, primary `#FF8A3D`, secondary `#FDD758`, success `#5BBE5D`, card radius `12`, hard shadow `4px 4px 0`, app bar height `64`, bottom nav 5 item.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter test` lulus 11 tests, `flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` build/install/run berhasil lalu koneksi CLI terputus.
- Manual login production belum dilakukan karena kredensial harus diisi langsung di emulator.

## Update fase Detail Modul dan Lesson

Status: Selesai.

- Figma MCP berhasil membaca frame `SCREEN 4 — Detail Materi` node `1:4637` dari file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, canvas `MOBILE EMI`.
- Detail modul siswa memakai endpoint nyata `GET /api/v1/student/modules/{id}`.
- Detail lesson siswa memakai endpoint nyata `GET /api/v1/class-lessons/{id}`.
- URL konten/media lesson memakai endpoint nyata `GET /api/v1/class-lessons/{id}/content-url`.
- Penyelesaian lesson memakai endpoint nyata `PATCH /api/v1/student/lessons/{id}/progress` dengan `status=completed` dan `progress_percent=100`.
- Route Flutter ditambah: `/student/modules/:moduleId` dan `/student/lessons/:lessonId`.
- UI mengikuti token Figma yang terbaca: card putih border `#1D1B17`, header kuning `#FDD758`, media area `#FFDBC9`, radius `8/12`, shadow `4px 4px 0` dan `2px 2px 0`, app bar 64, bottom nav aktif Modul.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 15 tests.
- Emulator: `flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` build/install/run berhasil; CLI timeout karena tetap attach, bukan crash. `adb devices` mendeteksi `emulator-5554`, `adb shell pidof id.emikolaka.emi_mobile` mengembalikan PID `7587`.
- Manual login dan penyelesaian lesson data production belum diuji karena kredensial harus diisi langsung di emulator.

## Update fase Kamus dan Audio

Status: Selesai.

- Figma MCP berhasil membaca `SCREEN 6 — Kamus Mekongga` node `1:6283` dan `SCREEN 7 — Detail Kata Kamus` node `1:4968` dari file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, canvas `MOBILE EMI`.
- Daftar kamus memakai endpoint nyata `GET /api/v1/dictionary`.
- Detail kamus memakai endpoint nyata `GET /api/v1/dictionary/{id}`.
- Search memakai query `search` dengan debounce 400ms.
- Filter kategori memakai query `category_id` dari kategori yang tersedia di response item.
- Audio memakai `audio.url` dari `DictionaryEntryResource`; package `just_audio` ditambahkan untuk play/pause/dispose.
- Route Flutter ditambah: `/student/dictionary` dan `/student/dictionary/:entryId`.
- UI mengikuti token Figma yang terbaca: search bar, chips, word card, hero word card, audio card biru, examples card kuning, bottom nav aktif Kamus, border tebal, radius 12, hard shadow.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 18 tests.
- Emulator: `flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` sempat menampilkan error cache incremental Kotlin dari package audio di drive berbeda, lalu build debug APK berhasil, install berhasil, app berjalan; CLI lost connection setelah attach. `adb devices` mendeteksi `emulator-5554`, `adb shell pidof id.emikolaka.emi_mobile` mengembalikan PID `8041`.
- Manual login, pencarian data production, dan audio nyata belum diuji karena kredensial harus diisi langsung di emulator.

## Update diagnosis buffering Modul/Kamus

Status: Selesai.

- Akar masalah Modul: `StudentModuleQuery` dipakai sebagai parameter `FutureProvider.family`, tetapi belum punya `==` dan `hashCode`. Setiap rebuild screen membuat instance query baru sehingga Riverpod melihat key provider baru dan memulai fetch ulang; loading terlihat panjang/berulang.
- Akar masalah Kamus: `DictionaryQuery` punya masalah sama; tiap rebuild/search/filter membuat identity provider tidak stabil walau value sama.
- Bukti diagnosis: file `student_module_providers.dart` dan `dictionary_providers.dart` sebelum fix hanya berisi field `search/status/categoryId` tanpa equality. Setelah fix ditambah value equality dan regression test `query_identity_test.dart` memastikan dua query dengan value sama menghasilkan key provider sama.
- Perbaikan: tambah `operator ==` dan `hashCode` pada `StudentModuleQuery` dan `DictionaryQuery`.
- Kotlin cache warning tidak relevan dengan buffering API/UI karena warning terjadi saat Gradle compile package audio; aplikasi tetap build/install/run dan masalah loading berasal dari lifecycle provider Flutter.
- Fitur Kuis diblokir: Figma MCP terkena `429` saat membaca frame Kuis, sehingga implementasi UI Kuis dihentikan sesuai batasan tugas.

## Update fase Daftar Kuis dan Detail Kuis

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, node `109:415`; hasil gagal `403 Forbidden` dengan body `{"status":403,"err":"Invalid token"}`.
- Mode desain memakai fallback dari `Docs/mobile/desain.md` dan referensi node sebelumnya: Dashboard `1:4221`, Daftar Modul `1:4473`, Detail Materi `1:4637`, Daftar Kamus `1:6283`, Detail Kamus `1:4968`; frame kuis `SCREEN 10 — Kuis & LKPD` node historis `109:415` belum terbaca ulang.
- Daftar kuis siswa memakai endpoint nyata `GET /api/v1/student/quizzes` dengan filter `availability` dan pull-to-refresh.
- Detail kuis siswa memakai endpoint nyata `GET /api/v1/student/quizzes/{id}`.
- Status kuis ditampilkan dari field backend nyata: `open_at`, `close_at`, `can_start`, `submitted_attempts_count`, `latest_submitted_at`.
- Jadwal, durasi, jumlah soal, attempt, dan nilai terbaik ditampilkan hanya jika field tersedia dari response.
- Route Flutter ditambah: `/student/quizzes` dan `/student/quizzes/:quizId`.
- Pengerjaan, penyimpanan jawaban, submit, dan hasil attempt penuh belum dibuat pada fase ini sesuai batasan scope.
- Verifikasi awal: `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 23 tests.

## Blocker

- Figma API rate limit 429/akses token tidak valid masih memblokir typography exact, logo, icon library, component set detail, dan frame kuis aktual.
- Manual production login membutuhkan kredensial demo dari pengelola.
- Native assets dependency tetap terdeteksi dari `jni`/`jni_flutter`, tetapi NDK Clang blocker sudah tidak muncul pada Flutter 3.44.6.

## Keputusan arsitektur

- Flutter hanya frontend mobile.
- Backend tetap Laravel `/api/v1`.
- PostgreSQL hanya diakses melalui Laravel.
- Speaking AI tidak dipanggil langsung dari Flutter.
- MVP foundation hanya siswa; role guru/admin diarahkan ke unsupported role.

## Keputusan desain sementara

- Typography memakai fallback teknis karena detail Figma masih terblokir.
- Splash dan unsupported role adalah Temporary Foundation karena frame tidak tersedia.
- Loading/empty/error memakai foundation minimal sampai component Figma final tersedia.

## Gap API

- Tidak ada refresh token khusus; session validasi memakai `/auth/me`.
- Edit profile endpoint ada, tetapi UI edit ditunda di foundation.
- Dashboard siswa penuh belum dihubungkan pada fase ini karena scope hanya foundation.

## Fase berikutnya

1. Manual production login dengan akun demo siswa tanpa mencatat kredensial.
2. Implement dashboard siswa memakai `/student/dashboard/summary`.
3. Implement modul dan lesson foundation penuh.
4. Implement kamus dan kuis setelah dashboard/modul stabil.
