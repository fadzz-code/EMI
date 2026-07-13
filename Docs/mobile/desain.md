# Desain Mobile EMI

## 1. Tujuan Dokumen

Dokumen ini menjadi sumber desain reusable untuk seluruh implementasi aplikasi Flutter EMI.

Setiap prompt implementasi Flutter berikutnya wajib membaca dokumen ini sebelum membuat UI. Tujuannya agar seluruh screen Flutter memakai sumber visual yang sama, tidak membuat warna/spacing/typography sendiri, dan tetap konsisten dengan desain Figma EMI.

Dokumen ini bukan source code Flutter dan tidak menggantikan audit API. Dokumen ini hanya mengatur keputusan visual, pemetaan screen, komponen, token, dan aturan review UI.

## 2. Urutan Sumber Kebenaran

Urutan sumber kebenaran desain:

1. Figma MCP.
2. `Docs/mobile/desain.md`.
3. `Docs/mobile` lainnya.
4. `Emi-Frontend` untuk referensi alur.
5. Keputusan temporary yang dicatat jelas.

Aturan:

- Figma MCP adalah sumber utama visual.
- Source Flutter bukan sumber kebenaran desain jika berbeda dari Figma.
- `Emi-Frontend` hanya dipakai untuk memahami alur dan fitur yang sudah berjalan, bukan untuk membuat token visual baru.
- Material 3 hanya fondasi teknis Flutter, bukan sumber gaya visual EMI.
- Keputusan temporary wajib diberi label `Temporary` atau `Needs Figma Verification`.

## 3. Sumber Figma

- Nama file: `Untitled`.
- File key: `tZcPOdYQhry2xHzm1B0UIC`.
- Page: `Page 1`.
- Page node ID: `0:1`.
- Section: tidak terbaca sebagai section eksplisit dari MCP; frame dikelompokkan lewat nama frame dan posisi area Admin/Guru/Siswa/Auth.
- Frame utama:
  - Desktop auth: `AUTH-01` sampai `AUTH-05`.
  - Desktop admin: `ADMIN-01` sampai `ADMIN-19`.
  - Desktop guru: `TEACHER-01` sampai `TEACHER-13`.
  - Desktop siswa: `STUDENT-01` sampai `STUDENT-14`.
- Frame mobile:
  - Auth mobile: `Pilih Jenis Akun EMI (Mobile)` node `117:2`, `Halaman Login EMI (Mobile)` node `117:51`.
  - Admin mobile: `SCREEN 1 — Beranda Admin` node `105:4` sampai `SCREEN 17 — Progress & Pengaturan` node `105:2288`.
  - Guru mobile: `SCREEN 1 — Beranda Guru` node `105:5621` sampai `SCREEN 13 — Media Kelas & Profil Guru` node `105:4226`.
  - Siswa mobile: `SCREEN 1 — Beranda Belajar` node `107:5989` sampai `SCREEN 18 — Sinkronisasi Data` node `109:1473`.
- Frame web:
  - Desktop role frames tercatat di `Docs/ui-ux-figma-audit.md`: auth, admin, guru, siswa.
- Component library:
  - Component set eksplisit belum terbaca dari MCP output awal.
  - Komponen berulang terbaca sebagai frame bernama `Header - TopAppBar`, `Mobile BottomNavBar`, `BottomNavBar`, `Button - FAB`, `Rejection Bottom Sheet`, `Info Banner`, `Main Content Canvas`, `Card` pattern.
- Tanggal atau versi: tidak tersedia dari MCP output awal.
- Status akses:
  - File berhasil diakses sekali lewat Figma MCP.
  - Drill-down node berikutnya terblokir rate limit Figma API `429`; detail token yang belum terbaca diberi status `Needs Figma Verification`.

Update verifikasi fase Dashboard/Modul:

