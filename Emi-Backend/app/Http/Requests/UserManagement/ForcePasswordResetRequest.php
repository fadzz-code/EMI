<?php

namespace App\Http\Requests\UserManagement;

use App\Http\Requests\ApiFormRequest;
use App\Http\Requests\Concerns\HasFriendlyPasswordMessages;
use Illuminate\Validation\Rules\Password;

class ForcePasswordResetRequest extends ApiFormRequest
{
    use HasFriendlyPasswordMessages;

    public function rules(): array
    {
        return [
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
        ];
    }
}
