<?php

namespace App\Http\Requests\Admin;

use App\Http\Requests\ApiFormRequest;

class UpdateApplicationSettingsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'subtitle' => ['nullable', 'string', 'max:180'],
            'active_academic_year' => ['required', 'string', 'max:30'],
            'timezone' => ['required', 'timezone'],
        ];
    }
}