- File Figma aktif: `Untitled`.
- File key aktif: `oMA2sYbh2B7cgzGJINNiar`.
- Canvas: `MOBILE EMI`, node `0:1`.
- Dashboard Siswa: `SCREEN 1 — Beranda Belajar`, node `1:4221`.
- Daftar Modul Siswa: `SCREEN 3 — Modul Belajar`, node `1:4473`.
- Component/frame terbaca: `Header - TopAppBar`, `BottomNavBar (Mobile)`, `Section - Hero Card`, `Section - Stats Grid`, `Section - Lanjutkan Belajar Specific Module`, `Section - Menu Cepat`, `Search Bar`, `Filter Chips`, `Statistics Cards`, `Card 1/2/3`.
- Variables/styles terbaca: Plus Jakarta Sans 12/700 nav label, Plus Jakarta Sans 18/700 dashboard heading, Plus Jakarta Sans 18/600 module heading, Plus Jakarta Sans 16/800 app bar title; fill `#FEF8F1`, `#FFF9F2`, `#FFFFFF`, `#1D1B17`, `#FF8A3D`, `#FDD758`, `#5BBE5D`, `#564338`, `#004910`; shadow `4px 4px 0px 0px rgba(29, 27, 23, 1)`; app bar height `64`; page padding `16`; hero padding `24`; card radius `12`; hero radius `16`; bottom nav active pill `9999`.

Jika akses Figma MCP kembali tersedia, audit berikutnya wajib membaca ulang node screen prioritas dan memperbarui dokumen ini.

## 4. Status Desain yang Tersedia

| Area | Mobile tersedia | Web tersedia | Component tersedia | Status |
|---|---:|---:|---:|---|
| Splash | Tidak | Tidak teridentifikasi | Tidak | Missing |
| Login | Ya | Ya | Partial | Partial |
| Dashboard siswa | Ya | Ya | Partial | Ready |
| Modul | Ya | Ya | Partial | Ready |
| Lesson | Ya | Ya | Partial | Ready |
| Kamus | Ya | Ya | Partial | Ready |
| Detail kamus | Ya | Ya | Partial | Ready |
| Kuis | Ya | Ya | Partial | Ready |
| Attempt kuis | Ya | Ya | Partial | Ready |
| Hasil kuis | Ya | Ya | Partial | Ready |
| Progress | Ya | Ya | Partial | Ready |
| Profil | Ya | Ya | Partial | Ready |
| Chatbot | Ya | Ya | Partial | Partial |
| Budaya | Ya | Ya | Partial | Ready |
| Speaking | Ya | Ya | Partial | Ready |
| Unsupported role | Tidak teridentifikasi | Tidak teridentifikasi | Tidak | Missing |
| Loading | Tidak teridentifikasi sebagai frame khusus | Tidak teridentifikasi | Tidak | Needs manual verification |
| Empty state | Tidak teridentifikasi sebagai frame khusus | Tidak teridentifikasi | Tidak | Needs manual verification |
| Error state | Tidak teridentifikasi sebagai frame khusus | Tidak teridentifikasi | Tidak | Needs manual verification |

## 5. Karakter Visual EMI

Berdasarkan output Figma MCP dan audit `Docs/ui-ux-figma-audit.md`, karakter visual EMI:

- Gaya visual: neobrutalism / bold card UI terverifikasi dari stroke tebal, shadow offset keras, warna flat, dan layout blok.
- Kontras: tinggi, dengan teks gelap di permukaan cream/white dan aksen orange/yellow/green.
- Komponen: top app bar, bottom navigation, card, FAB, chip/badge, bottom sheet, form input, dan dashboard cards memakai blok tegas.
- Typography: Figma audit mencatat Quicksand dominan di desktop, Plus Jakarta Sans dominan di mobile/student responsive, serta Lexend/Work Sans di auth. MCP output awal tidak memberi detail style typography per node karena rate limit saat drill-down.
- Ilustrasi/pola: beberapa background memakai radial dot/pattern fill dari Figma, misalnya `GRADIENT_RADIAL` dengan cream/white base.
- Ikon: ikon terlihat pada bottom nav/top app bar/FAB, tetapi library ikon tidak terbaca dari MCP output awal.
- Shadow: banyak shadow offset keras, misalnya `4px 4px 0px 0px`, `8px 8px 0px 0px`, `0px -4px 0px 0px`, `4px 0px 0px 0px`.
- Border: stroke gelap dengan width 2px atau 4px sering muncul; bottom sheet memiliki stroke `3px 3px 0px`.
- Radius: common radius dari audit adalah 8px, 12px, pill 9999px; MCP output juga menunjukkan FAB radius 9999px dan bottom sheet radius `24px 24px 0px 0px`.

Bukti neobrutalism dari MCP:

