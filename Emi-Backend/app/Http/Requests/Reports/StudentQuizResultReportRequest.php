<?php

namespace App\Http\Requests\Reports;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StudentQuizResultReportRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['nullable', Rule::in(['in_progress', 'submitted', 'expired', 'completed'])],
            'date_from' => ['nullable', 'date_format:Y-m-d'],
            'date_to' => ['nullable', 'date_format:Y-m-d'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:'.config('dashboard.max_per_page')],
            'sort_by' => ['nullable', Rule::in(['quiz_title', 'best_score_percent', 'attempt_count', 'latest_submitted_at'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
