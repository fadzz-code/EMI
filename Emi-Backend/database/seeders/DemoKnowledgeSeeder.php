<?php

namespace Database\Seeders;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoKnowledgeSeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $admin = User::query()->where('email', 'admin.demo@emi.local')->firstOrFail();

        foreach ($this->items() as $item) {
            $this->upsertModel(AiKnowledgeItem::class, ['title' => $item['title']], [
                'category' => $item['category'],
                'content' => $item['content'],
                'source_type' => 'manual',
                'source_url' => null,
                'status' => $item['status'],
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
            ]);
        }
    }

    private function items(): array
    {
        return [
            ['title' => 'Demo: Apa itu bahasa Mekongga?', 'category' => 'Bahasa', 'status' => 'published', 'content' => 'Bahasa Mekongga adalah bahasa daerah masyarakat Mekongga di wilayah Kolaka dan sekitarnya. EMI membantu siswa mengenal kosakata, sapaan, dan konteks budaya secara bertahap. Konten demo ini perlu validasi narasumber.'],
            ['title' => 'Demo: Apa saja budaya Mekongga?', 'category' => 'Budaya', 'status' => 'published', 'content' => 'Budaya Mekongga pada demo EMI mencakup tradisi lisan, nilai kebersamaan, sopan santun, penghormatan kepada orang tua dan guru, serta kegiatan adat masyarakat setempat. Detail budaya perlu validasi narasumber.'],
            ['title' => 'Demo: Contoh sapaan bahasa Mekongga', 'category' => 'Sapaan', 'status' => 'published', 'content' => 'Contoh materi sapaan demo memakai kosakata mombesara untuk latihan menyapa guru dan teman. Kosakata dan kalimat harus divalidasi narasumber sebelum dipakai sebagai materi final.'],
            ['title' => 'Demo: Nilai sopan santun masyarakat Mekongga', 'category' => 'Budaya', 'status' => 'published', 'content' => 'Pembelajaran bahasa perlu memperhatikan kesopanan, konteks lawan bicara, dan penghormatan kepada orang yang lebih tua. Nilai ini dipakai pada modul sapaan dan latihan speaking demo.'],
            ['title' => 'Demo: Cara belajar bahasa Mekongga di EMI', 'category' => 'Panduan EMI', 'status' => 'published', 'content' => 'Siswa dapat mulai dari modul, membaca materi, mencari kata di kamus, mengerjakan kuis, latihan speaking, lalu memantau progres belajar di EMI.'],
            ['title' => 'Demo Draft: Catatan Narasumber', 'category' => 'Draft', 'status' => 'draft', 'content' => 'Placeholder materi yang belum disetujui narasumber.'],
            ['title' => 'Demo Arsip: Materi Lama', 'category' => 'Arsip', 'status' => 'archived', 'content' => 'Materi lama untuk menguji status archived.'],
        ];
    }
}
