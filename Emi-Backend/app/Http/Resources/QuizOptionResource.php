<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizOptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $showCorrect = (bool) $this->resource->getAttribute('show_correct_flag');

        return [
            'id' => $this->id,
            'option_text' => $this->option_text,
            'is_correct' => $this->when($showCorrect, $this->is_correct),
            'order_number' => $this->order_number,
        ];
    }
}
