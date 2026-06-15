# EMI Backend Instructions

## Stack

- Laravel 12
- PHP 8.2
- PostgreSQL 16
- Laravel Sanctum
- UUID untuk primary key domain

## Architecture

Route
→ Form Request
→ Controller tipis
→ Service
→ Model
→ API Resource

## Rules

- Gunakan Policy untuk authorization.
- Gunakan transaction untuk proses multi-tabel.
- Gunakan Form Request untuk validasi.
- Jangan menaruh business logic kompleks di controller.
- Jangan percaya user_id, teacher_id, student_id, atau class_id dari frontend.
- Gunakan Bahasa Indonesia untuk pesan API.
- Jangan mengubah schema yang sudah stabil tanpa alasan terbukti.
- Jangan commit .env atau credential.

## Verification

Setelah perubahan backend, jalankan:

php artisan test
vendor/bin/pint
git diff --check