- `Button - FAB` node `105:656`: fill `#FF8A3D`, stroke `#1D1B17`, stroke weight `2px`, shadow `4px 4px 0px 0px rgba(29, 27, 23, 1)`, radius `9999px`.
- `Button - Tambah Kata` node `105:1570`: fill `#FF8A3D`, stroke `#1D1B17`, stroke weight `2px`, shadow `8px 8px 0px 0px rgba(29, 27, 23, 1)`, radius `9999px`.
- `Header - TopAppBar` node `105:745`: bottom stroke `2px`, shadow `0px 4px 0px 0px rgba(29, 27, 23, 1)`.
- `Rejection Bottom Sheet` node `105:403`: stroke `3px 3px 0px`, shadow `0px -8px 0px 0px rgba(29, 27, 23, 0.1)`, radius `24px 24px 0px 0px`.
- Sidebar desktop template `EL-9c9ec0e2`: dark stroke and shadow `4px 0px 0px 0px rgba(36, 25, 20, 1)`.

## 6. Design Tokens

Semua token di bawah berasal dari Figma MCP output atau `Docs/ui-ux-figma-audit.md`. Token yang belum terbaca jangan dibuat di Flutter sebagai nilai final.

### 6.1 Warna

| Token | Nilai Figma | Fungsi | Node/style sumber |
|---|---|---|---|
| primary | `#FF8A3D` | Aksi utama, FAB, button aksen | `fill_91bed1c8`, node `105:656`, `105:1570` |
| secondary | `#FDD758` | Aksen kuning | `Docs/ui-ux-figma-audit.md` Design System Signals |
| background | `#FEF8F1` | Background mobile cream | `fill_6d4aa6c2`, banyak mobile frames |
| background warm | `#FFF9F2` | Background alternatif / patterned screens | `fill_ceea2803`, `fill_01d2500f`, `fill_d0db59d8` |
| background web | `#FFF8F6` | Background desktop role screens | `fill_a716fb68`, `fill_7c98d52c` |
| surface | `#FFFFFF` | Card/surface putih | `fill_658ab2fa` |
| surface soft | `#FFF1EB` | Header/surface soft | `fill_3f27471e` |
| surface accent | `#FEEAE0` | Sidebar/area accent | `fill_eff2200e` |
| text primary | `#1D1B17` | Ink mobile utama | `fill_d976ee90` |
| text primary web | `#241914` | Ink/brown web utama | `fill_47f1055c` |
| text dark | `#1B1B1B` | Ink auth/mobile variant | `fill_630929c9` |
| border | `#1D1B17` | Border mobile | `fill_d976ee90` |
| border web | `#241914` | Border desktop | `fill_47f1055c` |
| shadow | `rgba(29, 27, 23, 1)` | Shadow mobile offset | `effect_36459ccd` |
| shadow web | `rgba(36, 25, 20, 1)` | Shadow desktop offset | `effect_a2517ce3`, `effect_6b8717ef` |
| success | `#5BBE5D` | Status sukses | `Docs/ui-ux-figma-audit.md` Design System Signals |
| warning | `#FDD758` | Status warning/aksen | `Docs/ui-ux-figma-audit.md` Design System Signals |
| error | `#BA1A1A` | Status error/danger | `Docs/ui-ux-figma-audit.md` Design System Signals |
| info | Needs Figma Verification | Info state | Tidak terbaca dari MCP output awal |

### 6.2 Typography

| Token | Font family | Size | Weight | Line height | Sumber |
|---|---|---:|---:|---:|---|
| display | Needs Figma Verification |  |  |  | Drill-down typography terkena Figma API 429 |
| heading 1 | Needs Figma Verification |  |  |  | Drill-down typography terkena Figma API 429 |
| heading 2 | Needs Figma Verification |  |  |  | Drill-down typography terkena Figma API 429 |
| heading 3 | Needs Figma Verification |  |  |  | Drill-down typography terkena Figma API 429 |
| body | Plus Jakarta Sans / Quicksand candidate |  |  |  | `Docs/ui-ux-figma-audit.md` mencatat mobile/student responsive memakai Plus Jakarta Sans, desktop dominan Quicksand |
| body small | Needs Figma Verification |  |  |  | Drill-down typography terkena Figma API 429 |
| label | Needs Figma Verification |  |  |  | Drill-down typography terkena Figma API 429 |
| button | Needs Figma Verification |  |  |  | Drill-down typography terkena Figma API 429 |

