# Pedoman Desain Mobile EMI

**Dokumen:** `desain-mobile.md`  
**Status:** Acuan wajib implementasi dan review UI Mobile EMI  
**Versi:** 2.0 — Task-First Stacked Layout  
**Platform:** Flutter Mobile  
**Role:** Admin, Guru, dan Siswa  
**Acuan visual:** Website EMI terbaru  
**Arah desain:** neobrutalism ringan, putih–oranye, rapi, mudah dipahami, dan konsisten

---

## 1. Tujuan

Dokumen ini menjadi sumber acuan tunggal untuk seluruh desain Mobile EMI.

Tujuan utama:

1. Menyamakan identitas visual Mobile dengan Website EMI.
2. Membuat tampilan Admin, Guru, dan Siswa konsisten.
3. Mengurangi kotak tebal, bayangan berlebihan, dan layout yang terasa penuh.
4. Menjaga seluruh fitur mudah digunakan pada layar kecil.
5. Memastikan tombol, form, sidebar, list, detail, dialog, dan status menggunakan pola yang sama.
6. Mengutamakan Bahasa Indonesia sederhana untuk pengguna siswa SD–SMA.
7. Menjaga functional parity Web–Mobile tanpa memaksa susunan halaman identik.

> Web boleh menggunakan tabel, modal, dan editor inline. Mobile boleh menggunakan screen terpisah. Fungsi dan hasil data harus sama, tetapi layout menyesuaikan perangkat.

---

## 2. Karakter Visual EMI

Karakter visual EMI adalah:

- bersih;
- hangat;
- ramah;
- berani tetapi tidak kasar;
- sederhana;
- mudah dipahami;
- memiliki aksen neobrutalism ringan;
- dominan putih dan oranye;
- ikon sederhana dan konsisten.

### Prinsip neobrutalism EMI

Gunakan:

- border gelap yang jelas;
- bayangan pendek dan tegas;
- bentuk sederhana;
- warna aksen kuat;
- tipografi yang mudah dibaca.

Jangan gunakan:

- border tebal pada setiap elemen;
- bayangan besar pada semua kartu;
- terlalu banyak kotak di dalam kotak;
- warna berbeda untuk setiap menu;
- sudut terlalu tajam;
- dekorasi yang mengurangi ruang isi;
- efek 3D berlebihan.

### Aturan penting

- Border tegas hanya untuk elemen utama.
- Elemen di dalam kartu tidak perlu memiliki border tebal lagi.
- Maksimal satu lapisan bayangan pada satu kelompok konten.
- Gunakan ruang kosong untuk memisahkan bagian, bukan selalu kotak.
- Satu layar memiliki satu fokus utama.

---

## 3. Sumber Kebenaran Desain

Urutan sumber kebenaran:

1. `desain-mobile.md`
2. design token Mobile EMI
3. warna dan ikon Website EMI
4. implementasi komponen reusable
5. halaman individual

Dilarang menentukan warna, radius, ukuran ikon, atau gaya tombol langsung di halaman jika token sudah tersedia.

---

# 4. Color Palette

Palet berikut menjadi acuan Mobile dan mengikuti karakter Website EMI.

## 4.1 Warna utama

| Token | Hex | Penggunaan |
|---|---:|---|
| `EmiColors.background` | `#FFF8F2` | Latar utama aplikasi |
| `EmiColors.surface` | `#FFFFFF` | Kartu, form, drawer, dialog |
| `EmiColors.primary` | `#FF8738` | Tombol utama, ikon aktif, highlight |
| `EmiColors.primaryPressed` | `#E96F21` | State tombol ditekan |
| `EmiColors.primarySoft` | `#FFF0E4` | Latar aktif ringan |
| `EmiColors.ink` | `#2B211D` | Teks utama, border, shadow |
| `EmiColors.textSecondary` | `#6F5548` | Teks penjelas |
| `EmiColors.textMuted` | `#927B70` | Hint, metadata, teks nonaktif |
| `EmiColors.divider` | `#D8C8BE` | Divider dan border lembut |
| `EmiColors.surfaceMuted` | `#F7EEE8` | Area sekunder, chip, field read-only |

## 4.2 Warna aksi

| Aksi | Warna | Hex | Aturan |
|---|---|---:|---|
| Simpan / Tambah / Lanjutkan | Oranye | `#FF8738` | Tombol utama |
| Edit | Kuning | `#FFD34E` | Teks gelap |
| Hapus | Merah | `#E5484D` | Teks putih |
| Arsip | Putih | `#FFFFFF` | Border gelap, teks gelap |
| Publish | Hijau | `#2F9E68` | Teks putih |
| Retry / Info | Biru | `#3B82F6` | Teks putih |
| Batal / Kembali | Putih | `#FFFFFF` | Border gelap |
| Nonaktif | Abu muda | `#E7E0DC` | Tidak dapat ditekan |

## 4.3 Warna status

| Status | Background | Teks/Icon |
|---|---:|---:|
| Draft | `#F3EAE4` | `#5F4B42` |
| Published / Aktif | `#DDF5E8` | `#207A4C` |
| Processing | `#E7F0FF` | `#2563A8` |
| Completed | `#DDF5E8` | `#207A4C` |
| Pending | `#FFF3CC` | `#8A6500` |
| Failed | `#FFE1E3` | `#A62932` |
| Archived | `#ECE7E4` | `#685952` |
| Reviewed | `#EDE4FF` | `#6941A5` |

## 4.4 Aturan penggunaan warna

- Oranye hanya untuk aksi utama, item aktif, dan highlight.
- Merah hanya untuk aksi destruktif atau error.
- Kuning hanya untuk edit, peringatan ringan, atau status pending.
- Hijau hanya untuk publish, aktif, berhasil, dan selesai.
- Jangan memakai warna status sebagai dekorasi tanpa makna.
- Teks utama selalu memiliki kontras tinggi.
- Jangan menggunakan teks oranye muda di atas putih.
- Maksimal tiga warna aksi terlihat bersamaan dalam satu area.

