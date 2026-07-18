<?php

namespace App\Jobs;

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
            $attempt->forceFill(['status' => 'pending'])->save();

            return;
        }

        $attempt->forceFill(['status' => 'processing', 'ai_error' => null])->save();

        try {
            $result = $client->analyze($attempt->refresh()->load('audioMedia'));

            $attempt->forceFill([
                'status' => 'completed',
                'ai_engine' => $result['engine'] ?? null,
                'ai_model' => $result['model'] ?? null,
                'ai_transcription' => $result['transcription'] ?? null,
                'ai_score' => $result['score'] ?? null,
                'ai_alignment' => $result['alignment'] ?? null,
                'ai_raw_response' => $result,
                'ai_error' => null,
            ])->save();
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
            $attempt->forceFill([
                'status' => 'failed',
                'ai_error' => in_array($exception->getMessage(), $publicErrors, true) ? $exception->getMessage() : 'Analisis speaking AI gagal.',
            ])->save();
        }
    }
}
