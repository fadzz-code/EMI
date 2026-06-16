<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListStudentQuizzesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'search' => ['nullable', 'string', 'max:255'],
            'availability' => ['nullable', Rule::in(['open', 'not_open', 'closed'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['nullable', Rule::in(['open_at', 'close_at', 'created_at', 'title'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
