<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ApplyQuizTemplateRequest;
use App\Models\QuizTemplate;
use App\Services\QuizTemplateApplyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class QuizTemplateApplyController extends Controller
{
    public function __construct(private readonly QuizTemplateApplyService $service) {}

    public function __invoke(ApplyQuizTemplateRequest $request, string $id): JsonResponse
    {
        $template = QuizTemplate::query()->findOrFail($id);
        Gate::authorize('apply', $template);

        return ApiResponse::success('Template kuis selesai diterapkan.', $this->service->apply($template, $request->validated('class_ids'), $request->user(), $request));
    }
}
