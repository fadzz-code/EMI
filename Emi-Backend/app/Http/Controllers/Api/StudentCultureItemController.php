<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\ClassCultureItemResource;
use App\Models\ClassCultureItem;
use App\Services\CultureAccessService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentCultureItemController extends Controller
{
    public function __construct(private readonly CultureAccessService $accessService) {}

    public function index(Request $request): JsonResponse
    {
        $classIds = $this->accessService->studentClassIds($request->user());
        $requestedClassId = $request->query('class_id');

        if ($requestedClassId) {
            $classIds = in_array($requestedClassId, $classIds, true) ? [$requestedClassId] : [];
        }

        if ($classIds === []) {
            return ApiResponse::success('Data budaya kosong.', []);
        }

        $perPage = (int) ($request->query('per_page') ?? 15);
        $items = ClassCultureItem::query()
            ->whereIn('class_id', $classIds)
            ->where('status', 'published')
            ->whereHas('schoolClass', fn ($q) => $q->where('status', 'active')->whereHas('school', fn ($sq) => $sq->where('status', 'active')))
            ->with('media', 'schoolClass.school')
            ->orderBy('display_order', 'asc')
            ->paginate($perPage);

        return ApiResponse::paginated('Data budaya Mekongga berhasil diambil.', $items, ClassCultureItemResource::collection($items->getCollection())->resolve());
    }
}
