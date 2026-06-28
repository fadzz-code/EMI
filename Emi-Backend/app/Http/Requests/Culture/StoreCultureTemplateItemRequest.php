<?php

namespace App\Http\Requests\Culture;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreCultureTemplateItemRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'content_type' => ['required', Rule::in(['image', 'audio', 'pdf', 'video', 'youtube', 'article', 'link'])],
            'media_id' => ['nullable', 'uuid', 'exists:media_files,id'],
            'external_url' => ['nullable', 'url', 'max:2048'],
            'display_order' => ['nullable', 'integer', 'min:1'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
        ];
    }
}
