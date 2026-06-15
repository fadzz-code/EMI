<?php

namespace App\Http\Requests\SchoolClass;

use App\Http\Requests\ApiFormRequest;

class AssignStudentRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'student_id' => ['required', 'uuid', 'exists:users,id'],
        ];
    }
}
