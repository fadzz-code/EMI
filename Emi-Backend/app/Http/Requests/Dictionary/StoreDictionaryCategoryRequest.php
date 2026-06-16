<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreDictionaryCategoryRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
            'created_by' => ['prohibited'],
            'updated_by' => ['prohibited'],
            'slug' => ['prohibited'],
        ];
    }
}