---

# 5. Typography

Gunakan font yang sama atau paling dekat dengan Website EMI.

## 5.1 Font

Prioritas:

1. font brand Website EMI bila sudah tersedia dan legal digunakan;
2. `Nunito Sans`;
3. `Poppins`;
4. fallback sistem.

Untuk keterbacaan Mobile, hindari font dekoratif pada paragraf panjang.

## 5.2 Skala teks

| Token | Ukuran | Weight | Penggunaan |
|---|---:|---:|---|
| `displaySmall` | 30 | 700 | Judul dashboard utama |
| `headlineLarge` | 26 | 700 | Judul halaman |
| `headlineMedium` | 22 | 700 | Judul bagian |
| `titleLarge` | 18 | 700 | Judul kartu/detail |
| `titleMedium` | 16 | 600 | Subjudul dan item list |
| `bodyLarge` | 16 | 400 | Isi utama |
| `bodyMedium` | 14 | 400 | Deskripsi |
| `labelLarge` | 14 | 700 | Tombol |
| `labelMedium` | 12 | 600 | Badge dan metadata |
| `caption` | 12 | 400 | Bantuan kecil |

## 5.3 Aturan teks

- Judul halaman maksimal dua baris.
- Isi paragraf maksimal 70 karakter per baris pada tablet.
- Gunakan sentence case, bukan semua huruf kapital.
- Hindari istilah teknis seperti:
  - sinkronisasi;
  - integrasi;
  - konfigurasi;
  - payload;
  - request;
  - UUID.
- Gunakan istilah ramah:
  - “Muat ulang”;
  - “Coba lagi”;
  - “Belum tersedia”;
  - “Data belum ditemukan”;
  - “Simpan perubahan”.

---

# 6. Spacing, Radius, Border, dan Shadow

## 6.1 Spacing

Gunakan kelipatan 4.

| Token | Nilai |
|---|---:|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 24 |
| `xxl` | 32 |

Aturan umum:

- padding horizontal screen: `16`;
- tablet: `24`;
- jarak antarbagian: `24`;
- jarak antarfield: `16`;
- jarak ikon dan teks: `10–12`;
- jarak antaritem list: `12`.

## 6.2 Radius

| Elemen | Radius |
|---|---:|
| Kartu utama | 14 |
| Tombol | 12 |
| Input | 12 |
| Dialog | 16 |
| Badge/chip | 999 |
| Icon container | 12 |

## 6.3 Border

| Kondisi | Ketebalan |
|---|---:|
| Border utama | 1.5 px |
| Fokus input | 2 px |
| Divider | 1 px |
| Komponen kecil | 1–1.5 px |

Jangan memakai border 3–4 px pada seluruh kartu.

## 6.4 Shadow

Neobrutalism EMI menggunakan shadow pendek:

- offset: `(3, 4)`;
- blur: `0`;
- warna: `EmiColors.ink`;
- opacity: `1`.

Gunakan shadow hanya untuk:

- kartu hero;
- tombol utama tertentu;
- drawer utama;
- dialog penting;
- kartu aktif.

Jangan gunakan shadow pada:

- setiap field;
- setiap row;
- badge;
- item di dalam kartu;
- divider;
- kartu bertumpuk.

---

# 7. Iconography

## 7.1 Set ikon canonical

Gunakan keluarga ikon yang sama dengan Website EMI.

Rekomendasi:

- Web: Lucide Icons.
- Mobile: `lucide_icons_flutter` atau paket Lucide Flutter yang stabil.
- Bila paket Lucide sudah ada, jangan mencampurnya dengan Material Icons kecuali ikon tidak tersedia.

## 7.2 Ukuran ikon

| Konteks | Ukuran |
|---|---:|
| Bottom navigation | 24 |
| Drawer/sidebar | 22–24 |
| Tombol dengan teks | 20 |
| Icon-only button | 22 |
| Empty state | 40–48 |
| Dashboard metric | 24–28 |

## 7.3 Mapping ikon

| Fitur | Ikon |
|---|---|
| Beranda | `LayoutDashboard` |
| Pengguna | `Users` |
| Sekolah | `School` |
| Kelas | `Presentation` atau `UsersRound` |
| Kamus | `BookOpen` |
| Basis AI | `BrainCircuit` |
| Modul | `BookMarked` |
| Materi | `FileText` |
| Kuis | `ClipboardList` |
| Speaking | `Mic` |
| Budaya | `Globe2` |
| Progress | `TrendingUp` |
| Pengaturan | `Settings` |
| Profil | `UserRound` |
| Tambah | `Plus` |
| Edit | `Pencil` |
| Hapus | `Trash2` |
| Arsip | `Archive` |
| Publish | `Send` atau `UploadCloud` |
| Cari | `Search` |
| Filter | `SlidersHorizontal` |
| Refresh | `RefreshCw` |
| Download | `Download` |
| Upload | `Upload` |
| Putar audio | `Play` |
| Jeda | `Pause` |
| Buka tautan | `ExternalLink` |
| Kembali | `ArrowLeft` |
| Selanjutnya | `ChevronRight` |
| Sebelumnya | `ChevronLeft` |

## 7.4 Aturan ikon

- Ikon harus memiliki makna jelas.
- Icon-only wajib memiliki tooltip/semantics.
- Jangan menggunakan emoji sebagai ikon menu.
- Jangan memakai ikon berbeda untuk aksi yang sama.
- Ikon destruktif berwarna merah.
- Ikon aktif berwarna oranye.
- Ikon nonaktif menggunakan warna muted.

---

# 8. Struktur Layout Mobile

## 8.1 Pola layout utama: Task-First Stacked Layout

Struktur utama Mobile EMI menggunakan **Task-First Stacked Layout**, bukan Bento Layout penuh.

Prinsipnya:

