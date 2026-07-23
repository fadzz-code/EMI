<?php

namespace App\Http\Requests\Reports;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class AdminProgressOverviewRequest extends ApiFormRequest
{
    public function rules(): array
    {
        $max = config('dashboard.max_per_page');

        return [
            'school_id' => ['nullable', 'uuid'],
            'class_id' => ['nullable', 'uuid'],
            'search' => ['nullable', 'string', 'max:255'],
            'learning_status' => ['nullable', Rule::in(['not_started', 'in_progress', 'completed'])],
            'quiz_status' => ['nullable', Rule::in(['not_started', 'in_progress', 'completed'])],
            'date_from' => ['nullable', 'date_format:Y-m-d'],
            'date_to' => ['nullable', 'date_format:Y-m-d'],
            'student_page' => ['nullable', 'integer', 'min:1'],
            'student_per_page' => ['nullable', 'integer', 'min:1', "max:{$max}"],
            'class_page' => ['nullable', 'integer', 'min:1'],
            'class_per_page' => ['nullable', 'integer', 'min:1', "max:{$max}"],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', "max:{$max}"],
            'analysis_status' => ['nullable', Rule::in(['pending', 'processing', 'completed', 'failed'])],
            'review_status' => ['nullable', Rule::in(['pending', 'reviewed'])],
        ];
    }
}
