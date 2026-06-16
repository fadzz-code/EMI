<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreClassModuleRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'status' => ['nullable', Rule::in(['draft'])],
            'sort_order' => ['nullable', 'integer', 'min:1'],
        ];
    }
}
