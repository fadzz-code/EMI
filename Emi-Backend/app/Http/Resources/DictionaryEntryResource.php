<?php

namespace App\Http\Resources;

use App\Services\MediaAccessService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DictionaryEntryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $audio = $this->resource->relationLoaded('audioMedia') ? $this->audioMedia : null;

        return [
            'id' => $this->id,
            'category' => $this->whenLoaded('category', fn () => new DictionaryCategoryResource($this->category)),
            'category_id' => $this->category_id,
            'indonesia' => $this->indonesia,
            'english' => $this->english,
            'mekongga' => $this->mekongga,
            'example_mekongga' => $this->example_mekongga,
            'example_indonesia' => $this->example_indonesia,
            'sentence_examples' => $this->whenLoaded('sentenceExamples', fn () => $this->sentenceExamples->map(fn ($example) => [
                'id' => $example->id,
                'kode' => $example->code,
                'contoh_mekongga' => $example->example_mekongga,
                'contoh_indonesia' => $example->example_indonesia,
            ])->values()),
            'audio' => $audio ? [
                'id' => $audio->id,
                'url' => app(MediaAccessService::class)->publicUrl($audio),
                'mime_type' => $audio->mime_type,
            ] : null,
            'status' => $this->status,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
