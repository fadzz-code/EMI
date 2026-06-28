<?php

namespace App\Http\Requests\Culture;

use App\Http\Requests\ApiFormRequest;

class ApplyCultureTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'class_ids' => ['required', 'array', 'min:1'],
            'class_ids.*' => ['required', 'uuid', 'exists:classes,id'],
        ];
    }
}