- konten disusun vertikal berdasarkan prioritas tugas;
- pengguna langsung memahami hal yang perlu dilakukan;
- satu layar memiliki satu fokus utama;
- informasi sekunder diletakkan setelah tugas utama;
- grid hanya dipakai untuk ringkasan pendek;
- halaman tetap nyaman digunakan dengan satu tangan.

Bento Layout dari Website tetap menjadi acuan visual, tetapi penggunaannya di Mobile dibatasi.

### Bento yang diperbolehkan di Mobile

Bento hanya digunakan untuk:

- ringkasan 2 × 2;
- metric card pendek;
- quick action maksimal empat item;
- dashboard tablet;
- section yang seluruh itemnya memiliki bobot setara.

Bento tidak digunakan untuk:

- seluruh isi dashboard;
- form;
- daftar data panjang;
- detail dengan banyak metadata;
- aksi CRUD;
- halaman Kuis;
- halaman Speaking;
- laporan panjang;
- layar phone dengan banyak kartu berbeda ukuran.

> Mobile EMI mempertahankan karakter visual Bento dari Web melalui kartu, warna, ikon, dan hierarki, tetapi struktur utamanya tetap vertikal dan task-first.

## 8.2 Hierarki konten

Setiap screen mengikuti urutan prioritas:

1. **Context** — pengguna sedang berada di mana.
2. **Primary task** — hal utama yang perlu dilakukan.
3. **Status** — kondisi data atau progress saat ini.
4. **Supporting content** — daftar, informasi, atau aktivitas.
5. **Secondary action** — filter, arsip, edit, atau menu tambahan.

Jangan meletakkan semua informasi dengan bobot visual yang sama.

## 8.3 Pola dashboard canonical

Urutan dashboard Mobile:

```text
App Bar
Sapaan dan konteks role
Primary Action Card
Ringkasan mini 2 × 2
Tugas penting / perlu perhatian
Akses cepat
Aktivitas atau konten terbaru
```

### Primary Action Card

Satu kartu utama menampilkan tindakan terpenting.

Contoh:

- Siswa: `Lanjutkan belajar`
- Guru: `Buka kelas terakhir`
- Admin: `Tinjau persetujuan baru`

Aturan:

- hanya satu primary card;
- satu tombol utama;
- boleh memakai border dan shadow neobrutalism;
- tidak berisi banyak kartu kecil;
- teks pendek dan langsung.

### Ringkasan mini 2 × 2

Gunakan untuk metrik singkat.

Contoh Siswa:

- Modul selesai;
- Kuis aktif;
- Nilai terakhir;
- Speaking terbaru.

Contoh Guru:

- Kelas aktif;
- Siswa;
- Kuis menunggu;
- Speaking perlu dinilai.

Contoh Admin:

- Persetujuan;
- Pengguna aktif;
- Kelas;
- Sumber AI.

Aturan:

- maksimal dua kolom pada phone;
- satu ikon;
- satu label;
- satu nilai;
- helper text maksimal satu baris;
- `Belum tersedia` untuk data null;
- jangan memakai `0` palsu.

### Tugas penting

Gunakan list vertikal, bukan kartu Bento besar.

Contoh:

```text
[Ikon] Kuis Kosakata Dasar
       Berakhir besok
       [Kerjakan]

[Ikon] Modul Pengenalan
       2 dari 5 materi selesai
       [Lanjutkan]
```

Satu item hanya memiliki:

- ikon;
- judul;
- satu deskripsi;
- status;
- satu aksi utama.

### Akses cepat

Gunakan salah satu:

- grid 2 × 2;
- baris ikon sederhana;
- horizontal list pendek untuk maksimal empat item.

Jangan menampilkan lima kartu tinggi seperti dashboard Web.

## 8.4 Pola halaman daftar

Struktur:

```text
App Bar
Judul dan deskripsi
Search
Filter dan Sort
Tombol Tambah
List vertikal
Pagination
```

Aturan:

- search selalu berada di lokasi yang konsisten;
- filter membuka bottom sheet pada phone;
- seluruh kartu dapat ditekan jika membuka detail;
- aksi sekunder masuk menu tiga titik;
- list lebih diutamakan daripada grid untuk data administratif;
- grid hanya untuk konten visual seperti Budaya.

## 8.5 Pola halaman detail

Struktur:

```text
App Bar kembali
Judul dan badge status
Ringkasan utama
Informasi inti
Media
Progress / aktivitas
Aksi utama
Menu aksi tambahan
```

Aturan:

- tidak semua section dibungkus kartu;
- gunakan section title dan divider;
- label berada di atas nilai pada phone;
- hindari row label/value dengan lebar tetap;
- aksi destruktif ditempatkan terpisah.

## 8.6 Pola halaman form

Struktur:

```text
App Bar kembali
Judul
Deskripsi singkat
Kelompok field
Upload / preview
Sticky Action Bar
```

Aturan:

- satu kolom pada phone;
- dua kolom hanya untuk tablet dan field pendek;
- tombol Simpan selalu mudah dijangkau;
- Hapus dan Arsip tidak disandingkan langsung dengan Simpan;
- keyboard tidak boleh menutup aksi utama;
- field panjang menggunakan wrap;
- dropdown tidak boleh overflow.

## 8.7 Pola halaman laporan

Struktur:

```text
App Bar
Judul
Filter
Summary
Chart / metric
List detail
Export
Pagination
```

Aturan:

- summary boleh memakai mini Bento 2 × 2;
- chart tidak boleh menjadi satu-satunya cara membaca data;
- list detail tetap vertikal;
- filter kompleks menggunakan bottom sheet;
- export diletakkan sebagai secondary action;
- data null tampil `Belum tersedia`.

## 8.8 Pola halaman transaksi Kuis

Struktur:

```text
App Bar minimal
Progress soal
Timer
Pertanyaan
Media soal
Jawaban
Navigasi Sebelumnya / Berikutnya
Submit
```

Aturan:

- minimalkan distraksi;
- drawer dan bottom navigation dapat disembunyikan saat attempt;
- timer selalu terlihat tetapi tidak mendominasi;
- jawaban memiliki touch target besar;
- submit memerlukan konfirmasi;
- status simpan jawaban terlihat;
- jangan gunakan Bento Layout.

## 8.9 Pola halaman Speaking

Struktur:

```text
App Bar
Latihan dan teks referensi
Audio referensi
Status alat / mikrofon
Primary record action
Preview
Status analisis
Hasil dan feedback
```

Aturan:

- satu primary action: rekam atau hubungkan alat;
- status izin/hardware terlihat jelas;
- progress analisis tampil;
- hasil ditampilkan vertikal;
- audio control tidak dibungkus banyak kotak;
- jangan gunakan Bento Layout untuk proses rekam.

## 8.10 Aturan kepadatan layar

Phone:

- maksimal satu primary card;
- maksimal empat metric card;
- maksimal satu baris quick action;
- maksimal dua aksi langsung per item;
- aksi tambahan menggunakan menu;
- maksimal dua kolom;
- tidak ada horizontal scroll untuk fungsi utama.

Tablet:

- primary dan summary dapat berdampingan;
- grid maksimum tiga atau empat kolom;
- detail panel diperbolehkan;
- tetap mempertahankan urutan baca vertikal.

## 8.11 Progressive disclosure

Informasi ditampilkan bertahap.

Tampilkan langsung:

- judul;
- status;
- tugas utama;
- data yang paling sering digunakan.

Sembunyikan di menu atau section lanjutan:

- metadata teknis;
- aksi destruktif;
- riwayat panjang;
- filter lanjutan;
- informasi jarang dipakai.

Tujuannya agar pengguna tidak merasa seluruh sistem tampil sekaligus.

## 8.12 Konsistensi lintas role

Pola layout harus tetap dikenali pada tiga role.

| Elemen | Admin | Guru | Siswa |
|---|---|---|---|
| Navigasi utama | Drawer | Drawer | Bottom navigation |
| Fokus dashboard | Antrean tindakan | Kelas dan penilaian | Tugas belajar |
| List utama | Data administratif | Kelas/konten | Materi/tugas |
| Primary action | Tinjau/Tambah | Buka kelas/Tambah | Lanjutkan/Kerjakan |
| Ringkasan | Sistem | Kelas | Progress pribadi |
| Kepadatan | Tinggi | Sedang | Rendah |

---

## 8.1 Breakpoint

| Lebar | Mode |
|---|---|
| `< 600 px` | Phone |
| `600–899 px` | Tablet compact |
| `>= 900 px` | Tablet/large layout |

## 8.2 Phone

Gunakan:

- AppBar ringkas;
- konten satu kolom;
- drawer untuk banyak menu;
- bottom navigation untuk menu utama Siswa;
- tombol aksi utama sticky di bawah bila form panjang;
- list card vertikal.

Jangan gunakan:

- sidebar permanen;
- tabel horizontal besar;
- grid lebih dari dua kolom;
- fixed width;
- scroll horizontal untuk data utama.

## 8.3 Tablet

Gunakan:

- navigation rail atau drawer;
- grid dua kolom;
- detail panel bila cukup ruang;
- maksimum lebar konten sekitar 960 px;
- tetap menjaga urutan baca vertikal.

---

# 9. App Shell dan Navigasi

## 9.1 AppBar

Tinggi: `56–64 px`.

Isi:

- tombol menu/kembali;
- logo kecil EMI;
- judul halaman;
- aksi utama opsional;
- avatar/profil opsional.

Aturan:

- jangan menampilkan header terlalu tinggi;
- judul maksimal satu baris;
- tombol Keluar tidak selalu ditampilkan di AppBar; letakkan di Drawer/Profil;
- hindari terlalu banyak icon action.

## 9.2 Drawer / Sidebar Mobile

Admin dan Guru menggunakan Drawer.

Struktur:

1. logo EMI;
2. nama role:
   - Ruang Admin;
   - Ruang Guru;
3. profil ringkas;
4. daftar menu;
5. divider;
6. Profil;
7. Keluar di bagian bawah.

Ukuran:

- lebar: `84%` layar;
- maksimum: `320 px`.

Item menu:

- tinggi minimum `52 px`;
- ikon `22–24 px`;
- padding horizontal `16 px`;
- radius `12 px`.

State aktif:

- background `primarySoft`;
- ikon dan teks `primary`;
- indikator kecil di sisi kiri;
- tanpa shadow tebal.

State biasa:

- background transparan;
- teks `ink`;
- tidak perlu border.

> Jangan membungkus setiap menu dengan kotak. Hanya item aktif yang diberi latar.

## 9.3 Bottom Navigation Siswa

Gunakan maksimal lima item:

1. Beranda;
2. Modul;
3. Kuis;
4. Speaking;
5. Lainnya.

Menu Lainnya membuka:

- Kamus;
- Budaya;
- Chatbot AI;
- Progress;
- Profil.

Aturan:

- tinggi `64–72 px`;
- label selalu terlihat;
- ikon aktif oranye;
- item aktif boleh memakai background lembut;
- jangan membuat bottom navigation berbeda di setiap detail screen;
- satu helper mapping route canonical.

## 9.4 Back navigation

- Detail dan form selalu memiliki tombol kembali.
- Setelah simpan, kembali ke detail atau daftar yang benar.
- Jangan mengandalkan `pop` bila route dibuka langsung tanpa stack.
- Deep-link tetap harus aman.

---

# 10. Dashboard

## 10.1 Struktur

Urutan dashboard:

1. salam dan nama pengguna;
2. ringkasan utama;
3. aksi cepat;
4. progress;
5. konten terbaru atau tugas;
6. status penting.

## 10.2 Hero card

Hero card boleh memiliki:

- border utama;
- shadow neobrutalism;
- satu tombol utama;
- satu visual/metric.

Jangan menaruh banyak kartu kecil di dalam hero card dengan border tebal.

