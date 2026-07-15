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

## Update fase Attempt, Submit, dan Hasil Kuis

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, node `109:617`; hasil gagal `403 Forbidden` dengan body `{"status":403,"err":"Invalid token"}`.
- Mode desain memakai fallback dari `Docs/mobile/desain.md`, referensi node sebelumnya `1:4221`, `1:4473`, `1:4637`, `1:6283`, `1:4968`, dan node historis kuis `109:415`, `109:617`, `109:719`.
- Start/resume attempt memakai endpoint nyata `POST /api/v1/class-quizzes/{id}/attempts`.
- Load result/detail attempt memakai endpoint nyata `GET /api/v1/quiz-attempts/{id}`.
- Simpan jawaban memakai endpoint nyata `PUT /api/v1/quiz-attempts/{id}/answers/{question_id}`.
- Submit memakai endpoint nyata `POST /api/v1/quiz-attempts/{id}/submit` dengan header `Idempotency-Key`.
- Tipe soal yang didukung UI: `multiple_choice` via `selected_option_id` dan isian/short answer via `answer_text`.
- Timer ditampilkan dari `expires_at` backend jika tersedia.
- Back handling memberi konfirmasi keluar saat attempt masih `in_progress`.
- Hasil menampilkan nilai hanya jika backend mengirim field result sesuai `show_result`; jika tidak, UI menampilkan status tanpa membuat nilai lokal.
- Gap backend: resume layar pengerjaan penuh harus lewat start endpoint karena `GET /api/v1/quiz-attempts/{id}` tidak memuat `classQuiz.questions.options`.
- Verifikasi awal: `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 24 tests.

## Update fase Progress Belajar dan Profil

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, node `109:1179`; hasil gagal `403 Forbidden` dengan body `{"status":403,"err":"Invalid token"}`.
- Mode desain memakai fallback dari `Docs/mobile/desain.md` dan referensi node sebelumnya `1:4221`, `1:4473`, `1:4637`, `1:6283`, `1:4968`.
- Progress Belajar memakai endpoint nyata `GET /api/v1/student/reports/progress`.
- Progress menampilkan summary backend, progress per modul, lesson selesai/total, dan statistik kuis hanya dari field response.
- Profil memakai data nyata `GET /api/v1/auth/me` dari session.
- Edit profil memakai endpoint nyata `PATCH /api/v1/auth/me` dengan `full_name` dan `phone`.
- Ganti password memakai endpoint nyata `PUT /api/v1/auth/password` dengan `current_password`, `password`, dan `password_confirmation`.
- Avatar URL ditampilkan dari `UserResource.avatar.url` jika tersedia.
- Upload/hapus avatar belum diaktifkan walau endpoint tersedia karena package picker/file flow Android belum ada dan belum diuji.
- Logout tetap memakai endpoint nyata `POST /api/v1/auth/logout` dan menghapus session lokal.
- Route Flutter ditambah: `/student/progress`.
- Verifikasi awal: `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 26 tests.

## Update avatar dan hardening MVP Siswa

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, node profil `109:1328`; hasil gagal `403 Forbidden` dengan body `{"status":403,"err":"Invalid token"}`.
- Mode desain memakai fallback dari `Docs/mobile/desain.md` dan komponen profil existing; `Docs/mobile/desain.md` tidak diubah karena tidak ada data Figma baru.
- Kontrak avatar backend terverifikasi dari route/controller/request/service/resource: `POST /api/v1/auth/me/avatar`, `DELETE /api/v1/auth/me/avatar`, multipart field `avatar`, public media, response `UserResource.avatar.id/url`.
- Tipe avatar diterima backend: `image/jpeg`, `image/png`, `image/webp`; batas ukuran `MEDIA_MAX_IMAGE_KB` default 5120 KB.
- Flutter memakai `image_picker` untuk galeri, validasi ekstensi `jpg/jpeg/png/webp` dan ukuran 5 MB sebelum upload, preview lokal, progress upload Dio multipart, double-submit prevention via `auth.isLoading`, error validation ramah, refresh current user dari response upload/delete, dan fallback avatar jika URL null/gagal dimuat.
- Hapus avatar memakai dialog konfirmasi dan endpoint `DELETE /auth/me/avatar`.
- Audit stabilitas MVP memperbaiki bug nyata: progress bar dashboard/modul di-clamp 0..1, back detail kuis aman untuk deep link, `setState` async attempt kuis diberi guard `mounted`, error audio kamus diberi guard `mounted`, token lokal dibersihkan saat API mengembalikan 401.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 29 tests.
- Emulator production: `flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` build debug APK, install, dan app berjalan; command timeout karena Flutter CLI attach. PID app terdeteksi `9923`.
- Manual production login dan upload/delete avatar ke API production belum dilakukan karena kredensial demo tidak tersedia; picker/cancel/preview perlu verifikasi manual dengan akun siswa.

