<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class Phase9BasisAiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_basis_ai_knowledge_item(): void
    {
        $admin = User::factory()->admin()->create();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/ai/knowledge', [
            'title' => 'Sejarah Mekongga',
            'category' => 'Budaya',
            'content' => 'Kerajaan Mekongga adalah bagian dari sejarah lokal.',
            'source_type' => 'manual',
        ])->assertCreated()
            ->assertJsonPath('data.title', 'Sejarah Mekongga')
            ->assertJsonPath('data.status', 'draft');

        $this->assertDatabaseHas('ai_knowledge_items', [
            'title' => 'Sejarah Mekongga',
            'status' => 'draft',
            'created_by' => $admin->id,
        ]);
    }

    public function test_non_admin_cannot_create_admin_knowledge_item(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/admin/ai/knowledge', [
            'title' => 'Sejarah Mekongga',
            'content' => 'Konten.',
            'source_type' => 'manual',
        ])->assertForbidden();
    }

    public function test_admin_can_publish_archive_and_delete_knowledge_item(): void
    {
        $admin = User::factory()->admin()->create();
        $item = AiKnowledgeItem::factory()->create(['created_by' => $admin->id]);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/ai/knowledge/{$item->id}/publish")
            ->assertOk()
            ->assertJsonPath('data.status', 'published');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/ai/knowledge/{$item->id}/archive")
            ->assertOk()
            ->assertJsonPath('data.status', 'archived');

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/admin/ai/knowledge/{$item->id}")
            ->assertOk();

        $this->assertSoftDeleted('ai_knowledge_items', ['id' => $item->id]);
    }

    public function test_student_chatbot_returns_fallback_without_published_match(): void
    {
        $student = User::factory()->student()->approved()->create();

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa itu teknologi luar angkasa?',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Saya belum menemukan jawaban dari Basis AI yang tersedia.')
            ->assertJsonPath('data.source', null)
            ->assertJsonPath('data.matched', false)
            ->assertJsonPath('data.mode', 'default_extractive')
            ->assertJsonPath('data.provider', 'default');
    }

    public function test_student_chatbot_returns_matched_answer_source_and_default_provider(): void
    {
        $student = User::factory()->student()->approved()->create();
        $item = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Sejarah Mekongga',
            'category' => 'Budaya',
            'content' => 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka. Informasi ini berasal dari Basis AI EMI.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa sejarah Mekongga?',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.mode', 'default_extractive')
            ->assertJsonPath('data.provider', 'default')
            ->assertJsonPath('data.source.id', $item->id)
            ->assertJsonPath('data.source.title', 'Sejarah Mekongga')
            ->assertJsonPath('data.source.category', 'Budaya')
            ->assertJsonFragment([
                'answer' => 'Berdasarkan Basis AI EMI, berikut informasi yang ditemukan: Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka.',
            ]);
    }

    public function test_student_chatbot_only_uses_published_knowledge(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->create([
            'title' => 'Rahasia Draft Mekongga',
            'content' => 'Draft tidak boleh dipakai chatbot.',
            'status' => 'draft',
        ]);
        AiKnowledgeItem::factory()->archived()->create([
            'title' => 'Arsip Mekongga',
            'content' => 'Arsip tidak boleh dipakai chatbot.',
        ]);
        $published = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Budaya Mekongga',
            'category' => 'Budaya',
            'content' => 'Budaya Mekongga memiliki sumber terbit yang boleh digunakan siswa.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Jelaskan sumber terbit',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.id', $published->id);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa rahasia draft?',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Saya belum menemukan jawaban dari Basis AI yang tersedia.')
            ->assertJsonPath('data.matched', false);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa isi arsip?',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Saya belum menemukan jawaban dari Basis AI yang tersedia.')
            ->assertJsonPath('data.matched', false);
    }

    public function test_chatbot_does_not_require_external_ai_config(): void
    {
        config([
            'services.openai' => null,
            'services.gemini' => null,
            'services.groq' => null,
        ]);

        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Bahasa Mekongga',
            'content' => 'Bahasa Mekongga dipelajari melalui sumber Basis AI yang dipublikasikan.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'sumber dipublikasikan',
        ])->assertOk()
            ->assertJsonPath('data.mode', 'default_extractive')
            ->assertJsonPath('data.provider', 'default')
            ->assertJsonPath('data.matched', true);
    }

    public function test_chatbot_does_not_return_broad_item_only_because_of_generic_keyword(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Budaya Mekongga',
            'category' => 'Budaya',
            'content' => 'Suku Tolaki-Mekongga merupakan suku yang mendiami daerah Mekongga.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'arti mekongga',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Saya belum menemukan jawaban dari Basis AI yang tersedia.')
            ->assertJsonPath('data.matched', false)
            ->assertJsonPath('data.confidence', 0);
    }

    public function test_chatbot_chooses_specific_item_over_broad_item(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Budaya Mekongga',
            'category' => 'Budaya',
            'content' => 'Suku Tolaki-Mekongga merupakan suku yang mendiami daerah Mekongga.',
        ]);
        $specific = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Arti nama Mekongga',
            'category' => 'Sejarah',
            'content' => 'Mekongga berasal dari cerita rakyat tentang asal-usul nama wilayah dan masyarakatnya.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'arti mekongga',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.id', $specific->id)
            ->assertJsonPath('data.source.source_type', 'manual');
    }

    public function test_chatbot_returns_snippet_around_matched_keyword(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata dasar Mekongga',
            'content' => 'Pembuka umum tentang pembelajaran. Kata monga berarti makan dalam Bahasa Mekongga. Penutup materi.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'arti monga',
        ])->assertOk()
            ->assertJsonFragment([
                'answer' => 'Berdasarkan Basis AI EMI, berikut informasi yang ditemukan: Kata monga berarti makan dalam Bahasa Mekongga.',
            ]);
    }

    public function test_chatbot_response_includes_link_source_metadata(): void
    {
        $student = User::factory()->student()->approved()->create();
        $item = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata harian Mekongga',
            'category' => 'Kosakata',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
            'source_type' => 'link',
            'source_url' => 'https://example.com/kosakata-mekongga',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.source.id', $item->id)
            ->assertJsonPath('data.source.source_type', 'link')
            ->assertJsonPath('data.source.source_url', 'https://example.com/kosakata-mekongga');
    }

    public function test_published_link_and_pdf_items_are_searchable_through_content_field(): void
    {
        $student = User::factory()->student()->approved()->create();
        $pdf = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Dokumen asal usul Mekongga',
            'content' => 'Ringkasan dokumen menjelaskan asal usul Mekongga dari cerita rakyat.',
            'source_type' => 'pdf',
            'source_url' => 'https://example.com/asal-usul.pdf',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'asal usul cerita rakyat',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.id', $pdf->id)
            ->assertJsonPath('data.source.source_type', 'pdf')
            ->assertJsonPath('data.source.source_url', 'https://example.com/asal-usul.pdf');
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
