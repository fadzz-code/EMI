<?php

namespace Tests\Feature;

use App\Models\AiKnowledgeItem;
use App\Models\ChatbotConversation;
use App\Models\ChatbotMessage;
use App\Models\User;
use App\Services\ChatbotService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Mockery\MockInterface;
use Tests\TestCase;

class ChatbotConversationHistoryTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    public function test_first_message_creates_a_new_conversation_owned_by_the_student(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Sejarah Mekongga',
            'content' => 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka. Informasi ini berasal dari Basis AI EMI.',
        ]);

        $response = $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa sejarah Mekongga?',
        ])->assertOk();

        $conversationId = $response->json('data.conversation_id');
        $this->assertNotNull($conversationId);

        $this->assertDatabaseHas('chatbot_conversations', [
            'id' => $conversationId,
            'user_id' => $student->id,
            'status' => 'active',
        ]);

        $this->assertDatabaseHas('chatbot_messages', [
            'chatbot_conversation_id' => $conversationId,
            'role' => 'user',
            'content' => 'Apa sejarah Mekongga?',
        ]);

        $this->assertDatabaseHas('chatbot_messages', [
            'chatbot_conversation_id' => $conversationId,
            'role' => 'assistant',
        ]);
    }

    public function test_second_message_with_conversation_id_appends_to_the_same_conversation(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Sejarah Mekongga',
            'content' => 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka. Informasi ini berasal dari Basis AI EMI.',
        ]);

        $first = $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa sejarah Mekongga?',
        ])->assertOk();
        $conversationId = $first->json('data.conversation_id');

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Ceritakan lebih lanjut.',
            'conversation_id' => $conversationId,
        ])->assertOk()
            ->assertJsonPath('data.conversation_id', $conversationId);

        $this->assertSame(1, ChatbotConversation::query()->where('user_id', $student->id)->count());
        $this->assertSame(4, ChatbotMessage::query()->where('chatbot_conversation_id', $conversationId)->count());
    }

    public function test_student_cannot_continue_another_students_conversation(): void
    {
        $owner = User::factory()->student()->approved()->create();
        $intruder = User::factory()->student()->approved()->create();
        $conversation = ChatbotConversation::query()->create([
            'user_id' => $owner->id,
            'title' => 'Percakapan lama',
            'status' => 'active',
        ]);

        $this->withToken($this->tokenFor($intruder))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Coba akses punya orang lain.',
            'conversation_id' => $conversation->id,
        ])->assertNotFound();
    }

    public function test_student_can_list_only_their_own_conversations(): void
    {
        $student = User::factory()->student()->approved()->create();
        $otherStudent = User::factory()->student()->approved()->create();

        ChatbotConversation::query()->create(['user_id' => $student->id, 'title' => 'Milik saya', 'status' => 'active', 'last_message_at' => now()]);
        ChatbotConversation::query()->create(['user_id' => $otherStudent->id, 'title' => 'Milik orang lain', 'status' => 'active', 'last_message_at' => now()]);

        $response = $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/chatbot/conversations')
            ->assertOk();

        $titles = collect($response->json('data'))->pluck('title')->all();
        $this->assertSame(['Milik saya'], $titles);
    }

    public function test_student_can_view_own_conversation_detail_with_messages(): void
    {
        $student = User::factory()->student()->approved()->create();
        $conversation = ChatbotConversation::query()->create(['user_id' => $student->id, 'title' => 'Sesi 1', 'status' => 'active']);
        ChatbotMessage::query()->create(['chatbot_conversation_id' => $conversation->id, 'role' => 'user', 'content' => 'Halo']);
        ChatbotMessage::query()->create(['chatbot_conversation_id' => $conversation->id, 'role' => 'assistant', 'content' => 'Halo juga', 'citations' => [['id' => 'x', 'title' => 'Sumber X']]]);

        $this->withToken($this->tokenFor($student))->getJson("/api/v1/student/chatbot/conversations/{$conversation->id}")
            ->assertOk()
            ->assertJsonCount(2, 'data.messages')
            ->assertJsonPath('data.messages.1.citations.0.title', 'Sumber X');
    }

    public function test_student_cannot_view_another_students_conversation_detail(): void
    {
        $owner = User::factory()->student()->approved()->create();
        $intruder = User::factory()->student()->approved()->create();
        $conversation = ChatbotConversation::query()->create(['user_id' => $owner->id, 'title' => 'Punya orang lain', 'status' => 'active']);

        $this->withToken($this->tokenFor($intruder))->getJson("/api/v1/student/chatbot/conversations/{$conversation->id}")
            ->assertNotFound();
    }

    public function test_student_can_delete_own_conversation(): void
    {
        $student = User::factory()->student()->approved()->create();
        $conversation = ChatbotConversation::query()->create(['user_id' => $student->id, 'title' => 'Hapus saya', 'status' => 'active']);

        $this->withToken($this->tokenFor($student))->deleteJson("/api/v1/student/chatbot/conversations/{$conversation->id}")
            ->assertOk();

        $this->assertSoftDeleted('chatbot_conversations', ['id' => $conversation->id]);
    }

    public function test_student_cannot_delete_another_students_conversation(): void
    {
        $owner = User::factory()->student()->approved()->create();
        $intruder = User::factory()->student()->approved()->create();
        $conversation = ChatbotConversation::query()->create(['user_id' => $owner->id, 'title' => 'Jangan dihapus', 'status' => 'active']);

        $this->withToken($this->tokenFor($intruder))->deleteJson("/api/v1/student/chatbot/conversations/{$conversation->id}")
            ->assertNotFound();

        $this->assertDatabaseHas('chatbot_conversations', ['id' => $conversation->id, 'deleted_at' => null]);
    }

    public function test_guest_cannot_access_any_chatbot_conversation_endpoint(): void
    {
        $this->postJson('/api/v1/student/chatbot/messages', ['message' => 'Halo'])->assertUnauthorized();
        $this->getJson('/api/v1/student/chatbot/conversations')->assertUnauthorized();
    }

    public function test_teacher_cannot_use_student_chatbot_endpoints(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Halo',
        ])->assertForbidden();
    }

    public function test_student_cannot_use_teacher_chatbot_endpoints(): void
    {
        $student = User::factory()->student()->approved()->create();

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/teacher/chatbot/messages', [
            'message' => 'Halo',
        ])->assertForbidden();
    }

    public function test_teacher_can_use_own_chatbot_endpoints_with_isolated_conversation(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Sejarah Mekongga',
            'content' => 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka. Informasi ini berasal dari Basis AI EMI.',
        ]);

        $response = $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/teacher/chatbot/messages', [
            'message' => 'Apa sejarah Mekongga?',
        ])->assertOk();

        $conversationId = $response->json('data.conversation_id');
        $this->assertNotNull($conversationId);
        $this->assertDatabaseHas('chatbot_conversations', [
            'id' => $conversationId,
            'user_id' => $teacher->id,
            'status' => 'active',
        ]);

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/chatbot/conversations')
            ->assertOk()
            ->assertJsonPath('data.0.id', $conversationId);

        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/teacher/chatbot/conversations/{$conversationId}")
            ->assertOk()
            ->assertJsonPath('data.id', $conversationId);

        $this->withToken($this->tokenFor($teacher))->deleteJson("/api/v1/teacher/chatbot/conversations/{$conversationId}")
            ->assertOk();

        $this->assertSoftDeleted('chatbot_conversations', ['id' => $conversationId]);
    }

    public function test_teacher_cannot_access_a_students_conversation_via_teacher_chatbot_endpoints(): void
    {
        $student = User::factory()->student()->approved()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $conversation = ChatbotConversation::query()->create([
            'user_id' => $student->id,
            'title' => 'Percakapan siswa',
            'status' => 'active',
        ]);

        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/teacher/chatbot/conversations/{$conversation->id}")
            ->assertNotFound();
    }

    public function test_retrieval_runs_exactly_once_per_message(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Sejarah Mekongga',
            'content' => 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka. Informasi ini berasal dari Basis AI EMI.',
        ]);

        $this->partialMock(ChatbotService::class, function (MockInterface $mock) {
            $mock->shouldReceive('respond')
                ->once()
                ->andReturn([
                    'answer' => 'Jawaban tunggal.',
                    'source' => null,
                    'matched' => false,
                    'mode' => 'default_extractive',
                    'provider' => 'default',
                    'confidence' => 0,
                ]);
        });

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa sejarah Mekongga?',
        ])->assertOk();
    }

    public function test_citations_are_persisted_and_returned_through_resource(): void
    {
        $student = User::factory()->student()->approved()->create();
        $item = AiKnowledgeItem::factory()->published()->create([
            'title' => 'Sejarah Mekongga',
            'category' => 'Budaya',
            'content' => 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka. Informasi ini berasal dari Basis AI EMI.',
        ]);

        $response = $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Apa sejarah Mekongga?',
        ])->assertOk();

        $conversationId = $response->json('data.conversation_id');
        $assistantMessage = ChatbotMessage::query()
            ->where('chatbot_conversation_id', $conversationId)
            ->where('role', 'assistant')
            ->first();

        $this->assertNotNull($assistantMessage->citations);
        $this->assertNotEmpty($assistantMessage->citations);
        $this->assertSame($item->id, $assistantMessage->citations[0]['id']);

        $this->withToken($this->tokenFor($student))->getJson("/api/v1/student/chatbot/conversations/{$conversationId}")
            ->assertOk()
            ->assertJsonPath('data.messages.1.citations.0.id', $item->id);
    }

    public function test_chatbot_endpoint_is_rate_limited(): void
    {
        $student = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Sejarah Mekongga',
            'content' => 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka. Informasi ini berasal dari Basis AI EMI.',
        ]);
        $token = $this->tokenFor($student);

        for ($i = 0; $i < 15; $i++) {
            $this->withToken($token)->postJson('/api/v1/student/chatbot/messages', [
                'message' => "Pertanyaan ke-{$i} tentang sejarah Mekongga?",
            ])->assertOk();
        }

        $this->withToken($token)->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Pertanyaan yang melebihi batas.',
        ])->assertStatus(429);
    }

    public function test_rate_limit_is_scoped_per_user_not_globally(): void
    {
        $studentA = User::factory()->student()->approved()->create();
        $studentB = User::factory()->student()->approved()->create();
        AiKnowledgeItem::factory()->published()->create([
            'title' => 'Sejarah Mekongga',
            'content' => 'Sejarah Kerajaan Mekongga berkembang di wilayah Kolaka. Informasi ini berasal dari Basis AI EMI.',
        ]);

        $tokenA = $this->tokenFor($studentA);
        for ($i = 0; $i < 15; $i++) {
            $this->withToken($tokenA)->postJson('/api/v1/student/chatbot/messages', [
                'message' => "Pertanyaan A ke-{$i} tentang sejarah Mekongga?",
            ])->assertOk();
        }

        $this->withToken($this->tokenFor($studentB))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Pertanyaan dari siswa lain.',
        ])->assertOk();
    }

    public function test_conversation_id_must_be_a_valid_uuid(): void
    {
        $student = User::factory()->student()->approved()->create();

        $this->withToken($this->tokenFor($student))->postJson('/api/v1/student/chatbot/messages', [
            'message' => 'Halo',
            'conversation_id' => 'not-a-uuid',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('conversation_id');
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
