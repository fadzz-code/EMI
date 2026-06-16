<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreQuizTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'instructions' => ['nullable', 'string'],
            'duration_minutes' => ['required', 'integer', 'min:1', 'max:'.config('quiz.max_duration_minutes')],
            'max_attempts' => ['required', 'integer', 'min:1', 'max:'.config('quiz.max_attempts')],
            'show_result' => ['nullable', 'boolean'],
            'status' => ['nullable', Rule::in(['draft'])],
        ];
    }
}
