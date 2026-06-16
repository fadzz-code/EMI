<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;

class ListDictionaryImportErrorsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'row_number' => ['sometimes', 'integer', 'min:1'],
            'field' => ['sometimes', 'string', 'max:255'],
            'code' => ['sometimes', 'string', 'max:255'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }
}
