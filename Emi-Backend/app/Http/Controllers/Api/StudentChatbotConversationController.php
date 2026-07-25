<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Ai\ListChatbotConversationsRequest;
use App\Http\Resources\ChatbotConversationResource;
use App\Services\ChatbotConversationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentChatbotConversationController extends Controller
{
    public function __construct(private readonly ChatbotConversationService $service) {}

    public function index(ListChatbotConversationsRequest $request): JsonResponse
    {
        $conversations = $this->service->listForUser(
            $request->user(),
            $request->validated('status'),
            (int) ($request->validated('per_page') ?? 15),
        );

        return ApiResponse::paginated(
            'Daftar percakapan berhasil diambil.',
            $conversations,
            ChatbotConversationResource::collection($conversations->getCollection())->resolve(),
        );
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $conversation = $this->service->showForUser($request->user(), $id);

        return ApiResponse::success('Detail percakapan berhasil diambil.', new ChatbotConversationResource($conversation));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $this->service->deleteForUser($request->user(), $id);

        return ApiResponse::success('Percakapan berhasil dihapus.', []);
    }
}
