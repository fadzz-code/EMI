# Instruksi Export PDF Buku Panduan EMI

## Export PDF lewat Google Chrome

1. Buka file `Docs/guides/export/buku-panduan-emi.html` di Google Chrome.
2. Tekan `Ctrl + P`.
3. Destination: Save as PDF.
4. Paper size: A4.
5. Margins: Default atau Custom.
6. Scale: 90 sampai 100 persen.
7. Centang Background graphics jika tersedia.
8. Simpan sebagai:

`Buku-Panduan-EMI.pdf`

## Opsi command line Chrome

Jika Google Chrome tersedia di path standar Windows, jalankan:

```powershell
"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless --disable-gpu --print-to-pdf="D:\!Kerjaan\EMI\Docs\guides\export\Buku-Panduan-EMI.pdf" "file:///D:/!Kerjaan/EMI/Docs/guides/export/buku-panduan-emi.html"
```

Jika path Chrome berbeda, sesuaikan lokasi `chrome.exe`.