## 10.3 Metric card

Phone:

- dua kolom;
- tinggi konsisten;
- ikon;
- label;
- nilai;
- helper text opsional.

Tablet:

- tiga atau empat kolom.

Metric yang tidak tersedia:

- tampilkan `Belum tersedia`;
- jangan tampilkan `0` palsu.

## 10.4 Quick action

Quick action menggunakan:

- icon container lembut;
- judul singkat;
- deskripsi satu baris;
- seluruh kartu dapat ditekan;
- tidak perlu shadow besar untuk semua item.

---

# 11. Kartu dan List

## 11.1 Kartu standar

Kartu standar:

- background putih;
- border `1.5 px`;
- radius `14`;
- padding `16`;
- shadow hanya jika kartu utama.

Kartu di dalam kartu:

- hindari border kedua;
- gunakan background `surfaceMuted`;
- atau divider.

## 11.2 List item

Struktur:

- ikon/avatar;
- judul;
- subtitle;
- badge/status;
- chevron atau menu aksi.

Aturan:

- seluruh item dapat ditekan bila membuka detail;
- tinggi minimum `64 px`;
- teks utama maksimal dua baris;
- metadata menggunakan teks secondary;
- aksi tidak boleh menumpuk.

## 11.3 Aksi item

Phone:

- aksi utama terlihat;
- aksi tambahan dalam menu tiga titik;
- hindari empat tombol sejajar dalam satu row.

Contoh:

- `Lihat` atau tap kartu;
- menu:
  - Edit;
  - Publish;
  - Arsip;
  - Hapus.

Tablet dapat menampilkan dua hingga tiga tombol langsung.

---

# 12. Tombol

## 12.1 Ukuran

| Jenis | Tinggi minimum |
|---|---:|
| Tombol utama | 48 |
| Tombol kecil | 40 |
| Icon-only | 44 × 44 |
| Floating action | 56 × 56 |

## 12.2 Jenis tombol

### Primary

- background oranye;
- border gelap;
- teks gelap atau putih berdasarkan kontras;
- shadow pendek;
- digunakan untuk satu aksi utama.

Contoh:

- Simpan;
- Tambah;
- Mulai;
- Lanjutkan.

### Secondary

- background putih;
- border gelap;
- teks gelap;
- tanpa shadow atau shadow sangat ringan.

Contoh:

- Kembali;
- Batal;
- Lihat Detail.

### Edit

- background kuning;
- border gelap;
- teks gelap;
- ikon Pencil.

### Archive

- background putih;
- border gelap;
- teks gelap;
- ikon Archive.

### Delete

- background merah;
- border merah gelap;
- teks putih;
- ikon Trash2.

### Publish

- background hijau;
- teks putih;
- ikon Send/UploadCloud.

### Disabled

- background abu;
- border abu;
- teks muted;
- tidak memiliki shadow;
- cursor/semantics disabled.

## 12.3 Aturan tombol

- Satu primary CTA per screen.
- Tombol destruktif tidak ditempatkan berdekatan dengan Simpan tanpa jarak.
- Hapus selalu memakai dialog konfirmasi.
- Arsip tidak perlu merah.
- Icon-only harus minimum 44 px.
- Jangan membuat tombol memenuhi seluruh lebar kecuali aksi utama form.
- Tombol loading mempertahankan lebar agar layout tidak bergeser.
- Tombol loading tidak dapat ditekan dua kali.

---

# 13. Form

## 13.1 Struktur form

Urutan:

1. judul form;
2. deskripsi singkat;
3. kelompok field;
4. bantuan/preview;
5. area aksi.

Phone:

- satu kolom;
- field penuh;
- tombol Simpan sticky di bawah jika form panjang.

Tablet:

- maksimal dua kolom untuk field pendek;
- field deskripsi/editor tetap penuh.

## 13.2 Input

Standar:

- tinggi minimum `52 px`;
- border `1.5 px`;
- radius `12`;
- background putih;
- label selalu terlihat;
- hint hanya sebagai contoh;
- error di bawah field;
- focus border oranye `2 px`.

Jangan:

- menggunakan hint sebagai pengganti label;
- memakai input ISO 8601 mentah;
- menampilkan ID internal;
- menyimpan field dengan tombol terlalu jauh tanpa sticky action.

## 13.3 Dropdown

- `isExpanded: true`;
- teks panjang ellipsis;
- value tidak boleh overflow;
- loading kategori terlihat;
- error kategori ramah;
- gunakan bottom sheet bila pilihan sangat banyak.

## 13.4 Date dan time

- gunakan date picker;
- gunakan time picker;
- tampilkan format Indonesia;
- konversi ke UTC/API hanya di data layer;
- validasi tanggal selesai setelah tanggal mulai.

## 13.5 Upload file

Tampilkan:

- nama file;
- tipe;
- ukuran;
- progress;
- tombol ganti;
- tombol hapus;
- error mudah dipahami.

Jangan tampilkan:

- raw path;
- UUID;
- media ID;
- storage path.

## 13.6 Form action area

Urutan phone:

1. Simpan;
2. Batal/Kembali;
3. Archive/Delete dipisahkan di bagian bawah.

Area sticky:

- background surface;
- border top lembut;
- safe area;
- padding `12–16`.

---

# 14. Detail Screen

Struktur:

1. AppBar + kembali;
2. judul dan status;
3. ringkasan;
4. section data;
5. media;
6. aktivitas/progress;
7. aksi.

Gunakan section title tanpa selalu membungkus section dalam kartu.

Metadata:

- label secondary;
- nilai utama;
- gunakan dua kolom hanya jika cukup lebar.

Phone:

- label di atas nilai;
- hindari row label/value dengan lebar tetap;
- teks panjang harus wrap.

---

# 15. Status, Badge, dan Chip

Badge:

- radius pill;
- padding horizontal `10`;
- padding vertical `5`;
- ikon opsional `14`;
- font `12–13`.

Status harus berasal dari backend canonical.

