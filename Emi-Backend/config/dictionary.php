<?php

return [
    'import_disk' => env('DICTIONARY_IMPORT_DISK', 'local'),
    'max_csv_kb' => (int) env('DICTIONARY_IMPORT_MAX_CSV_KB', 10240),
    'max_zip_kb' => (int) env('DICTIONARY_IMPORT_MAX_ZIP_KB', 256000),
    'max_rows' => (int) env('DICTIONARY_IMPORT_MAX_ROWS', 10000),
    'max_audio_files' => (int) env('DICTIONARY_IMPORT_MAX_AUDIO_FILES', 10000),
    'max_uncompressed_kb' => (int) env('DICTIONARY_IMPORT_MAX_UNCOMPRESSED_KB', 512000),
    'chunk_size' => (int) env('DICTIONARY_IMPORT_CHUNK_SIZE', 500),
    'sample_limit' => 20,
    'csv_headers' => [
        'vocabulary' => [
            'kode',
            'indonesia',
            'english',
            'mekongga',
            'kategori',
            'audio_filename',
        ],
        'sentence_examples' => [
            'kode',
            'contoh_mekongga',
            'contoh_indonesia',
        ],
    ],

    'xlsx_sheets' => [
        'vocabulary' => 'Kosakata',
        'sentence_examples' => 'Contoh Kalimat',
    ],
    'xlsx_headers' => [
        'vocabulary' => [
            'Indonesia',
            'Mekongga',
            'Inggris',
            'Kategori',
            'Audio (opsional)',
        ],
        'sentence_examples' => [
            'Bahasa Indonesia',
            'Bahasa Mekongga',
            'Kata Mekongga Terkait',
        ],
    ],
    'max_xlsx_kb' => (int) env('DICTIONARY_IMPORT_MAX_XLSX_KB', 20480),
];
