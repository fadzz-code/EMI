<?php

namespace Database\Seeders;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class BasisAiDemoSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::query()->where('email', 'admin@emi.test')->first();
        $adminId = $admin?->id;

        foreach ($this->items() as $item) {
            $knowledge = AiKnowledgeItem::withTrashed()->where('title', $item['title'])->first();

            if (! $knowledge) {
                $knowledge = new AiKnowledgeItem;
                $knowledge->id = (string) Str::uuid();
                $knowledge->title = $item['title'];
                $knowledge->created_by = $adminId;
            }

            if ($knowledge->trashed()) {
                $knowledge->restore();
            }

            $knowledge->forceFill([
                'category' => $item['category'],
                'content' => $item['content'],
                'source_type' => 'manual',
                'source_url' => null,
                'status' => 'published',
                'created_by' => $knowledge->created_by ?? $adminId,
                'updated_by' => $adminId,
            ])->save();
        }
    }

    private function items(): array
    {
        $note = 'Konten demo ini perlu disesuaikan dengan referensi resmi sekolah/admin.';

        return [
            [
                'title' => 'Arti Nama Mekongga',
                'category' => 'Bahasa',
                'content' => "Arti nama Mekongga pada konten demo ini dibahas sebagai bahan belajar awal. Admin sekolah perlu mengisi arti resmi, ejaan, dan penjelasan final sesuai referensi yang disetujui.\n\nKata kunci utama untuk pengetahuan ini adalah arti Mekongga, makna nama Mekongga, dan penjelasan nama Mekongga. {$note}",
            ],
            [
                'title' => 'Asal-usul Mekongga',
                'category' => 'Budaya',
                'content' => "Asal-usul Mekongga pada konten demo ini dipakai untuk menunjukkan cara Basis AI menjawab pertanyaan tentang latar belakang Mekongga. Isi final harus berasal dari guru, sekolah, atau narasumber budaya yang resmi.\n\nGunakan item ini untuk pertanyaan asal-usul Mekongga, latar belakang Mekongga, dan awal mula Mekongga. {$note}",
            ],
            [
                'title' => 'Budaya Mekongga',
                'category' => 'Budaya',
                'content' => "Budaya Mekongga dalam demo EMI mencakup contoh topik pembelajaran seperti adat, kebiasaan, cerita, seni, dan dokumentasi lokal yang dapat dimasukkan admin sebagai pengetahuan terverifikasi.\n\nPengetahuan ini membantu siswa bertanya tentang budaya Mekongga secara umum, tetapi detail budaya harus diisi dari sumber resmi. {$note}",
            ],
            [
                'title' => 'Bahasa Mekongga',
                'category' => 'Bahasa',
                'content' => "Bahasa Mekongga adalah fokus pembelajaran dalam aplikasi EMI. Demo ini menempatkan Bahasa Mekongga sebagai materi belajar kosakata, sapaan, contoh kalimat, dan latihan pemahaman.\n\nPertanyaan tentang apa itu Bahasa Mekongga dapat dijawab dari item ini. {$note}",
            ],
            [
                'title' => 'Kosakata Dasar Mekongga',
                'category' => 'Kosakata',
                'content' => "Kosakata dasar Mekongga adalah kumpulan kata awal yang dipakai siswa untuk mengenal istilah sehari-hari. Contoh tema kosakata dasar meliputi sapaan, benda di sekitar, aktivitas harian, guru, siswa, rumah, air, makan, dan sekolah.\n\nGunakan item ini untuk pertanyaan kosakata dasar Mekongga dan contoh kata awal yang perlu dipelajari. {$note}",
            ],
            [
                'title' => 'Cerita Rakyat Mekongga',
                'category' => 'Cerita Rakyat',
                'content' => "Cerita rakyat Mekongga pada Basis AI demo adalah tempat admin menyimpan ringkasan cerita lokal yang sudah diperiksa. Chatbot hanya boleh menjawab dari ringkasan cerita yang ditulis di Konten Pengetahuan.\n\nItem ini cocok untuk pertanyaan cerita rakyat Mekongga, kisah lokal Mekongga, dan bahan bacaan budaya. {$note}",
            ],
            [
                'title' => 'Belajar Bahasa Mekongga',
                'category' => 'Pembelajaran',
                'content' => "Cara belajar kosakata Mekongga dapat dimulai dari membaca kata, memahami arti, melihat contoh kalimat, mendengarkan audio jika tersedia, lalu berlatih memakai kata dalam percakapan sederhana.\n\nUntuk belajar Bahasa Mekongga secara bertahap, siswa dapat mulai dari sapaan, kosakata dasar, materi modul, lalu latihan kuis. {$note}",
            ],
        ];
    }
}
