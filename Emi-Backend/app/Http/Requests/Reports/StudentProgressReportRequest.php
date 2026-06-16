<?php

namespace App\Http\Requests\Reports;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StudentProgressReportRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'school_id' => ['nullable', 'uuid'],
            'class_id' => ['nullable', 'uuid'],
            'student_id' => ['nullable', 'uuid'],
            'search' => ['nullable', 'string', 'max:255'],
            'learning_status' => ['nullable', Rule::in(['not_started', 'in_progress', 'completed'])],
            'quiz_status' => ['nullable', Rule::in(['not_started', 'in_progress', 'completed'])],
            'date_from' => ['nullable', 'date_format:Y-m-d'],
            'date_to' => ['nullable', 'date_format:Y-m-d'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:'.config('dashboard.max_per_page')],
            'sort_by' => ['nullable', Rule::in(['full_name', 'overall_learning_progress_percent', 'average_best_quiz_score_percent', 'last_learning_activity_at', 'last_quiz_activity_at'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
