<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;

class UpdateClassQuizRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'instructions' => ['sometimes', 'nullable', 'string'],
            'duration_minutes' => ['sometimes', 'required', 'integer', 'min:1', 'max:'.config('quiz.max_duration_minutes')],
            'max_attempts' => ['sometimes', 'required', 'integer', 'min:1', 'max:'.config('quiz.max_attempts')],
            'show_result' => ['sometimes', 'boolean'],
            'open_at' => ['sometimes', 'nullable', 'date'],
            'close_at' => ['sometimes', 'nullable', 'date', 'after:open_at'],
        ];
    }
}
