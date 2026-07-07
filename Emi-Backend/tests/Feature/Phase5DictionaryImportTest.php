<?php

namespace Tests\Feature;

use App\Jobs\ProcessDictionaryImport;
use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportJob;
use App\Models\DictionarySentenceExample;
use App\Models\MediaFile;
use App\Models\User;
use App\Services\DictionaryImportProcessingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use ZipArchive;

class Phase5DictionaryImportTest extends TestCase
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
            'dictionary.max_zip_kb' => 256000,
            'dictionary.max_rows' => 10000,
            'dictionary.max_audio_files' => 10000,
            'dictionary.max_uncompressed_kb' => 512000,
            'dictionary.chunk_size' => 2,
            'media.public_disk' => 'public',
            'media.private_disk' => 'local',
        ]);
    }

    public function test_admin_category_crud_authorization_duplicate_deactivation_visibility_and_audit(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/admin/dictionary/categories', [
            'name' => 'Verba',
        ])->assertForbidden();

        $response = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/dictionary/categories', [
            'name' => 'Verba',
            'description' => 'Kata kerja',
            'status' => 'active',
            'created_by' => $teacher->id,
            'slug' => 'custom',
        ])->assertUnprocessable();
        $this->assertArrayHasKey('created_by', $response->json('errors'));

        $category = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/dictionary/categories', [
            'name' => 'Verba',
            'description' => 'Kata kerja',
        ])->assertCreated()
            ->assertJsonPath('data.slug', 'verba')
            ->json('data');

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/dictionary/categories', ['name' => 'verba'])
            ->assertConflict()
            ->assertJsonPath('code', 'DICTIONARY_CATEGORY_DUPLICATE');

        $categoryModel = DictionaryCategory::query()->findOrFail($category['id']);
        DictionaryEntry::factory()->create(['category_id' => $categoryModel->id, 'created_by' => $admin->id]);
        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/dictionary/categories/{$categoryModel->id}", ['status' => 'inactive'])
            ->assertConflict()
            ->assertJsonPath('code', 'CATEGORY_HAS_ACTIVE_ENTRIES');

        DictionaryEntry::query()->where('category_id', $categoryModel->id)->update(['status' => 'inactive']);
        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/dictionary/categories/{$categoryModel->id}", ['status' => 'inactive'])
            ->assertOk();
        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/dictionary')->assertOk()->assertJsonPath('meta.total', 0);

        $this->assertDatabaseHas('audit_logs', ['action' => 'dictionary.category_created']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'dictionary.category_deactivated']);
    }

    public function test_dictionary_entry_crud_audio_validation_duplicate_soft_delete_and_media_usage(): void
    {
        $admin = User::factory()->admin()->create();
        $category = DictionaryCategory::factory()->create(['created_by' => $admin->id]);
        $audio = $this->uploadedMedia($admin, 'audio', $this->mp3File(), 'public');
        $privateAudio = $this->uploadedMedia($admin, 'audio', $this->mp3File('private.mp3'), 'private');
        $document = $this->uploadedMedia($admin, 'document', $this->pdfFile(), 'public');

        $entryId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/dictionary/entries', [
            'category_id' => $category->id,
            'indonesia' => '  Makan  ',
            'english' => 'Eat',
            'mekongga' => 'Monga',
            'example_mekongga' => 'Inoi monga',
            'example_indonesia' => 'Saya makan',
            'audio_media_id' => $audio->id,
            'indonesia_normalized' => 'client',
        ])->assertUnprocessable()->json('data.id');

        $entryId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/dictionary/entries', [
            'category_id' => $category->id,
            'indonesia' => '  Makan  ',
            'english' => 'Eat',
            'mekongga' => 'Monga',
            'audio_media_id' => $audio->id,
        ])->assertCreated()
            ->assertJsonPath('data.audio.id', $audio->id)
            ->assertJsonMissingPath('data.audio.path')
            ->json('data.id');

        $entry = DictionaryEntry::query()->findOrFail($entryId);
        $this->assertSame('makan', $entry->indonesia_normalized);

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/dictionary/entries', [
            'category_id' => $category->id,
            'indonesia' => 'makan',
            'english' => 'eat',
            'mekongga' => 'monga',
        ])->assertConflict()->assertJsonPath('code', 'DICTIONARY_DUPLICATE');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/dictionary/entries/{$entryId}", [
            'audio_media_id' => $privateAudio->id,
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_DICTIONARY_AUDIO');
        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/dictionary/entries/{$entryId}", [
            'audio_media_id' => $document->id,
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_DICTIONARY_AUDIO');

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/media/{$audio->id}")
            ->assertConflict()
            ->assertJsonPath('code', 'MEDIA_IN_USE');

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/dictionary/entries/{$entryId}")->assertOk();
        $this->assertSoftDeleted('dictionary_entries', ['id' => $entryId]);
        $this->assertDatabaseHas('audit_logs', ['action' => 'dictionary.entry_created']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'dictionary.entry_deleted']);
    }

    public function test_dictionary_search_scope_filters_audio_and_security(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create();
        $category = DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        $inactiveCategory = DictionaryCategory::factory()->inactive()->create(['created_by' => $admin->id]);
        $audio = $this->uploadedMedia($admin, 'audio', $this->mp3File(), 'public');
        DictionaryEntry::factory()->create([
            'category_id' => $category->id,
            'created_by' => $admin->id,
            'indonesia' => 'Makan',
            'english' => 'Eat',
            'mekongga' => 'Monga',
            'indonesia_normalized' => 'makan',
            'english_normalized' => 'eat',
            'mekongga_normalized' => 'monga',
            'audio_media_id' => $audio->id,
        ]);
        DictionaryEntry::factory()->inactive()->create(['category_id' => $category->id, 'created_by' => $admin->id]);
        DictionaryEntry::factory()->create(['category_id' => $inactiveCategory->id, 'created_by' => $admin->id]);

        $this->app['auth']->forgetGuards();
        $this->flushHeaders()->getJson('/api/v1/dictionary')->assertUnauthorized();
        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/dictionary?search=mak&language=indonesia')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonMissingPath('data.0.audio.disk')
            ->assertJsonMissingPath('data.0.audio.checksum');
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/dictionary?search=eat&language=english')->assertOk()->assertJsonPath('meta.total', 1);
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/dictionary?search=onga&language=mekongga')->assertOk()->assertJsonPath('meta.total', 1);
        $this->withToken($this->tokenFor($student))->getJson("/api/v1/dictionary?category_id={$category->id}&letter=m&per_page=1")
            ->assertOk()
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonPath('meta.total', 1);
    }

    public function test_import_preview_validates_csv_header_encoding_rows_duplicates_and_does_not_create_entries(): void
    {
        $admin = User::factory()->admin()->create();
        $category = DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        DictionaryEntry::factory()->create([
            'category_id' => $category->id,
            'created_by' => $admin->id,
            'indonesia' => 'Minum',
            'english' => 'Drink',
            'mekongga' => 'Mokale',
            'indonesia_normalized' => 'minum',
            'english_normalized' => 'drink',
            'mekongga_normalized' => 'mokale',
        ]);

        $this->withToken($this->tokenFor(User::factory()->teacher()->approved()->create()))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($this->validCsv()),
        ])->assertForbidden();

        $this->withToken($this->tokenFor($admin))->get('/api/v1/admin/dictionary/imports/template')
            ->assertOk()
            ->assertHeader('X-Content-Type-Options', 'nosniff');

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile("wrong,header\n"),
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_CSV_HEADER');
        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile("\xFF\xFE\x00"),
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_CSV_ENCODING');

        config(['dictionary.max_rows' => 1]);
        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($this->validCsv()."2,lari,run,lumaa,Verba,\n"),
        ])->assertUnprocessable()->assertJsonPath('code', 'CSV_ROW_LIMIT_EXCEEDED');
        config(['dictionary.max_rows' => 10000]);

        $csv = "\xEF\xBB\xBF".implode(',', config('dictionary.csv_headers.vocabulary'))."\n"
            ."1,makan,eat,monga,Verba,monga.mp3\n"
            ."2,,drink,mokale,Verba,missing.mp3\n"
            ."3,tidur,sleep,moleo,TidakAda,\n"
            ."4,minum,drink,mokale,Verba,\n"
            ."5,makan,eat,monga,Verba,\n";
        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($csv),
            'audio_zip' => $this->zipFile(['monga.mp3' => $this->mp3Content(), 'unused.mp3' => $this->mp3Content()]),
            'duplicate_strategy' => 'reject',
        ])->assertCreated()
            ->assertJsonPath('data.status', 'preview_ready');

        $summary = $response->json('data.summary');
        $this->assertSame(5, $summary['total_rows']);
        $this->assertSame(1, $summary['valid_rows']);
        $this->assertSame(4, $summary['invalid_rows']);
        $this->assertSame(1, $summary['unused_audio_files']);
        $this->assertSame(0, DictionaryEntry::query()->where('indonesia', 'makan')->count());
        $this->assertDatabaseHas('dictionary_import_errors', ['code' => 'AUDIO_FILE_NOT_FOUND']);
        $this->assertDatabaseHas('dictionary_import_errors', ['code' => 'CATEGORY_NOT_FOUND']);
        $this->assertDatabaseHas('dictionary_import_errors', ['code' => 'DICTIONARY_DUPLICATE']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'dictionary.import_previewed']);
    }

    public function test_client_templates_are_strictly_separated_and_download_headers_match(): void
    {
        Queue::fake();
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $vocabularyHeader = 'kode,indonesia,english,mekongga,kategori,audio_filename';
        $sentenceHeader = 'kode,contoh_mekongga,contoh_indonesia';

        $this->withToken($this->tokenFor($admin))->get('/api/v1/admin/dictionary/imports/vocabulary/template')
            ->assertOk()
            ->assertStreamedContent($vocabularyHeader."\n1,makan,eat,monga,Verba,\n2,air,water,air,Nomina,\n3,selamat,hello,ari,Sapaan,\n");

        $this->withToken($this->tokenFor($admin))->get('/api/v1/admin/dictionary/imports/sentence_examples/template')
            ->assertOk()
            ->assertStreamedContent($sentenceHeader."\n1,inoi monga kade,saya sedang makan nasi\n2,air i laika,air di rumah\n3,ari nggiro,selamat pagi\n");

        $vocabularyJob = $this->previewAndQueue($admin, $this->validCsv(''), 'skip');
        app(DictionaryImportProcessingService::class)->process($vocabularyJob->id);

        $sentenceJobId = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'import_type' => 'sentence_examples',
            'csv_file' => $this->csvFile($this->sentenceCsv()),
        ])->assertCreated()
            ->assertJsonPath('data.import_type', 'sentence_examples')
            ->assertJsonPath('data.summary.valid_rows', 1)
            ->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$sentenceJobId}/confirm")->assertStatus(202);
        app(DictionaryImportProcessingService::class)->process($sentenceJobId);
        $this->assertSame(1, DictionarySentenceExample::query()->where('example_mekongga', 'inoi monga kade')->count());

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'import_type' => 'vocabulary',
            'csv_file' => $this->csvFile($this->sentenceCsv()),
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'Template CSV tidak sesuai. Gunakan template Kosakata.');

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'import_type' => 'sentence_examples',
            'csv_file' => $this->csvFile($this->validCsv('')),
        ])->assertUnprocessable()
            ->assertJsonPath('message', 'Template CSV tidak sesuai. Gunakan template Contoh Kalimat.');

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'import_type' => 'vocabulary',
            'csv_file' => $this->csvFile($vocabularyHeader.",extra\n1,makan,eat,monga,Verba,,x\n"),
        ])->assertUnprocessable();

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'import_type' => 'sentence_examples',
            'csv_file' => $this->csvFile('contoh_mekongga,kode,contoh_indonesia'."\ninoi monga kade,1,saya sedang makan nasi\n"),
        ])->assertUnprocessable();
    }

    public function test_system_sentence_template_upload_uses_sentence_import_type(): void
    {
        Queue::fake();
        $admin = User::factory()->admin()->create();
        foreach (['Verba', 'Nomina', 'Sapaan'] as $name) {
            DictionaryCategory::factory()->create(['name' => $name, 'slug' => str($name)->lower()->toString(), 'created_by' => $admin->id]);
        }

        $vocabularyCsv = implode(',', config('dictionary.csv_headers.vocabulary'))."\n"
            ."1,makan,eat,monga,Verba,\n"
            ."2,air,water,air,Nomina,\n"
            ."3,selamat,hello,ari,Sapaan,\n";
        $vocabularyJob = $this->previewAndQueue($admin, $vocabularyCsv, 'skip');
        app(DictionaryImportProcessingService::class)->process($vocabularyJob->id);

        $sentenceCsv = implode(',', config('dictionary.csv_headers.sentence_examples'))."\n"
            ."1,inoi monga kade,saya sedang makan nasi\n"
            ."2,air i laika,air di rumah\n"
            ."3,ari nggiro,selamat pagi\n";

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'import_type' => 'sentence_examples',
            'csv_file' => $this->csvFile($sentenceCsv),
        ])->assertCreated()
            ->assertJsonPath('data.import_type', 'sentence_examples')
            ->assertJsonPath('data.summary.valid_rows', 3);
    }

    public function test_sentence_examples_attach_to_existing_dictionary_entry_by_code_and_show_in_detail(): void
    {
        Queue::fake();
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->approved()->create();
        DictionaryCategory::factory()->create(['name' => 'Sapaan', 'slug' => 'sapaan', 'created_by' => $admin->id]);

        $vocabularyJob = $this->previewAndQueue($admin, implode(',', config('dictionary.csv_headers.vocabulary'))."\nARI,selamat,hello,ari,Sapaan,\n", 'skip');
        app(DictionaryImportProcessingService::class)->process($vocabularyJob->id);
        $entry = DictionaryEntry::query()->where('code', 'ARI')->firstOrFail();

        $sentenceCsv = implode(',', config('dictionary.csv_headers.sentence_examples'))."\n"
            ."ARI,Ari nggiro,Selamat pagi\n"
            ."ARI,Ari mbule,Selamat kembali\n";
        $sentenceJob = $this->previewAndQueue($admin, $sentenceCsv, 'skip', 'sentence_examples');
        app(DictionaryImportProcessingService::class)->process($sentenceJob->id);

        $this->assertSame(1, DictionaryEntry::query()->where('code', 'ARI')->count());
        $this->assertSame(2, DictionarySentenceExample::query()->where('dictionary_entry_id', $entry->id)->count());

        $this->withToken($this->tokenFor($student))->getJson("/api/v1/dictionary/{$entry->id}")
            ->assertOk()
            ->assertJsonCount(2, 'data.sentence_examples')
            ->assertJsonFragment(['contoh_mekongga' => 'Ari nggiro', 'contoh_indonesia' => 'Selamat pagi'])
            ->assertJsonFragment(['contoh_mekongga' => 'Ari mbule', 'contoh_indonesia' => 'Selamat kembali']);
    }

    public function test_sentence_example_import_with_unknown_code_is_invalid_and_does_not_create_entry(): void
    {
        $admin = User::factory()->admin()->create();

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'import_type' => 'sentence_examples',
            'csv_file' => $this->csvFile($this->sentenceCsv('TIDAKADA')),
        ])->assertCreated()
            ->assertJsonPath('data.summary.valid_rows', 0)
            ->assertJsonPath('data.summary.invalid_rows', 1);

        $this->assertDatabaseHas('dictionary_import_errors', [
            'field' => 'kode',
            'code' => 'CODE_NOT_FOUND',
            'message' => 'Kode tidak ditemukan di kosakata. Import kosakata terlebih dahulu.',
        ]);
        $this->assertSame(0, DictionaryEntry::query()->count());
    }

    public function test_valid_csv_without_audio_zip_can_be_confirmed_and_imported_with_audio_warning(): void
    {
        Queue::fake();
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($this->validCsv()),
        ])->assertCreated()
            ->assertJsonPath('data.summary.total_rows', 1)
            ->assertJsonPath('data.summary.valid_rows', 1)
            ->assertJsonPath('data.summary.invalid_rows', 0)
            ->assertJsonPath('data.summary.warning_count', 1)
            ->assertJsonPath('data.summary.audio_missing', 1);

        $jobId = $response->json('data.id');
        $this->assertDatabaseHas('dictionary_import_errors', [
            'import_job_id' => $jobId,
            'field' => 'audio_filename',
            'code' => 'AUDIO_FILE_NOT_FOUND',
        ]);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")
            ->assertStatus(202)
            ->assertJsonPath('data.status', 'queued');
        Queue::assertPushed(ProcessDictionaryImport::class, 1);

        app(DictionaryImportProcessingService::class)->process($jobId);
        $entry = DictionaryEntry::query()->where('indonesia', 'makan')->firstOrFail();
        $this->assertNull($entry->audio_media_id);
        $this->assertSame('completed', DictionaryImportJob::query()->findOrFail($jobId)->status);
    }

    public function test_audio_exact_filename_matching_does_not_use_row_order(): void
    {
        Queue::fake();
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $job = $this->previewAndQueueWithZip($admin, $this->validCsv('makan.mp3'), [
            'urutan-pertama.mp3' => $this->mp3Content(),
            'makan.mp3' => $this->mp3Content(),
        ]);
        app(DictionaryImportProcessingService::class)->process($job->id);

        $entry = DictionaryEntry::query()->where('indonesia', 'makan')->firstOrFail();
        $this->assertNotNull($entry->audio_media_id);
        $this->assertSame('makan.mp3', $entry->audioMedia->metadata['audio_filename'] ?? null);
    }

    public function test_required_text_fields_still_make_row_invalid_even_when_audio_is_optional(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $csv = implode(',', config('dictionary.csv_headers.vocabulary'))."\n"
            ."1,,eat,monga,Verba,monga.mp3\n";

        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($csv),
        ])->assertCreated();

        $this->assertSame(0, $response->json('data.summary.valid_rows'));
        $this->assertSame(1, $response->json('data.summary.invalid_rows'));
        $this->assertDatabaseHas('dictionary_import_errors', ['code' => 'REQUIRED']);
        $this->assertDatabaseHas('dictionary_import_errors', ['code' => 'AUDIO_FILE_NOT_FOUND']);
    }

    public function test_zip_audio_security_and_exact_filename_mapping(): void
    {
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);

        $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($this->validCsv('Monga.mp3')),
            'audio_zip' => $this->zipFile(['monga.mp3' => $this->mp3Content()]),
        ])->assertCreated()->assertJsonPath('data.summary.audio_missing', 1);

        foreach ([
            '../monga.mp3' => $this->mp3Content(),
            '/monga.mp3' => $this->mp3Content(),
            'folder/monga.mp3' => $this->mp3Content(),
            'bad.zip' => 'PK',
            'bad.php' => '<?php echo 1;',
        ] as $name => $content) {
            $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
                'csv_file' => $this->csvFile($this->validCsv($name)),
                'audio_zip' => $this->zipFile([$name => $content]),
            ])->assertUnprocessable();
        }
    }

    public function test_confirm_dispatches_once_and_processing_imports_audio_entries_and_history(): void
    {
        Queue::fake();
        $admin = User::factory()->admin()->create();
        DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        $response = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($this->validCsv()),
            'audio_zip' => $this->zipFile(['monga.mp3' => $this->mp3Content()]),
        ])->assertCreated();
        $jobId = $response->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")
            ->assertStatus(202)
            ->assertJsonPath('data.status', 'queued');
        Queue::assertPushed(ProcessDictionaryImport::class, 1);
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")->assertStatus(202);
        Queue::assertPushed(ProcessDictionaryImport::class, 1);

        app(DictionaryImportProcessingService::class)->process($jobId);
        $job = DictionaryImportJob::query()->findOrFail($jobId);
        $this->assertSame('completed', $job->status);
        $this->assertSame(1, $job->inserted_rows);
        $entry = DictionaryEntry::query()->where('indonesia', 'makan')->firstOrFail();
        $this->assertNotNull($entry->audio_media_id);
        $this->assertSame('audio', $entry->audioMedia->purpose);
        $this->assertSame('public', $entry->audioMedia->visibility);

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/dictionary/imports')->assertOk()->assertJsonPath('meta.total', 1);
        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/dictionary/imports/{$jobId}")->assertOk();
        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/dictionary/imports/{$jobId}/errors")->assertOk();
        $this->withToken($this->tokenFor(User::factory()->teacher()->approved()->create()))->getJson("/api/v1/admin/dictionary/imports/{$jobId}")->assertForbidden();
        $this->assertDatabaseHas('audit_logs', ['action' => 'dictionary.import_queued']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'dictionary.import_completed']);
    }

    public function test_duplicate_strategy_skip_update_reject_and_no_valid_rows(): void
    {
        Queue::fake();
        $admin = User::factory()->admin()->create();
        $category = DictionaryCategory::factory()->create(['name' => 'Verba', 'slug' => 'verba', 'created_by' => $admin->id]);
        $otherCategory = DictionaryCategory::factory()->create(['name' => 'Nomina', 'slug' => 'nomina', 'created_by' => $admin->id]);
        $existing = DictionaryEntry::factory()->create([
            'category_id' => $category->id,
            'created_by' => $admin->id,
            'indonesia' => 'makan',
            'english' => 'eat',
            'mekongga' => 'monga',
            'indonesia_normalized' => 'makan',
            'english_normalized' => 'eat',
            'mekongga_normalized' => 'monga',
            'example_indonesia' => 'lama',
        ]);

        $skipJob = $this->previewAndQueue($admin, $this->validCsv('', 'Nomina'), 'skip');
        app(DictionaryImportProcessingService::class)->process($skipJob->id);
        $this->assertSame('lama', $existing->refresh()->example_indonesia);
        $this->assertSame(1, $skipJob->refresh()->skipped_rows);

        $updateJob = $this->previewAndQueue($admin, $this->validCsv('', 'Nomina'), 'update');
        app(DictionaryImportProcessingService::class)->process($updateJob->id);
        $this->assertSame($otherCategory->id, $existing->refresh()->category_id);

        $rejectPreview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($this->validCsv('', 'Nomina')),
            'duplicate_strategy' => 'reject',
        ])->assertCreated();
        $rejectJobId = $rejectPreview->json('data.id');
        $this->assertSame(0, DictionaryImportJob::query()->findOrFail($rejectJobId)->valid_rows);
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$rejectJobId}/confirm")
            ->assertConflict()
            ->assertJsonPath('code', 'IMPORT_HAS_NO_VALID_ROWS');
    }

    private function previewAndQueue(User $admin, string $csv, string $strategy, string $importType = 'vocabulary'): DictionaryImportJob
    {
        $jobId = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($csv),
            'duplicate_strategy' => $strategy,
            'import_type' => $importType,
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")->assertStatus(202);

        return DictionaryImportJob::query()->findOrFail($jobId);
    }

    private function previewAndQueueWithZip(User $admin, string $csv, array $zipFiles): DictionaryImportJob
    {
        $jobId = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $this->csvFile($csv),
            'audio_zip' => $this->zipFile($zipFiles),
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$jobId}/confirm")->assertStatus(202);

        return DictionaryImportJob::query()->findOrFail($jobId);
    }

    private function uploadedMedia(User $user, string $purpose, UploadedFile $file, string $visibility): MediaFile
    {
        $response = $this->withToken($this->tokenFor($user))->post('/api/v1/media', [
            'file' => $file,
            'purpose' => $purpose,
            'visibility' => $visibility,
        ])->assertCreated();

        return MediaFile::query()->findOrFail($response->json('data.id'));
    }

    private function validCsv(string $audioFilename = 'monga.mp3', string $category = 'Verba', string $code = '1'): string
    {
        return implode(',', config('dictionary.csv_headers.vocabulary'))."\n"
            ."{$code},makan,eat,monga,{$category},{$audioFilename}\n";
    }

    private function sentenceCsv(string $code = '1'): string
    {
        return implode(',', config('dictionary.csv_headers.sentence_examples'))."\n"
            ."{$code},inoi monga kade,saya sedang makan nasi\n";
    }

    private function csvFile(string $content): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('kamus.csv', $content);
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

    private function mp3File(string $name = 'audio.mp3'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, $this->mp3Content());
    }

    private function mp3Content(): string
    {
        return "\xFF\xFB\x90\x64".str_repeat("\x00", 1024);
    }

    private function pdfFile(): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('materi.pdf', "%PDF-1.4\n%%EOF");
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
