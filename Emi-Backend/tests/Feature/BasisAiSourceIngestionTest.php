<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeItem;
use App\Models\AiKnowledgeSourcePage;
use App\Models\User;
use App\Services\AiPdfPageClassifier;
use App\Services\AiSourceIngestionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Mockery;
use Tests\TestCase;

class BasisAiSourceIngestionTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $student;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->admin()->create();
        $this->student = User::factory()->student()->approved()->create();
    }

    public function test_admin_can_extract_readable_text_from_mocked_public_html_link()
    {
        Http::fake([
            'https://example.com/artikel' => Http::response(
                '<html><body><nav>Menu</nav><article><h1>Judul Artikel</h1><p>Ini adalah isi artikel yang penting.</p></article><footer>Copyright</footer></body></html>',
                200
            ),
        ]);

        $response = $this->actingAs($this->admin)->postJson('/api/v1/admin/ai/knowledge/extract-source', [
            'source_type' => 'link',
            'source_url' => 'https://example.com/artikel',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.content', 'Judul ArtikelIni adalah isi artikel yang penting.');
    }

    public function test_non_admin_cannot_extract_source_content()
    {
        $response = $this->actingAs($this->student)->postJson('/api/v1/admin/ai/knowledge/extract-source', [
            'source_type' => 'link',
            'source_url' => 'https://example.com/artikel',
        ]);

        $response->assertStatus(403);
    }

    public function test_link_extraction_rejects_localhost_private_url()
    {
        $response = $this->actingAs($this->admin)->postJson('/api/v1/admin/ai/knowledge/extract-source', [
            'source_type' => 'link',
            'source_url' => 'http://localhost/secret',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.source_url.0', 'URL tidak valid.');

        $response = $this->actingAs($this->admin)->postJson('/api/v1/admin/ai/knowledge/extract-source', [
            'source_type' => 'link',
            'source_url' => 'http://127.0.0.1/secret',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.source_url.0', 'URL tidak valid.');
    }

    public function test_link_extraction_returns_clear_error_for_unreadable_content()
    {
        Http::fake([
            'https://example.com/empty' => Http::response('<html><body></body></html>', 200),
        ]);

        $response = $this->actingAs($this->admin)->postJson('/api/v1/admin/ai/knowledge/extract-source', [
            'source_type' => 'link',
            'source_url' => 'https://example.com/empty',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.source_url.0', 'Tidak ada teks yang dapat dibaca di halaman ini.');
    }

    public function test_pdf_extraction_handles_text_based_pdf()
    {
        $mockService = Mockery::mock(AiSourceIngestionService::class);
        $mockService->shouldReceive('extract')
            ->with('pdf', 'https://example.com/test.pdf')
            ->andReturn([
                'content' => 'Teks PDF yang diekstrak',
                'title' => 'Judul PDF',
                'source_type' => 'pdf',
                'source_url' => 'https://example.com/test.pdf',
                'character_count' => 23,
                'warnings' => [],
            ]);

        $this->app->instance(AiSourceIngestionService::class, $mockService);

        $response = $this->actingAs($this->admin)->postJson('/api/v1/admin/ai/knowledge/extract-source', [
            'source_type' => 'pdf',
            'source_url' => 'https://example.com/test.pdf',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.content', 'Teks PDF yang diekstrak');
    }

    public function test_pdf_extraction_returns_clear_error_for_invalid_pdf()
    {
        Http::fake([
            'https://example.com/invalid.pdf' => Http::response('not a pdf', 200),
        ]);

        $response = $this->actingAs($this->admin)->postJson('/api/v1/admin/ai/knowledge/extract-source', [
            'source_type' => 'pdf',
            'source_url' => 'https://example.com/invalid.pdf',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.source_url.0', 'File bukan PDF yang valid.');
    }

    public function test_admin_can_upload_text_based_pdf_and_receive_extracted_content()
    {
        Storage::fake('public');
        $file = UploadedFile::fake()->createWithContent('struktur bahasa mekongga.pdf', $this->textPdfContent());

        $response = $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-pdf-upload', [
            'file' => $file,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.source_type', 'pdf')
            ->assertJsonPath('data.original_filename', 'struktur bahasa mekongga.pdf')
            ->assertJsonPath('data.title', 'struktur bahasa mekongga');

        $this->assertStringContainsString('Sagu rumbia pangan tradisional Mekongga', $response->json('data.content'));
        $this->assertStringStartsWith('/storage/ai-knowledge-sources/', $response->json('data.source_url'));
        Storage::disk('public')->assertExists(str_replace('/storage/', '', $response->json('data.source_url')));
    }

    public function test_non_admin_cannot_upload_pdf_for_extraction()
    {
        $file = UploadedFile::fake()->createWithContent('dokumen.pdf', $this->textPdfContent());

        $response = $this->actingAs($this->student)->post('/api/v1/admin/ai/knowledge/extract-pdf-upload', [
            'file' => $file,
        ]);

        $response->assertStatus(403);
    }

    public function test_invalid_non_pdf_upload_is_rejected()
    {
        $file = UploadedFile::fake()->createWithContent('dokumen.txt', 'bukan pdf');

        $response = $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-pdf-upload', [
            'file' => $file,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('file');
    }

    public function test_empty_pdf_upload_returns_clear_indonesian_error()
    {
        Storage::fake('public');
        $file = UploadedFile::fake()->createWithContent('scan.pdf', $this->emptyPdfContent());

        $response = $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/extract-pdf-upload', [
            'file' => $file,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.file.0', 'PDF tidak memiliki teks yang dapat dibaca. PDF hasil scan/foto belum didukung.');
    }

    public function test_uploaded_pdf_extracted_content_can_be_saved_and_used_by_student_chatbot()
    {
        AiKnowledgeItem::factory()->create([
            'title' => 'Artikel Rumbia',
            'content' => 'Sagu rumbia adalah bahan pangan tradisional penting di Sulawesi Tenggara.',
            'source_type' => 'link',
            'source_url' => 'https://example.com/rumbia',
            'status' => 'published',
            'created_by' => $this->admin->id,
        ]);

        $response = $this->actingAs($this->student)->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa itu sagu rumbia?',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.source_url', 'https://example.com/rumbia');
    }

    public function test_pdf_source_page_model_table_works(): void
    {
        $item = AiKnowledgeItem::factory()->create(['created_by' => $this->admin->id]);

        $page = AiKnowledgeSourcePage::query()->create([
            'ai_knowledge_item_id' => $item->id,
            'page_number' => 14,
            'content' => 'Struktur bahasa Mekongga memiliki pola kalimat khusus.',
            'content_hash' => hash('sha256', 'Struktur bahasa Mekongga memiliki pola kalimat khusus.'),
            'char_count' => 54,
            'word_count' => 7,
            'metadata' => ['source' => 'pdf', 'page_number' => 14],
        ]);

        $this->assertSame(14, $page->fresh()->metadata['page_number']);
        $this->assertSame(1, $item->sourcePages()->count());
    }

    public function test_admin_can_import_pdf_as_page_aware_source_without_content(): void
    {
        Storage::fake('public');
        $file = UploadedFile::fake()->createWithContent('struktur bahasa mekongga.pdf', $this->textPdfContent());

        $response = $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/import-pdf', [
            'title' => 'Struktur Bahasa Mekongga',
            'category' => 'Bahasa',
            'content' => 'b',
            'file' => $file,
            'status' => 'draft',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.page_count', 1)
            ->assertJsonPath('data.skipped_page_count', 0);

        $item = AiKnowledgeItem::query()->findOrFail($response->json('data.item_id'));
        $this->assertSame('pdf', $item->source_type);
        $this->assertStringStartsWith('/storage/ai-knowledge-sources/', $item->source_url);
        $this->assertSame('Dokumen PDF telah diproses sebagai sumber Basis AI. Isi lengkap disimpan per halaman dan digunakan untuk pencarian Chatbot AI.', $item->content);
        $this->assertStringContainsString('Sagu rumbia pangan tradisional Mekongga', $item->sourcePages()->first()->content);
        $this->assertGreaterThan(0, $item->chunks()->count());
        $metadata = $item->chunks()->first()->metadata;
        $this->assertSame(1, $metadata['page_number']);
        $this->assertSame(1, $metadata['page_start']);
        $this->assertSame(1, $metadata['page_end']);
        Storage::disk('public')->assertExists(str_replace('/storage/', '', $item->source_url));
    }

    public function test_pdf_page_classifier_detects_table_of_contents(): void
    {
        $result = app(AiPdfPageClassifier::class)->classify("DAFTAR ISI\nBAB I PENDAHULUAN ........ 1\n1.1 Latar Belakang ........ 2\n1.2 Masalah ........ 3\n2.3 Wilayah Pemakaian dan Pemakai Bahasa Mekongga ..... 12", 3);

        $this->assertSame('table_of_contents', $result['page_type']);
        $this->assertFalse($result['searchable']);
        $this->assertSame('Daftar isi', $result['skip_reason']);
    }

    public function test_toc_source_page_is_stored_but_marked_not_searchable(): void
    {
        $item = AiKnowledgeItem::factory()->create(['created_by' => $this->admin->id]);
        $classification = app(AiPdfPageClassifier::class)->classify("DAFTAR ISI\nBAB I PENDAHULUAN ........ 1\n1.1 Latar Belakang ........ 2\n1.2 Masalah ........ 3\n2.3 Wilayah Pemakaian Bahasa Mekongga ..... 12", 3);

        $page = AiKnowledgeSourcePage::query()->create([
            'ai_knowledge_item_id' => $item->id,
            'page_number' => 3,
            'content' => $classification['content'],
            'content_hash' => hash('sha256', $classification['content']),
            'char_count' => mb_strlen($classification['content']),
            'word_count' => str_word_count($classification['content']),
            'metadata' => [
                'page_type' => $classification['page_type'],
                'searchable' => $classification['searchable'],
                'skip_reason' => $classification['skip_reason'],
            ],
        ]);

        $this->assertSame('table_of_contents', $page->fresh()->metadata['page_type']);
        $this->assertFalse($page->fresh()->metadata['searchable']);
    }

    public function test_import_empty_pdf_returns_clear_error(): void
    {
        Storage::fake('public');
        $file = UploadedFile::fake()->createWithContent('scan.pdf', $this->emptyPdfContent());

        $response = $this->actingAs($this->admin)->post('/api/v1/admin/ai/knowledge/import-pdf', [
            'title' => 'Scan PDF',
            'file' => $file,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.file.0', 'PDF tidak memiliki teks yang dapat dibaca. PDF hasil scan/foto belum didukung tanpa OCR.');
    }

    private function textPdfContent(): string
    {
        $stream = "BT /F1 18 Tf 100 700 Td (Sagu rumbia pangan tradisional Mekongga) Tj ET\n";

        return $this->buildPdf([
            '<< /Type /Catalog /Pages 2 0 R >>',
            '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
            '<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 612 792] /Contents 5 0 R >>',
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
            '<< /Length '.strlen($stream)." >>\nstream\n{$stream}endstream",
        ]);
    }

    private function emptyPdfContent(): string
    {
        return $this->buildPdf([
            '<< /Type /Catalog /Pages 2 0 R >>',
            '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
            '<< /Type /Page /Parent 2 0 R /Resources << >> /MediaBox [0 0 612 792] >>',
        ]);
    }

    private function buildPdf(array $objects): string
    {
        $pdf = "%PDF-1.4\n";
        $offsets = [0];

        foreach ($objects as $index => $object) {
            $offsets[] = strlen($pdf);
            $number = $index + 1;
            $pdf .= "{$number} 0 obj\n{$object}\nendobj\n";
        }

        $xrefOffset = strlen($pdf);
        $pdf .= "xref\n0 ".(count($objects) + 1)."\n";
        $pdf .= "0000000000 65535 f \n";

        foreach (array_slice($offsets, 1) as $offset) {
            $pdf .= str_pad((string) $offset, 10, '0', STR_PAD_LEFT)." 00000 n \n";
        }

        $pdf .= "trailer\n<< /Root 1 0 R /Size ".(count($objects) + 1)." >>\n";
        $pdf .= "startxref\n{$xrefOffset}\n%%EOF";

        return $pdf;
    }
}
