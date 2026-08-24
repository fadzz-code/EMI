<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Speaking\ApplySpeakingTemplateRequest;
use App\Models\SpeakingExercise;
use App\Services\SpeakingTemplateApplyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class SpeakingTemplateApplyController extends Controller
{
    public function __construct(private readonly SpeakingTemplateApplyService $service) {}

    public function __invoke(ApplySpeakingTemplateRequest $request, string $id): JsonResponse
    {
        $template = SpeakingExercise::query()->findOrFail($id);
        Gate::authorize('apply', $template);

        return ApiResponse::success(
            'Template speaking berhasil diterapkan.',
            $this->service->apply(
                $template,
                $request->validated('class_ids'),
                $request->user(),
                $request,
                (bool) $request->validated('sync_existing', false),
            ),
        );
    }
}
