<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;

class ReorderClassModulesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'module_ids' => ['required', 'array', 'min:1'],
            'module_ids.*' => ['required', 'uuid'],
        ];
    }
}
