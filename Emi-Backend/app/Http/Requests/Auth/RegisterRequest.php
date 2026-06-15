<?php

namespace App\Http\Requests\Auth;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends ApiFormRequest
{
    protected function prepareForValidation(): void
    {
        if ($this->filled('email')) {
            $this->merge(['email' => Str::lower(trim((string) $this->email))]);
        }
    }

    public function rules(): array
    {
        return [
            'full_name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
            'requested_role' => ['required', Rule::in(['teacher', 'student'])],
            'school_id' => ['required', 'uuid', Rule::exists('schools', 'id')->where('status', 'active')],
            'class_id' => [
                'required',
                'uuid',
                Rule::exists('classes', 'id')
                    ->where('status', 'active')
                    ->where('school_id', (string) $this->input('school_id')),
            ],
        ];
    }
}
