<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;

class ReorderLessonsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'lesson_ids' => ['required', 'array', 'min:1'],
            'lesson_ids.*' => ['required', 'uuid'],
        ];
    }
}
