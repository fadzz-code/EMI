<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;

class ApplyQuizTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'class_ids' => ['required', 'array', 'min:1'],
            'class_ids.*' => ['required', 'uuid', 'distinct', 'exists:classes,id'],
        ];
    }
}
