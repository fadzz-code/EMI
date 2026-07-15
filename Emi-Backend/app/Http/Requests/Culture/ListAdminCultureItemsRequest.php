<?php

namespace App\Http\Requests\Culture;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListAdminCultureItemsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
            'content_type' => ['nullable', Rule::in(['image', 'audio', 'pdf', 'video', 'youtube', 'article', 'link'])],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }
}
