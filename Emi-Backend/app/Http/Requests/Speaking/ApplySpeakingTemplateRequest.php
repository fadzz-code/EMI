<?php

namespace App\Http\Requests\Speaking;

use App\Http\Requests\ApiFormRequest;

class ApplySpeakingTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'class_ids' => ['required', 'array', 'min:1'],
            'class_ids.*' => ['required', 'uuid', 'distinct', 'exists:classes,id'],
            'sync_existing' => ['sometimes', 'boolean'],
        ];
    }
}
