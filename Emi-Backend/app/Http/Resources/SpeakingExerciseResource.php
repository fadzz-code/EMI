<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SpeakingExerciseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'prompt_text' => $this->prompt_text,
            'target_text' => $this->target_text,
            'target_translation' => $this->target_translation,
            'reference_audio_media_id' => $this->reference_audio_media_id,
            'language_code' => $this->language_code,
            'difficulty' => $this->difficulty,
            'classroom_id' => $this->classroom_id,
            'source_speaking_exercise_id' => $this->source_speaking_exercise_id,
            'created_by_id' => $this->created_by_id,
            'status' => $this->status,
            'metadata' => $this->metadata,
            'attempts_count' => $this->whenCounted('attempts'),
            'reference_audio' => $this->whenLoaded('referenceAudio', fn () => [
                'id' => $this->referenceAudio?->id,
                'url' => $this->referenceAudio?->isPublic()
                    ? $request->getSchemeAndHttpHost().'/api/v1/public/media/'.$this->referenceAudio->id.'/content'
                    : null,
                'mime_type' => $this->referenceAudio?->mime_type,
                'file_name' => $this->referenceAudio?->original_name,
                'original_name' => $this->referenceAudio?->original_name,
                'visibility' => $this->referenceAudio?->visibility,
            ]),
            'classroom' => $this->whenLoaded('classroom', fn () => [
                'id' => $this->classroom?->id,
                'name' => $this->classroom?->name,
                'school' => $this->classroom?->school ? [
                    'id' => $this->classroom->school->id,
                    'name' => $this->classroom->school->name,
                ] : null,
            ]),
            'created_by' => $this->whenLoaded('creator', fn () => [
                'id' => $this->creator?->id,
                'full_name' => $this->creator?->full_name,
            ]),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
