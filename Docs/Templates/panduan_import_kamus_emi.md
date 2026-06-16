# Panduan Import Kamus EMI

Gunakan file `template_import_kamus_emi.csv` dengan header berikut:

```csv
indonesia,english,mekongga,kategori,contoh_mekongga,contoh_indonesia,audio_filename
```

Ketentuan:

- File CSV wajib UTF-8. UTF-8 BOM boleh digunakan.
- Header harus sama persis dan berurutan.
- Kolom `indonesia`, `english`, `mekongga`, dan `kategori` wajib diisi.
- Kategori harus sudah dibuat dan berstatus aktif.
- `audio_filename` boleh kosong.
- Jika memakai ZIP audio, nilai `audio_filename` harus sama persis dengan nama file MP3/WAV/M4A/OGG/WEBM di ZIP.
- Nama audio di ZIP tidak boleh berada dalam folder dan tidak boleh mengandung path seperti `../`.
- Preview import wajib diperiksa sebelum confirm.
- Data invalid tidak masuk ke kamus final.
