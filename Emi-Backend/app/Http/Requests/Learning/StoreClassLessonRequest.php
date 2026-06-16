<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreClassLessonRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'content_type' => ['required', Rule::in(['text', 'image', 'audio', 'pdf', 'video', 'link'])],
            'content_body' => ['nullable', 'string'],
            'media_id' => ['nullable', 'uuid', 'exists:media_files,id'],
            'external_url' => ['nullable', 'url', 'max:2048'],
            'sort_order' => ['nullable', 'integer', 'min:1'],
            'status' => ['nullable', Rule::in(['draft', 'published'])],
        ];
    }
}
