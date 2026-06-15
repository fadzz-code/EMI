<?php

namespace Database\Factories;

use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<RegistrationRequest>
 */
class RegistrationRequestFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->student()->pending(),
            'school_id' => School::factory(),
            'class_id' => fn (array $attributes) => SchoolClass::factory()->state([
                'school_id' => $attributes['school_id'],
            ]),
            'requested_role' => 'student',
            'status' => 'pending',
            'reviewed_by' => null,
            'review_note' => null,
            'reviewed_at' => null,
        ];
    }

    public function teacher(): static
    {
        return $this->state(fn (array $attributes) => [
            'user_id' => User::factory()->teacher()->pending(),
            'requested_role' => 'teacher',
        ]);
    }

    public function approved(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'approved',
            'reviewed_by' => User::factory()->admin(),
            'review_note' => 'Pendaftaran disetujui.',
            'reviewed_at' => now(),
        ]);
    }

    public function rejected(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'rejected',
            'reviewed_by' => User::factory()->admin(),
            'review_note' => 'Data pendaftaran tidak sesuai.',
            'reviewed_at' => now(),
        ]);
    }
}
