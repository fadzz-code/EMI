<?php

namespace App\Http\Requests\Reports;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class QuizResultReportRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'school_id' => ['nullable', 'uuid'],
            'class_id' => ['nullable', 'uuid'],
            'quiz_id' => ['nullable', 'uuid'],
            'student_id' => ['nullable', 'uuid'],
            'status' => ['nullable', Rule::in(['not_started', 'in_progress', 'submitted', 'expired', 'completed'])],
            'attempt_status' => ['nullable', Rule::in(['in_progress', 'submitted', 'expired'])],
            'date_from' => ['nullable', 'date_format:Y-m-d'],
            'date_to' => ['nullable', 'date_format:Y-m-d'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:'.config('dashboard.max_per_page')],
            'sort_by' => ['nullable', Rule::in(['student_name', 'quiz_title', 'best_score_percent', 'attempt_count', 'latest_submitted_at'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
