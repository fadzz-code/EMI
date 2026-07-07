<?php

namespace Database\Seeders;

use App\Models\AdminCultureItem;
use App\Models\ClassCultureItem;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DemoCultureSeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $admin = User::query()->where('email', 'admin.demo@emi.local')->firstOrFail();
        $teacher = User::query()->where('email', 'guru.rina@emi.local')->firstOrFail();
        $class = SchoolClass::query()->where('name', 'VII-A Mekongga')->firstOrFail();

        foreach ($this->items() as $index => $item) {
            $adminItem = $this->upsertModel(AdminCultureItem::class, ['title' => $item['title']], [
                'admin_group_id' => $item['group_id'],
                'description' => $item['description'],
                'content_type' => 'article',
                'media_id' => null,
                'external_url' => null,
                'display_order' => $index + 1,
                'status' => $item['status'],
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
                'published_at' => $item['status'] === 'published' ? now() : null,
                'archived_at' => null,
            ]);

            if ($item['status'] === 'published') {
                $this->upsertModel(ClassCultureItem::class, ['class_id' => $class->id, 'title' => $item['title']], [
                    'source_culture_template_id' => null,
                    'source_culture_template_item_id' => null,
                    'title' => $adminItem->title,
                    'description' => $adminItem->description,
                    'content_type' => 'article',
                    'media_id' => null,
                    'external_url' => null,
                    'thumbnail_media_id' => null,
                    'display_order' => $adminItem->display_order,
                    'status' => 'published',
                    'created_by' => $teacher->id,
                    'updated_by' => $teacher->id,
                    'published_at' => now(),
                    'archived_at' => null,
                ]);
            }
        }
    }

    private function items(): array
    {
        return [
            ['group_id' => Str::uuid()->toString(), 'title' => 'Demo: Sopan Santun dalam Percakapan', 'status' => 'published', 'description' => 'Konten demo tentang pentingnya menyapa dengan hormat kepada guru, orang tua, dan teman. Perlu validasi narasumber.'],
            ['group_id' => Str::uuid()->toString(), 'title' => 'Demo: Mengenal Budaya Mekongga di Kolaka', 'status' => 'published', 'description' => 'Pengantar budaya Mekongga sebagai konteks belajar bahasa daerah di EMI. Perlu validasi narasumber.'],
            ['group_id' => Str::uuid()->toString(), 'title' => 'Demo Draft: Media Budaya', 'status' => 'draft', 'description' => 'Placeholder konten budaya yang menunggu media dan validasi narasumber.'],
        ];
    }
}
