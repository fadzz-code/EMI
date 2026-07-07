<?php

namespace App\Http\Requests\Admin;

use App\Http\Requests\ApiFormRequest;

class UpdateBannerSettingsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'enabled' => ['required', 'boolean'],
            'file' => ['nullable', 'image', 'max:5120'],
        ];
    }
}
