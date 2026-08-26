<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Services\OfflineManifestService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentOfflineManifestController extends Controller
{
    public function __invoke(Request $request, OfflineManifestService $service): JsonResponse
    {
        $manifest = $service->build($request->user());
        $etag = '"'.hash('sha256', json_encode([
            'schema' => $manifest['schema'],
            'schema_version' => $manifest['schema_version'],
            'modules' => $manifest['modules'],
            'dictionaries' => $manifest['dictionaries'],
        ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR)).'"';

        if ($request->headers->get('If-None-Match') === $etag) {
            return response()->json(null, 304)->withHeaders(['ETag' => $etag]);
        }

        return ApiResponse::success('Manifest offline berhasil diambil.', $manifest)->withHeaders(['ETag' => $etag]);
    }
}
