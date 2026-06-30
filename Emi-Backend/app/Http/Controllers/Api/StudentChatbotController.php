<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Ai\StudentChatbotMessageRequest;
use App\Services\ChatbotService;
use Illuminate\Http\JsonResponse;

class StudentChatbotController extends Controller
{
    public function __construct(private readonly ChatbotService $service) {}

    public function store(StudentChatbotMessageRequest $request): JsonResponse
    {
        $result = $this->service->respond($request->user(), $request->validated('message'));

        return ApiResponse::success('Respons Chatbot AI berhasil dibuat.', $result);
    }
}
