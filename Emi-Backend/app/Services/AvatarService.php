<?php

namespace App\Services;

use App\Models\MediaFile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

class AvatarService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly MediaDeletionService $mediaDeletionService,
        private readonly MediaUploadService $mediaUploadService,
    ) {}

    public function updateAvatar(User $user, UploadedFile $avatar, Request $request): User
    {
        $newAvatar = $this->mediaUploadService->upload($user, $avatar, 'avatar', 'public', [], $request);
        $oldAvatar = $user->avatarMedia;

        $user = DB::transaction(function () use ($user, $newAvatar, $oldAvatar, $request) {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->firstOrFail();
            $lockedUser->forceFill(['avatar_media_id' => $newAvatar->id])->save();

            $this->auditLogService->record('user.avatar_updated', $lockedUser, $lockedUser, [
                'avatar_media_id' => $oldAvatar?->id,
            ], [
                'avatar_media_id' => $newAvatar->id,
            ], [], $request);

            return $lockedUser;
        });

        if ($oldAvatar instanceof MediaFile) {
            $this->mediaDeletionService->deleteUnused($oldAvatar, $user, $request);
        }

        return $user->refresh()->load('avatarMedia');
    }

    public function removeAvatar(User $user, Request $request): User
    {
        $oldAvatar = $user->avatarMedia;

        $user = DB::transaction(function () use ($user, $oldAvatar, $request) {
            $lockedUser = User::query()->whereKey($user->id)->lockForUpdate()->firstOrFail();
            $lockedUser->forceFill(['avatar_media_id' => null])->save();

            $this->auditLogService->record('user.avatar_removed', $lockedUser, $lockedUser, [
                'avatar_media_id' => $oldAvatar?->id,
            ], [
                'avatar_media_id' => null,
            ], [], $request);

            return $lockedUser;
        });

        if ($oldAvatar instanceof MediaFile) {
            $this->mediaDeletionService->deleteUnused($oldAvatar, $user, $request);
        }

        return $user->refresh()->load('avatarMedia');
    }
}
