<?php

namespace App\Http\Requests\SchoolClass;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateSchoolClassRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'grade_level' => ['nullable', 'string', 'max:50'],
            'academic_year' => ['required', 'string', 'max:50'],
            'status' => ['required', Rule::in(['active', 'inactive'])],
        ];
    }
}
