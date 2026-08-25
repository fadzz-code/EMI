<?php

namespace App\Http\Requests\Learning;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class PublishModuleTemplateRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'apply_to_all_active_classes' => ['sometimes', 'boolean'],
            'publish_class_modules' => [
                'sometimes',
                'boolean',
                Rule::prohibitedIf(fn () => $this->boolean('publish_class_modules') && ! $this->boolean('apply_to_all_active_classes')),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'publish_class_modules.prohibited' => 'Opsi langsung tampil ke siswa hanya dapat dipilih jika salinan dikirim ke semua kelas aktif.',
        ];
    }
}
