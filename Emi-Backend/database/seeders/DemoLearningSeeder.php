<?php

namespace Database\Seeders;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\LessonTemplate;
use App\Models\ModuleTemplate;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoLearningSeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $admin = User::query()->where('email', 'admin.demo@emi.local')->firstOrFail();
        $teacher = User::query()->where('email', 'guru.rina@emi.local')->firstOrFail();
        $class = SchoolClass::query()->where('name', 'VII-A Mekongga')->firstOrFail();

        foreach ($this->modules() as $moduleIndex => $moduleData) {
            $module = $this->upsertModel(ModuleTemplate::class, ['title' => $moduleData['title']], [
                'description' => $moduleData['description'],
                'status' => 'published',
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
                'published_at' => now(),
                'archived_at' => null,
            ]);

            $lessons = [];
            foreach ($moduleData['lessons'] as $lessonIndex => $lessonData) {
                $lessons[] = $this->upsertModel(LessonTemplate::class, ['module_template_id' => $module->id, 'title' => $lessonData['title']], [
                    'description' => $lessonData['description'],
                    'content_type' => 'text',
                    'content_body' => $lessonData['body'],
                    'media_id' => null,
                    'external_url' => null,
                    'sort_order' => $lessonIndex + 1,
                    'status' => 'published',
                    'created_by' => $admin->id,
                    'updated_by' => $admin->id,
                    'published_at' => now(),
                    'archived_at' => null,
                ]);
            }

            $classModule = $this->upsertModel(ClassModule::class, ['class_id' => $class->id, 'source_module_template_id' => $module->id], [
                'title' => $module->title,
                'description' => $module->description,
                'status' => 'published',
                'sort_order' => $moduleIndex + 1,
                'created_by' => $teacher->id,
                'updated_by' => $teacher->id,
                'published_at' => now(),
                'archived_at' => null,
            ]);

            foreach ($lessons as $lesson) {
                $this->upsertModel(ClassLesson::class, ['class_module_id' => $classModule->id, 'source_lesson_template_id' => $lesson->id], [
                    'title' => $lesson->title,
                    'description' => $lesson->description,
                    'content_type' => $lesson->content_type,
                    'content_body' => $lesson->content_body,
                    'media_id' => null,
                    'external_url' => null,
                    'sort_order' => $lesson->sort_order,
                    'status' => 'published',
                    'created_by' => $teacher->id,
                    'updated_by' => $teacher->id,
                    'published_at' => now(),
                    'archived_at' => null,
                ]);
            }
        }
    }

    private function modules(): array
    {
        return [
            ['title' => 'Demo: Sapaan Dasar Bahasa Mekongga', 'description' => 'Modul demo mengenal sapaan dasar.', 'lessons' => [
                ['title' => 'Mengenal Sapaan', 'description' => 'Pengantar sapaan dalam konteks sekolah dan keluarga.', 'body' => 'Sapaan membantu siswa memulai percakapan dengan sopan. Materi ini memakai contoh demo mombesara yang perlu validasi narasumber.'],
                ['title' => 'Menyapa Guru dan Teman', 'description' => 'Dialog sederhana untuk menyapa guru dan teman.', 'body' => 'Gunakan suara jelas dan sikap sopan saat menyapa guru atau teman.'],
                ['title' => 'Ungkapan Terima Kasih', 'description' => 'Cara berterima kasih dengan sopan.', 'body' => 'Materi demo memakai kata morini sebagai terima kasih. Arti perlu validasi narasumber.'],
            ]],
            ['title' => 'Demo: Bahasa dan Budaya Sehari-hari', 'description' => 'Modul demo hubungan bahasa, budaya, dan EMI.', 'lessons' => [
                ['title' => 'Belajar Bahasa Daerah di EMI', 'description' => 'Alur belajar di EMI.', 'body' => 'Siswa belajar dari modul, kamus, kuis, speaking, latihan, dan laporan progres.'],
                ['title' => 'Nilai Sopan Santun', 'description' => 'Bahasa dipakai sesuai konteks.', 'body' => 'Sopan santun penting dalam percakapan dengan guru, orang tua, dan teman.'],
                ['title' => 'Mengenal Budaya Mekongga', 'description' => 'Pengantar budaya Mekongga.', 'body' => 'Konten budaya demo memberi konteks penggunaan bahasa Mekongga. Detail perlu validasi narasumber.'],
            ]],
        ];
    }
}
