<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListAdminDictionaryEntriesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'search' => ['sometimes', 'string', 'max:255'],
            'category_id' => ['sometimes', 'uuid', 'exists:dictionary_categories,id'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
            'has_audio' => ['sometimes', 'boolean'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['sometimes', Rule::in(['indonesia', 'english', 'mekongga', 'created_at'])],
            'sort_direction' => ['sometimes', Rule::in(['asc', 'desc'])],
        ];
    }
}
