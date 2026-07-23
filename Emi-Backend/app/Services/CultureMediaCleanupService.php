<?php

namespace App\Services;

use App\Models\MediaFile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Throwable;

class CultureMediaCleanupService
{
    public function __construct(private readonly MediaDeletionService $mediaDeletionService) {}

    public function afterCommit(array $mediaIds, User $actor, Request $request): void
    {
        $ids = array_values(array_unique(array_filter($mediaIds)));
        if ($ids === []) {
            return;
        }

        DB::afterCommit(function () use ($ids, $actor, $request) {
            foreach ($ids as $id) {
                $media = MediaFile::query()->active()->find($id);
                if (! $media) {
                    continue;
                }

                try {
                    $this->mediaDeletionService->deleteUnused($media, $actor, $request);
                } catch (Throwable $exception) {
                    report($exception);
                }
            }
        });
    }
}
