<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizTemplateQuestionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $this->whenLoaded('options', fn () => $this->options->each->setAttribute('show_correct_flag', true));

        return [
            'id' => $this->id,
            'quiz_template_id' => $this->quiz_template_id,
            'question_type' => $this->question_type,
            'question_text' => $this->question_text,
            'image_media_id' => $this->image_media_id,
            'correct_answer_text' => $this->correct_answer_text,
            'use_fuzzy_matching' => $this->use_fuzzy_matching,
            'fuzzy_threshold' => $this->fuzzy_threshold,
            'points' => $this->points,
            'order_number' => $this->order_number,
            'explanation' => $this->explanation,
            'options' => QuizOptionResource::collection($this->whenLoaded('options')),
            'image_media' => new MediaFileResource($this->whenLoaded('imageMedia')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
