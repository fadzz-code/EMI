<?php

return [
    'free_provider' => env('AI_FREE_PROVIDER', 'none'),
    'free_api_key' => env('AI_FREE_API_KEY'),
    'free_model' => env('AI_FREE_MODEL'),
    'free_timeout_seconds' => (int) env('AI_FREE_TIMEOUT_SECONDS', 8),

    'embedding' => [
        'provider' => env('AI_EMBEDDING_PROVIDER', 'none'),
        'api_key' => env('AI_EMBEDDING_API_KEY'),
        'model' => env('AI_EMBEDDING_MODEL', 'gemini-embedding-001'),
        'dimensions' => (int) env('AI_EMBEDDING_DIMENSIONS', 768),
        'timeout_seconds' => (int) env('AI_EMBEDDING_TIMEOUT_SECONDS', 10),
    ],

    'vector_retrieval' => [
        'enabled' => (bool) env('AI_VECTOR_RETRIEVAL_ENABLED', false),
        'top_k' => (int) env('AI_VECTOR_TOP_K', 5),
        'keyword_top_k' => (int) env('AI_KEYWORD_TOP_K', 5),
    ],
];
