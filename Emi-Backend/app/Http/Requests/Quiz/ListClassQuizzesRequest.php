<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListClassQuizzesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'class_id' => ['nullable', 'uuid'],
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['nullable', Rule::in(['created_at', 'title', 'status', 'open_at'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
