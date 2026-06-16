<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListModuleTemplatesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'search' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
            'created_by' => ['nullable', 'uuid', 'exists:users,id'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['nullable', Rule::in(['title', 'status', 'created_at', 'updated_at'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