Aturan typography:

- Jangan memilih font final sebelum membaca text styles langsung dari Figma.
- Untuk Flutter foundation, font boleh ditandai temporary jika belum ada akses style final.
- Jangan mencampur Quicksand, Plus Jakarta Sans, Lexend, dan Work Sans tanpa keputusan eksplisit dari Figma audit berikutnya.

### 6.3 Spacing

| Token | Nilai | Penggunaan | Sumber |
|---|---:|---|---|
| screen width mobile | 390px | Lebar frame mobile Figma | Banyak mobile frames: `107:5989`, `109:1552`, dll |
| top app bar height | 64px | Header mobile | `Header - TopAppBar`, node `107:6016`, `109:1671`, `105:884` |
| desktop top bar height | 80px | Header desktop | `layout_02e06f4e`, `layout_9f3da82c` |
| page horizontal padding | 16px | Main content mobile | `Main Content Canvas` node `107:6034`, `109:1553`, `105:947` |
| auth horizontal padding | 20px | Auth mobile content | `Pilih Jenis Akun EMI (Mobile)` node `117:17` |
| section gap | 24px | Main content group gap | Banyak `Main Content Canvas` nodes |
| large section gap | 32px | Siswa dashboard/progress/speaking group gap | node `107:6034`, `109:168`, `109:1180` |
| bottom nav top border spacing | 4px vertical padding | Bottom nav mobile | node `105:126`, `105:153`, `109:1302` |
| bottom safe padding | 80px / 96px / 100px / 128px | Scroll bottom padding untuk nav | layout vars `layout_07143a0e`, `layout_da042a72`, `layout_d0703f92` |

### 6.4 Border

- Warna utama mobile: `#1D1B17` dari `fill_d976ee90`.
- Warna utama web: `#241914` dari `fill_47f1055c`.
- Width umum: `2px` untuk top app bar, bottom nav, FAB, card/action surfaces.
- Width kuat: `4px` untuk beberapa border bawah/atas nav dan desktop header/sidebar.
- Bottom sheet: stroke `3px 3px 0px` pada node `105:403`.
- Style: solid.
- Penggunaan: header bottom border, bottom nav top border, card border, button border, FAB border, sidebar border.

### 6.5 Radius

- Radius button: Needs Figma Verification untuk button umum; FAB terverifikasi `9999px`.
- Radius card: 8px dan 12px tercatat di `Docs/ui-ux-figma-audit.md`; node detail perlu verifikasi ulang.
- Radius input: Needs Figma Verification.
- Radius modal/bottom sheet: `24px 24px 0px 0px` dari node `105:403`.
- Radius pill/chip: `9999px` dari audit dan FAB nodes.

### 6.6 Shadow

| Token | Offset X | Offset Y | Blur | Spread | Warna | Sumber |
|---|---:|---:|---:|---:|---|---|
| shadow hard mobile | 4px | 4px | 0px | 0px | `rgba(29, 27, 23, 1)` | `effect_36459ccd`, node `105:656` |
| shadow hard mobile large | 8px | 8px | 0px | 0px | `rgba(29, 27, 23, 1)` | node `105:1570` |
| shadow top nav | 0px | 4px | 0px | 0px | `rgba(29, 27, 23, 1)` | node `105:745` |
| shadow bottom nav | 0px | -4px | 0px | 0px | `rgba(0, 0, 0, 1)` | `effect_8bed2836` |
| shadow bottom sheet | 0px | -8px | 0px | 0px | `rgba(29, 27, 23, 0.1)` | node `105:403` |
| shadow desktop side | 4px | 0px | 0px | 0px | `rgba(36, 25, 20, 1)` | `effect_6b8717ef` |
| shadow desktop hard | 4px | 4px | 0px | 0px | `rgba(36, 25, 20, 1)` | `effect_a2517ce3` |
| shadow subtle header | 0px | 1px | 2px | 0px | `rgba(0, 0, 0, 0.05)` | node `105:884`, `109:442` |

Aturan: jangan memakai soft shadow generik jika screen Figma memakai offset shadow keras.

### 6.7 Iconography

