<?php

namespace Database\Factories;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<AiKnowledgeItem> */
class AiKnowledgeItemFactory extends Factory
{
    protected $model = AiKnowledgeItem::class;

    public function definition(): array
    {
        return [
            'title' => 'Sejarah Mekongga',
            'category' => 'Budaya',
            'content' => 'Kerajaan Mekongga adalah bagian dari sejarah dan budaya masyarakat Mekongga.',
            'source_type' => 'manual',
            'source_url' => null,
            'status' => 'draft',
            'created_by' => User::factory()->admin(),
        ];
    }

    public function published(): static
    {
        return $this->state(fn (): array => [
            'status' => 'published',
        ]);
    }

    public function archived(): static
    {
        return $this->state(fn (): array => [
            'status' => 'archived',
        ]);
    }
}
