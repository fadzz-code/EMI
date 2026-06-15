<?php

namespace App\Http\Requests\SchoolClass;

use App\Http\Requests\ApiFormRequest;

class AssignTeacherRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'teacher_id' => ['required', 'uuid', 'exists:users,id'],
        ];
    }
}