## Update fase Chatbot Siswa

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, node chatbot `109:1100`; hasil gagal `403 Forbidden` dengan body `{"status":403,"err":"Invalid token"}`.
- Mode desain memakai fallback dari `Docs/mobile/desain.md`, komponen mobile EMI existing, dan gaya neobrutalism; `Docs/mobile/desain.md` tidak diubah karena tidak ada data Figma baru.
- Audit backend menemukan route aktif tunggal `POST /api/v1/student/chatbot/messages` dengan auth Sanctum dan role `student`; route lama `/student/chatbot/message` di dokumen audit lama adalah stale.
- Backend tidak menyediakan daftar percakapan, create conversation, detail riwayat, pagination riwayat, delete, atau archive; Flutter memakai flow chat tunggal tanpa persistence palsu.
- Request chatbot memakai body `message` string wajib, min 2, max 1000. Response non-streaming berisi `answer`, `source`, `matched`, `mode`, `provider`, dan opsional `confidence`.
- Flutter menambah route `/student/chatbot`, akses dari menu cepat dashboard, parsing model/repository, controller Riverpod, bubble user/assistant, source expansion, input multiline, loading, error + retry, double-send prevention, auto-scroll hanya saat user masih di bawah, keyboard/SafeArea aman, dan tidak membuat Dio baru.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 34 tests.
- Emulator production: `flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` build debug APK, install, dan app berjalan; command timeout karena Flutter CLI attach. PID app terdeteksi `10131`.
- Manual production login dan kirim pesan chatbot belum dilakukan karena kredensial demo tidak tersedia; navigasi/input/keyboard/pesan production perlu verifikasi manual dengan akun siswa.

## Update navigasi Siswa dan Budaya Mekongga

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, node Budaya `109:871`; hasil gagal `403 Forbidden` dengan body `{"status":403,"err":"Invalid token"}`.
- Mode desain memakai fallback dari `Docs/mobile/desain.md`, pola AppBar/bottom nav existing, dan gaya neobrutalism; `Docs/mobile/desain.md` tidak diubah karena tidak ada data Figma baru.
- Bottom navigation tetap lima item: Beranda, Modul, Kamus, Kuis, Profil. Progress, Chatbot, dan Budaya tidak ditambahkan ke bottom navigation.
- `EmiScaffold` menjadi student shell reusable dengan hamburger AppBar, drawer kiri, header pengguna, dan menu sidebar: Progress Belajar `/student/progress`, Chatbot `/student/chatbot`, Budaya Mekongga `/student/culture`.
- Drawer menutup sebelum navigasi, memberi selected state sesuai route aktif, Android back menutup drawer lebih dulu, dan menghindari route ganda saat item aktif ditekan.
- Audit backend Budaya menemukan route aktif `GET /api/v1/student/culture` dengan auth Sanctum dan role `student`; query didukung `class_id`, `page`, `per_page`; response paginated berisi `ClassCultureItemResource` dengan media public URL dari backend.
- Tidak ada endpoint detail Budaya khusus siswa, search, kategori, atau filter lain untuk siswa; detail mobile memakai data list/cache dan tidak membuat endpoint palsu.
- Flutter menambah daftar Budaya, detail Budaya, pagination load more, pull-to-refresh, loading/empty/error/retry, media image dari URL backend, fallback URL untuk audio/video/pdf/link, dan route `/student/culture/:cultureId`.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 41 tests.
- Emulator production: `flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` build debug APK, install, dan app berjalan; command timeout karena Flutter CLI attach. PID app terdeteksi `10379`.
- Manual production login, buka drawer, navigasi Progress/Chatbot/Budaya, dan data Budaya nyata belum dilakukan karena kredensial demo tidak tersedia; perlu manual verification dengan akun siswa.

