<?php

namespace Database\Factories;

use App\Models\LessonTemplate;
use App\Models\ModuleTemplate;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<LessonTemplate> */
class LessonTemplateFactory extends Factory
{
    protected $model = LessonTemplate::class;

    public function definition(): array
    {
        return [
            'module_template_id' => ModuleTemplate::factory(),
            'title' => 'Mengenal Sapaan',
            'description' => null,
            'content_type' => 'text',
            'content_body' => 'Materi sapaan dasar.',
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
