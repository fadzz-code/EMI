<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class PreviewDictionaryImportRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'csv_file' => ['required', 'file', 'extensions:csv,xlsx'],
            'audio_zip' => ['sometimes', 'file', 'extensions:zip', 'max:'.config('dictionary.max_zip_kb')],
            'import_type' => ['sometimes', Rule::in(['vocabulary', 'sentence_examples', 'combined'])],
            'duplicate_strategy' => ['sometimes', Rule::in(['skip', 'update', 'reject'])],
            'csv_disk' => ['prohibited'],
            'csv_path' => ['prohibited'],
            'audio_zip_disk' => ['prohibited'],
            'audio_zip_path' => ['prohibited'],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            $file = $this->file('csv_file');
            if (! $file || ! $file->isValid()) {
                return;
            }

            $extension = mb_strtolower($file->getClientOriginalExtension());
            $importType = $this->input('import_type');
            $maxKb = (int) config($extension === 'xlsx' ? 'dictionary.max_xlsx_kb' : 'dictionary.max_csv_kb');

            if ((int) $file->getSize() > $maxKb * 1024) {
                $validator->errors()->add('csv_file', "Ukuran file {$extension} maksimal {$maxKb} KB.");
            }

            if (($extension === 'xlsx' && $importType !== null && $importType !== 'combined') || ($extension === 'csv' && $importType === 'combined')) {
                $validator->errors()->add('import_type', 'Tipe import tidak sesuai dengan format file. XLSX wajib combined dan CSV tidak boleh combined.');
            }
        }];
    }
}
