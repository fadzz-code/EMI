<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListDictionaryCategoriesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'search' => ['sometimes', 'string', 'max:255'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }
}
