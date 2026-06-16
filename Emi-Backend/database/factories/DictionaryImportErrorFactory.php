<?php

namespace Database\Factories;

use App\Models\DictionaryImportError;
use App\Models\DictionaryImportJob;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<DictionaryImportError> */
class DictionaryImportErrorFactory extends Factory
{
    protected $model = DictionaryImportError::class;

    public function definition(): array
    {
        return [
            'import_job_id' => DictionaryImportJob::factory(),
            'row_number' => 2,
            'field' => 'indonesia',
            'code' => 'REQUIRED',
            'message' => 'Kolom indonesia wajib diisi.',
            'raw_data' => [],
            'created_at' => now(),
        ];
    }
}
