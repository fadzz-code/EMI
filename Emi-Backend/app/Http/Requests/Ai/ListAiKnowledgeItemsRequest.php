<?php

namespace App\Http\Requests\Ai;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListAiKnowledgeItemsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'search' => ['nullable', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['nullable', Rule::in(['title', 'category', 'status', 'created_at', 'updated_at'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
