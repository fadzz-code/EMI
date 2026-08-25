<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Learning\ApplyModuleTemplateRequest;
use App\Models\ModuleTemplate;
use App\Services\ModuleTemplateApplyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class ModuleTemplateApplyController extends Controller
{
    public function __construct(private readonly ModuleTemplateApplyService $service) {}

    public function __invoke(ApplyModuleTemplateRequest $request, string $id): JsonResponse
    {
        $template = ModuleTemplate::query()->findOrFail($id);
        Gate::authorize('apply', $template);

        return ApiResponse::success('Template modul berhasil diterapkan.', $this->service->apply(
            $template,
            $request->validated('class_ids'),
            $request->user(),
            $request,
            (bool) $request->validated('sync_existing', false),
            (bool) $request->validated('publish_class_modules', false),
        ));
    }
}
