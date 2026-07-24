<?php

namespace Database\Factories;

use App\Models\PasswordResetRequest;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PasswordResetRequest>
 */
class PasswordResetRequestFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory()->student()->approved(),
            'requested_by' => fn (array $attributes) => $attributes['user_id'],
            'status' => 'pending',
            'reviewed_by' => null,
            'review_note' => null,
            'reviewed_at' => null,
        ];
    }

    public function approved(): static
    {
        return $this->state(fn () => [
            'status' => 'approved',
            'reviewed_by' => User::factory()->admin(),
            'reviewed_at' => now(),
        ]);
    }

    public function rejected(): static
    {
        return $this->state(fn () => [
            'status' => 'rejected',
            'reviewed_by' => User::factory()->admin(),
            'review_note' => 'Permintaan tidak dapat diverifikasi.',
            'reviewed_at' => now(),
        ]);
    }
}