- Library ikon: Needs Figma Verification; MCP output tidak menyebut library ikon.
- Ukuran ikon: Needs Figma Verification per node.
- Stroke: Needs Figma Verification.
- Filled/outlined: Needs Figma Verification.
- Penggunaan terverifikasi:
  - Bottom navigation icon pada semua role mobile.
  - Top app bar icon/menu/back/user actions.
  - FAB icon pada admin mobile dan kamus admin mobile.
  - Feature cards memakai ikon visual.
- Aturan:
  - Jangan mengganti aset ikon custom tanpa alasan.
  - Jika library belum diketahui, gunakan placeholder teknis hanya setelah dicatat `Temporary`.
  - Jangan membuat ikon custom tiruan jika aset Figma asli tersedia.

## 7. Pemetaan Komponen Figma ke Flutter

| Komponen Figma | Node ID | Komponen Flutter yang direncanakan | Status | Catatan |
|---|---|---|---|---|
| App logo | Needs Figma Verification | `EmiLogo` | Needs manual verification | Logo node tidak terbaca dari MCP output awal. |
| Splash | Missing | `SplashScreen` | Missing | Tidak ada frame splash teridentifikasi. |
| Login card | `117:51` | `LoginCard` | Partial | Node frame ada, detail card terkena rate limit. |
| Text field | Needs Figma Verification | `EmiTextField` | Needs manual verification | Detail input belum terbaca. |
| Password field | Needs Figma Verification | `EmiPasswordField` | Needs manual verification | Detail input belum terbaca. |
| Primary button | `105:656`, `105:1570` for FAB/action style | `EmiButton.primary` | Partial | Button umum perlu detail node; FAB action verified. |
| Secondary button | Needs Figma Verification | `EmiButton.secondary` | Needs manual verification | Jangan finalkan tanpa node. |
| Card | Multiple `Main Content Canvas` child cards | `EmiCard` | Partial | Border/shadow style terverifikasi umum, detail card perlu node. |
| Feature card | `107:6149` area | `FeatureCard` | Partial | Detail card di menu belajar perlu re-audit. |
| App bar | `107:6016`, `109:1671`, `105:884` | `EmiTopAppBar` | Ready | Height 64, bottom stroke 2px, cream fill. |
| Bottom navigation | `107:5990`, `109:1302`, `105:126` | `EmiBottomNavigation` | Ready | Width 390, top border 2/4px, white fill. |
| Drawer jika ada | Tidak teridentifikasi mobile | `EmiDrawer` | Missing | Mobile lebih banyak bottom nav/top app bar. |
| Badge | Needs Figma Verification | `EmiBadge` | Needs manual verification | Status chip terlihat di audit, node detail belum dibaca. |
| Status chip | Needs Figma Verification | `StatusChip` | Needs manual verification | Perlu node detail. |
| Loading | Tidak teridentifikasi | `EmiLoadingState` | Missing | Buat berdasarkan component style setelah Figma tersedia. |
| Empty state | Tidak teridentifikasi | `EmiEmptyState` | Missing | Buat temporary jika perlu, catat. |
| Error state | Tidak teridentifikasi | `EmiErrorState` | Missing | Buat temporary jika perlu, catat. |
| Modal | Needs Figma Verification | `EmiDialog` | Partial | Bottom sheet tersedia; modal desktop belum detail. |
| Bottom sheet | `105:403` | `EmiBottomSheet` | Ready | Radius 24 top, stroke 3px, shadow top. |
| Dashboard card | `107:6034` children | `DashboardCard` | Partial | Layout dashboard siswa tersedia; detail card perlu drill-down. |
| Profile card | `109:1361` children | `ProfileCard` | Partial | Screen profil ada; detail card perlu drill-down. |
| Unsupported role | Missing | `UnsupportedRoleScreen` | Missing | Perlu desain atau temporary foundation. |

## 8. Aturan Adaptasi Web ke Mobile

- Identitas visual Figma dipertahankan.
- Layout desktop tidak disalin pixel-perfect ke Flutter mobile.
- Sidebar desktop menjadi navigasi mobile jika role mobile butuh menu.
- Tabel desktop menjadi card atau list mobile.
- Layout multi-column menjadi single-column.
- Hover state menjadi pressed state.
- Dialog desktop dapat menjadi bottom sheet jika sesuai pola Figma.
- Touch target harus cukup besar; nilai minimum teknis Flutter boleh mengikuti platform, tetapi bukan token Figma.
- SafeArea wajib untuk semua screen.
- Keyboard tidak boleh menyebabkan overflow.
- Back navigation harus mengikuti Android.
- Loading, empty, error, dan retry harus tersedia.
- Jangan mengubah alur bisnis hanya untuk menyesuaikan desain.
- Jangan menghapus fitur yang ada hanya karena frame Figma tidak lengkap.

