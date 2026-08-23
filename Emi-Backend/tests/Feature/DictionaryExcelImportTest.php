<?php

namespace Tests\Feature;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportError;
use App\Models\DictionaryImportJob;
use App\Models\DictionarySentenceExample;
use App\Models\MediaFile;
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

    public function test_source_size_limits_use_extension_specific_config(): void
    {
        $admin = User::factory()->admin()->create();
        config(['dictionary.max_csv_kb' => 1, 'dictionary.max_xlsx_kb' => 2]);

        foreach ([['csv', 2, 1], ['xlsx', 3, 2]] as [$extension, $size, $limit]) {
            $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
                'csv_file' => UploadedFile::fake()->create("kamus.{$extension}", $size),
            ])->assertUnprocessable()
                ->assertJsonValidationErrors('csv_file')
                ->assertJsonPath('errors.csv_file.0', "Ukuran file {$extension} maksimal {$limit} KB.");
        }
    }

    public function test_ambiguous_related_indonesia_link_is_rejected(): void
    {
        $admin = User::factory()->admin()->create();
        $category = DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        foreach (['Monga', 'Mongaa'] as $mekongga) {
            DictionaryEntry::factory()->create(['category_id' => $category->id, 'indonesia' => 'Makan', 'indonesia_normalized' => 'makan', 'mekongga' => $mekongga, 'mekongga_normalized' => mb_strtolower($mekongga), 'created_by' => $admin->id]);
        }

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([], [['Makan', '', 'Saya makan', 'Inoi monga', '']]),
        ])->assertCreated();

        $this->assertDatabaseHas('dictionary_import_errors', ['import_job_id' => $response->json('data.id'), 'code' => 'AMBIGUOUS_RELATED_INDONESIA']);
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
            [['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', '']],
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

    public function test_combined_workbook_indonesia_only_rows_do_not_require_optional_fields(): void
    {
        $admin = User::factory()->admin()->create();

        $workbook = $this->buildWorkbook(
            [
                ['Makan', '', '', '', ''],
                ['Minum', '', '', '', ''],
                ['Tidur', '', '', '', ''],
                ['Ada', '', '', '', ''],
            ],
            [],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $jobId = $preview->json('data.id');
        $job = DictionaryImportJob::query()->findOrFail($jobId);
        $this->assertSame(4, $job->valid_rows);
        $this->assertSame(0, $job->invalid_rows);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $job->refresh();
        $this->assertSame('completed', $job->status);
        $this->assertSame(4, $job->inserted_rows);

        foreach (['makan', 'minum', 'tidur', 'ada'] as $normalized) {
            $entry = DictionaryEntry::query()->where('indonesia_normalized', $normalized)->where('status', 'active')->firstOrFail();
            $this->assertSame('', $entry->mekongga);
            $this->assertSame('', $entry->english);
            $this->assertNull($entry->category_id);
            $this->assertNull($entry->audio_media_id);
        }
    }

    public function test_legacy_sentence_headers_and_multiple_exact_mekongga_relations_are_supported(): void
    {
        $admin = User::factory()->admin()->create();
        $workbook = $this->buildWorkbook(
            [['Makan', 'dahu', '', '', ''], ['Minum', 'mosoko', '', '', '']],
            [['Saya makan dan minum', 'Dahu mosoko', 'dahu, mosoko']],
            true,
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();
        $job = DictionaryImportJob::query()->findOrFail($preview->json('data.id'));

        $this->assertSame(4, $job->valid_rows);
        $this->assertSame(0, $job->invalid_rows);
        $this->assertSame(2, $job->summary['sentence_examples']['valid_rows']);
    }

    public function test_processing_resolves_final_sentence_identity_after_pending_vocabulary_mapping(): void
    {
        $admin = User::factory()->admin()->create();
        $entry = DictionaryEntry::factory()->create([
            'indonesia' => 'Makan',
            'indonesia_normalized' => 'makan',
            'mekongga' => 'mongga',
            'mekongga_normalized' => 'mongga',
            'created_by' => $admin->id,
        ]);
        $sentence = DictionarySentenceExample::query()->create([
            'dictionary_entry_id' => $entry->id,
            'code' => 'SENTENCE-1',
            'example_indonesia' => 'Saya sedang makan nasi di dapur',
            'example_indonesia_normalized' => 'saya sedang makan nasi di dapur',
            'example_mekongga' => 'Teks lama',
            'example_mekongga_normalized' => 'teks lama',
            'status' => 'active',
            'created_by' => $admin->id,
        ]);
        $workbook = $this->buildWorkbook(
            [['Makan', 'mongga', '', '', '']],
            [['Saya sedang makan nasi di dapur', '', 'mongga']],
            true,
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
            'duplicate_strategy' => 'update',
        ])->assertCreated();
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertAccepted();
        $this->artisan('queue:work', ['--once' => true]);

        $job = DictionaryImportJob::query()->findOrFail($preview->json('data.id'));
        $this->assertSame('completed', $job->status);
        $this->assertSame(1, DictionarySentenceExample::query()->where('dictionary_entry_id', $entry->id)->where('example_indonesia_normalized', 'saya sedang makan nasi di dapur')->count());
        $this->assertSame('Teks lama', $sentence->refresh()->example_mekongga);
    }

    public function test_processing_sentence_identity_collision_keeps_partial_success(): void
    {
        $admin = User::factory()->admin()->create();
        $entry = DictionaryEntry::factory()->create(['indonesia' => 'Makan', 'indonesia_normalized' => 'makan', 'mekongga' => 'mongga', 'mekongga_normalized' => 'mongga', 'created_by' => $admin->id]);
        DictionarySentenceExample::query()->create([
            'dictionary_entry_id' => $entry->id,
            'code' => 'SENTENCE-1',
            'example_indonesia' => 'Saya makan',
            'example_indonesia_normalized' => 'saya makan',
            'example_mekongga' => '',
            'example_mekongga_normalized' => '',
            'status' => 'active',
            'created_by' => $admin->id,
        ]);
        $workbook = $this->buildWorkbook(
            [['Makan', 'mongga', 'Eat', '', ''], ['Minum', 'mosoko', '', '', '']],
            [['Saya makan', '', 'mongga'], ['Tidak valid', '', 'tidak-ada']],
            true,
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook, 'duplicate_strategy' => 'update'])->assertCreated();
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertAccepted();
        $this->artisan('queue:work', ['--once' => true]);

        $job = DictionaryImportJob::query()->findOrFail($preview->json('data.id'));
        $this->assertSame('completed_with_errors', $job->status);
        $this->assertDatabaseHas('dictionary_entries', ['indonesia_normalized' => 'minum', 'mekongga_normalized' => 'mosoko']);
        $this->assertSame(1, DictionarySentenceExample::query()->where('dictionary_entry_id', $entry->id)->where('example_indonesia_normalized', 'saya makan')->count());
    }

    public function test_legacy_unresolved_relation_and_unknown_category_are_partial_success_warnings(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Frase Kata Benda']);
        $workbook = $this->buildWorkbook(
            [['Makan', 'dahu', '', 'frasa kata benda', ''], ['Minum', 'mosoko', '', 'Tidak Dikenal', '']],
            [['Valid', 'Dahu', 'dahu'], ['Invalid', 'X', 'tidak-ada']],
            true,
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();
        $job = DictionaryImportJob::query()->findOrFail($preview->json('data.id'));

        $this->assertSame(3, $job->valid_rows);
        $this->assertSame(1, $job->invalid_rows);
        $this->assertSame(1, $job->summary['vocabulary']['categories_normalized']);
        $this->assertSame(1, $job->summary['vocabulary']['unknown_categories']);
        $this->assertDatabaseHas('dictionary_import_errors', ['import_job_id' => $job->id, 'code' => 'LEGACY_MEKONGGA_RELATION_NOT_FOUND']);
        $this->assertDatabaseHas('dictionary_import_errors', ['import_job_id' => $job->id, 'code' => 'WARNING_UNKNOWN_CATEGORY']);
    }

    public function test_legacy_ambiguous_mekongga_relation_does_not_choose_randomly(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryEntry::factory()->count(2)->create(['mekongga' => 'dahu', 'mekongga_normalized' => 'dahu', 'status' => 'active']);

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([], [['Kalimat', 'Dahu', 'dahu']], true),
        ])->assertCreated();

        $this->assertSame(0, $preview->json('data.valid_rows'));
        $this->assertDatabaseHas('dictionary_import_errors', ['import_job_id' => $preview->json('data.id'), 'code' => 'AMBIGUOUS_LEGACY_MEKONGGA_RELATION']);
    }

    public function test_combined_workbook_reports_unmatched_sentence_row_as_validation_error_without_aborting_others(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $workbook = $this->buildWorkbook(
            [['Makan', 'Monga', 'Eat', 'Verba', '']],
            [
                ['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', ''],
                ['TidakAda', '', 'Kalimat tanpa kata terkait', 'Contoh tak dikenal', ''],
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

        $this->assertNotEmpty(array_filter($errors, fn ($error) => $error['code'] === 'RELATED_INDONESIA_NOT_FOUND'));
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
            [['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', '']],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $job = DictionaryImportJob::query()->findOrFail($preview->json('data.id'));
        $this->assertSame(3, $job->valid_rows);
        $this->assertSame(0, $job->invalid_rows);
        $this->assertSame(1, $job->summary['vocabulary']['unknown_categories']);
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
            [['Air', '', 'Air di rumah', 'Aiwoi i laika', '']],
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

    public function test_blank_audio_without_zip_does_not_create_audio_warning(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([['Makan', 'Monga', 'Eat', 'Verba', '']], []),
        ])->assertCreated();

        $response->assertJsonPath('data.warning_count', 0)
            ->assertJsonPath('data.summary.audio.files_found', 0)
            ->assertJsonPath('data.summary.audio.matched', 0)
            ->assertJsonPath('data.summary.audio.missing', 0);
        $this->assertDatabaseMissing('dictionary_import_errors', [
            'import_job_id' => $response->json('data.id'),
            'code' => 'AUDIO_AUTO_NOT_FOUND',
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

    public function test_combined_workbook_progressively_enriches_existing_entry_without_erasing_blank_cells(): void
    {
        $admin = User::factory()->admin()->create();
        $category = DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        DictionaryEntry::factory()->create([
            'category_id' => $category->id,
            'indonesia' => 'Makan',
            'english' => 'Eat',
            'mekongga' => 'Monga',
            'indonesia_normalized' => 'makan',
            'english_normalized' => 'eat',
            'mekongga_normalized' => 'monga',
            'created_by' => $admin->id,
        ]);

        $workbook = $this->buildWorkbook([['Makan', '', '', 'Verba', '']], []);

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entry = DictionaryEntry::query()->where('indonesia_normalized', 'makan')->firstOrFail();
        $this->assertSame('Eat', $entry->english);
        $this->assertSame('Monga', $entry->mekongga);
        $this->assertSame($category->id, $entry->category_id);
    }

    public function test_combined_workbook_blank_audio_without_zip_keeps_existing_audio(): void
    {
        $admin = User::factory()->admin()->create();
        $category = DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        $media = MediaFile::factory()->audio()->create(['uploaded_by' => $admin->id]);
        DictionaryEntry::factory()->create([
            'category_id' => $category->id,
            'indonesia' => 'Makan',
            'english' => 'Eat',
            'mekongga' => 'Monga',
            'indonesia_normalized' => 'makan',
            'english_normalized' => 'eat',
            'mekongga_normalized' => 'monga',
            'audio_media_id' => $media->id,
            'created_by' => $admin->id,
        ]);

        $workbook = $this->buildWorkbook([['Makan', '', '', 'Verba', '']], []);

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entry = DictionaryEntry::query()->where('indonesia_normalized', 'makan')->firstOrFail();
        $this->assertSame($media->id, $entry->audio_media_id);
    }

    public function test_combined_workbook_sentence_audio_is_explicit_only_and_never_cross_attaches_vocab_audio(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $workbook = $this->buildWorkbook(
            [['Makan', 'Monga', 'Eat', 'Verba', 'monga.mp3']],
            [['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', '']],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
            'audio_zip' => $this->zipFile(['monga.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024)]),
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entry = DictionaryEntry::query()->where('indonesia_normalized', 'makan')->firstOrFail();
        $sentence = DictionarySentenceExample::query()->where('dictionary_entry_id', $entry->id)->firstOrFail();

        $this->assertNotNull($entry->audio_media_id);
        $this->assertNull($sentence->audio_media_id);
    }

    public function test_combined_workbook_sentence_explicit_audio_is_attached_to_sentence(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $workbook = $this->buildWorkbook(
            [['Makan', 'Monga', 'Eat', 'Verba', '']],
            [['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', 'kalimat.mp3']],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
            'audio_zip' => $this->zipFile(['kalimat.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024)]),
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entry = DictionaryEntry::query()->where('indonesia_normalized', 'makan')->firstOrFail();
        $sentence = DictionarySentenceExample::query()->where('dictionary_entry_id', $entry->id)->firstOrFail();

        $this->assertNull($entry->audio_media_id);
        $this->assertNotNull($sentence->audio_media_id);
    }

    public function test_combined_workbook_audio_priority_prefers_indonesia_then_mekongga_then_english(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([['Makan', 'Monga', 'Eat', 'Verba', '']], []),
            'audio_zip' => $this->zipFile([
                'makan.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
                'monga.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
                'eat.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
            ]),
        ])->assertCreated();

        $response->assertJsonPath('data.summary.audio.matched', 1)
            ->assertJsonPath('data.summary.audio.ambiguous', 0);

        $errors = $this->withToken($this->tokenFor($admin))
            ->getJson("/api/v1/admin/dictionary/imports/{$response->json('data.id')}/errors")
            ->assertOk()
            ->json('data');
        $this->assertEmpty(array_filter($errors, fn ($error) => in_array($error['code'], ['AUDIO_AUTO_AMBIGUOUS', 'AUDIO_AUTO_NOT_FOUND'], true)));

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$response->json('data.id')}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entry = DictionaryEntry::query()->where('indonesia_normalized', 'makan')->firstOrFail();
        $this->assertNotNull($entry->audio_media_id);
    }

    public function test_combined_workbook_explicit_audio_filename_wins_over_automatic_candidate(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->buildWorkbook([['Makan', 'Monga', 'Eat', 'Verba', 'suara-makan-final.mp3']], []),
            'audio_zip' => $this->zipFile([
                'makan.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
                'suara-makan-final.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
            ]),
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$response->json('data.id')}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entry = DictionaryEntry::query()->where('indonesia_normalized', 'makan')->firstOrFail();
        $this->assertNotNull($entry->audio_media_id);
        $this->assertSame('suara-makan-final.mp3', $entry->audioMedia->original_name);
    }

    public function test_combined_workbook_long_text_beyond_255_characters_is_supported(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $longIndonesia = 'Makan '.str_repeat('kata', 80);
        $longMekongga = 'Monga '.str_repeat('ina', 80);

        $workbook = $this->buildWorkbook(
            [[$longIndonesia, $longMekongga, 'Eat', 'Verba', '']],
            [[$longIndonesia, '', 'Saya sedang makan '.str_repeat('nasi', 80), 'Inoi monga kade', '']],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entry = DictionaryEntry::query()->where('indonesia_normalized', mb_strtolower($longIndonesia))->firstOrFail();
        $this->assertGreaterThan(255, strlen($entry->indonesia));
        $sentence = DictionarySentenceExample::query()->where('dictionary_entry_id', $entry->id)->firstOrFail();
        $this->assertGreaterThan(255, strlen($sentence->example_indonesia));
    }

    public function test_combined_workbook_identical_sentence_pair_in_workbook_is_merged_without_duplicate_insert(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $workbook = $this->buildWorkbook(
            [['Makan', 'Monga', 'Eat', 'Verba', '']],
            [
                ['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', ''],
                ['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', ''],
            ],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $job = DictionaryImportJob::query()->findOrFail($preview->json('data.id'));
        $this->assertSame(2, $job->valid_rows);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$job->id}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entry = DictionaryEntry::query()->where('indonesia_normalized', 'makan')->firstOrFail();
        $this->assertSame(1, DictionarySentenceExample::query()->where('dictionary_entry_id', $entry->id)->count());
    }

    public function test_combined_workbook_duplicate_indonesia_rows_merge_with_later_nonempty_wins(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $workbook = $this->buildWorkbook(
            [
                ['Makan', 'Monga', '', '', ''],
                ['Makan', 'Monga', 'Eat', 'Verba', ''],
            ],
            [['Makan', '', 'Saya sedang makan nasi', 'Inoi monga kade', '']],
        );

        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $job = DictionaryImportJob::query()->findOrFail($preview->json('data.id'));
        $this->assertSame(2, $job->valid_rows);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/dictionary/imports/{$job->id}/confirm")
            ->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true, '--queue' => 'default']);

        $entries = DictionaryEntry::query()->where('indonesia_normalized', 'makan')->get();
        $this->assertCount(1, $entries);
        $this->assertSame('Monga', $entries->first()->mekongga);
        $this->assertSame('Eat', $entries->first()->english);
        $this->assertSame('Verba', $entries->first()->category->name);
    }

    public function test_history_and_job_scoped_errors_require_confirmation_and_active_history_is_denied(): void
    {
        $admin = User::factory()->admin()->create();
        $job = DictionaryImportJob::factory()->create(['uploaded_by' => $admin->id, 'status' => 'preview_ready']);
        $error = DictionaryImportError::factory()->create(['import_job_id' => $job->id]);

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}/errors/{$error->id}")->assertUnprocessable();
        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}/errors/{$error->id}", ['confirm' => true])->assertOk();
        $this->assertDatabaseMissing('dictionary_import_errors', ['id' => $error->id]);

        foreach (['queued', 'processing'] as $status) {
            $job->update(['status' => $status]);
            $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}", ['confirm' => true])
                ->assertConflict()->assertJsonPath('code', 'ACTIVE_IMPORT_CANNOT_BE_DELETED');
            $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}/errors", ['confirm' => true])
                ->assertConflict()->assertJsonPath('code', 'ACTIVE_IMPORT_CANNOT_BE_DELETED');
        }
    }

    public function test_stuck_previewing_history_can_be_deleted(): void
    {
        $admin = User::factory()->admin()->create();
        $job = DictionaryImportJob::factory()->create(['uploaded_by' => $admin->id, 'status' => 'previewing']);

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/imports/{$job->id}", ['confirm' => true])->assertOk();
        $this->assertDatabaseMissing('dictionary_import_jobs', ['id' => $job->id]);
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
    private function buildWorkbook(array $vocabularyRows, array $sentenceRows, bool $legacySentences = false): UploadedFile
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
        $sentenceSheet->fromArray($legacySentences
            ? ['Bahasa Indonesia', 'Bahasa Mekongga', 'Kata Mekongga Terkait']
            : ['Kata Indonesia Terkait', 'Kata Mekongga Terkait (opsional)', 'Bahasa Indonesia', 'Bahasa Mekongga', 'Audio (opsional)'], null, 'A1');
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
