<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ChatbotConversation;
use App\Models\ChatbotMessage;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ChatbotConversationService
{
    public function __construct(private readonly ChatbotService $chatbotService) {}

    /**
     * Sends one user message through the chatbot, retrieves an answer exactly
     * once, and persists both turns to the conversation owned by $student.
     *
     * If $conversationId is null, a new conversation is created. If it is
     * provided, ownership is enforced (a student can never write into
     * another user's conversation, even by guessing/brute-forcing a UUID).
     */
    public function sendMessage(User $student, string $message, ?string $conversationId = null): array
    {
        $conversation = $conversationId !== null
            ? $this->findOwnedOrFail($student, $conversationId)
            : null;

        // The retrieval/answer call happens exactly once per user message,
        // regardless of whether we are starting a new conversation or
        // continuing an existing one.
        $result = $this->chatbotService->respond($student, $message);

        return DB::transaction(function () use ($student, $message, $conversation, $result): array {
            $conversation = $conversation ?? ChatbotConversation::query()->create([
                'user_id' => $student->id,
                'title' => $this->titleFromMessage($message),
                'status' => 'active',
            ]);

            ChatbotMessage::query()->create([
                'chatbot_conversation_id' => $conversation->id,
                'role' => 'user',
                'content' => $message,
            ]);

            $citations = $this->citationsFromResult($result);

            ChatbotMessage::query()->create([
                'chatbot_conversation_id' => $conversation->id,
                'role' => 'assistant',
                'content' => (string) ($result['answer'] ?? ''),
                'citations' => $citations,
                'retrieval_mode' => $result['mode'] ?? null,
                'provider' => $result['provider'] ?? null,
                'confidence' => $result['confidence'] ?? null,
                'fallback_reason' => $result['fallback_reason'] ?? null,
            ]);

            $conversation->forceFill(['last_message_at' => now()])->save();

            return [
                'conversation_id' => $conversation->id,
                'response' => $result,
            ];
        });
    }

    public function listForUser(User $student, ?string $status = null, int $perPage = 15)
    {
        return ChatbotConversation::query()
            ->forUser($student)
            ->when($status, fn ($query, $value) => $query->where('status', $value))
            ->orderByDesc('last_message_at')
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    public function showForUser(User $student, string $conversationId): ChatbotConversation
    {
        return $this->findOwnedOrFail($student, $conversationId)->load('messages');
    }

    public function deleteForUser(User $student, string $conversationId): void
    {
        $conversation = $this->findOwnedOrFail($student, $conversationId);
        $conversation->delete();
    }

    private function findOwnedOrFail(User $student, string $conversationId): ChatbotConversation
    {
        $conversation = ChatbotConversation::query()
            ->forUser($student)
            ->find($conversationId);

        if ($conversation === null) {
            throw new ApiException('Percakapan tidak ditemukan.', 'CONVERSATION_NOT_FOUND', 404);
        }

        return $conversation;
    }

    private function titleFromMessage(string $message): string
    {
        $normalized = trim(preg_replace('/\s+/u', ' ', $message) ?? $message);

        return Str::limit($normalized, 60);
    }

    private function citationsFromResult(array $result): array
    {
        if (isset($result['sources']) && is_array($result['sources'])) {
            return $result['sources'];
        }

        if (isset($result['source']) && is_array($result['source'])) {
            return [$result['source']];
        }

        return [];
    }
}