## Update fase Speaking Siswa

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, node Speaking `109:158`; hasil gagal `403 Forbidden` dengan body `{"status":403,"err":"Invalid token"}`.
- Mode desain memakai fallback dari `Docs/mobile/desain.md`, komponen mobile EMI existing, dan gaya neobrutalism; `Docs/mobile/desain.md` tidak diubah karena tidak ada data Figma baru.
- Audit backend Speaking Siswa memakai route aktif: `GET /api/v1/student/speaking/exercises`, `GET /api/v1/student/speaking/exercises/{exercise}`, `GET /api/v1/student/speaking/attempts`, `GET /api/v1/student/speaking/attempts/{attempt}`, `POST /api/v1/student/speaking/exercises/{exercise}/attempts`.
- Multipart submit memakai field `file`; opsional `audio_duration_seconds` integer 1-30; ukuran maksimal `config('speaking.max_audio_mb', 5)` default 5 MB.
- MIME diterima backend: `audio/webm`, `video/webm`, `audio/wav`, `audio/x-wav`, `audio/mpeg`, `audio/mp4`, `audio/m4a`, `audio/ogg`; fallback `application/octet-stream` diterima hanya jika extension aman `webm/wav/mp3/m4a/mp4/mpeg/mpga/ogg/oga`.
- Flutter merekam AAC LC `m4a` memakai package `record`, mengirim MIME normalisasi `audio/mp4`, memutar audio memakai `just_audio`, izin mikrofon memakai `permission_handler`, dan file sementara memakai `path_provider`.
- Route Flutter ditambah: `/student/speaking` dan `/student/speaking/:exerciseId`; akses dari sidebar, bukan bottom navigation. Bottom navigation tetap lima item: Beranda, Modul, Kamus, Kuis, Profil.
- Flow Flutter mencakup daftar latihan, detail target/instruksi, audio referensi jika URL public tersedia, rekam/stop/timer 30 detik, preview/play/pause, rekam ulang/hapus, upload progress, double-submit prevention, status pending/processing/completed/failed, hasil AI, feedback guru, riwayat attempt, loading/empty/error/retry, pull-to-refresh.
- AI asynchronous via queue `AnalyzeSpeakingAttemptJob`; Flutter memakai refresh manual dan polling terbatas 12 kali x 5 detik setelah submit, tanpa polling tanpa batas.
- Gap backend: list exercise dan attempt speaking belum paginated; reference audio private mengirim URL null sehingga butuh temporary URL bila ingin playback private; `audio_url` attempt berupa `/api/v1/media/{id}` metadata, bukan temporary playback URL; tidak ada endpoint delete local/remote attempt; status khusus hanya dari attempt detail; produksi perlu queue/AI enabled agar status selesai.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 46 tests.
- Emulator production: `flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` build debug APK, install, dan app berjalan; command timeout karena Flutter CLI attach. PID app terdeteksi `10878`.
- Manual production login, buka sidebar Speaking, rekam mikrofon, submit data production, audio referensi nyata, dan hasil AI nyata masih Needs manual verification karena kredensial demo/data production tidak tersedia.

## Update release readiness Android

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk file `Untitled`, file key `oMA2sYbh2B7cgzGJINNiar`, node `109:158`; hasil gagal `403 Forbidden` dengan body `{"status":403,"err":"Invalid token"}`. Mode desain tetap fallback existing; `Docs/mobile/desain.md` tidak diubah.
- Audit Android: applicationId `id.emikolaka.emi_mobile`, app name `EMI Mobile`, version `1.0.0+1`, compileSdk/targetSdk dari Flutter 3.44.6, minSdk dari Flutter default, permission `INTERNET` dan `RECORD_AUDIO`, production API default `https://api.emi-kolaka.id/api/v1`, debug banner off, cleartext tidak diaktifkan untuk production, launcher icon/splash masih Flutter default/temporary.
- Signing release dibuat aman: `android/key.properties` opsional dan di-ignore; jika tidak ada signing config, release APK dibangun unsigned dan tidak memakai debug key. Tidak ada keystore/password/token/local.properties/build output yang distage.
- Regression audit memperbaiki bug nyata: 401 sekarang mengubah auth state ke unauthenticated, pagination Budaya tidak menggandakan item page yang sama, double-submit kuis dicegah dengan guard dialog/submitting dan idempotency key stabil per attempt, recorder speaking dihentikan saat dispose, avatar drawer/profil fallback aman untuk URL kosong/gagal. Sidebar siswa diperbarui secara terpusat untuk memuat semua 9 rute menu: Beranda, Modul, Kamus, Kuis, Progress Belajar, Chatbot, Budaya, Speaking, dan Profil. Bottom navigation tetap 5 item.
- Gap yang tidak diubah: detail Budaya deep-link tetap bergantung cache/list karena backend tidak punya endpoint detail siswa; release signing belum tersedia; adaptive icon/logo final belum tersedia dari Figma.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 47 tests.
- Build APK release production: `flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id` berhasil membuat `Emi-Mobile/build/app/outputs/flutter-apk/app-release.apk` ukuran 55,264,426 bytes (52.7 MB). Kotlin incremental cache warning muncul karena package di drive C dan project di drive D, tetapi build selesai.
- Install release APK ke emulator gagal karena unsigned: `INSTALL_PARSE_FAILED_NO_CERTIFICATES`. Ini expected selama signing release belum tersedia.
- AAB release tidak dijalankan karena `android/key.properties`/keystore signing tidak tersedia dan tidak boleh membuat signing key baru.
- Emulator smoke memakai debug production dart-define: build/install/launch berhasil, app hidup PID `11046`, logcat 200 baris terakhir tidak memuat `FATAL EXCEPTION`/`AndroidRuntime` untuk app.
- Manual QA masih Needs manual verification: login production, semua flow data backend, permission microphone setelah login, picker cancel/avatar, speaking submit AI, media private, dan perangkat fisik.

