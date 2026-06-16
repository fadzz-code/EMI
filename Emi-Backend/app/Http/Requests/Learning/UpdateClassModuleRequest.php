<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateClassModuleRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'status' => ['sometimes', Rule::in(['draft', 'published', 'archived'])],
            'sort_order' => ['sometimes', 'integer', 'min:1'],
        ];
    }
}
