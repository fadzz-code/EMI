<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListQuizAttemptsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'student_id' => ['nullable', 'uuid'],
            'status' => ['nullable', Rule::in(['in_progress', 'submitted', 'expired'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['nullable', Rule::in(['started_at', 'submitted_at', 'score_percent'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