## 9. Pola Navigasi Mobile

Navigasi dari Figma yang tersedia:

- Mobile memakai `Header - TopAppBar` tinggi 64px.
- Mobile memakai `BottomNavBar` di banyak screen role Admin/Guru/Siswa.
- Beberapa screen transactional menekan bottom nav dan memakai contextual action bar, misalnya `SCREEN 11 — Pengerjaan Kuis` node `109:617`.
- Bottom nav memiliki fill `#FFFFFF` dan top border gelap 2px/4px.

Temporary Navigation Proposal untuk MVP Siswa:

- Beranda.
- Belajar.
- Kamus.
- Progress.
- Profil.

Status proposal: Temporary, karena label akhir bottom nav siswa belum terbaca detail dari node child akibat rate limit. Proposal ini sesuai dengan Docs/mobile dan pola screen siswa Figma, tetapi wajib diverifikasi ulang dari node bottom nav Figma sebelum implementasi final.

## 10. Aturan Implementasi Flutter

1. Semua token harus terpusat.
2. Jangan hardcode token yang sama di banyak file.
3. Gunakan `ThemeData` dan extension jika dibutuhkan.
4. Material 3 hanya sebagai fondasi teknis.
5. Widget harus mengikuti Figma.
6. Jangan menggunakan gradient jika tidak ada di Figma.
7. Jangan menggunakan glassmorphism jika tidak ada di Figma.
8. Jangan menggunakan soft shadow generik jika Figma memakai offset shadow.
9. Jangan mengganti logo.
10. Jangan membuat aset tiruan jika aset asli tersedia.
11. Jangan menambahkan warna baru tanpa alasan.
12. Setiap penyimpangan dari Figma harus dicatat.
13. Jangan memakai ukuran desktop secara langsung di mobile.
14. Jangan mengorbankan keterbacaan demi gaya.

## 11. Responsive Mobile Rules

Aturan berdasarkan Figma dan keputusan teknis:

- Small phone: implementation decision; gunakan layout scroll single-column dan hindari fixed height dari Figma jika menyebabkan overflow.
- Standard phone: Figma mobile memakai width 390px sebagai referensi utama.
- Large phone: implementation decision; pertahankan max content width bila perlu agar card tidak terlalu melebar.
- Portrait: prioritas utama karena semua frame mobile yang terbaca berbasis portrait 390px.
- Landscape: Needs Figma Verification; minimal jangan crash dan gunakan scroll.
- Text scaling: implementation decision; jangan kunci text scale kecuali ada alasan aksesibilitas.
- Accessibility: touch target harus cukup, contrast harus mengikuti Figma, dan semantic label wajib untuk tombol/icon.
- Keyboard: form login/search/input harus scroll atau resize aman.
- SafeArea: wajib di top app bar, bottom nav, bottom sheet, dan screen dengan keyboard.
- Overflow: semua content panjang harus scroll; jangan potong card.
- Scroll behavior: screen mobile Figma banyak memakai `overflowScroll: y`; implementasi Flutter harus memakai scroll view untuk konten panjang.

Breakpoint teknis sementara:

- `<= 360dp`: small phone.
- `361dp–430dp`: standard phone.
- `> 430dp`: large phone.

Status breakpoint: implementation decision, bukan token Figma.

## 12. Screen Design Map

