<?php

namespace Database\Factories;

use App\Models\ClassModule;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<ClassModule> */
class ClassModuleFactory extends Factory
{
    protected $model = ClassModule::class;

    public function definition(): array
    {
        return [
            'class_id' => SchoolClass::factory(),
            'source_module_template_id' => null,
            'title' => 'Modul Kelas',
            'description' => 'Materi untuk kelas.',
            'status' => 'draft',
            'sort_order' => 1,
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
