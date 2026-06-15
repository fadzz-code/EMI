<?php

namespace App\Http\Requests\SchoolClass;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class StoreSchoolClassRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'school_id' => ['required', 'uuid', 'exists:schools,id'],
            'name' => ['required', 'string', 'max:255'],
            'grade_level' => ['nullable', 'string', 'max:50'],
            'academic_year' => ['required', 'string', 'max:50'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
        ];
    }
}
