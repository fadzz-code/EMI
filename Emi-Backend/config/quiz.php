<?php

return [
    'max_duration_minutes' => (int) env('QUIZ_MAX_DURATION_MINUTES', 240),
    'max_attempts' => (int) env('QUIZ_MAX_ATTEMPTS', 10),
    'default_fuzzy_threshold' => (int) env('QUIZ_DEFAULT_FUZZY_THRESHOLD', 85),
];
