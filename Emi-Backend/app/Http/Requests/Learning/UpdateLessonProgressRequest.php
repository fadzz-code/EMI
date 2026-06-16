<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateLessonProgressRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['required', Rule::in(['not_started', 'in_progress', 'completed'])],
            'progress_percent' => ['nullable', 'integer', 'min:0', 'max:100'],
        ];
    }
}
