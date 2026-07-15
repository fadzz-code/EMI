<?php

namespace App\Http\Requests\Ai;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateAiKnowledgeItemRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:255'],
            'content' => ['sometimes', 'required', 'string'],
            'source_type' => ['sometimes', 'required', Rule::in(['manual', 'link', 'pdf'])],
            'source_url' => ['nullable', 'required_if:source_type,link,pdf', 'string', 'max:2048'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
        ];
    }
}
