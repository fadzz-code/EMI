# EMI Mobile — Kesiapan Rilis Google Play Store

Status per 26 Juli 2026. Dokumen ini merangkum hasil audit tombol/fungsi 3
role (Admin, Guru, Siswa) + Autentikasi, dan checklist kepatuhan Google Play
Console sebelum submit untuk review.

## 1. Audit fungsional (tombol/aksi)

Audit menyeluruh terhadap `onPressed`/`onTap` di seluruh `lib/features`
(Admin, Teacher, Student, Auth) — **tidak ditemukan tombol mati, TODO/FIXME
tersisa, fungsi kosong, atau dead-link navigasi**. Semua `null` pada
`onPressed`/`onTap` yang ditemukan adalah *disable state* yang disengaja:
loading guard, validasi form, batas pagination, atau business rule
(`canStart`, dsb). Seluruh 263 pemanggilan `context.push`/`context.go`
memiliki `GoRoute` yang cocok di `app_router.dart`.

**Kesimpulan: tidak ada perbaikan tombol yang diperlukan.**

## 2. Alasan umum Google Play menolak aplikasi

Bukan cuma Privacy Policy. Yang paling sering menyebabkan **rejection** atau
**app tidak lolos review**:

| # | Kategori | Detail | Status EMI Mobile |
|---|----------|--------|---------------------|
| 1 | **Privacy Policy URL hilang/tidak valid** | Wajib ada URL publik, dapat diakses tanpa login, menjelaskan data yang dikumpulkan | ✅ Dibuat: `https://emi-kolaka.id/privacy` |
| 2 | **Data Safety form tidak sesuai kode** | Play scan permission & SDK di APK/AAB, dibandingkan dengan deklarasi Data Safety di Console. Declare RECORD_AUDIO tapi form bilang "no audio collected" = rejection | ⚠️ Wajib isi manual di Play Console (lihat §4) |
| 3 | **Permission tidak dijelaskan/tidak perlu** | `RECORD_AUDIO` dan galeri foto harus punya alasan jelas & digunakan hanya saat dibutuhkan (bukan diminta di startup) | ✅ Mic diminta on-demand saat masuk fitur Speaking; foto via `image_picker`/`file_picker` on-demand |
| 4 | **Signing / App Bundle tidak valid** | AAB harus signed dengan upload key yang konsisten | ⚠️ `android/key.properties` belum ada di repo (memang harus lokal, tidak di-commit) — lihat README |
| 5 | **Target SDK terlalu lama** | Play mewajibkan `targetSdk` mengikuti API level terbaru (kebijakan tahunan) | ✅ Pakai `flutter.targetSdkVersion` (ikut Flutter SDK terbaru) — pastikan Flutter versi terbaru saat build release |
| 6 | **Cleartext traffic (HTTP tanpa TLS)** | Aplikasi yang mengirim data via HTTP polos ditolak/di-flag sebagai risiko keamanan | ✅ Ditambahkan `network_security_config.xml`, cleartext hanya untuk `10.0.2.2`/`localhost` (dev), production wajib HTTPS (sudah dipaksa di `AppEnvironment`) |
| 7 | **App crash / ANR saat review** | Reviewer Google install & buka app; crash di halaman utama = auto-reject | ➡️ Rekomendasi: jalankan smoke test manual di APK release sebelum upload (lihat §5) |
| 8 | **Konten placeholder / "Lorem ipsum" / broken UI** | Layar kosong, ikon default, teks debug | ✅ Tidak ditemukan pada audit tombol; pastikan tidak ada data dummy di demo akun yang dipakai reviewer |
| 9 | **Deceptive behavior / metadata tidak sesuai app** | Screenshot Play Store harus sama dengan tampilan asli app | ➡️ Siapkan screenshot resmi dari build terbaru (folder `Docs/guides/screenshot-checklist.md` sudah ada) |
| 10 | **Icon/launcher masih default Flutter** | Google Play menolak app dengan ikon generik "Flutter logo" | ⚠️ Perlu dicek — lihat §3 |
| 11 | **Akun uji (test account) tidak disediakan** | Untuk app dengan login wajib, reviewer butuh kredensial demo yang valid dan tidak expired | ➡️ Siapkan 3 akun demo (admin/guru/siswa) aktif saat submit, cantumkan di App Content > App access |
| 12 | **Target audience & content rating salah** | App edukasi untuk sekolah wajib isi "Target age group" dan lulus Content Rating Questionnaire dengan jujur | ➡️ Isi saat submit di Play Console |
| 13 | **Akun anak-anak (Families Policy)** | Karena siswa sekolah bisa di bawah 13 tahun, App tunduk pada Google Play *Families Policy* jika menargetkan anak. Jika Siswa SMP/SMA (13+), umumnya aman sebagai app umum, tapi wajib jujur di Content Rating & Target Audience | ➡️ Pastikan target audience diisi sesuai usia siswa nyata (biasanya 13+ untuk SMP/SMA) |
| 14 | **Package name / applicationId placeholder** | `com.example.*` otomatis ditolak | ✅ Sudah `id.emikolaka.emi_mobile`, valid |
| 15 | **Data collection lewat WebView tanpa disclosure** | Tidak berlaku di app ini (tidak ditemukan WebView) | ✅ N/A |

