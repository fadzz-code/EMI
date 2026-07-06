<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Speaking\StoreAdminSpeakingExerciseRequest;
use App\Http\Requests\Speaking\UpdateAdminSpeakingExerciseRequest;
use App\Http\Resources\SpeakingExerciseResource;
use App\Models\SpeakingExercise;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminSpeakingExerciseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) ($request->query('per_page') ?? 15);
        $status = $request->query('status');

        $exercises = SpeakingExercise::query()
            ->with(['referenceAudio', 'creator'])
            ->whereNull('classroom_id')
            ->when($status, fn ($query) => $query->where('status', $status))
            ->latest()
            ->paginate($perPage);

        return ApiResponse::paginated(
            'Data target speaking global berhasil diambil.',
            $exercises,
            SpeakingExerciseResource::collection($exercises->getCollection())->resolve(),
        );
    }

    public function store(StoreAdminSpeakingExerciseRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['classroom_id'] = null;
        $data['created_by_id'] = $request->user()->id;
        $data['status'] = $data['status'] ?? 'draft';
        $data['language_code'] = 'mekongga';

        $exercise = SpeakingExercise::query()->create($data);

        return ApiResponse::success('Target speaking global berhasil dibuat.', new SpeakingExerciseResource($exercise->load(['referenceAudio', 'creator'])), 201);
    }

    public function show(SpeakingExercise $exercise): JsonResponse
    {
        $this->authorizeAdminExercise($exercise);

        return ApiResponse::success('Detail target speaking global berhasil diambil.', new SpeakingExerciseResource($exercise->load(['referenceAudio', 'creator'])));
    }

    public function update(UpdateAdminSpeakingExerciseRequest $request, SpeakingExercise $exercise): JsonResponse
    {
        $this->authorizeAdminExercise($exercise);

        $data = $request->validated();
        unset($data['created_by_id']);
        unset($data['classroom_id']);

        $exercise->update($data);

        return ApiResponse::success('Target speaking global berhasil diperbarui.', new SpeakingExerciseResource($exercise->refresh()->load(['referenceAudio', 'creator'])));
    }

    public function archive(SpeakingExercise $exercise): JsonResponse
    {
        $this->authorizeAdminExercise($exercise);

        $exercise->forceFill(['status' => 'archived'])->save();

        return ApiResponse::success('Target speaking global berhasil diarsipkan.', new SpeakingExerciseResource($exercise->refresh()->load(['referenceAudio', 'creator'])));
    }

    private function authorizeAdminExercise(SpeakingExercise $exercise): void
    {
        abort_unless($exercise->classroom_id === null, 403, 'Hanya dapat mengelola target speaking global.');
    }
}