Contoh label:

- Draf;
- Dipublikasikan;
- Diproses;
- Selesai;
- Gagal;
- Diarsipkan;
- Sudah dinilai.

Jangan menampilkan status internal bahasa Inggris kepada pengguna bila tersedia terjemahan.

---

# 16. Dialog, Bottom Sheet, dan Snackbar

## 16.1 Dialog

Gunakan dialog untuk:

- hapus;
- keluar;
- perubahan yang tidak dapat dibatalkan;
- konfirmasi publish penting.

Struktur:

- ikon;
- judul;
- penjelasan;
- tombol Batal;
- tombol aksi.

Delete:

- tombol konfirmasi merah;
- tombol Batal putih.

## 16.2 Bottom sheet

Gunakan untuk:

- filter;
- pilihan aksi;
- pilihan kategori banyak;
- media action;
- menu Lainnya.

## 16.3 Snackbar

Gunakan untuk:

- sukses singkat;
- error ringan;
- status aksi.

Aturan:

- durasi cukup dibaca;
- memiliki action Retry bila relevan;
- jangan menampilkan exception teknis;
- satu snackbar pada satu waktu.

---

# 17. Loading, Empty, Error, dan Offline State

## 17.1 Loading

Gunakan:

- skeleton untuk list/dashboard;
- spinner kecil untuk tombol;
- progress bar untuk upload.

Jangan:

- menutup seluruh layar dengan spinner untuk perubahan kecil;
- membiarkan tombol tetap aktif;
- menampilkan loading tanpa batas.

## 17.2 Empty state

Struktur:

- ikon;
- judul;
- deskripsi;
- CTA jika ada.

Contoh:

- “Modul belum tersedia”
- “Belum ada kuis untuk kelas ini”
- “Data belum ditemukan”

Jangan memakai dashed border tebal besar untuk semua empty state. Gunakan background lembut dan border ringan.

## 17.3 Error state

Tampilkan:

- pesan Indonesia;
- penyebab yang dapat dipahami;
- tombol Coba Lagi;
- bantuan bila diperlukan.

Jangan tampilkan:

- stack trace;
- status code mentah;
- UUID;
- response JSON;
- storage path.

## 17.4 Offline

Tampilkan:

- banner offline;
- data cache jika tersedia;
- tombol Muat Ulang;
- jangan menyebut server internal.

---

# 18. Media

## 18.1 Image

- gunakan aspect ratio;
- placeholder saat loading;
- fallback bila gagal;
- tap untuk preview bila relevan.

## 18.2 Audio

- play/pause;
- progress;
- durasi;
- loading;
- error;
- hanya satu audio bermain pada satu waktu.

## 18.3 Video

- jangan autoplay;
- tampilkan thumbnail;
- tombol play/open;
- gunakan URL/media canonical;
- fallback ke buka eksternal bila player internal tidak tersedia.

## 18.4 PDF/Dokumen

- nama file;
- ukuran;
- tombol Buka;
- tombol Unduh bila tersedia;
- jangan menampilkan URL mentah sebagai satu-satunya aksi.

## 18.5 External link

- label “Buka Tautan”;
- ikon ExternalLink;
- validasi http/https;
- konfirmasi bila menuju aplikasi eksternal diperlukan.

---

# 19. Search, Filter, dan Pagination

## 19.1 Search

- search field di bagian atas list;
- ikon Search;
- clear button;
- debounce;
- reset ke page pertama;
- error tidak berubah menjadi empty state.

## 19.2 Filter

Phone:

- tombol Filter membuka bottom sheet;
- tampilkan jumlah filter aktif;
- tombol Terapkan;
- tombol Reset.

Jangan menampilkan banyak dropdown horizontal.

## 19.3 Pagination

Phone:

- tombol Sebelumnya dan Berikutnya;
- label `Halaman X dari Y`;
- tombol disabled pada boundary;
- loading tidak menghilangkan seluruh list bila masih ada data lama.

Tablet boleh memakai nomor halaman.

---

# 20. Role-Specific Layout

## 20.0 Prinsip layout LMS per role

Setiap role memiliki pertanyaan utama yang berbeda.

- **Siswa:** Apa yang harus saya kerjakan sekarang?
- **Guru:** Kelas atau siswa mana yang membutuhkan perhatian?
- **Admin:** Tindakan administratif apa yang harus diselesaikan?

Layout harus menjawab pertanyaan tersebut pada bagian atas screen.


## 20.1 Admin

### Pola utama: Action Queue Layout

Urutan dashboard:

1. persetujuan yang menunggu;
2. error/status sistem yang membutuhkan perhatian;
3. ringkasan pengguna, sekolah, dan kelas;
4. quick action terbatas;
5. aktivitas terbaru.

Admin boleh memiliki kepadatan lebih tinggi daripada role lain, tetapi tetap memakai section dan list vertikal.

Karakter:

- padat tetapi tetap rapi;
- fokus pada data dan aksi;
- drawer;
- filter dan search mudah ditemukan;
- aksi destruktif terlindungi.

Dashboard Admin:

- ringkasan metrik;
- persetujuan terbaru;
- aktivitas;
- quick action terbatas.

## 20.2 Guru

### Pola utama: Class-Centered Layout

Urutan dashboard:

1. kelas yang diajar;
2. tugas/attempt yang perlu dinilai;
3. materi dan kuis terbaru;
4. progress siswa;
5. Speaking yang menunggu review.

Detail kelas menggunakan segmented control atau tab yang konsisten:

- Siswa;
- Modul;
- Kuis;
- Budaya;
- Progress.

Context kelas harus tetap terlihat ketika Guru berpindah section.

Karakter:

- fokus pada kelas dan siswa;
- akses cepat ke modul, kuis, budaya, speaking, dan progress;
- drawer;
- class context selalu terlihat.

Screen detail kelas:

- header kelas;
- ringkasan;
- tab/section:
  - siswa;
  - modul;
  - kuis;
  - budaya;
  - progress.