## 3. Yang masih perlu dicek/dibuat manual (tidak bisa via kode)

Ini bagian yang **tidak bisa saya pastikan dari kode** — perlu dicek/disiapkan
oleh kamu langsung:

- [ ] **App icon custom — WAJIB DIGANTI (BLOCKER).** Diperiksa langsung:
  `android/app/src/main/res/mipmap-*/ic_launcher.png` **masih logo default
  Flutter (biru)**. Google Play menolak ikon generik ini. Pipeline sudah
  disiapkan di `pubspec.yaml` (`flutter_launcher_icons`), tinggal:
  1. Ganti `Emi-Mobile/assets/icon/emi_icon.png` (512×512, tanpa transparansi)
     dan `emi_icon_foreground.png` (adaptive icon, background transparan)
     dengan logo EMI asli — lihat `assets/icon/README.md`.
  2. `flutter pub get`
  3. `dart run flutter_launcher_icons`
  4. Verifikasi `android/app/src/main/res/mipmap-*/ic_launcher.png` sudah
     berubah dari logo Flutter ke logo EMI.
- [ ] **Splash screen** — pastikan bukan splash default Flutter putih polos.
- [ ] **Keystore signing** (`android/key.properties` + file `.jks`) — wajib
  dibuat sebelum build AAB release, **jangan commit ke Git**.
- [ ] **Screenshot & feature graphic** untuk listing Play Store (lihat
  `Docs/guides/screenshot-checklist.md`).
- [ ] **Akun demo untuk reviewer** (App Content → App access) — 1 admin,
  1 guru, 1 siswa yang aktif & tidak akan dihapus selama masa review.
- [ ] **Data Safety form** di Play Console (lihat §4 di bawah, sudah saya
  siapkan draftnya).
- [ ] **Deploy halaman `/privacy`** ke `https://emi-kolaka.id/privacy` (sudah
  dibuat filenya, tinggal deploy `Emi-Frontend`).
- [ ] **Support email aktif**: `support@emi-kolaka.id` dipakai di halaman
  privacy — pastikan email ini benar-benar aktif dan dipantau.

## 4. Draft isian Data Safety (Play Console → App content → Data safety)

Isi form ini persis sesuai apa yang benar-benar dikumpulkan aplikasi
(cocokkan dengan kebijakan privasi):

