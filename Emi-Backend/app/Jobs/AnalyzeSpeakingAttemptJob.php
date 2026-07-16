<?php

namespace App\Jobs;

use App\Models\SpeakingAttempt;
use App\Services\SpeakingAiClient;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
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
        } catch (Throwable) {
            $attempt->forceFill([
                'status' => 'failed',
                'ai_error' => 'Analisis speaking AI gagal.',
            ])->save();
        }
    }
}
