<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ListQuizTemplatesRequest;
use App\Http\Requests\Quiz\PublishQuizTemplateRequest;
use App\Http\Requests\Quiz\StoreQuizTemplateRequest;
use App\Http\Requests\Quiz\UpdateQuizTemplateRequest;
use App\Http\Resources\QuizTemplateResource;
use App\Models\QuizTemplate;
use App\Models\SchoolClass;
use App\Services\QuizTemplateApplyService;
use App\Services\QuizTemplateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminQuizTemplateController extends Controller
{
    public function __construct(
        private readonly QuizTemplateService $service,
        private readonly QuizTemplateApplyService $applyService,
    ) {}

    public function index(ListQuizTemplatesRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', QuizTemplate::class);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'created_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';

        $templates = QuizTemplate::query()
            ->withCount('questions')
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(fn ($inner) => $inner->where('title', 'ilike', "%{$search}%")->orWhere('description', 'ilike', "%{$search}%")))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['created_by'] ?? null, fn ($query, $createdBy) => $query->where('created_by', $createdBy))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data template kuis berhasil diambil.', $templates, QuizTemplateResource::collection($templates->getCollection())->resolve());
    }

    public function store(StoreQuizTemplateRequest $request): JsonResponse
    {
        Gate::authorize('create', QuizTemplate::class);

        return ApiResponse::success('Template kuis berhasil dibuat.', new QuizTemplateResource($this->service->create($request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $template = QuizTemplate::query()->with('questions.options', 'questions.imageMedia')->findOrFail($id);
        Gate::authorize('view', $template);

        return ApiResponse::success('Detail template kuis berhasil diambil.', new QuizTemplateResource($template));
    }

    public function update(UpdateQuizTemplateRequest $request, string $id): JsonResponse
    {
        $template = QuizTemplate::query()->findOrFail($id);
        Gate::authorize('update', $template);

        return ApiResponse::success('Template kuis berhasil diperbarui.', new QuizTemplateResource($this->service->update($template, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $template = QuizTemplate::query()->findOrFail($id);
        Gate::authorize('delete', $template);
        $this->service->delete($template, $request->user(), $request);

        return ApiResponse::success('Template kuis berhasil dihapus.', []);
    }

    public function publish(PublishQuizTemplateRequest $request, string $id): JsonResponse
    {
        $template = QuizTemplate::query()->findOrFail($id);
        Gate::authorize('update', $template);
        $template = $this->service->publish($template, $request->user(), $request);
        $distribution = null;

        if ($request->validated('apply_to_all_active_classes', false)) {
            $classIds = SchoolClass::query()
                ->where('status', 'active')
                ->whereHas('school', fn ($query) => $query->where('status', 'active'))
                ->pluck('id')
                ->all();
            $distribution = $this->applyService->apply($template, $classIds, $request->user(), $request);
        }

        $data = (new QuizTemplateResource($template))->resolve();
        $data['distribution'] = $distribution;

        return ApiResponse::success('Template kuis berhasil dipublish.', $data);
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $template = QuizTemplate::query()->findOrFail($id);
        Gate::authorize('update', $template);

        return ApiResponse::success('Template kuis berhasil diarsipkan.', new QuizTemplateResource($this->service->archive($template, $request->user(), $request)));
    }
}
