<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeChunk;
use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminKnowledgeManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_filters_source_type_before_pagination(): void
    {
        $admin = User::factory()->admin()->create();

        AiKnowledgeItem::factory()->count(3)->create(['source_type' => 'manual', 'status' => 'draft', 'created_by' => $admin->id]);
        AiKnowledgeItem::factory()->count(2)->create(['source_type' => 'pdf', 'status' => 'published', 'created_by' => $admin->id]);
        AiKnowledgeItem::factory()->create(['source_type' => 'link', 'status' => 'published', 'title' => 'Sejarah Mekongga', 'created_by' => $admin->id]);

        $this->actingAs($admin)->getJson('/api/v1/admin/ai/knowledge?source_type=manual&per_page=2')
            ->assertOk()
            ->assertJsonPath('meta.total', 3)
            ->assertJsonPath('meta.last_page', 2)
            ->assertJsonCount(2, 'data');

        $this->actingAs($admin)->getJson('/api/v1/admin/ai/knowledge?source_type=pdf')
            ->assertOk()
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('data.0.source_type', 'pdf');

        $this->actingAs($admin)->getJson('/api/v1/admin/ai/knowledge?source_type=link&status=published&search=Sejarah')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.source_type', 'link');
    }

    public function test_create_pdf_without_file_and_url_is_rejected(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)->postJson('/api/v1/admin/ai/knowledge', [
            'title' => 'Coba',
            'category' => 'Umum',
            'content' => 'Isi',
            'source_type' => 'pdf',
            'status' => 'draft',
            'source_url' => '',
        ])->assertStatus(422)
            ->assertJsonValidationErrors('source_url');

        $this->actingAs($admin)->postJson('/api/v1/admin/ai/knowledge', [
            'title' => 'Coba',
            'category' => 'Umum',
            'content' => 'Isi',
            'source_type' => 'pdf',
            'status' => 'draft',
            'source_url' => '   ',
        ])->assertStatus(422)
            ->assertJsonValidationErrors('source_url');
    }

    public function test_invalid_source_type_is_validation_error(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)->getJson('/api/v1/admin/ai/knowledge?source_type=video')
            ->assertStatus(422)
            ->assertJsonValidationErrors('source_type');
    }

    public function test_non_admin_and_guest_cannot_manage_knowledge(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create();

        $this->actingAs($teacher)->getJson('/api/v1/admin/ai/knowledge?source_type=manual')->assertStatus(403);
        $this->actingAs($student)->getJson('/api/v1/admin/ai/knowledge?source_type=manual')->assertStatus(403);
        $this->getJson('/api/v1/admin/ai/knowledge?source_type=manual')->assertStatus(403);
    }

    public function test_retry_processing_uses_dedicated_endpoint_and_is_idempotent_for_failed_pdf(): void
    {
        $admin = User::factory()->admin()->create();
        $item = AiKnowledgeItem::factory()->create([
            'source_type' => 'pdf',
            'status' => 'draft',
            'content' => 'Sagu rumbia adalah pangan tradisional Mekongga yang siap digunakan chatbot dan cukup panjang untuk pencarian.',
            'created_by' => $admin->id,
        ]);

        $this->assertSame('failed', $item->processingStatus());

        $this->actingAs($admin)->postJson("/api/v1/admin/ai/knowledge/{$item->id}/retry-processing")
            ->assertOk()
            ->assertJsonPath('data.processing_status', 'ready');

        $this->assertSame(1, $item->chunks()->count());

        $this->actingAs($admin)->postJson("/api/v1/admin/ai/knowledge/{$item->id}/retry-processing")
            ->assertStatus(409);

        $this->assertSame(1, $item->chunks()->count());
    }

    public function test_manual_and_ready_sources_cannot_use_retry(): void
    {
        $admin = User::factory()->admin()->create();
        $manual = AiKnowledgeItem::factory()->create(['source_type' => 'manual', 'created_by' => $admin->id]);

        $this->actingAs($admin)->postJson("/api/v1/admin/ai/knowledge/{$manual->id}/retry-processing")
            ->assertStatus(422);
    }

    public function test_publish_readiness_is_enforced_on_create_update_and_publish(): void
    {
        $admin = User::factory()->admin()->create();

        $this->actingAs($admin)->postJson('/api/v1/admin/ai/knowledge', [
            'title' => 'Manual Terbit',
            'category' => 'Umum',
            'content' => 'Sagu rumbia adalah pangan tradisional Mekongga yang dibuat dari pohon rumbia.',
            'source_type' => 'manual',
            'status' => 'published',
        ])->assertCreated();

        $this->actingAs($admin)->postJson('/api/v1/admin/ai/knowledge', [
            'title' => 'PDF Belum Siap',
            'category' => 'Umum',
            'content' => 'Dokumen PDF telah diproses sebagai sumber Basis AI. Isi lengkap disimpan per halaman dan digunakan untuk pencarian Chatbot AI.',
            'source_type' => 'pdf',
            'status' => 'published',
            'source_url' => 'https://example.com/test.pdf',
        ])->assertStatus(409)
            ->assertJsonFragment(['message' => 'Sumber pengetahuan belum siap digunakan.']);

        $pdf = AiKnowledgeItem::factory()->create([
            'source_type' => 'pdf',
            'status' => 'draft',
            'content' => 'Dokumen PDF telah diproses sebagai sumber Basis AI. Isi lengkap disimpan per halaman dan digunakan untuk pencarian Chatbot AI.',
            'source_url' => 'https://example.com/test.pdf',
            'created_by' => $admin->id,
        ]);

        $this->actingAs($admin)->postJson("/api/v1/admin/ai/knowledge/{$pdf->id}/publish")
            ->assertStatus(409)
            ->assertJsonMissing(['message' => 'chunk']);

        $pdf->sourcePages()->create([
            'page_number' => 1,
            'content' => 'Test content',
            'content_hash' => 'hash',
            'char_count' => 12,
            'word_count' => 2,
            'metadata' => ['searchable' => true],
        ]);
        $this->readyChunk($pdf);

        $this->actingAs($admin)->postJson("/api/v1/admin/ai/knowledge/{$pdf->id}/publish")
            ->assertOk()
            ->assertJsonPath('data.status', 'published')
            ->assertJsonPath('data.processing_status', 'ready');

        $this->actingAs($admin)->putJson("/api/v1/admin/ai/knowledge/{$pdf->id}", [
            'title' => 'Judul Baru',
            'category' => $pdf->category,
            'content' => 'Dokumen PDF telah diproses sebagai sumber Basis AI. Isi lengkap disimpan per halaman dan digunakan untuk pencarian Chatbot AI.',
            'source_type' => 'pdf',
            'status' => 'published',
            'source_url' => 'https://example.com/test.pdf',
        ])->assertOk()
            ->assertJsonPath('data.title', 'Judul Baru');
    }

    public function test_retrieval_uses_only_published_ready_sources(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->approved()->create();

        AiKnowledgeItem::factory()->create([
            'title' => 'Manual Draft Rumbia',
            'content' => 'Sagu rumbia draft tidak boleh dipakai chatbot.',
            'source_type' => 'manual',
            'status' => 'draft',
            'created_by' => $admin->id,
        ]);
        AiKnowledgeItem::factory()->create([
            'title' => 'Manual Arsip Rumbia',
            'content' => 'Sagu rumbia arsip tidak boleh dipakai chatbot.',
            'source_type' => 'manual',
            'status' => 'archived',
            'created_by' => $admin->id,
        ]);
        $failedPdf = AiKnowledgeItem::factory()->create([
            'title' => 'PDF Gagal Rumbia',
            'content' => 'Dokumen PDF telah diproses sebagai sumber Basis AI. Isi lengkap disimpan per halaman dan digunakan untuk pencarian Chatbot AI.',
            'source_type' => 'pdf',
            'status' => 'published',
            'created_by' => $admin->id,
        ]);
        $readyPdf = AiKnowledgeItem::factory()->create([
            'title' => 'PDF Siap Rumbia',
            'content' => 'Sagu rumbia siap dipakai chatbot.',
            'source_type' => 'pdf',
            'status' => 'published',
            'created_by' => $admin->id,
        ]);
        $this->readyChunk($readyPdf, 'Sagu rumbia siap dipakai chatbot sebagai pangan tradisional khas Mekongga yang penting.');

        $response = $this->actingAs($student)->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa itu rumbia siap?',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.id', $readyPdf->id);

        $this->assertFalse($failedPdf->isReadyForPublication());
    }

    private function readyChunk(AiKnowledgeItem $item, string $content = 'Sagu rumbia adalah pangan tradisional Mekongga yang siap digunakan chatbot dan cukup panjang untuk pencarian.'): void
    {
        AiKnowledgeChunk::query()->create([
            'ai_knowledge_item_id' => $item->id,
            'chunk_index' => 0,
            'content' => $content,
            'content_hash' => hash('sha256', $content),
            'character_count' => mb_strlen($content),
            'token_estimate' => 20,
            'metadata' => ['searchable' => true, 'source_type' => $item->source_type],
        ]);
    }
}
