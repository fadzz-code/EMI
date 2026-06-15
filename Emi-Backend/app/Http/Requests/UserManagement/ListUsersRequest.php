<?php

namespace App\Http\Requests\UserManagement;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListUsersRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'role' => ['sometimes', Rule::in(['admin', 'teacher', 'student'])],
            'status' => ['sometimes', Rule::in(['pending', 'approved', 'rejected', 'inactive'])],
            'school_id' => ['sometimes', 'uuid', 'exists:schools,id'],
            'class_id' => ['sometimes', 'uuid', 'exists:classes,id'],
            'search' => ['sometimes', 'string', 'max:255'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['sometimes', Rule::in(['full_name', 'email', 'role', 'status', 'created_at'])],
            'sort_direction' => ['sometimes', Rule::in(['asc', 'desc'])],
        ];
    }
}
