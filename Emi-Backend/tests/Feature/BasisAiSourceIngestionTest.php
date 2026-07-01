<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use App\Services\AiSourceIngestionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
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

    public function test_extracted_content_can_be_saved_and_used_by_student_chatbot()
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
}
