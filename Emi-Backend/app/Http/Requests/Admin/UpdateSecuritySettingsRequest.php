<?php

namespace App\Http\Requests\Admin;

use App\Http\Requests\ApiFormRequest;

class UpdateSecuritySettingsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'new_login_alert' => ['required', 'boolean'],
            'weekly_report_email' => ['required', 'boolean'],
        ];
    }
}
