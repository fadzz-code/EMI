<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Culture\ApplyCultureTemplateRequest;
use App\Models\CultureTemplate;
use App\Services\CultureTemplateApplyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class CultureTemplateApplyController extends Controller
{
    public function __construct(private readonly CultureTemplateApplyService $service) {}

    public function __invoke(ApplyCultureTemplateRequest $request, string $id): JsonResponse
    {
        $template = CultureTemplate::query()->findOrFail($id);
        Gate::authorize('apply', $template);

        return ApiResponse::success('Template budaya berhasil diterapkan.', $this->service->apply(
            $template,
            $request->validated('class_ids'),
            $request->user(),
            $request,
            (bool) $request->validated('sync_existing', false)
        ));
    }
}
