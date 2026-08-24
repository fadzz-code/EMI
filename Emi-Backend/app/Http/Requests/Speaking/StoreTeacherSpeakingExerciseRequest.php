<?php

namespace App\Http\Requests\Speaking;

use App\Models\MediaFile;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

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
            'template_exercise_id' => [
                'nullable',
                'uuid',
                Rule::exists('speaking_exercises', 'id')
                    ->where('status', 'published')
                    ->whereNull('classroom_id')
                    ->whereNull('deleted_at'),
            ],
            'title' => [Rule::requiredIf(fn () => ! $this->filled('template_exercise_id')), 'string', 'max:255'],
            'prompt_text' => ['nullable', 'string', 'max:5000'],
            'target_text' => [Rule::requiredIf(fn () => ! $this->filled('template_exercise_id')), 'string', 'max:5000'],
            'target_translation' => ['nullable', 'string', 'max:5000'],
            'reference_audio_media_id' => [
                'nullable',
                'uuid',
                Rule::exists('media_files', 'id')
                    ->where('purpose', 'speaking_reference_audio')
                    ->whereNull('deleted_at')
                    ->where(function ($query): void {
                        $query->where('uploaded_by', $this->user()?->id)
                            ->orWhere('visibility', 'public');
                    }),
            ],
            'language_code' => ['nullable', 'string', 'max:20'],
            'difficulty' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', Rule::in(['draft', 'published'])],
            'metadata' => ['nullable', 'array'],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            if (! $this->filled('reference_audio_media_id')) {
                return;
            }

            $media = MediaFile::query()->find($this->input('reference_audio_media_id'));

            if ($media && ! str_starts_with($media->mime_type, 'audio/')) {
                $validator->errors()->add('reference_audio_media_id', 'Media referensi harus berupa audio.');
            }
        }];
    }
}
