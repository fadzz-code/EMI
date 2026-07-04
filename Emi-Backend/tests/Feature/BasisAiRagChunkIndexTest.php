<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeChunk;
use App\Models\AiKnowledgeItem;
use App\Models\AiKnowledgeSourcePage;
use App\Models\User;
use App\Services\Ai\EmbeddingProviderInterface;
use App\Services\Ai\EmbeddingProviderResolver;
use App\Services\Ai\EmbeddingResult;
use App\Services\AiKnowledgeChunkingService;
use App\Services\AiKnowledgeEmbeddingService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
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

    public function test_reindex_rebuilds_pdf_chunks_from_source_pages_not_placeholder(): void
    {
        $item = AiKnowledgeItem::factory()->create([
            'content' => 'Placeholder yang tidak boleh menjadi chunk final.',
            'source_type' => 'pdf',
            'source_url' => '/storage/ai-knowledge-sources/test.pdf',
        ]);
        AiKnowledgeSourcePage::query()->create([
            'ai_knowledge_item_id' => $item->id,
            'page_number' => 14,
            'content' => 'Halaman empat belas menjelaskan struktur bahasa Mekongga secara rinci.',
            'content_hash' => hash('sha256', 'Halaman empat belas menjelaskan struktur bahasa Mekongga secara rinci.'),
            'char_count' => 68,
            'word_count' => 8,
            'metadata' => ['source' => 'pdf', 'page_number' => 14],
        ]);

        $this->artisan('ai:knowledge:reindex')->assertExitCode(0);

        $chunk = $item->refresh()->chunks()->firstOrFail();
        $this->assertStringContainsString('Halaman empat belas', $chunk->content);
        $this->assertStringNotContainsString('Placeholder', $chunk->content);
        $this->assertSame(14, $chunk->metadata['page_number']);
        $this->assertSame(14, $chunk->metadata['page_start']);
        $this->assertSame(14, $chunk->metadata['page_end']);
    }

    public function test_manual_content_still_chunks_from_content(): void
    {
        $item = AiKnowledgeItem::factory()->create([
            'content' => 'Konten manual tetap digunakan sebagai sumber chunk Basis AI.',
            'source_type' => 'manual',
        ]);

        app(AiKnowledgeChunkingService::class)->rebuild($item);

        $this->assertStringContainsString('Konten manual', $item->refresh()->chunks()->firstOrFail()->content);
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

    public function test_embedding_metadata_fields_are_fillable_and_casted(): void
    {
        $chunk = new AiKnowledgeChunk([
            'embedding_provider' => 'fake',
            'embedding_model' => 'fake-model',
            'embedding_dimensions' => 768,
            'embedded_at' => now(),
            'embedding_hash' => 'hash',
            'embedding_error' => null,
        ]);

        $this->assertSame('fake', $chunk->embedding_provider);
        $this->assertSame('integer', $chunk->getCasts()['embedding_dimensions']);
        $this->assertSame('datetime', $chunk->getCasts()['embedded_at']);
    }

    public function test_embed_command_exists_and_exits_gracefully_when_provider_is_none(): void
    {
        $this->enableEmbeddingColumn();
        config(['ai.embedding.provider' => 'none']);

        $this->artisan('ai:knowledge:embed')
            ->expectsOutput('Embedding Basis AI EMI')
            ->expectsOutput('Provider embedding belum dikonfigurasi atau API key belum tersedia.')
            ->assertExitCode(0);
    }

    public function test_embed_command_exits_gracefully_when_vector_storage_is_unavailable(): void
    {
        $this->app->instance(AiKnowledgeEmbeddingService::class, new class extends AiKnowledgeEmbeddingService
        {
            public function __construct() {}

            public function vectorStorageAvailable(): bool
            {
                return false;
            }

            public function providerAvailable(): bool
            {
                return true;
            }
        });

        $this->artisan('ai:knowledge:embed')
            ->expectsOutput('Embedding Basis AI EMI')
            ->expectsOutput('Kolom embedding belum tersedia. Jalankan migration pada PostgreSQL dengan pgvector aktif.')
            ->assertExitCode(0);
    }

    public function test_embedding_service_stores_mocked_vector_and_metadata(): void
    {
        $this->enableEmbeddingColumn();
        $this->bindFakeEmbeddingProvider(EmbeddingResult::success(array_fill(0, 768, 0.1), 'fake', 'fake-model', 768, 'document'));
        $chunk = $this->makeChunk();

        $result = app(AiKnowledgeEmbeddingService::class)->embed($chunk);

        $this->assertSame('succeeded', $result['status']);
        $chunk->refresh();
        $this->assertStringStartsWith('[0.1,0.1,0.1', $chunk->embedding);
        $this->assertSame('fake', $chunk->embedding_provider);
        $this->assertSame('fake-model', $chunk->embedding_model);
        $this->assertSame(768, $chunk->embedding_dimensions);
        $this->assertNotNull($chunk->embedded_at);
        $this->assertNotNull($chunk->embedding_hash);
        $this->assertNull($chunk->embedding_error);
    }

    public function test_embedding_service_stores_error_when_provider_fails(): void
    {
        $this->enableEmbeddingColumn();
        $this->bindFakeEmbeddingProvider(EmbeddingResult::failure('Gagal palsu.', 'fake', 'fake-model', 3));
        $chunk = $this->makeChunk();

        $result = app(AiKnowledgeEmbeddingService::class)->embed($chunk);

        $this->assertSame('failed', $result['status']);
        $this->assertSame('Gagal palsu.', $chunk->refresh()->embedding_error);
    }

    public function test_embedding_service_skips_unchanged_chunks_by_hash(): void
    {
        $this->enableEmbeddingColumn();
        $this->bindFakeEmbeddingProvider(EmbeddingResult::success(array_fill(0, 768, 0.1), 'fake', 'fake-model', 768, 'document'));
        $chunk = $this->makeChunk();
        $service = app(AiKnowledgeEmbeddingService::class);
        $service->embed($chunk);

        $result = $service->embed($chunk->refresh());

        $this->assertSame('skipped', $result['status']);
    }

    public function test_force_reembeds_unchanged_chunks(): void
    {
        $this->enableEmbeddingColumn();
        $this->bindFakeEmbeddingProvider(EmbeddingResult::success(array_fill(0, 768, 0.1), 'fake', 'fake-model', 768, 'document'));
        $chunk = $this->makeChunk();
        $service = app(AiKnowledgeEmbeddingService::class);
        $service->embed($chunk);

        $result = $service->embed($chunk->refresh(), true);

        $this->assertSame('succeeded', $result['status']);
    }

    public function test_embed_command_limit_limits_processed_chunks(): void
    {
        $this->enableEmbeddingColumn();
        $this->bindFakeEmbeddingProvider(EmbeddingResult::success(array_fill(0, 768, 0.1), 'fake', 'fake-model', 768, 'document'));
        $this->makeChunk();
        $this->makeChunk('Konten kedua yang cukup panjang untuk embedding Basis AI EMI.');

        $this->artisan('ai:knowledge:embed --limit=1')
            ->expectsOutput('- Chunk diproses: 1')
            ->assertExitCode(0);
    }

    public function test_reindex_without_embed_keeps_current_behavior(): void
    {
        AiKnowledgeItem::factory()->count(2)->create();

        $this->artisan('ai:knowledge:reindex')
            ->expectsOutputToContain('Basis AI reindex selesai.')
            ->doesntExpectOutput('Embedding dilewati karena provider embedding atau kolom vector belum tersedia.')
            ->assertExitCode(0);
    }

    public function test_reindex_with_embed_does_not_fail_when_provider_unavailable(): void
    {
        AiKnowledgeItem::factory()->create();
        $this->bindFakeEmbeddingProvider(EmbeddingResult::failure('Provider tidak tersedia.'), false);

        $this->artisan('ai:knowledge:reindex --embed')
            ->expectsOutputToContain('Basis AI reindex selesai.')
            ->expectsOutput('Embedding dilewati karena provider embedding atau kolom vector belum tersedia.')
            ->assertExitCode(0);
    }

    private function enableEmbeddingColumn(): void
    {
        if (! Schema::hasColumn('ai_knowledge_chunks', 'embedding')) {
            Schema::table('ai_knowledge_chunks', function (Blueprint $table) {
                $table->text('embedding')->nullable();
            });
        }
    }

    private function bindFakeEmbeddingProvider(EmbeddingResult $result, bool $available = true): void
    {
        $provider = new class($result, $available) implements EmbeddingProviderInterface
        {
            public function __construct(private readonly EmbeddingResult $result, private readonly bool $available) {}

            public function isAvailable(): bool
            {
                return $this->available;
            }

            public function embedDocument(string $text): EmbeddingResult
            {
                return $this->result;
            }

            public function embedQuery(string $text): EmbeddingResult
            {
                return $this->result;
            }
        };

        $this->app->instance(EmbeddingProviderResolver::class, new class($provider) extends EmbeddingProviderResolver
        {
            public function __construct(private readonly EmbeddingProviderInterface $provider) {}

            public function resolve(): EmbeddingProviderInterface
            {
                return $this->provider;
            }
        });
    }

    private function makeChunk(string $content = 'Konten pengetahuan yang cukup panjang untuk embedding Basis AI EMI.'): AiKnowledgeChunk
    {
        $item = AiKnowledgeItem::factory()->create(['content' => $content]);

        return AiKnowledgeChunk::query()->create([
            'ai_knowledge_item_id' => $item->id,
            'chunk_index' => 0,
            'content' => $content,
            'content_hash' => hash('sha256', $content),
            'character_count' => mb_strlen($content),
            'token_estimate' => 10,
            'metadata' => [],
        ]);
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
