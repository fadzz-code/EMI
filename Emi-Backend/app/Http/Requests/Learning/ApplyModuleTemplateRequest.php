<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;

class ApplyModuleTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'class_ids' => ['required', 'array', 'min:1'],
            'class_ids.*' => ['required', 'uuid', 'exists:classes,id'],
            'sync_existing' => ['sometimes', 'boolean'],
        ];
    }
}
