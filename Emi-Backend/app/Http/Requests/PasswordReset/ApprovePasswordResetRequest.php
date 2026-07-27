<?php

namespace App\Http\Requests\PasswordReset;

use App\Http\Requests\ApiFormRequest;
use App\Http\Requests\Concerns\HasFriendlyPasswordMessages;
use Illuminate\Validation\Rules\Password;

class ApprovePasswordResetRequest extends ApiFormRequest
{
    use HasFriendlyPasswordMessages;

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
            'review_note' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ];
    }
}
