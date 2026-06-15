<?php

namespace App\Http\Requests\School;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateSchoolRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'address' => ['nullable', 'string'],
            'phone' => ['nullable', 'string', 'max:50'],
            'status' => ['required', Rule::in(['active', 'inactive'])],
        ];
    }
}
