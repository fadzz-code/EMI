<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeChunk;
use App\Models\AiKnowledgeItem;
use App\Models\DictionaryEntry;
use App\Models\User;
use App\Services\Ai\EmbeddingProviderInterface;
use App\Services\Ai\EmbeddingProviderResolver;
use App\Services\Ai\EmbeddingResult;
use App\Services\Ai\GeminiEmbeddingProvider;
use App\Services\Ai\NullEmbeddingProvider;
use App\Services\DictionaryNormalizer;
use App\Services\VectorChunkRetriever;
use Database\Seeders\BasisAiDemoSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class Phase9BasisAiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['ai.free_provider' => 'none']);
    }

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

    public function test_manual_content_create_flow_requires_content(): void
    {
        $admin = User::factory()->admin()->create();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/ai/knowledge', [
            'title' => 'Manual Tanpa Konten',
            'source_type' => 'manual',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('content');
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

    public function test_ai_vector_config_defaults_are_safe(): void
    {
        config(['ai.embedding.provider' => 'none', 'ai.vector_retrieval.enabled' => false]);

        $this->assertSame('none', config('ai.embedding.provider'));
        $this->assertSame('gemini-embedding-001', config('ai.embedding.model'));
        $this->assertSame(768, config('ai.embedding.dimensions'));
        $this->assertFalse(config('ai.vector_retrieval.enabled'));
    }

    public function test_default_embedding_resolver_returns_null_provider(): void
    {
        config(['ai.embedding.provider' => 'none']);
        $provider = app(EmbeddingProviderResolver::class)->resolve();

        $this->assertInstanceOf(NullEmbeddingProvider::class, $provider);
        $this->assertFalse($provider->isAvailable());
    }

    public function test_null_embedding_provider_returns_failed_document_result(): void
    {
        $result = (new NullEmbeddingProvider)->embedDocument('Materi budaya Mekongga.');

        $this->assertFalse($result->success);
        $this->assertSame([], $result->vector);
        $this->assertSame('document', $result->inputType);
        $this->assertSame('Provider embedding belum dikonfigurasi.', $result->error);
    }

    public function test_null_embedding_provider_returns_failed_query_result(): void
    {
        $result = (new NullEmbeddingProvider)->embedQuery('Apa itu Mekongga?');

        $this->assertFalse($result->success);
        $this->assertSame([], $result->vector);
        $this->assertSame('query', $result->inputType);
        $this->assertSame('Provider embedding belum dikonfigurasi.', $result->error);
    }

    public function test_gemini_embedding_provider_is_unavailable_without_api_key(): void
    {
        $provider = $this->geminiEmbeddingProvider(null);

        $this->assertFalse($provider->isAvailable());
        $this->assertFalse($provider->embedDocument('Materi')->success);
    }

    public function test_gemini_embedding_provider_parses_mocked_document_response(): void
    {
        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/*' => Http::response([
                'embedding' => ['values' => [0.1, 0.2, 0.3]],
            ]),
        ]);

        $result = $this->geminiEmbeddingProvider()->embedDocument('Materi budaya Mekongga.');

        $this->assertTrue($result->success);
        $this->assertSame([0.1, 0.2, 0.3], $result->vector);
        $this->assertSame('gemini', $result->provider);
        $this->assertSame('gemini-embedding-001', $result->model);
        $this->assertSame(3, $result->dimensions);
        $this->assertSame('document', $result->inputType);
        $this->assertSame('RETRIEVAL_DOCUMENT', $result->metadata['task_type']);

        Http::assertSent(fn (Request $request): bool => $request->url() === 'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent?key=test-key'
            && $request->data()['taskType'] === 'RETRIEVAL_DOCUMENT'
            && $request->data()['outputDimensionality'] === 3);
    }

    public function test_gemini_embedding_provider_parses_mocked_query_response(): void
    {
        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/*' => Http::response([
                'embedding' => ['values' => ['0.4', '0.5', '0.6']],
            ]),
        ]);

        $result = $this->geminiEmbeddingProvider()->embedQuery('Apa itu Mekongga?');

        $this->assertTrue($result->success);
        $this->assertSame([0.4, 0.5, 0.6], $result->vector);
        $this->assertSame('query', $result->inputType);
        $this->assertSame('RETRIEVAL_QUERY', $result->metadata['task_type']);

        Http::assertSent(fn (Request $request): bool => $request->data()['taskType'] === 'RETRIEVAL_QUERY');
    }

    public function test_gemini_embedding_provider_returns_failure_on_non_success_response(): void
    {
        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/*' => Http::response(['error' => 'failed'], 500),
        ]);

        $result = $this->geminiEmbeddingProvider()->embedDocument('Materi');

        $this->assertFalse($result->success);
        $this->assertSame('Provider embedding mengembalikan respons gagal.', $result->error);
        $this->assertSame(500, $result->metadata['status']);
    }

    public function test_gemini_embedding_provider_returns_failure_on_malformed_response(): void
    {
        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/*' => Http::response(['embedding' => ['values' => []]]),
        ]);

        $result = $this->geminiEmbeddingProvider()->embedDocument('Materi');

        $this->assertFalse($result->success);
        $this->assertSame('Respons embedding tidak valid.', $result->error);
    }

    public function test_gemini_embedding_provider_returns_failure_on_dimension_mismatch(): void
    {
        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/*' => Http::response([
                'embedding' => ['values' => [0.1, 0.2]],
            ]),
        ]);

        $result = $this->geminiEmbeddingProvider()->embedDocument('Materi');

        $this->assertFalse($result->success);
        $this->assertSame('Dimensi embedding tidak sesuai konfigurasi.', $result->error);
        $this->assertSame(2, $result->metadata['actual_dimensions']);
    }

    public function test_embedding_provider_tests_do_not_allow_real_http_requests(): void
    {
        Http::preventStrayRequests();
        Http::fake([
            'https://generativelanguage.googleapis.com/v1beta/*' => Http::response([
                'embedding' => ['values' => [0.1, 0.2, 0.3]],
            ]),
        ]);

        $result = $this->geminiEmbeddingProvider()->embedQuery('Apa itu Mekongga?');

        $this->assertTrue($result->success);
        Http::assertSentCount(1);
    }

    public function test_ai_vector_doctor_command_runs_without_postgresql(): void
    {
        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite.driver' => 'sqlite',
            'database.connections.sqlite.database' => ':memory:',
        ]);

        $this->artisan('ai:vector:doctor')
            ->expectsOutputToContain('Pemeriksaan Vector RAG EMI')
            ->expectsOutputToContain('Vector retrieval membutuhkan PostgreSQL + pgvector')
            ->assertSuccessful();
    }

    public function test_student_chatbot_returns_fallback_without_published_match(): void
    {
        $student = User::factory()->student()->approved()->create();

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa itu teknologi luar angkasa?',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Hmm, aku belum menemukan jawaban yang tepat untuk pertanyaan itu.')
            ->assertJsonPath('data.source', null)
            ->assertJsonPath('data.matched', false)
            ->assertJsonPath('data.mode', 'default_extractive')
            ->assertJsonPath('data.provider', 'default');
    }

    public function test_student_chatbot_answers_dictionary_exact_indonesian_match(): void
    {
        $student = User::factory()->student()->approved()->create();
        $entry = $this->createDictionaryEntry('air', 'water', 'owai');

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'bahasa Mekongga dari air',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Dalam Kamus EMI, kata "air" memiliki padanan Bahasa Mekongga: "owai".')
            ->assertJsonPath('data.source.title', 'Kamus EMI')
            ->assertJsonPath('data.source.source_type', 'dictionary')
            ->assertJsonPath('data.source.dictionary_entry_id', $entry->id)
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.mode', 'dictionary')
            ->assertJsonPath('data.provider', 'dictionary')
            ->assertJsonPath('data.confidence', 100);
    }

    public function test_student_chatbot_answers_arti_kata_from_dictionary_exact_indonesian_match(): void
    {
        $student = User::factory()->student()->approved()->create();
        $this->createDictionaryEntry('makan', 'eat', 'monga');

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'arti kata makan',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Dalam Kamus EMI, kata "makan" memiliki padanan Bahasa Mekongga: "monga".')
            ->assertJsonPath('data.mode', 'dictionary')
            ->assertJsonPath('data.provider', 'dictionary');
    }

    public function test_student_chatbot_answers_suffix_artinya_from_dictionary(): void
    {
        $student = User::factory()->student()->approved()->create();
        $this->createDictionaryEntry('air dimasak', 'cooked water', 'kulata');

        foreach (['kulata artinya', 'kulata artinya apa', 'apa artinya kulata', 'makna kata kulata'] as $message) {
            $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
                'message' => $message,
            ])->assertOk()
                ->assertJsonPath('data.answer', 'Dalam Kamus EMI, kata "kulata" berarti "air dimasak" dalam Bahasa Indonesia.')
                ->assertJsonPath('data.mode', 'dictionary')
                ->assertJsonPath('data.provider', 'dictionary');
        }
    }

    public function test_dictionary_intent_without_match_does_not_invent_translation(): void
    {
        $student = User::factory()->student()->approved()->create();

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'bahasa Mekongga dari galaksi',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Hmm, aku belum menemukan jawaban yang tepat untuk pertanyaan itu.')
            ->assertJsonPath('data.matched', false)
            ->assertJsonPath('data.provider', 'default');
    }

    public function test_missing_dictionary_word_falls_back_to_basis_ai_chunks(): void
    {
        $student = User::factory()->student()->approved()->create();
        $item = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata galaksi',
            'content' => 'Galaksi dipakai sebagai contoh kata serapan dalam materi Basis AI.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'bahasa Mekongga dari galaksi',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.id', $item->id)
            ->assertJsonPath('data.mode', 'default_extractive');
    }

    public function test_learning_method_kosakata_question_does_not_trigger_dictionary_mode(): void
    {
        $student = User::factory()->student()->approved()->create();
        $item = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Belajar Bahasa Mekongga',
            'content' => 'Cara belajar kosakata Mekongga dimulai dari membaca kata lalu latihan percakapan.',
        ]);
        $this->createDictionaryEntry('kosakata', 'vocabulary', 'kosakata');

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'bagaimana cara belajar kosakata Mekongga',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.id', $item->id)
            ->assertJsonPath('data.mode', 'default_extractive');
    }

    public function test_dictionary_answer_does_not_call_free_ai_provider(): void
    {
        config(['ai.free_provider' => 'groq', 'ai.free_api_key' => 'test-key']);
        Http::fake();
        $student = User::factory()->student()->approved()->create();
        $this->createDictionaryEntry('minum', 'drink', 'inahu');

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'apa bahasa Mekongga dari minum',
        ])->assertOk()
            ->assertJsonPath('data.mode', 'dictionary')
            ->assertJsonPath('data.provider', 'dictionary');

        Http::assertNothingSent();
    }

    public function test_inactive_dictionary_entries_are_ignored(): void
    {
        $student = User::factory()->student()->approved()->create();
        $this->createDictionaryEntry('air', 'water', 'owai', 'inactive');

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'bahasa Mekongga dari air',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Hmm, aku belum menemukan jawaban yang tepat untuk pertanyaan itu.')
            ->assertJsonPath('data.matched', false);
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
            ->assertJsonPath('data.answer', 'Hmm, aku belum menemukan jawaban yang tepat untuk pertanyaan itu.')
            ->assertJsonPath('data.matched', false);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa isi arsip?',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Hmm, aku belum menemukan jawaban yang tepat untuk pertanyaan itu.')
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
            ->assertJsonPath('data.answer', 'Hmm, aku belum menemukan jawaban yang tepat untuk pertanyaan itu.')
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

    public function test_basis_ai_demo_seeder_is_idempotent_and_chatbot_matches_distinct_sources(): void
    {
        $student = User::factory()->student()->approved()->create();
        User::factory()->admin()->create(['email' => 'admin@emi.test']);

        $this->seed(BasisAiDemoSeeder::class);
        $this->seed(BasisAiDemoSeeder::class);

        $this->assertSame(7, AiKnowledgeItem::query()->published()->count());

        $arti = $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'arti mekongga',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->json('data.source.title');

        $bahasa = $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'apa itu bahasa mekongga',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->json('data.source.title');

        $belajar = $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'bagaimana cara belajar kosakata mekongga',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->json('data.source.title');

        $this->assertSame('Arti Nama Mekongga', $arti);
        $this->assertSame('Bahasa Mekongga', $bahasa);
        $this->assertSame('Belajar Bahasa Mekongga', $belajar);
        $this->assertCount(3, array_unique([$arti, $bahasa, $belajar]));
    }

    public function test_ai_free_provider_none_uses_default_extractive(): void
    {
        config(['ai.free_provider' => 'none']);
        $student = User::factory()->student()->approved()->create(['full_name' => 'Nama Siswa Rahasia', 'email' => 'rahasia@example.com']);
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.mode', 'default_extractive')
            ->assertJsonPath('data.provider', 'default')
            ->assertJsonPath('data.fallback_reason', 'free_ai_disabled');
    }

    public function test_no_basis_ai_match_still_calls_external_provider_for_hybrid_grounding(): void
    {
        config(['ai.free_provider' => 'groq', 'ai.free_api_key' => 'test-key', 'ai.vector_retrieval.enabled' => false, 'ai.embedding.provider' => 'none']);
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Jawaban umum tanpa dokumen lokal.']],
                ],
            ]),
        ]);
        $student = User::factory()->student()->approved()->create();

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'pertanyaan luar angkasa',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Jawaban umum tanpa dokumen lokal.')
            ->assertJsonPath('data.matched', false)
            ->assertJsonPath('data.mode', 'free_ai')
            ->assertJsonPath('data.provider', 'groq')
            ->assertJsonPath('data.source', null);

        Http::assertSentCount(1);
    }

    public function test_no_basis_ai_match_falls_back_to_default_when_provider_disabled(): void
    {
        config(['ai.free_provider' => 'none']);
        Http::fake();
        $student = User::factory()->student()->approved()->create();

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'pertanyaan luar angkasa',
        ])->assertOk()
            ->assertJsonPath('data.matched', false)
            ->assertJsonPath('data.provider', 'default')
            ->assertJsonPath('data.fallback_reason', 'free_ai_disabled');

        Http::assertNothingSent();
    }

    public function test_free_provider_error_falls_back_to_default_extractive(): void
    {
        config(['ai.free_provider' => 'groq', 'ai.free_api_key' => 'test-key']);
        Http::fake([
            'api.groq.com/*' => Http::response(['error' => 'failed'], 500),
        ]);
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.mode', 'default_extractive')
            ->assertJsonPath('data.provider', 'default')
            ->assertJsonPath('data.fallback_reason', 'free_ai_error');
    }

    public function test_free_provider_success_returns_free_ai_mode_and_provider(): void
    {
        config(['ai.free_provider' => 'groq', 'ai.free_api_key' => 'test-key', 'ai.free_model' => 'demo-model']);
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Monga berarti makan dalam konteks kosakata yang tersedia.']],
                ],
            ]),
        ]);
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.answer', 'Monga berarti makan dalam konteks kosakata yang tersedia.')
            ->assertJsonPath('data.mode', 'free_ai')
            ->assertJsonPath('data.provider', 'groq')
            ->assertJsonPath('data.matched', true);
    }

    public function test_free_provider_prompt_uses_question_and_basis_ai_reference_without_user_personal_data(): void
    {
        config(['ai.free_provider' => 'groq', 'ai.free_api_key' => 'test-key']);
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Jawaban dari referensi.']],
                ],
            ]),
        ]);
        $student = User::factory()->student()->approved()->create([
            'full_name' => 'Nama Siswa Rahasia',
            'email' => 'rahasia@example.com',
        ]);
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'category' => 'Kosakata',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.mode', 'free_ai');

        Http::assertSent(function (Request $request): bool {
            $messages = collect($request->data()['messages'] ?? []);
            $prompt = (string) ($messages->firstWhere('role', 'user')['content'] ?? '');

            return str_contains($prompt, 'monga makan')
                && str_contains($prompt, 'Kosakata monga')
                && str_contains($prompt, 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.')
                && ! str_contains($prompt, 'Nama Siswa Rahasia')
                && ! str_contains($prompt, 'rahasia@example.com');
        });
    }

    public function test_vector_retriever_is_not_called_when_disabled(): void
    {
        config(['ai.vector_retrieval.enabled' => false]);
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);
        $this->app->instance(VectorChunkRetriever::class, new class extends VectorChunkRetriever
        {
            public function __construct() {}

            public function retrieve(string $message): array
            {
                throw new \RuntimeException('Vector retriever should not be called.');
            }
        });

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.retrieval_mode', 'keyword');
    }

    public function test_dictionary_short_circuits_before_vector_retrieval(): void
    {
        config(['ai.vector_retrieval.enabled' => true]);
        $student = User::factory()->student()->approved()->create();
        $this->createDictionaryEntry('air', 'water', 'owai');
        $this->app->instance(VectorChunkRetriever::class, new class extends VectorChunkRetriever
        {
            public function __construct() {}

            public function retrieve(string $message): array
            {
                throw new \RuntimeException('Vector retriever should not be called.');
            }
        });

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'bahasa Mekongga dari air',
        ])->assertOk()
            ->assertJsonPath('data.mode', 'dictionary')
            ->assertJsonPath('data.provider', 'dictionary');
    }

    public function test_vector_enabled_with_unavailable_provider_falls_back_to_keyword(): void
    {
        config(['ai.vector_retrieval.enabled' => true, 'ai.embedding.provider' => 'none']);
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.retrieval_mode', 'keyword');
    }

    public function test_vector_enabled_with_query_embedding_failure_falls_back_to_keyword(): void
    {
        config(['ai.vector_retrieval.enabled' => true]);
        $this->bindEmbeddingProvider(EmbeddingResult::failure('Gagal query.', 'fake', 'fake-model', 3));
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.retrieval_mode', 'keyword');
    }

    public function test_vector_sql_failure_falls_back_to_keyword(): void
    {
        config(['ai.vector_retrieval.enabled' => true]);
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);
        $this->app->instance(VectorChunkRetriever::class, new class extends VectorChunkRetriever
        {
            public function __construct() {}

            public function retrieve(string $message): array
            {
                return [];
            }
        });

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.source.retrieval_mode', 'keyword');
    }

    public function test_vector_retriever_returns_published_embedded_chunks_only(): void
    {
        if (! $this->canRunVectorSql()) {
            $this->markTestSkipped('pgvector is not available for this test database.');
        }

        config(['ai.vector_retrieval.enabled' => true]);
        $this->bindEmbeddingProvider(EmbeddingResult::success(array_fill(0, 768, 0.1), 'fake', 'fake-model', 768, 'query'));
        $published = $this->embeddedChunk('published', '[0.1,'.implode(',', array_fill(0, 767, '0.1')).']');
        $this->embeddedChunk('draft', '[0.1,'.implode(',', array_fill(0, 767, '0.1')).']');
        $this->embeddedChunk('archived', '[0.1,'.implode(',', array_fill(0, 767, '0.1')).']');

        $results = app(VectorChunkRetriever::class)->retrieve('materi budaya');

        $this->assertSame([$published->id], collect($results)->pluck('chunk.id')->all());
        $this->assertSame('vector', $results[0]['retrieval_mode']);
    }

    public function test_vector_retriever_ignores_non_searchable_pdf_chunks(): void
    {
        if (! $this->canRunVectorSql()) {
            $this->markTestSkipped('pgvector is not available for this test database.');
        }

        config(['ai.vector_retrieval.enabled' => true]);
        $this->bindEmbeddingProvider(EmbeddingResult::success(array_fill(0, 768, 0.1), 'fake', 'fake-model', 768, 'query'));
        $body = $this->embeddedChunk('published', '[0.1,'.implode(',', array_fill(0, 767, '0.1')).']', ['page_type' => 'body', 'searchable' => true]);
        $this->embeddedChunk('published', '[0.1,'.implode(',', array_fill(0, 767, '0.1')).']', ['page_type' => 'table_of_contents', 'searchable' => false]);

        $results = app(VectorChunkRetriever::class)->retrieve('materi budaya');

        $this->assertSame([$body->id], collect($results)->pluck('chunk.id')->all());
    }

    public function test_vector_and_keyword_results_are_deduplicated(): void
    {
        config(['ai.vector_retrieval.enabled' => true]);
        $student = User::factory()->student()->approved()->create();
        $item = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);
        $chunk = $item->chunks()->create([
            'chunk_index' => 0,
            'content' => $item->content,
            'content_hash' => hash('sha256', $item->content),
            'character_count' => mb_strlen($item->content),
            'token_estimate' => 10,
            'metadata' => [],
        ]);
        $this->app->instance(VectorChunkRetriever::class, new class($item, $chunk) extends VectorChunkRetriever
        {
            public function __construct(private readonly AiKnowledgeItem $item, private readonly AiKnowledgeChunk $chunk) {}

            public function retrieve(string $message): array
            {
                return [[
                    'item' => $this->item,
                    'chunk' => $this->chunk,
                    'confidence' => 90,
                    'keywords' => collect(),
                    'retrieval_mode' => 'vector',
                    'similarity_score' => 0.9,
                    'distance' => 0.1,
                ]];
            }
        });

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonCount(1, 'data.sources')
            ->assertJsonPath('data.source.retrieval_mode', 'vector');
    }

    public function test_ai_provider_receives_merged_selected_chunks_only(): void
    {
        config(['ai.vector_retrieval.enabled' => true, 'ai.free_provider' => 'groq', 'ai.free_api_key' => 'test-key']);
        Http::fake([
            'api.groq.com/*' => Http::response([
                'choices' => [
                    ['message' => ['content' => 'Jawaban dari referensi terpilih.']],
                ],
            ]),
        ]);
        $student = User::factory()->student()->approved()->create();
        $vectorItem = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Ritual mosehe',
            'content' => 'Ritual mosehe adalah upacara penyucian wilayah.',
        ]);
        $keywordItem = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Kosakata monga',
            'content' => 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.',
        ]);
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Dokumen tidak terpilih',
            'content' => 'Konten ini tidak boleh masuk prompt provider.',
        ]);
        $vectorChunk = $vectorItem->chunks()->create([
            'chunk_index' => 0,
            'content' => $vectorItem->content,
            'content_hash' => hash('sha256', $vectorItem->content),
            'character_count' => mb_strlen($vectorItem->content),
            'token_estimate' => 10,
            'metadata' => [],
        ]);
        $this->app->instance(VectorChunkRetriever::class, new class($vectorItem, $vectorChunk) extends VectorChunkRetriever
        {
            public function __construct(private readonly AiKnowledgeItem $item, private readonly AiKnowledgeChunk $chunk) {}

            public function retrieve(string $message): array
            {
                return [[
                    'item' => $this->item,
                    'chunk' => $this->chunk,
                    'confidence' => 85,
                    'keywords' => collect(),
                    'retrieval_mode' => 'vector',
                    'similarity_score' => 0.85,
                    'distance' => 0.15,
                ]];
            }
        });

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'monga makan',
        ])->assertOk()
            ->assertJsonPath('data.mode', 'free_ai');

        Http::assertSent(function (Request $request): bool {
            $messages = collect($request->data()['messages'] ?? []);
            $prompt = (string) ($messages->firstWhere('role', 'user')['content'] ?? '');

            return str_contains($prompt, 'Ritual mosehe adalah upacara penyucian wilayah.')
                && str_contains($prompt, 'Kata monga digunakan untuk menjelaskan kegiatan makan sehari-hari.')
                && ! str_contains($prompt, 'Konten ini tidak boleh masuk prompt provider.');
        });
    }

    private function bindEmbeddingProvider(EmbeddingResult $result, bool $available = true): void
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

    private function canRunVectorSql(): bool
    {
        try {
            return DB::getDriverName() === 'pgsql'
                && (bool) (DB::selectOne("select exists (select 1 from pg_extension where extname = 'vector') as installed")->installed ?? false);
        } catch (\Throwable) {
            return false;
        }
    }

    private function embeddedChunk(string $status, string $embedding, array $metadata = []): AiKnowledgeChunk
    {
        $item = AiKnowledgeItem::factory()->create([
            'status' => $status,
            'content' => 'Materi budaya lokal yang sudah memiliki embedding.',
        ]);
        $chunk = $item->chunks()->create([
            'chunk_index' => 0,
            'content' => $item->content,
            'content_hash' => hash('sha256', $item->content),
            'character_count' => mb_strlen($item->content),
            'token_estimate' => 10,
            'metadata' => $metadata,
        ]);
        DB::table('ai_knowledge_chunks')->where('id', $chunk->id)->update(['embedding' => $embedding]);

        return $chunk->refresh();
    }

    private function geminiEmbeddingProvider(?string $apiKey = 'test-key'): GeminiEmbeddingProvider
    {
        return new GeminiEmbeddingProvider(
            provider: 'gemini',
            apiKey: $apiKey,
            model: 'gemini-embedding-001',
            baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
            dimensions: 3,
            timeoutSeconds: 1,
        );
    }

    private function createDictionaryEntry(string $indonesia, string $english, string $mekongga, string $status = 'active'): DictionaryEntry
    {
        $normalizer = app(DictionaryNormalizer::class);

        return DictionaryEntry::factory()->create([
            'indonesia' => $indonesia,
            'english' => $english,
            'mekongga' => $mekongga,
            'indonesia_normalized' => $normalizer->normalize($indonesia),
            'english_normalized' => $normalizer->normalize($english),
            'mekongga_normalized' => $normalizer->normalize($mekongga),
            'status' => $status,
        ]);
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
