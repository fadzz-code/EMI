<?php

namespace Database\Factories;

use App\Models\SchoolClass;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TeacherClassAssignment>
 */
class TeacherClassAssignmentFactory extends Factory
{
    public function definition(): array
    {
        return [
            'teacher_id' => User::factory()->teacher()->approved(),
            'class_id' => SchoolClass::factory(),
            'assigned_by' => User::factory()->admin(),
            'is_active' => true,
            'assigned_at' => now(),
            'ended_at' => null,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
            'ended_at' => now(),
        ]);
    }
}
