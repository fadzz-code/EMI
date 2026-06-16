<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizQuestionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $showSensitive = (bool) $this->resource->getAttribute('show_sensitive_answers');
        $this->whenLoaded('options', fn () => $this->options->each->setAttribute('show_correct_flag', $showSensitive));

        return [
            'id' => $this->id,
            'class_quiz_id' => $this->class_quiz_id,
            'question_type' => $this->question_type,
            'question_text' => $this->question_text,
            'image_media_id' => $this->image_media_id,
            'correct_answer_text' => $this->when($showSensitive, $this->correct_answer_text),
            'use_fuzzy_matching' => $this->when($showSensitive, $this->use_fuzzy_matching),
            'fuzzy_threshold' => $this->when($showSensitive, $this->fuzzy_threshold),
            'points' => $this->points,
            'order_number' => $this->order_number,
            'explanation' => $this->when($showSensitive, $this->explanation),
            'options' => QuizOptionResource::collection($this->whenLoaded('options')),
            'image_media' => new MediaFileResource($this->whenLoaded('imageMedia')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
