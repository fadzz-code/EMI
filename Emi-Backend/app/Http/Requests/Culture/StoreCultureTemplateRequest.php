<?php

namespace App\Http\Requests\Culture;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreCultureTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
        ];
    }
}
