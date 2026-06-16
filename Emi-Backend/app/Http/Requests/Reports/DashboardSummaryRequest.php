<?php

namespace App\Http\Requests\Reports;

use App\Http\Requests\ApiFormRequest;

class DashboardSummaryRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'date_from' => ['nullable', 'date_format:Y-m-d'],
            'date_to' => ['nullable', 'date_format:Y-m-d'],
            'school_id' => ['nullable', 'uuid'],
            'class_id' => ['nullable', 'uuid'],
        ];
    }
}
