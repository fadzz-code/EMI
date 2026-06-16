<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateLessonTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'content_type' => ['sometimes', Rule::in(['text', 'image', 'audio', 'pdf', 'video', 'link'])],
            'content_body' => ['sometimes', 'nullable', 'string'],
            'media_id' => ['sometimes', 'nullable', 'uuid', 'exists:media_files,id'],
            'external_url' => ['sometimes', 'nullable', 'url', 'max:2048'],
            'sort_order' => ['sometimes', 'integer', 'min:1'],
            'status' => ['sometimes', Rule::in(['draft', 'published', 'archived'])],
        ];
    }
}
