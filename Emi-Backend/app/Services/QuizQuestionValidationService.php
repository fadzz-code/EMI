<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\MediaFile;

class QuizQuestionValidationService
{
    public function validate(array $data): void
    {
        $type = $data['question_type'] ?? null;

        if (($data['image_media_id'] ?? null) !== null) {
            $media = MediaFile::query()->active()->find($data['image_media_id']);
            if (! $media || $media->purpose !== 'question_image') {
                throw new ApiException('Media gambar soal tidak valid.', 'INVALID_QUESTION_MEDIA', 422);
            }
        }

        if (($data['points'] ?? 0) < 1) {
            throw new ApiException('Poin soal tidak valid.', 'INVALID_QUESTION_TYPE', 422);
        }

        if (($data['fuzzy_threshold'] ?? null) !== null && ((int) $data['fuzzy_threshold'] < 1 || (int) $data['fuzzy_threshold'] > 100)) {
            throw new ApiException('Fuzzy threshold tidak valid.', 'INVALID_FUZZY_THRESHOLD', 422);
        }

        if ($type === 'multiple_choice') {
            $this->validateMultipleChoice($data);

            return;
        }

        if ($type === 'short_answer') {
            $this->validateShortAnswer($data);

            return;
        }

        throw new ApiException('Tipe soal tidak valid.', 'INVALID_QUESTION_TYPE', 422);
    }

    private function validateMultipleChoice(array $data): void
    {
        $options = $data['options'] ?? [];
        $correct = collect($options)->where('is_correct', true)->count();

        if (count($options) < 2 || $correct !== 1 || ($data['correct_answer_text'] ?? null) !== null || ($data['use_fuzzy_matching'] ?? false) || ($data['fuzzy_threshold'] ?? null) !== null) {
            throw new ApiException('Opsi pilihan ganda tidak valid.', 'INVALID_QUESTION_OPTIONS', 422);
        }
    }

    private function validateShortAnswer(array $data): void
    {
        if (trim((string) ($data['correct_answer_text'] ?? '')) === '' || count($data['options'] ?? []) > 0) {
            throw new ApiException('Soal isian singkat tidak valid.', 'INVALID_QUESTION_TYPE', 422);
        }
    }
}
