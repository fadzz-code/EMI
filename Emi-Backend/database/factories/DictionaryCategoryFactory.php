<?php

namespace Database\Factories;

use App\Models\DictionaryCategory;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/** @extends Factory<DictionaryCategory> */
class DictionaryCategoryFactory extends Factory
{
    protected $model = DictionaryCategory::class;

    public function definition(): array
    {
        $name = fake()->unique()->word();

        return [
            'name' => Str::title($name),
            'slug' => Str::slug($name),
            'description' => fake()->optional()->sentence(),
            'status' => 'active',
            'created_by' => User::factory()->admin(),
            'updated_by' => null,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (): array => [
            'status' => 'inactive',
        ]);
    }
}
