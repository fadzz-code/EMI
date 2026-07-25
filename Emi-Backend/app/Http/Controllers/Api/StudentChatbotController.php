<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Ai\StudentChatbotMessageRequest;
use App\Services\ChatbotConversationService;
use Illuminate\Http\JsonResponse;

class StudentChatbotController extends Controller
{
    public function __construct(private readonly ChatbotConversationService $service) {}

    public function store(StudentChatbotMessageRequest $request): JsonResponse
    {
        $outcome = $this->service->sendMessage(
            $request->user(),
            $request->validated('message'),
            $request->validated('conversation_id'),
        );

        return ApiResponse::success('Respons Chatbot AI berhasil dibuat.', [
            ...$outcome['response'],
            'conversation_id' => $outcome['conversation_id'],
        ]);
    }
}
