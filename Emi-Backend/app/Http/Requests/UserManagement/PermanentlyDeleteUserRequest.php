<?php

namespace App\Http\Requests\UserManagement;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class PermanentlyDeleteUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'admin';
    }

    public function rules(): array
    {
        return [
            'confirmation' => ['required', 'string', Rule::in(['hapus permanen'])],
        ];
    }

    public function messages(): array
    {
        return [
            'confirmation.in' => 'Ketik "hapus permanen" untuk menghapus akun.',
        ];
    }
}
