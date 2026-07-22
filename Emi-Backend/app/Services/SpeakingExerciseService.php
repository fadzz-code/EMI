<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\SpeakingExercise;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class SpeakingExerciseService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function delete(SpeakingExercise $exercise, User $actor, Request $request): void
    {
        DB::transaction(function () use ($exercise, $actor, $request) {
            $lockedExercise = SpeakingExercise::query()->lockForUpdate()->findOrFail($exercise->id);
            Gate::forUser($actor)->authorize('delete', $lockedExercise);

            if ($lockedExercise->attempts()->withTrashed()->exists()) {
                throw new ApiException(
                    'Latihan yang sudah memiliki hasil siswa tidak dapat dihapus. Arsipkan latihan ini agar tidak lagi tampil kepada siswa.',
                    'SPEAKING_EXERCISE_HAS_ATTEMPTS',
                    422,
                );
            }

            $lockedExercise->delete();
            $this->auditLogService->record('speaking_exercise.deleted', $lockedExercise, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
        });
    }
}