| Screen | Frame Figma | Status | Adaptasi Mobile | Catatan |
|---|---|---|---|---|
| Splash | Missing | Missing | Buat temporary minimal tanpa visual final | Perlu frame baru atau arahan. |
| Login | `Halaman Login EMI (Mobile)` node `117:51` | Partial | Pakai auth mobile style | Detail node terkena 429. |
| Dashboard siswa | `SCREEN 1 — Beranda Belajar` node `107:5989` | Ready | Main content single-column + bottom nav | Prioritas MVP. |
| Modul | `SCREEN 3 — Modul Belajar` node `107:6241` | Ready | List card modul | Ada top app bar + bottom nav. |
| Detail modul | `SCREEN 4 — Detail Materi` node `107:6405` | Partial | Detail modul/lesson content | Nama frame lebih mengarah detail materi; perlu cek detail modul khusus. |
| Lesson | `SCREEN 4 — Detail Materi` node `107:6405` | Ready | Content scroll + progress action | P0. |
| Kamus | `SCREEN 6 — Kamus Mekongga` node `109:1552` | Ready | Search/list card | P0. |
| Detail kamus | `SCREEN 7 — Detail Kata Kamus` node `109:236` | Ready | Detail vocabulary + audio | P0. |
| Kuis | `SCREEN 10 — Kuis & LKPD` node `109:415` | Ready | Quiz cards | P0. |
| Attempt kuis | `SCREEN 11 — Pengerjaan Kuis` node `109:617` | Ready | Transactional screen; contextual action bar | Bottom nav diganti action bar. |
| Hasil kuis | `SCREEN 12 — Hasil Kuis` node `109:719` | Ready | Score/result card | P0. |
| Progress | `SCREEN 16 — Progress Belajar` node `109:1179` | Ready | Progress summary cards | P0. |
| Profil | `SCREEN 17 — Profil Saya` node `109:1328` | Ready | Profile card/form | P0. |
| Chatbot | `SCREEN 15 — Chatbot AI` node `109:1100` | Partial | Chat surface | Detail chat children belum terbaca. |
| Budaya | `SCREEN 13 — Budaya Mekongga` node `109:871`, `SCREEN 14 — Detail Konten Budaya` node `109:997` | Ready | Feed + optional detail | Detail route belum P0 API. |
| Speaking | `SCREEN 8 — Latihan Speaking` node `109:158`, `SCREEN 9 — Hasil Speaking` node `109:337` | Ready | Recorder + result | P1 setelah MVP. |
| Unsupported role | Missing | Missing | Temporary role-block screen | Perlu desain. |

## 13. Asset Map

| Asset | Sumber Figma | Format | Target Flutter | Status |
|---|---|---|---|---|
| Logo EMI | Needs Figma Verification | Unknown | `assets/images/logo.*` | Needs manual review |
| Auth illustration | `Pilih Jenis Akun EMI (Mobile)` / `Halaman Login EMI (Mobile)` | Unknown | Auth screen asset | Needs manual review |
| Background pattern dot | Multiple fills `GRADIENT_RADIAL` | Vector/fill pattern | Theme/background painter or image if needed | Partial |
| Bottom nav icons | Mobile bottom nav nodes | Vector/icon | Icon widget/assets | Needs manual review |
| FAB icon | `Button - FAB` nodes | Vector/icon | Icon widget/assets | Needs manual review |
| Culture images | API media, not Figma token | Backend media URL | Runtime network image | Ready via API |
| Dictionary audio | API media, not Figma token | Audio URL | just_audio | Ready via API |
| Speaking reference audio | API media, not Figma token | Audio URL | just_audio | Ready via API |

Jangan mengekspor aset pada tugas ini. Ekspor aset hanya saat implementasi membutuhkan dan node sumber sudah pasti.

## 14. Bagian yang Belum Tersedia

| Area | Status | Dampak | Keputusan sementara | Tindak lanjut |
|---|---|---|---|---|
| Typography exact sizes | Needs Figma access | Theme text belum final | Jangan finalkan font size/weight | Re-audit text styles saat rate limit selesai. |
| Logo source | Needs manual review | Splash/login belum bisa final | Jangan buat logo tiruan | Ambil asset dari Figma saat node jelas. |
| Icon library | Needs manual review | Icon Flutter belum pasti | Pakai placeholder hanya bila dicatat | Audit icon nodes. |
| Splash | Needs design | Screen awal belum punya frame | Temporary minimal boleh | Minta desain atau buat proposal terpisah. |
| Unsupported role | Needs design | Role guard UI belum final | Temporary screen boleh | Minta desain atau buat proposal. |
| Loading state | Needs design | State API belum visual final | Temporary foundation | Audit Figma atau adaptasi card style. |
| Empty state | Needs design | State kosong belum visual final | Temporary foundation | Audit Figma atau adaptasi card style. |
| Error state | Needs design | Error/retry belum visual final | Temporary foundation | Audit Figma atau adaptasi card style. |
| Component library formal | Needs Figma access | Mapping component set belum lengkap | Gunakan repeated frames | Audit component set saat MCP bisa. |
| Figma rate limit | Needs Figma access | Drill-down node terblokir | Catat blocker | Retry setelah limit selesai atau gunakan file export resmi. |

