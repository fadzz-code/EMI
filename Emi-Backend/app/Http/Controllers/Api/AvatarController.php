<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Media\UploadAvatarRequest;
use App\Http\Resources\UserResource;
use App\Services\AvatarService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AvatarController extends Controller
{
    public function __construct(private readonly AvatarService $avatarService) {}

    public function store(UploadAvatarRequest $request): JsonResponse
    {
        $user = $this->avatarService->updateAvatar($request->user()->load('avatarMedia'), $request->file('avatar'), $request);

        return ApiResponse::success('Avatar berhasil diperbarui.', new UserResource($user), 201);
    }

    public function destroy(Request $request): JsonResponse
    {
        $user = $this->avatarService->removeAvatar($request->user()->load('avatarMedia'), $request);

        return ApiResponse::success('Avatar berhasil dihapus.', new UserResource($user));
    }
}
