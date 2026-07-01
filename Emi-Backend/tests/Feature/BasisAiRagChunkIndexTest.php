<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeChunk;
use App\Models\AiKnowledgeItem;
use App\Models\User;
use App\Services\AiKnowledgeChunkingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class BasisAiRagChunkIndexTest extends TestCase
{
    use RefreshDatabase;

    public function test_creating_knowledge_item_generates_chunks(): void
    {
        $admin = User::factory()->admin()->create();

        $response = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/ai/knowledge', [
            'title' => 'Pengetahuan Rumbia',
            'content' => str_repeat('Sagu rumbia adalah pangan lokal. ', 80),
            'source_type' => 'manual',
        ]);

        $response->assertCreated();
        $item = AiKnowledgeItem::query()->where('title', 'Pengetahuan Rumbia')->firstOrFail();

        $this->assertGreaterThan(1, $item->chunks()->count());
    }

    public function test_updating_content_rebuilds_chunks_without_duplicates(): void
    {
        $admin = User::factory()->admin()->create();
        $item = AiKnowledgeItem::factory()->create(['created_by' => $admin->id]);
        app(AiKnowledgeChunkingService::class)->rebuild($item);
        $oldChunkIds = $item->chunks()->pluck('id')->all();

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/ai/knowledge/{$item->id}", [
            'title' => $item->title,
            'content' => str_repeat('Kain tradisional memiliki motif khusus. ', 60),
            'source_type' => 'manual',
            'status' => 'draft',
        ])->assertOk();

        $item->refresh();
        $this->assertNotSame($oldChunkIds, $item->chunks()->pluck('id')->all());
        $this->assertSame($item->chunks()->count(), $item->chunks()->distinct('chunk_index')->count('chunk_index'));
    }

    public function test_publishing_ensures_chunks_exist(): void
    {
        $admin = User::factory()->admin()->create();
        $item = AiKnowledgeItem::factory()->create(['created_by' => $admin->id]);
        $item->chunks()->delete();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/ai/knowledge/{$item->id}/publish")
            ->assertOk();

        $this->assertGreaterThan(0, $item->refresh()->chunks()->count());
    }

    public function test_reindex_command_is_idempotent(): void
    {
        AiKnowledgeItem::factory()->count(2)->create();

        $this->artisan('ai:knowledge:reindex')->assertExitCode(0);
        $firstCount = AiKnowledgeChunk::query()->count();
        $this->artisan('ai:knowledge:reindex')->assertExitCode(0);

        $this->assertSame($firstCount, AiKnowledgeChunk::query()->count());
    }

    public function test_chatbot_searches_chunks_and_chooses_most_relevant_chunk(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Dokumen Panjang Budaya',
            'content' => str_repeat('Pembuka umum tentang budaya. ', 50).
                'Upacara mosehe wonua adalah ritual penyucian wilayah dalam tradisi lokal. '.
                str_repeat('Penutup umum tentang budaya. ', 50),
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'apa itu mosehe wonua',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.sources.0.chunk_index', 1)
            ->assertJsonFragment([
                'answer' => 'Berdasarkan Basis AI EMI, berikut informasi yang ditemukan: Upacara mosehe wonua adalah ritual penyucian wilayah dalam tradisi lokal.',
            ]);
    }

    public function test_chatbot_returns_fallback_when_no_chunk_passes_threshold(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'content' => 'Suku Tolaki-Mekongga merupakan suku yang mendiami daerah Mekongga.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'arti mekongga',
        ])->assertOk()
            ->assertJsonPath('data.matched', false)
            ->assertJsonPath('data.answer', 'Saya belum menemukan jawaban dari Basis AI yang tersedia.');
    }

    public function test_archived_and_draft_chunks_are_ignored(): void
    {
        $student = User::factory()->student()->approved()->create();
        $draft = AiKnowledgeItem::factory()->create(['content' => 'Rahasia lumanda hanya ada di draft.']);
        $archived = AiKnowledgeItem::factory()->archived()->create(['content' => 'Rahasia lumanda hanya ada di arsip.']);
        app(AiKnowledgeChunkingService::class)->rebuild($draft);
        app(AiKnowledgeChunkingService::class)->rebuild($archived);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'rahasia lumanda',
        ])->assertOk()
            ->assertJsonPath('data.matched', false);
    }

    public function test_free_ai_provider_receives_selected_chunks_only(): void
    {
        config(['ai.free_provider' => 'groq', 'ai.free_api_key' => 'test-key']);
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Jawaban dari chunk terpilih.']],
                ],
            ]),
        ]);
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Dokumen Panjang Rumbia',
            'content' => str_repeat('Bagian awal tidak relevan dan tidak boleh dikirim penuh. ', 40).
                'Sagu rumbia diolah dengan cara diparut dan diperas untuk mendapatkan pati. '.
                str_repeat('Bagian akhir tidak relevan dan tidak boleh dikirim penuh. ', 40),
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'bagaimana sagu rumbia diolah',
        ])->assertOk()
            ->assertJsonPath('data.mode', 'free_ai');

        Http::assertSent(function (Request $request): bool {
            $prompt = $request->data()['messages'][0]['content'] ?? '';

            return str_contains($prompt, 'Sagu rumbia diolah dengan cara diparut')
                && ! str_contains($prompt, str_repeat('Bagian awal tidak relevan dan tidak boleh dikirim penuh. ', 20))
                && ! str_contains($prompt, str_repeat('Bagian akhir tidak relevan dan tidak boleh dikirim penuh. ', 20));
        });
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
