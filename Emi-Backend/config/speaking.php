<?php

return [
    'ai' => [
        'enabled' => (bool) env('SPEAKING_AI_ENABLED', false),
        'base_url' => env('SPEAKING_AI_BASE_URL', 'http://127.0.0.1:8000'),
        'timeout_seconds' => (int) env('SPEAKING_AI_TIMEOUT_SECONDS', 60),
    ],
    'max_audio_mb' => (int) env('SPEAKING_MAX_AUDIO_MB', 5),
    'max_duration_seconds' => (int) env('SPEAKING_MAX_DURATION_SECONDS', 30),
];
