<?php

namespace App\Http\Requests\Reports;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class AdminClassProgressReportRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'school_id' => ['nullable', 'uuid'],
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in(['active', 'inactive'])],
            'date_from' => ['nullable', 'date_format:Y-m-d'],
            'date_to' => ['nullable', 'date_format:Y-m-d'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:'.config('dashboard.max_per_page')],
            'sort_by' => ['nullable', Rule::in(['class_name', 'active_students', 'average_learning_progress_percent', 'average_quiz_score_percent'])],
            'sort_direction' => ['nullable', Rule::in(['asc', 'desc'])],
        ];
    }
}
