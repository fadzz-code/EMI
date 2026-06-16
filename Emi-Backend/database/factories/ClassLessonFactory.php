<?php

namespace Database\Factories;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<ClassLesson> */
class ClassLessonFactory extends Factory
{
    protected $model = ClassLesson::class;

    public function definition(): array
    {
        return [
            'class_module_id' => ClassModule::factory(),
            'source_lesson_template_id' => null,
            'title' => 'Materi Kelas',
            'description' => null,
            'content_type' => 'text',
            'content_body' => 'Isi materi kelas.',
            'media_id' => null,
            'external_url' => null,
            'sort_order' => 1,
            'status' => 'draft',
            'created_by' => User::factory()->admin(),
        ];
    }

    public function published(): static
    {
        return $this->state(fn (): array => [
            'status' => 'published',
            'published_at' => now(),
        ]);
    }
}
