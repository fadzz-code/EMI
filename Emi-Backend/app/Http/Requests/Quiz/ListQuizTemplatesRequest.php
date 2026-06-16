<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListQuizTemplatesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
            'created_by' => ['nullable', 'uuid'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['nullable', Rule::in(['created_at', 'title', 'status'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
