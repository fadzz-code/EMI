<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreQuizQuestionRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'question_type' => ['required', Rule::in(['multiple_choice', 'short_answer'])],
            'question_text' => ['required', 'string'],
            'image_media_id' => ['nullable', 'uuid'],
            'correct_answer_text' => ['nullable', 'string'],
            'use_fuzzy_matching' => ['nullable', 'boolean'],
            'fuzzy_threshold' => ['nullable', 'integer', 'min:1', 'max:100'],
            'points' => ['required', 'integer', 'min:1'],
            'order_number' => ['required', 'integer', 'min:1'],
            'explanation' => ['nullable', 'string'],
            'options' => ['nullable', 'array'],
            'options.*.option_text' => ['required_with:options', 'string'],
            'options.*.is_correct' => ['required_with:options', 'boolean'],
            'options.*.order_number' => ['required_with:options', 'integer', 'min:1'],
        ];
    }
}
