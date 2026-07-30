<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Speaking\StoreTeacherSpeakingExerciseRequest;
use App\Http\Requests\Speaking\UpdateTeacherSpeakingExerciseRequest;
use App\Http\Resources\SpeakingExerciseResource;
use App\Models\SpeakingExercise;
use App\Services\SpeakingExerciseService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class TeacherSpeakingExerciseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $classIds = $this->activeTeacherClassIds($request);
        $perPage = (int) ($request->query('per_page') ?? 15);
        $status = $request->query('status');
        $classroomId = $request->query('classroom_id');

        $exercises = SpeakingExercise::query()
            ->with(['referenceAudio', 'classroom.school', 'creator'])
            ->withCount('attempts')
            ->whereIn('classroom_id', $classIds)
            ->when($status, fn ($query) => $query->where('status', $status))
            ->when($classroomId, fn ($query) => $query->where('classroom_id', $classroomId))
            ->latest()
            ->paginate($perPage);

        return ApiResponse::paginated(
            'Data target speaking berhasil diambil.',
            $exercises,
            SpeakingExerciseResource::collection($exercises->getCollection())->resolve(),
        );
    }

    public function templates(Request $request): JsonResponse
    {
        $perPage = (int) ($request->query('per_page') ?? 15);

        $templates = SpeakingExercise::query()
            ->with(['referenceAudio', 'creator'])
            ->whereNull('classroom_id')
            ->published()
            ->latest()
            ->paginate($perPage);

        return ApiResponse::paginated(
            'Data template speaking berhasil diambil.',
            $templates,
            SpeakingExerciseResource::collection($templates->getCollection())->resolve(),
        );
    }

    public function store(StoreTeacherSpeakingExerciseRequest $request): JsonResponse
    {
        $data = $request->validated();
        $template = isset($data['template_exercise_id'])
            ? SpeakingExercise::query()->whereNull('classroom_id')->published()->findOrFail($data['template_exercise_id'])
            : null;

        unset($data['template_exercise_id']);

        if ($template) {
            $data = array_merge([
                'title' => $template->title,
                'prompt_text' => $template->prompt_text,
                'target_text' => $template->target_text,
                'target_translation' => $template->target_translation,
                'reference_audio_media_id' => $template->reference_audio_media_id,
                'language_code' => $template->language_code,
                'difficulty' => $template->difficulty,
                'status' => 'draft',
                'metadata' => $template->metadata,
            ], $data);
        }

        $data['created_by_id'] = $request->user()->id;
        $data['status'] = $data['status'] ?? 'draft';
        $data['language_code'] = $data['language_code'] ?? 'mekongga';

        $exercise = SpeakingExercise::query()->create($data);

        return ApiResponse::success('Target speaking berhasil dibuat.', new SpeakingExerciseResource($exercise->load(['referenceAudio', 'classroom.school', 'creator'])), 201);
    }

    public function show(Request $request, SpeakingExercise $exercise): JsonResponse
    {
        $this->authorizeTeacherExercise($request, $exercise);

        return ApiResponse::success('Detail target speaking berhasil diambil.', new SpeakingExerciseResource($exercise->load(['classroom.school', 'creator'])->loadCount('attempts')));
    }

    public function update(UpdateTeacherSpeakingExerciseRequest $request, SpeakingExercise $exercise): JsonResponse
    {
        $this->authorizeTeacherExercise($request, $exercise);

        $data = $request->validated();
        unset($data['created_by_id']);
        unset($data['template_exercise_id']);

        $exercise->update($data);

        return ApiResponse::success('Target speaking berhasil diperbarui.', new SpeakingExerciseResource($exercise->refresh()->load(['classroom.school', 'creator'])));
    }

    public function destroy(Request $request, SpeakingExercise $exercise, SpeakingExerciseService $service): JsonResponse
    {
        Gate::authorize('delete', $exercise);
        $service->delete($exercise, $request->user(), $request);

        return ApiResponse::success('Latihan speaking berhasil dihapus.');
    }

    public function archive(Request $request, SpeakingExercise $exercise): JsonResponse
    {
        $this->authorizeTeacherExercise($request, $exercise);

        $exercise->forceFill(['status' => 'archived'])->save();

        return ApiResponse::success('Target speaking berhasil diarsipkan.', new SpeakingExerciseResource($exercise->refresh()->load(['classroom.school', 'creator'])));
    }

    private function authorizeTeacherExercise(Request $request, SpeakingExercise $exercise): void
    {
        abort_unless($exercise->classroom_id !== null, 403);
        abort_unless($this->activeTeacherClassIds($request)->contains($exercise->classroom_id), 403);
    }

    private function activeTeacherClassIds(Request $request)
    {
        return $request->user()->teacherClassAssignments()->where('is_active', true)->pluck('class_id');
    }
}