| Kategori data | Dikumpulkan? | Dibagikan ke pihak ke-3? | Wajib/opsional | Tujuan |
|---|---|---|---|---|
| Nama | Ya | Tidak | Wajib | Fungsi app (akun), Personalisasi |
| Alamat email | Ya | Tidak | Wajib | Fungsi app (akun & login) |
| Nomor telepon | Ya | Tidak | Opsional | Fungsi app |
| Foto profil (User photos) | Ya | Tidak | Opsional | Fungsi app |
| Audio (voice/rekaman) | Ya | Tidak | Opsional (hanya fitur Speaking) | Fungsi app (penilaian latihan) |
| App activity (progres belajar, hasil kuis) | Ya | Tidak | Wajib | Fungsi app |
| App info & performance (crash log jika ada) | Tergantung — jika belum pakai Crashlytics/Sentry, jawab **Tidak** | Tidak | — | — |
| Device/other IDs | Tidak (kecuali Flutter/plugin native mengumpulkan otomatis — cek dependency) | Tidak | — | — |

Checklist tambahan wajib dijawab **"Yes"** di form:
- Data dienkripsi saat transit (HTTPS) → **Ya** (setelah network security config aktif & backend production HTTPS).
- User dapat meminta penghapusan data → **Ya**, cantumkan link `https://emi-kolaka.id/privacy#hapus-akun`.

## 5. Rekomendasi smoke test sebelum upload AAB

1. `flutter build appbundle --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.emi-kolaka.id`
2. Install APK release (bukan debug) ke device fisik, bukan emulator.
3. Uji manual per role: login → dashboard → 1 fitur utama → logout, untuk
   Admin, Guru, Siswa.
4. Uji fitur Speaking (izin mikrofon) dan upload foto profil (izin galeri)
   memunculkan permission dialog yang benar dan tidak crash saat ditolak.
5. Uji tanpa koneksi internet — pastikan app menampilkan pesan error yang
   wajar, bukan crash/blank screen.
6. Uji tombol "Kebijakan Privasi" di halaman Profil (Admin & Siswa/Guru)
   membuka `https://emi-kolaka.id/privacy` di browser.

## 5b. Compile blocker yang ditemukan & diperbaiki

Saat verifikasi akhir, `flutter analyze` menemukan **error kompilasi** di
`admin_modules_screens.dart` (`AdminCard` undefined — import
`admin_widgets.dart` hilang, sisa dari sesi redesign sebelumnya). Ini
**blocker mutlak** karena app tidak bisa di-build sama sekali dalam kondisi
ini. Sudah diperbaiki dengan menambahkan import yang hilang.

Setelah perbaikan: `flutter analyze` → *No issues found*, dan seluruh test
suite (`flutter test`) → **323/323 lulus**.

## 6. Perubahan kode yang sudah dibuat pada sesi ini

| File | Perubahan |
|---|---|
| `Emi-Frontend/src/app/privacy/page.tsx` | Halaman Kebijakan Privasi publik, 11 bagian, sesuai kebutuhan Play Console |
| `Emi-Mobile/lib/shared/legal/privacy_policy.dart` | Konstanta URL privacy + helper `openPrivacyPolicy()` |
| `Emi-Mobile/lib/features/admin/presentation/admin_profile_screen.dart` | Tombol "Kebijakan Privasi" ditambahkan di Profil Admin |
| `Emi-Mobile/lib/features/profile/presentation/student_profile_screen.dart` | Tombol "Kebijakan Privasi" ditambahkan di Profil Siswa & Guru (screen dipakai bersama) |
| `Emi-Mobile/android/app/src/main/AndroidManifest.xml` | Tambah `uses-feature microphone required=false`, `networkSecurityConfig` |
| `Emi-Mobile/android/app/src/main/res/xml/network_security_config.xml` | Baru — blokir cleartext traffic di production, izinkan hanya untuk emulator dev |
| `Emi-Mobile/pubspec.yaml` | Tambah `flutter_launcher_icons` + konfigurasi, siap generate ikon begitu logo EMI tersedia |
| `Emi-Mobile/assets/icon/README.md` | Placeholder & instruksi mengganti launcher icon |
| `Emi-Mobile/lib/features/admin/presentation/admin_modules_screens.dart` | **Fix compile blocker** — import `admin_widgets.dart` yang hilang (app sebelumnya tidak bisa di-build) |

Semua perubahan kode sudah diverifikasi: `dart format` bersih,
`flutter analyze` (seluruh project) → **no issues**,
`flutter test` (seluruh project) → **323/323 lulus**.
