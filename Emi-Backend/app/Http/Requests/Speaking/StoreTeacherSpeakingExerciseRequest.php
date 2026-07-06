<?php

namespace App\Http\Requests\Speaking;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreTeacherSpeakingExerciseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'teacher';
    }

    public function rules(): array
    {
        return [
            'classroom_id' => [
                'required',
                'uuid',
                'exists:classes,id',
                Rule::exists('teacher_class_assignments', 'class_id')
                    ->where('teacher_id', $this->user()?->id)
                    ->where('is_active', true),
            ],
            'title' => ['required', 'string', 'max:255'],
            'prompt_text' => ['nullable', 'string', 'max:5000'],
            'target_text' => ['required', 'string', 'max:5000'],
            'target_translation' => ['nullable', 'string', 'max:5000'],
            'language_code' => ['nullable', 'string', 'max:20'],
            'difficulty' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', Rule::in(['draft', 'published'])],
            'metadata' => ['nullable', 'array'],
        ];
    }
}
