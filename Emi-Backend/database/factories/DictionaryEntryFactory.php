<?php

namespace Database\Factories;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\User;
use App\Services\DictionaryNormalizer;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<DictionaryEntry> */
class DictionaryEntryFactory extends Factory
{
    protected $model = DictionaryEntry::class;

    public function definition(): array
    {
        $indonesia = fake()->unique()->word();
        $english = fake()->unique()->word();
        $mekongga = fake()->unique()->word();
        $normalizer = app(DictionaryNormalizer::class);

        return [
            'category_id' => DictionaryCategory::factory(),
            'indonesia' => $indonesia,
            'english' => $english,
            'mekongga' => $mekongga,
            'indonesia_normalized' => $normalizer->normalize($indonesia),
            'english_normalized' => $normalizer->normalize($english),
            'mekongga_normalized' => $normalizer->normalize($mekongga),
            'example_mekongga' => fake()->optional()->sentence(),
            'example_indonesia' => fake()->optional()->sentence(),
            'audio_media_id' => null,
            'status' => 'active',
            'created_by' => User::factory()->admin(),
            'updated_by' => null,
            'source_import_job_id' => null,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (): array => [
            'status' => 'inactive',
        ]);
    }
}
