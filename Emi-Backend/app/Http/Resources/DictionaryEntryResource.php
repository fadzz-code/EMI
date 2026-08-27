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
            'code' => $this->code,
            'category' => $this->whenLoaded('category', fn () => new DictionaryCategoryResource($this->category)),
            'category_id' => $this->category_id,
            'indonesia' => $this->indonesia,
            'english' => $this->english,
            'mekongga' => $this->mekongga,
            'example_mekongga' => $this->relationLoaded('sentenceExamples') && $this->sentenceExamples->isNotEmpty() 
                ? $this->sentenceExamples->first()->example_mekongga 
                : $this->example_mekongga,
            'example_indonesia' => $this->relationLoaded('sentenceExamples') && $this->sentenceExamples->isNotEmpty() 
                ? $this->sentenceExamples->first()->example_indonesia 
                : $this->example_indonesia,
            'sentence_examples' => $this->whenLoaded('sentenceExamples', fn () => $this->sentenceExamples->map(fn ($example) => [
                'id' => $example->id,
                'kode' => $example->code,
                'contoh_mekongga' => $example->example_mekongga,
                'contoh_indonesia' => $example->example_indonesia,
                'audio' => $example->relationLoaded('audioMedia') && $example->audioMedia ? [
                    'id' => $example->audioMedia->id,
                    'url' => app(MediaAccessService::class)->publicUrl($example->audioMedia),
                    'mime_type' => $example->audioMedia->mime_type,
                    'extension' => $example->audioMedia->extension,
                    'size_bytes' => $example->audioMedia->size_bytes,
                    'checksum_sha256' => $example->audioMedia->checksum_sha256,
                    'updated_at' => $example->audioMedia->updated_at?->toISOString(),
                ] : null,
            ])->values()),
            'audio' => $audio ? [
                'id' => $audio->id,
                'url' => app(MediaAccessService::class)->publicUrl($audio),
                'mime_type' => $audio->mime_type,
                'extension' => $audio->extension,
                'size_bytes' => $audio->size_bytes,
                'checksum_sha256' => $audio->checksum_sha256,
                'updated_at' => $audio->updated_at?->toISOString(),
            ] : null,
            'status' => $this->status,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
