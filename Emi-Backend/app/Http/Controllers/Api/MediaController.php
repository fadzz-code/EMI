<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Media\TemporaryMediaUrlRequest;
use App\Http\Requests\Media\UploadMediaRequest;
use App\Http\Resources\MediaFileResource;
use App\Models\MediaFile;
use App\Services\MediaAccessService;
use App\Services\MediaDeletionService;
use App\Services\MediaUploadService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\StreamedResponse;

class MediaController extends Controller
{
    public function __construct(
        private readonly MediaAccessService $mediaAccessService,
        private readonly MediaDeletionService $mediaDeletionService,
        private readonly MediaUploadService $mediaUploadService,
    ) {}

    public function store(UploadMediaRequest $request): JsonResponse
    {
        $mediaFile = $this->mediaUploadService->upload(
            $request->user(),
            $request->file('file'),
            $request->validated('purpose'),
            $request->validated('visibility'),
            $request->validated('metadata') ?? [],
            $request,
        );

        return ApiResponse::success('Media berhasil diunggah.', new MediaFileResource($mediaFile), 201);
    }

    public function show(string $id): JsonResponse
    {
        $mediaFile = MediaFile::query()->active()->findOrFail($id);
        Gate::authorize('view', $mediaFile);

        return ApiResponse::success('Detail media berhasil diambil.', new MediaFileResource($mediaFile));
    }

    public function temporaryUrl(TemporaryMediaUrlRequest $request, string $id): JsonResponse
    {
        $mediaFile = MediaFile::query()->active()->findOrFail($id);

        if ($mediaFile->isPublic()) {
            throw new ApiException('Media publik tidak memerlukan tautan sementara.', 'PUBLIC_MEDIA_DOES_NOT_REQUIRE_TEMPORARY_URL', 409);
        }

        Gate::authorize('requestTemporaryUrl', $mediaFile);

        $minutes = (int) ($request->validated('expires_in_minutes') ?? config('media.signed_url_ttl_minutes'));
        $expiresAt = now()->addMinutes($minutes);

        return ApiResponse::success('Tautan sementara berhasil dibuat.', [
            'url' => $this->mediaAccessService->temporaryUrl($mediaFile, $expiresAt, $request->validated('disposition') ?? 'inline'),
            'expires_at' => $expiresAt->toISOString(),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $mediaFile = MediaFile::query()->active()->findOrFail($id);
        Gate::authorize('delete', $mediaFile);

        $this->mediaDeletionService->delete($mediaFile, $request->user(), $request);

        return ApiResponse::success('Media berhasil dihapus.', []);
    }

    public function publicContent(string $id): StreamedResponse
    {
        $mediaFile = MediaFile::query()->active()->findOrFail($id);
        Gate::authorize('viewPublicContent', $mediaFile);

        return $this->mediaAccessService->streamPublic($mediaFile);
    }

    public function download(Request $request, string $id): StreamedResponse
    {
        $mediaFile = MediaFile::query()->active()->findOrFail($id);
        $disposition = $request->query('disposition') === 'attachment' ? 'attachment' : 'inline';

        return $this->mediaAccessService->streamPrivate($mediaFile, $disposition);
    }
}
