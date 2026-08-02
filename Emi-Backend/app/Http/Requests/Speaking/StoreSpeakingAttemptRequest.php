<?php

namespace App\Http\Requests\Speaking;

use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\UploadedFile;
use Illuminate\Validation\Rule;

class StoreSpeakingAttemptRequest extends FormRequest
{
    private const ALLOWED_MIME_TYPES = [
        'audio/webm',
        'video/webm',
        'audio/wav',
        'audio/x-wav',
        'audio/mpeg',
        'audio/mp4',
        'video/mp4',
        'application/mp4',
        'audio/m4a',
        'audio/ogg',
    ];

    private const SAFE_EXTENSIONS = [
        'webm',
        'wav',
        'mp3',
        'm4a',
        'mp4',
        'mpeg',
        'mpga',
        'ogg',
        'oga',
    ];

    public function authorize(): bool
    {
        return $this->user()?->role === 'student';
    }

    public function rules(): array
    {
        $maxKb = (int) config('speaking.max_audio_mb', 5) * 1024;

        return [
            'file' => ['required', 'file', 'max:'.$maxKb, $this->audioFileRule()],
            'audio_duration_seconds' => ['nullable', 'integer', 'min:1', 'max:'.(int) config('speaking.max_duration_seconds', 30)],
            'capture_source' => ['sometimes', 'string', Rule::in([
                'web_microphone',
                'web_esp32_serial',
                'mobile_microphone',
                'mobile_esp32_bluetooth',
            ])],
        ];
    }

    public function messages(): array
    {
        return [
            'file.required' => 'Audio wajib diunggah.',
            'file.file' => 'Audio wajib berupa file.',
            'file.max' => 'Ukuran audio melebihi batas yang diizinkan.',
        ];
    }

    private function audioFileRule(): Closure
    {
        return function (string $attribute, mixed $value, Closure $fail): void {
            if (! $value instanceof UploadedFile) {
                return;
            }

            $mimeType = strtolower((string) $value->getMimeType());
            $extension = strtolower($value->getClientOriginalExtension());

            if (in_array($mimeType, self::ALLOWED_MIME_TYPES, true)) {
                return;
            }

            if ($mimeType === 'application/octet-stream' && in_array($extension, self::SAFE_EXTENSIONS, true)) {
                return;
            }

            $fail('Format audio tidak didukung. Gunakan rekaman dari browser atau file audio webm, wav, mp3, m4a, atau mp4.');
        };
    }
}
