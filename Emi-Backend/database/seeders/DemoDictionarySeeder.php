<?php

namespace Database\Seeders;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionarySentenceExample;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DemoDictionarySeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $admin = User::query()->where('email', 'admin.demo@emi.local')->firstOrFail();

        foreach ($this->entries() as $item) {
            $category = $this->upsertModel(DictionaryCategory::class, ['slug' => Str::slug('Demo '.$item['category'])], [
                'name' => 'Demo '.$item['category'],
                'description' => 'Kategori demo. Perlu validasi narasumber.',
                'status' => 'active',
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
            ]);

            $entry = $this->upsertModel(DictionaryEntry::class, ['code_normalized' => Str::lower($item['code'])], [
                'code' => $item['code'],
                'category_id' => $category->id,
                'indonesia' => $item['indonesia'],
                'english' => $item['english'],
                'mekongga' => $item['mekongga'],
                'indonesia_normalized' => Str::lower($item['indonesia']),
                'english_normalized' => Str::lower($item['english']),
                'mekongga_normalized' => Str::lower($item['mekongga']),
                'example_mekongga' => $item['example_mekongga'],
                'example_indonesia' => $item['example_indonesia'],
                'audio_media_id' => null,
                'status' => 'active',
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
                'source_import_job_id' => null,
            ]);

            $this->upsertModel(DictionarySentenceExample::class, [
                'dictionary_entry_id' => $entry->id,
                'example_mekongga_normalized' => Str::lower($item['example_mekongga']),
                'example_indonesia_normalized' => Str::lower($item['example_indonesia']),
            ], [
                'code' => $item['code'],
                'example_mekongga' => $item['example_mekongga'],
                'example_indonesia' => $item['example_indonesia'],
                'status' => 'active',
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
                'source_import_job_id' => null,
            ]);
        }
    }

    private function entries(): array
    {
        return [
            ['code' => 'DEMO-KOS-001', 'mekongga' => 'mombesara', 'indonesia' => 'salam / menyapa', 'english' => 'greeting', 'category' => 'Sapaan', 'example_mekongga' => 'Mombesara lako guru.', 'example_indonesia' => 'Salam kepada guru.'],
            ['code' => 'DEMO-KOS-002', 'mekongga' => 'mekambo', 'indonesia' => 'belajar', 'english' => 'study / learn', 'category' => 'Kegiatan Belajar', 'example_mekongga' => 'Aku mekambo bahasa Mekongga.', 'example_indonesia' => 'Saya belajar bahasa Mekongga.'],
            ['code' => 'DEMO-KOS-003', 'mekongga' => 'morini', 'indonesia' => 'terima kasih', 'english' => 'thank you', 'category' => 'Sopan Santun', 'example_mekongga' => 'Morini, ibu guru.', 'example_indonesia' => 'Terima kasih, ibu guru.'],
        ];
    }
}
