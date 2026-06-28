<?php

namespace App\Http\Requests\Culture;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateCultureTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'status' => ['sometimes', Rule::in(['draft', 'published', 'archived'])],
        ];
    }
}
