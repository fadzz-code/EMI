<?php

namespace App\Http\Requests\Concerns;

trait HasFriendlyPasswordMessages
{
    public function messages(): array
    {
        return [
            'password.required' => 'Password wajib diisi.',
            'password.min' => 'Password minimal 8 karakter.',
            'password.letters' => 'Password harus mengandung minimal satu huruf.',
            'password.numbers' => 'Password harus mengandung minimal satu angka.',
            'password.mixed' => 'Password harus mengandung huruf besar dan huruf kecil.',
            'password.symbols' => 'Password harus mengandung minimal satu simbol.',
            'password.confirmed' => 'Konfirmasi password tidak sama.',
        ];
    }
}
