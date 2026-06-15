<?php

namespace App\Http\Requests\SchoolClass;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListClassesRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'search' => ['sometimes', 'string', 'max:255'],
            'school_id' => ['sometimes', 'uuid', 'exists:schools,id'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
            'academic_year' => ['sometimes', 'string', 'max:50'],
            'grade_level' => ['sometimes', 'nullable', 'string', 'max:50'],
            'teacher_id' => ['sometimes', 'uuid', 'exists:users,id'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['sometimes', Rule::in(['name', 'grade_level', 'academic_year', 'status', 'created_at'])],
            'sort_direction' => ['sometimes', Rule::in(['asc', 'desc'])],
        ];
    }
}
