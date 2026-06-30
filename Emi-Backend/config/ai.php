<?php

return [
    'free_provider' => env('AI_FREE_PROVIDER', 'none'),
    'free_api_key' => env('AI_FREE_API_KEY'),
    'free_model' => env('AI_FREE_MODEL'),
    'free_timeout_seconds' => (int) env('AI_FREE_TIMEOUT_SECONDS', 8),
];