## 20.3 Siswa

### Pola utama: Learning Journey Layout

Urutan dashboard:

1. sapaan;
2. lanjutkan materi terakhir;
3. kuis aktif atau mendekati tenggat;
4. progress pribadi;
5. akses cepat;
6. aktivitas terbaru.

Prioritas visual:

- satu CTA utama;
- tugas yang perlu dilakukan;
- progress mudah dipahami;
- sedikit metrik administratif.

Siswa tidak perlu melihat seluruh informasi sistem sekaligus.

Karakter:

- paling sederhana;
- teks ramah;
- bottom navigation;
- CTA jelas;
- sedikit aksi per screen;
- progress mudah dipahami.

Dashboard Siswa:

- salam;
- lanjutkan belajar;
- tugas aktif;
- quick action;
- progress;
- jangan terlalu banyak metrik administratif.

---

# 21. Responsiveness dan Accessibility

## 21.1 Touch target

- minimum `44 × 44 px`;
- jarak antar-icon button minimum `8 px`;
- jangan menaruh tombol kecil berdempetan.

## 21.2 Text scale

- layout harus aman sampai text scale `1.3`;
- teks tidak boleh terpotong;
- tombol boleh bertambah tinggi.

## 21.3 Semantics

Wajib untuk:

- icon-only button;
- audio;
- upload;
- delete;
- bottom navigation;
- status.

## 21.4 Kontras

- teks normal minimal kontras WCAG AA;
- jangan memakai abu muda untuk teks penting;
- status tidak hanya dibedakan dengan warna; tambahkan label/ikon.

---

# 22. Komponen Reusable Wajib

Komponen berikut harus reusable dan tidak dibuat ulang per halaman:

- `EmiAppBar`
- `EmiDrawer`
- `EmiBottomNavigation`
- `EmiPageHeader`
- `EmiCard`
- `EmiMetricCard`
- `EmiListItem`
- `EmiEmptyState`
- `EmiErrorState`
- `EmiLoadingState`
- `EmiPrimaryButton`
- `EmiSecondaryButton`
- `EmiEditButton`
- `EmiArchiveButton`
- `EmiDeleteButton`
- `EmiPublishButton`
- `EmiIconButton`
- `EmiTextField`
- `EmiDropdownField`
- `EmiDateTimeField`
- `EmiSearchField`
- `EmiFilterSheet`
- `EmiStatusBadge`
- `EmiMediaPreview`
- `EmiStickyActionBar`
- `EmiConfirmDialog`

Setiap komponen harus menggunakan token, bukan hardcoded style.

---

# 23. Token Flutter yang Direkomendasikan

Contoh struktur:

```dart
abstract final class EmiColors {
  static const background = Color(0xFFFFF8F2);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFFF8738);
  static const primaryPressed = Color(0xFFE96F21);
  static const primarySoft = Color(0xFFFFF0E4);

  static const ink = Color(0xFF2B211D);
  static const textSecondary = Color(0xFF6F5548);
  static const textMuted = Color(0xFF927B70);
  static const divider = Color(0xFFD8C8BE);
  static const surfaceMuted = Color(0xFFF7EEE8);

  static const edit = Color(0xFFFFD34E);
  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF2F9E68);
  static const info = Color(0xFF3B82F6);
  static const disabled = Color(0xFFE7E0DC);
}

abstract final class EmiSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class EmiRadii {
  static const field = 12.0;
  static const button = 12.0;
  static const card = 14.0;
  static const dialog = 16.0;
}
```

Implementasi final harus mengikuti token aktual repository bila nama class berbeda.

---

# 24. Aturan Mengurangi “Kotak Tebal”

Masalah yang harus dihindari:

- kartu utama memiliki border dan shadow;
- di dalamnya terdapat kartu lain dengan border dan shadow;
- setiap row juga memiliki border;
- tombol dan ikon memiliki kotak tambahan;
- hasilnya terasa penuh dan berat.

Solusi:

1. Pilih satu container utama.
2. Gunakan divider untuk isi.
3. Gunakan background lembut untuk kelompok sekunder.
4. Hilangkan shadow pada child card.
5. Gunakan ruang kosong `16–24 px`.
6. Gunakan border hanya pada batas kelompok.
7. Gunakan icon container tanpa border bila kartu sudah memiliki border.
8. Empty state memakai border ringan, bukan kotak putus-putus besar.

Aturan praktis:

> Dalam satu area visual, maksimal satu border tegas dan satu shadow.

---

# 25. Pola Halaman Canonical

## 25.1 Halaman list

1. AppBar;
2. header judul dan deskripsi;
3. search/filter;
4. CTA Tambah;
5. list;
6. pagination;
7. empty/error/loading.

## 25.2 Halaman detail

1. AppBar kembali;
2. judul + status;
3. ringkasan;
4. informasi;
5. media/progress;
6. aksi utama;
7. menu aksi tambahan.

## 25.3 Halaman form

1. AppBar kembali;
2. judul;
3. deskripsi;
4. field;
5. preview;
6. sticky action bar;
7. destructive action terpisah.

## 25.4 Halaman dashboard

1. salam;
2. hero;
3. ringkasan;
4. quick actions;
5. aktivitas/progress;
6. informasi terbaru.

## 25.5 Halaman report

1. header;
2. filter;
3. summary;
4. chart/metric;
5. list detail;
6. export;
7. pagination.

---

# 26. Copywriting

Gunakan:

- “Tambah Modul”
- “Simpan Perubahan”
- “Hapus Data”
- “Arsipkan”
- “Publikasikan”
- “Coba Lagi”
- “Belum tersedia”
- “Tidak ada data”
- “Pilih kelas”
- “Buka tautan”
- “Putar audio”

Hindari:

- “Submit”
- “Retry”
- “Delete”
- “Archive”
- “Processing” pada UI pengguna
- “Integrasi berhasil”
- “Sinkronisasi”
- “Konfigurasi”
- “Payload gagal”

