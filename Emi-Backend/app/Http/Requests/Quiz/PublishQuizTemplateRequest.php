<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;

class PublishQuizTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'apply_to_all_active_classes' => ['sometimes', 'boolean'],
        ];
    }

    public function messages(): array
    {
        return [
            'apply_to_all_active_classes.boolean' => 'Pilihan distribusi ke semua kelas aktif harus bernilai benar atau salah.',
        ];
    }
}