## Update release signing workflow

Status: Terblokir signing.

- Audit aman signing dilakukan tanpa mencetak credential.
- `Emi-Mobile/android/key.properties` tidak ada.
- Tidak ditemukan keystore lokal `*.jks` atau `*.keystore` di `Emi-Mobile/android`.
- Environment variable signing umum (`ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) tidak tersedia.
- Gradle release config sudah mendukung `android/key.properties` jika tersedia, dengan property `storeFile`, `storePassword`, `keyAlias`, `keyPassword`; jika tidak tersedia, release build tetap unsigned dan tidak memakai debug key.
- `.gitignore` memastikan `android/key.properties`, `android/local.properties`, `android/app/*.jks`, `android/app/*.keystore`, dan build output tidak masuk Git.
- Karena signing tidak tersedia, signed APK dan AAB tidak dibuild, signed APK tidak diinstall ke emulator, dan smoke test signed release tidak dilakukan.
- Status release signing: `BLOCKED_BY_SIGNING` sampai pengelola menyediakan keystore dan `android/key.properties` lokal.

## Update audit E2E Siswa production

Status: Belum complete.

- Manual login production berhasil dilakukan oleh user langsung di emulator; password tidak dikirim ke chat dan tidak dicatat.
- App production debug attach berjalan di `emulator-5554`; PID terdeteksi, logcat audit tidak menemukan `FATAL EXCEPTION`/crash app dan tidak menemukan token/password tercetak.
- Flutter audit menemukan gap nyata Speaking: private reference audio dan audio attempt bisa datang tanpa playback URL, sedangkan mobile hanya memakai `url` langsung. Fix: Flutter sekarang meminta `POST /api/v1/media/{id}/temporary-url` saat `reference_audio.url`/`audio_url` null dan `media_id` tersedia, serta menampilkan playback rekaman terkirim.
- Regression test ditambah untuk temporary media URL Speaking.
- Verifikasi setelah fix: `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 47 tests.
- Build APK production berhasil: `build/app/outputs/flutter-apk/app-release.apk` 52.7 MB.
- `RELEASE_SIGNING_BLOCKED`: `android/key.properties`/keystore tidak tersedia; AAB/signed APK tidak dibuat.

| Flow | Status | Bukti |
|---|---|---|
| Splash, login, session, 401, logout | PASS sebagian | Login production user berhasil; 401 clear session sudah ada dan diuji unit; logout belum diverifikasi manual setelah semua flow agar session audit tetap berjalan. |
| Dashboard | NEEDS USER DATA | Login berhasil, tetapi data dashboard production tidak bisa dibuktikan lengkap dari UI dump Flutter. |
| Bottom navigation 5 item | PASS | Test `student_navigation_test.dart`; implementasi tetap Beranda, Modul, Kamus, Kuis, Profil. |
| Sidebar 9 item | PASS | Test `student_navigation_test.dart`; menu Beranda, Modul, Kamus, Kuis, Progress, Chatbot, Budaya, Speaking, Profil. |
| Modul/detail/lesson/selesai lesson | NEEDS USER DATA | Endpoint dan UI ada; perlu data modul/lesson production yang aman diubah untuk menandai selesai. |
| Kamus/detail/audio | NEEDS USER DATA | Endpoint dan audio UI ada; perlu entri production dengan audio valid. |
| Kuis list/detail/start/resume/PG/isian/autosave/timer/submit/hasil | NEEDS USER DATA | Endpoint/UI/test ada; perlu kuis production aktif dengan soal PG dan isian, serta izin submit data nyata. |
| Progress belajar | NEEDS USER DATA | Endpoint/UI ada; perlu perubahan lesson/kuis production untuk bukti end-to-end. |
| Profil/edit/ganti password | NEEDS USER DATA | Endpoint/UI ada; edit/password tidak diuji karena berisiko mengubah akun user tanpa data aman. |
| Avatar upload/hapus | NEEDS USER DATA | Endpoint/UI ada; perlu file gambar uji dan izin mengubah avatar akun production. |
| Chatbot | NEEDS USER DATA | Endpoint/UI ada; perlu kirim pesan production dan validasi jawaban/sumber. |
| Budaya list/detail | NEEDS USER DATA | Endpoint/UI ada; detail mobile dari cache/list karena backend tidak punya endpoint detail siswa. |
| Speaking full flow | BLOCKED/NEEDS USER DATA | Fix private media playback dibuat; tetap perlu exercise production, izin mic, upload, queue/AI running, status pending/processing/completed/failed, feedback/history. |

## Update Admin mobile core

Status: Selesai sebagian.

- Figma MCP dicoba satu kali untuk Admin mobile node `105:4`; hasil gagal `403 Invalid token`. Mode desain: fallback memakai `Docs/mobile/desain.md`, referensi Admin tercatat, dan komponen neobrutalism existing.
- Audit backend Admin dilakukan pada routes/controllers/resources/requests/policies/services. Endpoint READY dipakai tanpa mengarang kontrak.
- Auth role guard diperluas: Admin masuk `/admin/dashboard`; Admin tidak masuk route siswa; role selain Admin/Siswa tetap unsupported.
- Admin Shell dibuat tanpa bottom navigation, memakai AppBar + drawer/sidebar dengan header avatar, nama, email, role, active menu, close-before-navigate, no duplicate route, dan logout.
- Menu Admin terpusat: Dashboard, Persetujuan Akun, Guru dan Siswa, Sekolah, Kelas, Modul, Kamus, Basis AI, Kuis, Budaya Mekongga, Template Speaking, Progress, Pengaturan. Parity fungsi utama aktif; debt UI tersisa pada form panjang, tabel/kartu padat di layar sempit, serta verifikasi manual export laporan.
- Dashboard Admin memakai `GET /api/v1/admin/dashboard/summary` dan hanya menampilkan metrik yang dikirim backend.
- Fitur list/detail read-only dibuat untuk endpoint inti: users, classes, module templates, dictionary entries, quiz templates, culture items, speaking exercises, progress reports, settings. CRUD destruktif/form panjang belum diaktifkan di mobile core.
- Manual login Admin production dilakukan user langsung di emulator; password tidak dikirim ke chat. App berjalan di `emulator-5554`; logcat tidak menemukan crash fatal atau token/password tercetak. Pembukaan setiap menu/data nyata masih perlu verifikasi manual lanjutan karena UI dump Flutter tidak memberi bukti teks detail.
- Verifikasi: `flutter pub get` berhasil, `dart format .` berhasil, `flutter analyze` clean, `flutter test` lulus 51 tests.

## Blocker

- Manual E2E penuh Admin masih butuh verifikasi data production per menu dan izin melakukan aksi CRUD aman.
- Admin speaking attempt/feedback dedicated endpoint tidak tersedia; feedback speaking hanya teacher endpoint.
- Media library list endpoint tidak tersedia; media Admin hanya upload/detail/temporary-url/delete.
- Roles endpoint dedicated tidak tersedia; role hanya via user field/filter.
- Manual E2E penuh masih butuh data siswa production yang boleh diubah: modul/lesson, kuis aktif PG+isian, avatar test, chatbot prompt, speaking exercise, queue/AI, dan feedback guru.
- Figma API rate limit 429/akses token tidak valid masih memblokir typography exact, logo, icon library, component set detail, frame progress, dan frame profil aktual.
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
