<?php

namespace Database\Factories;

use App\Models\School;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SchoolClass>
 */
class SchoolClassFactory extends Factory
{
    public function definition(): array
    {
        return [
            'school_id' => School::factory(),
            'name' => 'Kelas '.fake()->numberBetween(1, 12).fake()->randomLetter(),
            'grade_level' => (string) fake()->numberBetween(1, 12),
            'academic_year' => fake()->randomElement(['2025/2026', '2026/2027', '2027/2028']),
            'status' => 'active',
            'created_by' => User::factory()->admin(),
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'inactive',
        ]);
    }
}
