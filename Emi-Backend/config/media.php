<?php

return [
    'public_disk' => env('MEDIA_PUBLIC_DISK', 'public'),
    'private_disk' => env('MEDIA_PRIVATE_DISK', 'local'),
    'signed_url_ttl_minutes' => (int) env('MEDIA_SIGNED_URL_TTL_MINUTES', 15),

    'max_kb' => [
        'image' => (int) env('MEDIA_MAX_IMAGE_KB', 5120),
        'document' => (int) env('MEDIA_MAX_DOCUMENT_KB', 25600),
        'audio' => (int) env('MEDIA_MAX_AUDIO_KB', 30720),
    ],

    'purposes' => [
        'avatar',
        'question_image',
        'lesson_image',
        'culture_media',
        'document',
        'audio',
        'speaking_recording',
    ],

    'visibilities' => [
        'public',
        'private',
    ],

    'allowed_mimes' => [
        'avatar' => [
            'image/jpeg',
            'image/png',
            'image/webp',
        ],
        'question_image' => [
            'image/jpeg',
            'image/png',
            'image/webp',
        ],
        'lesson_image' => [
            'image/jpeg',
            'image/png',
            'image/webp',
        ],
        'culture_media' => [
            'image/jpeg',
            'image/png',
            'image/webp',
            'application/pdf',
            'audio/mpeg',
            'audio/wav',
            'audio/x-wav',
            'audio/mp4',
            'audio/ogg',
            'audio/webm',
        ],
        'document' => [
            'application/pdf',
        ],
        'audio' => [
            'audio/mpeg',
            'audio/wav',
            'audio/x-wav',
            'audio/mp4',
            'audio/ogg',
            'audio/webm',
        ],
        'speaking_recording' => [
            'audio/mpeg',
            'audio/wav',
            'audio/x-wav',
            'audio/mp4',
            'audio/ogg',
            'audio/webm',
        ],
    ],

    'extensions' => [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        'application/pdf' => 'pdf',
        'audio/mpeg' => 'mp3',
        'audio/wav' => 'wav',
        'audio/x-wav' => 'wav',
        'audio/mp4' => 'm4a',
        'audio/ogg' => 'ogg',
        'audio/webm' => 'webm',
    ],
];