## 15. Checklist Implementasi UI

- [ ] Figma frame sudah dibaca
- [ ] Node ID dicatat
- [ ] Token digunakan dari desain.md
- [ ] Tidak ada warna tebakan
- [ ] Tidak ada typography tebakan
- [ ] Border sesuai Figma
- [ ] Shadow sesuai Figma
- [ ] Radius sesuai Figma
- [ ] SafeArea aman
- [ ] Keyboard aman
- [ ] Tidak ada overflow
- [ ] Loading state tersedia
- [ ] Empty state tersedia
- [ ] Error state tersedia
- [ ] Pressed state tersedia
- [ ] Screenshot dibandingkan dengan Figma
- [ ] Penyimpangan dicatat

## 16. Prosedur Review Visual

1. Baca frame Figma.
2. Implementasikan screen.
3. Jalankan emulator.
4. Ambil screenshot.
5. Bandingkan dengan Figma.
6. Cek warna.
7. Cek typography.
8. Cek spacing.
9. Cek border.
10. Cek shadow.
11. Cek radius.
12. Cek alignment.
13. Cek keyboard.
14. Cek SafeArea.
15. Catat perbedaan.
16. Perbaiki.
17. Update progress.

## 17. Aturan untuk Prompt Berikutnya

Setiap prompt implementasi Flutter wajib membaca:

- `Docs/mobile/mobile-architecture-plan.md`
- `Docs/mobile/mobile-api-coverage.md`
- `Docs/mobile/mobile-development-plan.md`
- `Docs/mobile/desain.md`
- `Docs/mobile/mobile-implementation-progress.md`

Prompt berikutnya tidak boleh mengulang seluruh design system.

Prompt cukup menyebut:

> Ikuti seluruh aturan visual dan token di `Docs/mobile/desain.md`.

Jika prompt menyentuh UI baru, prompt wajib menyebut frame Figma atau status `Temporary` jika frame belum ada.

## 18. Keputusan Desain

Keputusan final:

- Figma MCP adalah sumber visual utama.
- Mobile memakai gaya neobrutalism yang terverifikasi dari border tebal, offset shadow, card blok, dan warna flat.
- Flutter tidak boleh membuat palette sendiri.
- Flutter tidak boleh memakai soft Material look jika bertentangan dengan Figma.
- Siswa mobile memakai pola top app bar + bottom navigation dari Figma mobile.

Keputusan sementara:

- Navigation MVP siswa: Beranda, Belajar, Kamus, Progress, Profil.
- Splash dan unsupported role memakai temporary UI sampai ada frame Figma.
- Typography exact belum final karena MCP rate limit saat drill-down.
- Loading/empty/error state memakai temporary foundation bila belum ada frame khusus.

Penyimpangan dari Figma:

- Belum ada penyimpangan implementasi karena belum ada source Flutter.
- Semua penyimpangan nanti wajib dicatat di dokumen progress.

Alasan adaptasi mobile:

- Figma menyediakan mobile 390px; Flutter harus tetap responsif untuk variasi Android.
- Layout desktop tidak dipakai pixel-perfect di mobile.

## 19. Blocker

| Blocker | Dampak | Status | Tindak lanjut |
|---|---|---|---|
| Figma API rate limit `429` setelah akses awal | Tidak bisa drill-down node detail typography/input/icon/logo | Terblokir sebagian | Retry saat limit selesai atau minta export/token resmi. |
| Component set formal tidak terbaca | Component map masih berbasis frame berulang | Partial | Audit component library saat MCP tersedia. |
| Typography exact tidak terbaca | Font size/weight/line-height belum final | Needs Figma Verification | Re-audit text nodes/styles. |
| Logo node tidak terbaca | Asset logo belum bisa dipetakan final | Needs manual review | Cari logo node dari Figma atau asset resmi. |
| Loading/empty/error frame tidak teridentifikasi | State UI perlu temporary foundation | Needs design | Minta desain atau audit frame lain. |
| Splash frame tidak teridentifikasi | Splash belum final | Needs design | Minta desain atau buat proposal terpisah. |
| Unsupported role frame tidak teridentifikasi | Role guard UI belum final | Needs design | Minta desain atau buat proposal terpisah. |
