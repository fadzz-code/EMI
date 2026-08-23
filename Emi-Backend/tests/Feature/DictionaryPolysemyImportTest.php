<?php

namespace Tests\Feature;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportJob;
use App\Models\DictionarySentenceExample;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Tests\TestCase;
use ZipArchive;

class DictionaryPolysemyImportTest extends TestCase
{
    use RefreshDatabase;

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }

    private function buildWorkbook(array $vocabularyRows, array $sentenceRows): UploadedFile
    {
        $spreadsheet = new Spreadsheet;
        $spreadsheet->removeSheetByIndex(0);

        $vocabSheet = $spreadsheet->createSheet();
        $vocabSheet->setTitle(config('dictionary.xlsx_sheets.vocabulary'));
        $vocabSheet->fromArray(config('dictionary.xlsx_headers.vocabulary'), null, 'A1');
        foreach ($vocabularyRows as $index => $row) {
            $vocabSheet->fromArray($row, null, 'A'.($index + 2));
        }

        $sentenceSheet = $spreadsheet->createSheet();
        $sentenceSheet->setTitle(config('dictionary.xlsx_sheets.sentence_examples'));
        $sentenceSheet->fromArray(config('dictionary.xlsx_headers.sentence_examples'), null, 'A1');
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

    public function test_unique_indonesia_updates_using_progressive_behavior(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);

        DictionaryEntry::factory()->create([
            'indonesia' => 'Makan', 'mekongga' => 'Monga', 'english' => 'Eat',
            'indonesia_normalized' => 'makan', 'mekongga_normalized' => 'monga',
            'status' => 'active', 'category_id' => $cat->id,
        ]);

        $workbook = $this->buildWorkbook([['Makan', '', 'Eat', '', '']], []);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true]);

        $entries = DictionaryEntry::where('indonesia_normalized', 'makan')->get();
        $this->assertCount(1, $entries);
        $this->assertSame('Monga', $entries[0]->mekongga);
        $this->assertSame('Eat', $entries[0]->english);
    }

    public function test_polysemy_exact_update(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Bongga', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'bongga', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Wota', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'wota', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);

        $workbook = $this->buildWorkbook([['Belah', 'Wota', 'Split', '', '']], []);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true]);

        $entries = DictionaryEntry::where('indonesia_normalized', 'belah')->orderBy('mekongga_normalized')->get();
        $this->assertCount(2, $entries);
        $this->assertSame('bongga', $entries[0]->mekongga_normalized);
        $this->assertSame('Eat', $entries[0]->english);
        $this->assertSame('wota', $entries[1]->mekongga_normalized);
        $this->assertSame('Split', $entries[1]->english);
    }

    public function test_polysemy_new_sense(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Bongga', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'bongga', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Wota', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'wota', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);

        $workbook = $this->buildWorkbook([['Belah', 'Towo', 'Split', '', '']], []);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true]);

        $entries = DictionaryEntry::where('indonesia_normalized', 'belah')->orderBy('mekongga_normalized')->get();
        $this->assertCount(3, $entries);
        $this->assertSame(['bongga', 'towo', 'wota'], $entries->pluck('mekongga_normalized')->toArray());
    }

    public function test_polysemy_ambiguous_blank_mekongga(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Bongga', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'bongga', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Wota', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'wota', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);

        $workbook = $this->buildWorkbook([['Belah', '', '', '', '']], []);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();

        $job = DictionaryImportJob::findOrFail($preview->json('data.id'));
        $this->assertSame(0, $job->valid_rows);
        $this->assertSame(1, $job->invalid_rows);
        $errors = $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/dictionary/imports/{$job->id}/errors")->json('data');
        $this->assertSame('AMBIGUOUS_INDONESIA', $errors[0]['code']);
    }

    public function test_workbook_multi_sense(): void
    {
        $admin = User::factory()->admin()->create();
        $workbook = $this->buildWorkbook([
            ['Belah', 'Bongga', '', '', ''],
            ['Belah', 'Wota', '', '', ''],
            ['Belah', 'Towo', '', '', ''],
        ], []);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true]);

        $entries = DictionaryEntry::where('indonesia_normalized', 'belah')->orderBy('mekongga_normalized')->get();
        $this->assertCount(3, $entries);
    }

    public function test_sentence_unique(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);
        DictionaryEntry::factory()->create(['indonesia' => 'Makan', 'mekongga' => 'Monga', 'english' => 'Eat', 'indonesia_normalized' => 'makan', 'mekongga_normalized' => 'monga', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);

        $workbook = $this->buildWorkbook([], [['Makan', '', 'Saya makan', 'Inoi monga', '']]);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true]);

        $this->assertSame(1, DictionarySentenceExample::where('example_indonesia', 'Saya makan')->count());
    }

    public function test_sentence_polysemy_exact_disambiguation(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Bongga', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'bongga', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);
        $entry2 = DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Wota', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'wota', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);

        $workbook = $this->buildWorkbook([], [['Belah', 'Wota', 'Membelah kayu', 'Wota ...', '']]);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true]);

        $sentences = DictionarySentenceExample::where('dictionary_entry_id', $entry2->id)->get();
        $this->assertCount(1, $sentences);
    }

    public function test_sentence_polysemy_missing_disambiguation(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Bongga', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'bongga', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Wota', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'wota', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);

        $workbook = $this->buildWorkbook([], [['Belah', '', 'Membelah kayu', '...', '']]);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', ['csv_file' => $workbook])->assertCreated();

        $job = DictionaryImportJob::findOrFail($preview->json('data.id'));
        $this->assertSame(0, $job->valid_rows);
        $this->assertSame(1, $job->invalid_rows);
        $errors = $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/dictionary/imports/{$job->id}/errors")->json('data');
        $this->assertSame('AMBIGUOUS_RELATED_INDONESIA', $errors[0]['code']);
    }

    public function test_audio_polysemy_safety(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Bongga', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'bongga', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Wota', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'wota', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);

        $workbook = $this->buildWorkbook([['Belah', '', '', '', '']], []);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
            'audio_zip' => $this->zipFile(['belah.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024)]),
        ])->assertCreated();

        $job = DictionaryImportJob::findOrFail($preview->json('data.id'));
        $this->assertSame(0, $job->valid_rows);
        $errors = $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/dictionary/imports/{$job->id}/errors")->json('data');
        $this->assertContains('AMBIGUOUS_INDONESIA', collect($errors)->pluck('code'));
    }

    public function test_audio_mekongga_disambiguation(): void
    {
        $admin = User::factory()->admin()->create();
        $cat = DictionaryCategory::factory()->create(['name' => 'Kata Kerja']);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Bongga', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'bongga', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);
        DictionaryEntry::factory()->create(['indonesia' => 'Belah', 'mekongga' => 'Wota', 'english' => 'Eat', 'indonesia_normalized' => 'belah', 'mekongga_normalized' => 'wota', 'english_normalized' => 'eat', 'status' => 'active', 'category_id' => $cat->id]);

        $workbook = $this->buildWorkbook([
            ['Belah', 'Bongga', '', '', ''],
            ['Belah', 'Wota', '', '', ''],
        ], []);
        $preview = $this->withToken($this->tokenFor($admin))->post('/api/v1/admin/dictionary/imports/preview', [
            'csv_file' => $workbook,
            'audio_zip' => $this->zipFile([
                'bongga.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
                'wota.mp3' => "\xFF\xFB\x90\x64".str_repeat("\x00", 1024),
            ]),
        ])->assertCreated();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/dictionary/imports/{$preview->json('data.id')}/confirm")->assertStatus(202);
        $this->artisan('queue:work', ['--once' => true]);

        $bongga = DictionaryEntry::where('mekongga_normalized', 'bongga')->first();
        $wota = DictionaryEntry::where('mekongga_normalized', 'wota')->first();
        $this->assertNotNull($bongga->audio_media_id);
        $this->assertNotNull($wota->audio_media_id);
        $this->assertSame('bongga.mp3', $bongga->audioMedia->original_name);
        $this->assertSame('wota.mp3', $wota->audioMedia->original_name);
    }
}