Pengecualian istilah teknis hanya untuk log developer, bukan UI.

---

# 26A. Aturan agar LMS Mobile tidak membingungkan

1. Satu screen memiliki satu primary action.
2. Urutan konten mengikuti kebutuhan pengguna, bukan struktur database.
3. Navigasi utama tidak berubah antara list dan detail.
4. Posisi Search, Filter, Tambah, dan Pagination konsisten.
5. Gunakan label tindakan:
   - `Tambah Modul`;
   - `Simpan`;
   - `Lanjutkan`;
   - `Kerjakan`;
   - `Buka Hasil`.
6. Jangan memakai label abstrak seperti `Proses`, `Kelola`, atau `Aksi`.
7. Seluruh kartu yang membuka detail harus dapat ditekan.
8. Aksi tambahan menggunakan menu tiga titik.
9. Jangan menampilkan lebih dari dua tombol langsung pada satu item.
10. Gunakan breadcrumb ringan berupa judul/context, bukan breadcrumb desktop panjang.
11. Loading, empty, error, dan retry memiliki pola sama di seluruh role.
12. Jangan menampilkan data yang belum tersedia sebagai angka nol.
13. Gunakan progressive disclosure untuk metadata dan aksi jarang dipakai.
14. Jangan mengubah posisi navigasi berdasarkan halaman.
15. Jangan menggunakan horizontal scroll untuk fungsi utama.
16. Jangan memakai Bento penuh pada phone.
17. Maksimal dua kolom pada phone.
18. Gunakan sticky action untuk form panjang.
19. Gunakan bottom sheet untuk filter kompleks.
20. Gunakan bahasa yang bisa dipahami siswa tanpa penjelasan teknis.

---

# 27. Checklist Review Setiap Screen

## Layout

- [ ] Tidak ada horizontal overflow.
- [ ] Tidak ada fixed width yang merusak layar kecil.
- [ ] Padding screen konsisten.
- [ ] Satu fokus utama terlihat.
- [ ] Tidak ada kotak di dalam kotak secara berlebihan.
- [ ] Keyboard tidak menutup tombol utama.

## Navigasi

- [ ] AppBar sesuai role.
- [ ] Drawer/bottom nav konsisten.
- [ ] Back navigation benar.
- [ ] Selected state benar.
- [ ] Tidak ada tombol buntu.

## Tombol

- [ ] Primary oranye.
- [ ] Edit kuning.
- [ ] Arsip putih.
- [ ] Hapus merah.
- [ ] Publish hijau.
- [ ] Disabled jelas.
- [ ] Loading mencegah double tap.

## Form

- [ ] Label selalu terlihat.
- [ ] Error ramah.
- [ ] Dropdown tidak overflow.
- [ ] Date/time picker digunakan.
- [ ] Upload tidak menampilkan raw path.
- [ ] Simpan mudah dijangkau.

## State

- [ ] Loading tersedia.
- [ ] Empty tersedia.
- [ ] Error tersedia.
- [ ] Retry tersedia.
- [ ] Null tidak menjadi angka palsu.
- [ ] Status canonical.

## Accessibility

- [ ] Touch target minimum 44 px.
- [ ] Icon-only memiliki semantics.
- [ ] Kontras teks cukup.
- [ ] Text scale tidak merusak layout.

---

# 28. Urutan Implementasi Desain

Kerjakan setelah fungsi aman.

## Fase 1 — Foundation

1. Tetapkan token warna.
2. Tetapkan typography.
3. Tetapkan spacing/radius/shadow.
4. Tetapkan ikon canonical.
5. Buat komponen reusable.

## Fase 2 — Shell

1. AppBar.
2. Drawer Admin.
3. Drawer Guru.
4. Bottom navigation Siswa.
5. Page header.
6. Loading/error/empty global.

## Fase 3 — Screen prioritas

1. Dashboard tiga role.
2. List utama.
3. Detail.
4. Form.
5. Kuis.
6. Speaking.
7. Progress.

## Fase 4 — Screen pendukung

1. Pengaturan.
2. Profil.
3. Media.
4. Import/export.
5. Dialog dan bottom sheet.

## Fase 5 — QA desain

1. Redmi 9T.
2. Phone kecil 320–360 px.
3. Phone umum 390–430 px.
4. Tablet.
5. Text scale 1.3.
6. Dark mode hanya jika memang masuk scope; jika belum, jangan setengah diterapkan.

---

# 29. Definition of Done Desain

Satu screen dianggap selesai jika:

1. menggunakan token canonical;
2. menggunakan komponen reusable;
3. tidak memiliki style hardcoded yang tidak perlu;
4. konsisten dengan Website EMI;
5. tidak overflow;
6. loading, empty, error, dan retry tersedia;
7. tombol mengikuti warna aksi;
8. form ramah Mobile;
9. tidak menampilkan istilah teknis;
10. tidak ada kotak tebal berlebihan;
11. lulus widget/golden/layout test terkait;
12. lulus manual review pada perangkat nyata.

---

# 30. Kesimpulan

Identitas Mobile EMI harus tetap terasa satu keluarga dengan Website EMI:

- putih sebagai ruang utama;
- oranye sebagai aksi dan identitas;
- tinta gelap sebagai border dan teks;
- neobrutalism ringan sebagai karakter;
- ikon konsisten;
- **Task-First Stacked Layout** sebagai pola utama;
- Bento hanya untuk ringkasan mini;
- layout Mobile sederhana dan vertikal;
- fungsi sama, UX menyesuaikan perangkat.

Prioritas desain bukan membuat semua elemen mencolok. Prioritasnya adalah membuat pengguna memahami:

- sedang berada di halaman apa;
- apa yang dapat dilakukan;
- tombol mana yang utama;
- status data saat ini;
- apa yang harus dilakukan bila terjadi kesalahan.

> Gunakan border dan shadow untuk memberi karakter, bukan untuk membungkus setiap elemen.
