<?php

namespace Database\Factories;

use App\Models\DictionaryImportJob;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/** @extends Factory<DictionaryImportJob> */
class DictionaryImportJobFactory extends Factory
{
    protected $model = DictionaryImportJob::class;

    public function definition(): array
    {
        $id = (string) Str::uuid();

        return [
            'uploaded_by' => User::factory()->admin(),
            'status' => 'preview_ready',
            'duplicate_strategy' => 'skip',
            'csv_disk' => config('dictionary.import_disk', 'local'),
            'csv_path' => "dictionary/imports/{$id}/source.csv",
            'csv_original_name' => 'kamus.csv',
            'csv_size_bytes' => 128,
            'csv_checksum_sha256' => hash('sha256', $id.'csv'),
            'audio_zip_disk' => null,
            'audio_zip_path' => null,
            'audio_zip_original_name' => null,
            'audio_zip_size_bytes' => null,
            'audio_zip_checksum_sha256' => null,
            'total_rows' => 1,
            'valid_rows' => 1,
            'invalid_rows' => 0,
            'inserted_rows' => 0,
            'updated_rows' => 0,
            'skipped_rows' => 0,
            'warning_count' => 0,
            'summary' => [],
        ];
    }
}
