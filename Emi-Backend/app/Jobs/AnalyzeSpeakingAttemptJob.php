<?php

namespace App\Jobs;

use App\Exceptions\SpeakingAiException;
use App\Models\SpeakingAttempt;
use App\Services\SpeakingAiClient;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Throwable;

class AnalyzeSpeakingAttemptJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public readonly string $attemptId) {}

    public function handle(SpeakingAiClient $client): void
    {
        $attempt = SpeakingAttempt::query()->with('audioMedia')->find($this->attemptId);
        if (! $attempt) {
            return;
        }

        if (! $client->enabled()) {
            SpeakingAttempt::query()->whereKey($attempt->id)->where('status', '!=', 'reviewed')->update(['status' => 'pending']);

            return;
        }

        $started = SpeakingAttempt::query()->whereKey($attempt->id)->where('status', '!=', 'reviewed')->update(['status' => 'processing', 'ai_error' => null]);
        if (! $started) {
            return;
        }

        try {
            $result = $client->analyze($attempt->refresh()->load('audioMedia'));

            SpeakingAttempt::query()->whereKey($attempt->id)->where('status', '!=', 'reviewed')->update([
                'status' => 'completed',
                'ai_engine' => $result['engine'] ?? null,
                'ai_model' => $result['model'] ?? null,
                'ai_transcription' => $result['transcription'] ?? null,
                'ai_score' => $result['score'] ?? null,
                'ai_alignment' => isset($result['alignment']) ? json_encode($result['alignment'], JSON_THROW_ON_ERROR) : null,
                'ai_raw_response' => json_encode($result, JSON_THROW_ON_ERROR),
                'ai_error' => null,
            ]);
        } catch (Throwable $exception) {
            Log::warning('Analisis speaking gagal.', [
                'attempt_id' => $attempt->id,
                'media_id' => $attempt->audio_media_id,
                'media_disk' => $attempt->audioMedia?->disk,
                'media_path_hash' => $attempt->audioMedia ? hash('sha256', $attempt->audioMedia->path) : null,
                'exception' => $exception::class,
                'reason' => $exception->getMessage(),
            ]);
            $publicErrors = [
                'Media audio speaking tidak ditemukan.',
                'Audio speaking tidak ditemukan pada penyimpanan.',
                'Audio speaking tidak dapat dibaca.',
                'Layanan analisis speaking tidak dapat dihubungi.',
                'Autentikasi layanan analisis speaking gagal.',
                'Layanan analisis speaking melewati batas waktu.',
                'Audio speaking tidak dapat dianalisis.',
                'Layanan analisis speaking sedang tidak tersedia.',
            ];
            SpeakingAttempt::query()->whereKey($attempt->id)->where('status', '!=', 'reviewed')->update([
                'status' => 'failed',
                'ai_error' => in_array($exception->getMessage(), $publicErrors, true) ? $exception->getMessage() : 'Analisis speaking AI gagal.',
                'ai_raw_response' => json_encode(array_filter([
                    'error_code' => $exception instanceof SpeakingAiException ? $exception->errorCode : 'SPEAKING_AI_RESPONSE_INVALID',
                ]), JSON_THROW_ON_ERROR),
            ]);
        }
    }
}
