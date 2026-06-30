<?php

namespace App\Http\Requests\Ai;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreAiKnowledgeItemRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:255'],
            'content' => ['required', 'string'],
            'source_type' => ['required', Rule::in(['manual', 'link', 'pdf'])],
            'source_url' => ['nullable', 'required_if:source_type,link', 'url', 'max:2048'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
        ];
    }
}
