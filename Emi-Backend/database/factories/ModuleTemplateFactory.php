<?php

namespace Database\Factories;

use App\Models\ModuleTemplate;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<ModuleTemplate> */
class ModuleTemplateFactory extends Factory
{
    protected $model = ModuleTemplate::class;

    public function definition(): array
    {
        return [
            'title' => 'Kosakata Dasar',
            'description' => 'Pengenalan kosakata Mekongga.',
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

    public function archived(): static
    {
        return $this->state(fn (): array => [
            'status' => 'archived',
            'archived_at' => now(),
        ]);
    }
}
