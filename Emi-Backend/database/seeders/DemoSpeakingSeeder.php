<?php

namespace Database\Seeders;

use App\Models\SchoolClass;
use App\Models\SpeakingExercise;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoSpeakingSeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $admin = User::query()->where('email', 'admin.demo@emi.local')->firstOrFail();
        $teacher = User::query()->where('email', 'guru.rina@emi.local')->firstOrFail();
        $class = SchoolClass::query()->where('name', 'VII-A Mekongga')->firstOrFail();

        foreach ($this->exercises(null, $admin) as $exercise) {
            $this->upsertModel(SpeakingExercise::class, ['title' => $exercise['title'], 'classroom_id' => null], $exercise);
        }

        foreach ($this->exercises($class->id, $teacher) as $exercise) {
            $this->upsertModel(SpeakingExercise::class, ['title' => $exercise['title'], 'classroom_id' => $class->id], $exercise);
        }
    }

    private function exercises(?string $classId, User $creator): array
    {
        return [
            [
                'title' => $classId ? 'Demo Target: Sapaan kepada Guru' : 'Demo Template: Sapaan kepada Guru',
                'prompt_text' => 'Ucapkan sapaan sederhana kepada guru dengan suara jelas dan sopan.',
                'target_text' => 'Mombesara lako guru.',
                'target_translation' => 'Salam kepada guru.',
                'language_code' => 'mekongga',
                'difficulty' => 'easy',
                'lesson_id' => null,
                'module_id' => null,
                'classroom_id' => $classId,
                'created_by_id' => $creator->id,
                'status' => 'published',
                'metadata' => ['demo' => true, 'validation_note' => 'Perlu validasi narasumber.'],
            ],
            [
                'title' => $classId ? 'Demo Target: Ungkapan Terima Kasih' : 'Demo Template: Ungkapan Terima Kasih',
                'prompt_text' => 'Ucapkan ungkapan terima kasih kepada guru atau teman.',
                'target_text' => 'Morini, ibu guru.',
                'target_translation' => 'Terima kasih, ibu guru.',
                'language_code' => 'mekongga',
                'difficulty' => 'easy',
                'lesson_id' => null,
                'module_id' => null,
                'classroom_id' => $classId,
                'created_by_id' => $creator->id,
                'status' => 'published',
                'metadata' => ['demo' => true, 'validation_note' => 'Perlu validasi narasumber.'],
            ],
        ];
    }
}
