<?php

namespace Tests\Feature;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportError;
use App\Models\DictionaryImportJob;
use App\Models\DictionarySentenceExample;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Tests\TestCase;
use ZipArchive;

class DictionaryExcelImportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('local');
        Storage::fake('public');
        config([
            'dictionary.import_disk' => 'local',
            'dictionary.max_csv_kb' => 10240,
            'dictionary.max_xlsx_kb' => 20480,
            'dictionary.max_zip_kb' => 256000,
            'dictionary.max_rows' => 10000,
            'dictionary.max_audio_files' => 10000,
            'dictionary.max_uncompressed_kb' => 512000,
            'dictionary.chunk_size' => 2,
            'media.public_disk' => 'public',
            'media.private_disk' => 'local',
        ]);
    }

    public function test_xlsx_template_is_downloadable_with_two_sheets(): void
    {
        $admin = User::factory()->admin()->create();

        $response = $this->withToken($this->tokenFor($admin))
            ->get('/api/v1/admin/dictionary/imports/xlsx-template')
            ->assertOk();

        $this->assertSame(
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            $response->headers->get('Content-Type'),
        );
        $this->assertStringContainsString('.xlsx', (string) $response->headers->get('Content-Disposition'));
        $this->assertGreaterThan(1000, strlen($response->getContent()));
    }

    public function test_template_has_hidden_category_range_and_no_instructional_data_row(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $response = $this->withToken($this->tokenFor($admin))->get('/api/v1/admin/dictionary/imports/xlsx-template')->assertOk();
        $spreadsheet = IOFactory::load($this->temporaryFile($response->getContent()));

        $this->assertSame('hidden', $spreadsheet->getSheetByName('Daftar Kategori')->getSheetState());
        $this->assertNotNull($spreadsheet->getNamedRange('KategoriKamus'));
        $this->assertSame('KategoriKamus', $spreadsheet->getSheetByName('Kosakata')->getCell('D2')->getDataValidation()->getFormula1());
        $this->assertNull($spreadsheet->getSheetByName('Contoh Kalimat')->getCell('A5')->getValue());
    }

    public function test_xlsx_and_csv_import_types_cannot_be_mismatched(): void
    {
        $admin = User::factory()->admin()->create();

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([], []),
            'import_type' => 'vocabulary',
        ])->assertUnprocessable()->assertJsonValidationErrors('import_type');

        $csv = UploadedFile::fake()->createWithContent('kamus.csv', "kode,indonesia,english,mekongga,kategori,audio_filename\n");
        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $csv,
            'import_type' => 'combined',
        ])->assertUnprocessable()->assertJsonValidationErrors('import_type');
    }

    public function test_ambiguous_mekongga_link_is_rejected(): void
    {
        $admin = User::factory()->admin()->create();
        $category = DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        foreach (['Makan', 'Santap'] as $indonesia) {
            DictionaryEntry::factory()->create(['category_id' => $category->id, 'indonesia' => $indonesia, 'indonesia_normalized' => mb_strtolower($indonesia), 'mekongga' => 'Monga', 'mekongga_normalized' => 'monga', 'created_by' => $admin->id]);
        }

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([], [['Saya makan', 'Inoi monga', 'Monga']]),
        ])->assertCreated();

        $this->assertDatabaseHas('dictionary_import_errors', ['import_job_id' => $response->json('data.id'), 'code' => 'AMBIGUOUS_RELATED_MEKONGGA']);
    }

    public function test_nonblank_extra_workbook_column_is_rejected_and_preview_files_are_cleaned(): void
    {
        $admin = User::factory()->admin()->create();
        $workbook = $this->buildWorkbook([['Makan', 'Monga', 'Eat', 'Verba', '', 'Tidak boleh']], []);

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])
            ->assertUnprocessable()->assertJsonPath('code', 'INVALID_XLSX_EXTRA_COLUMNS');

        $this->assertSame(0, DictionaryImportJob::query()->count());
        $this->assertSame([], Storage::disk('local')->allFiles('dictionary/imports'));
    }

    public function test_teacher_cannot_download_xlsx_template(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();

        $this->withToken($this->tokenFor($teacher))
            ->get('/api/v1/admin/dictionary/imports/xlsx-template')
            ->assertForbidden();
    }

    public function test_combined_workbook_preview_and_confirm_imports_vocabulary_and_linked_sentences(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $workbook = $this->buildWorkbook(
            [['Makan', 'Monga', 'Eat', 'Verba', '']],
            [['Saya sedang makan nasi', 'Inoi monga kade', 'Monga']],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $jobId = $preview->json('data.id');
        $this->assertSame('combined', $preview->json('data.import_type'));
        $this->assertSame('xlsx', $preview->json('data.source_format'));
        $this->assertSame(2, DictionaryImportJob::query()->findOrFail($jobId)->valid_rows);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")
            ->assertStatus(202);

        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $job = DictionaryImportJob::query()->findOrFail($jobId);
        $this->assertSame('completed', $job->status);
        $this->assertSame(2, $job->inserted_rows);

        $entry = DictionaryEntry::query()->where('mekongga_normalized', 'monga')->firstOrFail();
        $this->assertSame('makan', $entry->indonesia_normalized);

        $sentence = DictionarySentenceExample::query()->where('dictionary_entry_id', $entry->id)->firstOrFail();
        $this->assertSame('inoi monga kade', $sentence->example_mekongga_normalized);
    }

    public function test_combined_workbook_reports_unmatched_sentence_row_as_validation_error_without_aborting_others(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $workbook = $this->buildWorkbook(
            [['Makan', 'Monga', 'Eat', 'Verba', '']],
            [
                ['Saya sedang makan nasi', 'Inoi monga kade', 'Monga'],
                ['Kalimat tanpa kata terkait', 'Contoh tak dikenal', 'TidakAda'],
            ],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $jobId = $preview->json('data.id');
        $job = DictionaryImportJob::query()->findOrFail($jobId);

        $this->assertSame(2, $job->valid_rows);
        $this->assertSame(1, $job->invalid_rows);

        $errors = $this->withToken($this->tokenFor($admin))
            ->getJson("/api/v1/admin/dictionary/imports/{$jobId}/errors")
            ->assertOk()
            ->json('data');

        $this->assertNotEmpty(array_filter($errors, fn ($error) => $error['code'] === 'RELATED_MEKONGGA_NOT_FOUND'));
    }

    public function test_combined_workbook_rejects_invalid_category_but_continues_other_rows(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $workbook = $this->buildWorkbook(
            [
                ['Makan', 'Monga', 'Eat', 'Verba', ''],
                ['Air', 'Aiwoi', 'Water', 'KategoriTidakAda', ''],
            ],
            [['Saya sedang makan nasi', 'Inoi monga kade', 'Monga']],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $job = DictionaryImportJob::query()->findOrFail($preview->json('data.id'));
        $this->assertSame(2, $job->valid_rows);
        $this->assertSame(1, $job->invalid_rows);
    }

    public function test_combined_workbook_can_link_to_an_already_existing_dictionary_entry(): void
    {
        $admin = User::factory()->admin()->create();
        $category = DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        DictionaryEntry::factory()->create([
            'category_id' => $category->id,
            'indonesia' => 'Air',
            'english' => 'Water',
            'mekongga' => 'Aiwoi',
            'indonesia_normalized' => 'air',
            'english_normalized' => 'water',
            'mekongga_normalized' => 'aiwoi',
            'created_by' => $admin->id,
        ]);

        $workbook = $this->buildWorkbook(
            [],
            [['Air di rumah', 'Aiwoi i laika', 'Aiwoi']],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $jobId = $preview->json('data.id');
        $job = DictionaryImportJob::query()->findOrFail($jobId);
        $this->assertSame(1, $job->valid_rows);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $this->assertDatabaseHas('dictionary_sentence_examples', [
            'example_mekongga_normalized' => 'aiwoi i laika',
        ]);
    }

    public function test_blank_audio_resolves_canonical_mekongga_filename_and_reports_audio_summary(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([['Makan', 'Mo-Ng_Ga!', 'Eat', 'Verba', '']], []),
            'audio_zip' => $this->zipFile(['mo ng.ga.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024)]),
        ])->assertCreated();

        $response->assertJsonPath('data.summary.audio.files_found', 1)
            ->assertJsonPath('data.summary.audio.matched', 1)
            ->assertJsonPath('data.summary.audio.missing', 0)
            ->assertJsonPath('data.summary.audio.ambiguous', 0)
            ->assertJsonPath('data.summary.audio.unused', 0);

        $jobId = $response->json('data.id');
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")->assertAccepted();
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);
        $this->assertSame(1, DictionaryImportJob::query()->findOrFail($jobId)->summary['audio']['installed']);
    }

    public function test_automatic_audio_match_is_deterministically_ambiguous_without_guessing(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([['Makan', 'Mo Ng_a!', 'Eat', 'Verba', '']], []),
            'audio_zip' => $this->zipFile([
                'MO-NGA.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
                'mo.ng a.MP3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
            ]),
        ])->assertCreated();

        $response->assertJsonPath('data.summary.audio.matched', 0)
            ->assertJsonPath('data.summary.audio.ambiguous', 1)
            ->assertJsonPath('data.summary.audio.unused', 2);
        $this->assertDatabaseHas('dictionary_import_errors', [
            'import_job_id' => $response->json('data.id'),
            'code' => 'AUDIO_AUTO_AMBIGUOUS',
        ]);
    }

    public function test_history_and_job_scoped_errors_require_confirmation_and_active_history_is_denied(): void
    {
        $admin = User::factory()->admin()->create();
        $job = DictionaryImportJob::factory()->create(['uploaded_by' => $admin->id, 'status' => 'preview_ready']);
        $error = DictionaryImportError::factory()->create(['import_job_id' => $job->id]);

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}/errors/{$error->id}")->assertUnprocessable();
        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}/errors/{$error->id}", ['confirm' => true])->assertOk();
        $this->assertDatabaseMissing('dictionary_import_errors', ['id' => $error->id]);

        foreach (['previewing', 'queued', 'processing'] as $status) {
            $job->update(['status' => $status]);
            $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}", ['confirm' => true])
                ->assertConflict()->assertJsonPath('code', 'ACTIVE_IMPORT_CANNOT_BE_DELETED');
            $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}/errors", ['confirm' => true])
                ->assertConflict()->assertJsonPath('code', 'ACTIVE_IMPORT_CANNOT_BE_DELETED');
        }
    }

    public function test_invalid_xlsx_sheet_names_are_rejected_with_clear_message(): void
    {
        $admin = User::factory()->admin()->create();

        $spreadsheet = new Spreadsheet;
        $spreadsheet->getActiveSheet()->setTitle('SheetSalah');
        $spreadsheet->getActiveSheet()->setCellValue('A1', 'Kolom');
        $writer = new Xlsx($spreadsheet);
        ob_start();
        $writer->save('php://output');
        $bytes = ob_get_clean();
        $path = tempnam(sys_get_temp_dir(), 'emi_bad_xlsx_');
        file_put_contents($path, $bytes);
        $file = new UploadedFile($path, 'salah.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', null, true);

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $file,
        ])->assertUnprocessable()
            ->assertJsonPath('code', 'INVALID_XLSX_SHEETS');
    }

    /**
     * @param  array<int, array{0: string, 1: string, 2: string, 3: string, 4: string}>  $vocabularyRows
     * @param  array<int, array{0: string, 1: string, 2: string}>  $sentenceRows
     */
    private function buildWorkbook(array $vocabularyRows, array $sentenceRows): UploadedFile
    {
        $spreadsheet = new Spreadsheet;
        $spreadsheet->removeSheetByIndex(0);

        $vocabSheet = $spreadsheet->createSheet();
        $vocabSheet->setTitle('Kosakata');
        $vocabSheet->fromArray(['Indonesia', 'Mekongga', 'Inggris', 'Kategori', 'Audio (opsional)'], null, 'A1');
        foreach ($vocabularyRows as $index => $row) {
            $vocabSheet->fromArray($row, null, 'A'.($index + 2));
        }

        $sentenceSheet = $spreadsheet->createSheet();
        $sentenceSheet->setTitle('Contoh Kalimat');
        $sentenceSheet->fromArray(['Bahasa Indonesia', 'Bahasa Mekongga', 'Kata Mekongga Terkait'], null, 'A1');
        foreach ($sentenceRows as $index => $row) {
            $sentenceSheet->fromArray($row, null, 'A'.($index + 2));
        }

        $writer = new Xlsx($spreadsheet);
        ob_start();
        $writer->save('php://output');
        $bytes = ob_get_clean();
        $path = tempnam(sys_get_temp_dir(), 'emi_xlsx_');
        file_put_contents($path, $bytes);

        return new UploadedFile($path, 'kamus.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', null, true);
    }

    private function zipFile(array $files): UploadedFile
    {
        $path = tempnam(sys_get_temp_dir(), 'emi_zip_');
        $zip = new ZipArchive;
        $zip->open($path, ZipArchive::OVERWRITE);
        foreach ($files as $name => $content) {
            $zip->addFromString($name, $content);
        }
        $zip->close();

        return new UploadedFile($path, 'audio.zip', 'application/zip', null, true);
    }

    private function temporaryFile(string $contents): string
    {
        $path = tempnam(sys_get_temp_dir(), 'emi_xlsx_read_');
        file_put_contents($path, $contents);

        return $path;
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
