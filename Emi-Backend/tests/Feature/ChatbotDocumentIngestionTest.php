<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use PhpOffice\PhpWord\IOFactory;
use PhpOffice\PhpWord\PhpWord;
use Tests\TestCase;

class ChatbotDocumentIngestionTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $teacher;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->admin()->create();
        $this->teacher = User::factory()->teacher()->approved()->create();
    }

    public function test_admin_can_upload_docx_and_receive_extracted_content(): void
    {
        Storage::fake('public');
        $file = $this->fakeDocx('sejarah mekongga.docx', 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka sejak lama.');

        $response = $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-document-upload', [
            'file' => $file,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.source_type', 'docx')
            ->assertJsonPath('data.original_filename', 'sejarah mekongga.docx');

        $this->assertStringContainsString('Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka', $response->json('data.content'));
        $this->assertStringStartsWith('/storage/ai-knowledge-sources/', $response->json('data.source_url'));
        Storage::disk('public')->assertExists(str_replace('/storage/', '', $response->json('data.source_url')));
    }

    public function test_admin_can_upload_txt_and_receive_extracted_content(): void
    {
        Storage::fake('public');
        $file = UploadedFile::fake()->createWithContent('budaya.txt', 'Budaya Mekongga kaya akan tradisi lisan dan tarian adat.');

        $response = $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-document-upload', [
            'file' => $file,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.source_type', 'txt')
            ->assertJsonPath('data.original_filename', 'budaya.txt');

        $this->assertStringContainsString('Budaya Mekongga kaya akan tradisi lisan', $response->json('data.content'));
    }

    public function test_non_admin_cannot_upload_document_for_extraction(): void
    {
        $file = UploadedFile::fake()->createWithContent('dokumen.txt', 'Konten rahasia.');

        $this->actingAs($this->teacher)->post('/api/v1/admin/ai/knowledge/extract-document-upload', [
            'file' => $file,
        ])->assertForbidden();
    }

    public function test_invalid_file_type_is_rejected(): void
    {
        $file = UploadedFile::fake()->create('gambar.png', 100);

        $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-document-upload', [
            'file' => $file,
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('file');
    }

    public function test_empty_txt_upload_returns_clear_indonesian_error(): void
    {
        $file = UploadedFile::fake()->createWithContent('kosong.txt', '   ');

        $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-document-upload', [
            'file' => $file,
        ])->assertUnprocessable()
            ->assertJsonPath('errors.file.0', 'Berkas TXT kosong atau tidak dapat dibaca.');
    }

    public function test_docx_source_can_be_saved_published_and_used_by_student_chatbot(): void
    {
        Storage::fake('public');
        $file = $this->fakeDocx('adat mekongga.docx', 'Upacara adat Mekongga dilaksanakan setiap tahun oleh masyarakat Kolaka. Informasi ini berasal dari Basis AI EMI.');

        $extracted = $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-document-upload', [
            'file' => $file,
        ])->assertStatus(200)->json('data');

        $item = $this->actingAs($this->admin)->postJson('/api/v1/admin/ai/knowledge', [
            'title' => $extracted['title'] ?? 'Adat Mekongga',
            'category' => 'Budaya',
            'content' => $extracted['content'],
            'source_type' => 'docx',
            'source_url' => $extracted['source_url'],
        ])->assertCreated()->json('data');

        $this->actingAs($this->admin)->postJson("/api/v1/admin/ai/knowledge/{$item['id']}/publish")
            ->assertOk()
            ->assertJsonPath('data.status', 'published');

        $this->assertDatabaseHas('ai_knowledge_items', [
            'id' => $item['id'],
            'source_type' => 'docx',
            'status' => 'published',
        ]);

        $student = User::factory()->student()->approved()->create();
        $this->app['auth']->forgetGuards();
        $token = $student->createToken('PHPUnit')->plainTextToken;

        $this->withToken($token)->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Bagaimana upacara adat Mekongga dilaksanakan?',
        ])->assertOk()
            ->assertJsonPath('data.matched', true);
    }

    public function test_invalid_docx_upload_returns_clear_error(): void
    {
        $file = UploadedFile::fake()->createWithContent('rusak.docx', 'bukan docx yang valid');

        $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-document-upload', [
            'file' => $file,
        ])->assertUnprocessable()
            ->assertJsonPath('errors.file.0', 'Dokumen DOCX tidak valid atau rusak.');
    }

    public function test_list_can_filter_by_docx_and_txt_source_type(): void
    {
        AiKnowledgeItem::factory()->create(['created_by' => $this->admin->id, 'source_type' => 'docx']);
        AiKnowledgeItem::factory()->create(['created_by' => $this->admin->id, 'source_type' => 'manual']);

        $this->actingAs($this->admin)->getJson('/api/v1/admin/ai/knowledge?source_type=docx')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    private function fakeDocx(string $filename, string $text): UploadedFile
    {
        $phpWord = new PhpWord;
        $section = $phpWord->addSection();
        $section->addText($text);

        $tempPath = tempnam(sys_get_temp_dir(), 'docx').'.docx';
        IOFactory::createWriter($phpWord, 'Word2007')->save($tempPath);

        $file = new UploadedFile($tempPath, $filename, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', null, true);
        $this->beforeApplicationDestroyed(function () use ($tempPath) {
            if (file_exists($tempPath)) {
                unlink($tempPath);
            }
        });

        return $file;
    }
}
