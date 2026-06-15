<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Public\PublicSchoolClassesRequest;
use App\Http\Requests\Public\PublicSchoolIndexRequest;
use App\Http\Resources\SchoolClassPublicResource;
use App\Http\Resources\SchoolPublicResource;
use App\Models\School;
use Illuminate\Http\JsonResponse;

class PublicLookupController extends Controller
{
    public function schools(PublicSchoolIndexRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $perPage = min((int) ($validated['per_page'] ?? 15), 100);
        $sortBy = $validated['sort_by'] ?? 'name';
        $sortDirection = $validated['sort_direction'] ?? 'asc';

        $schools = School::query()
            ->where('status', 'active')
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where('name', 'ilike', "%{$search}%"))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated(
            'Data sekolah berhasil diambil.',
            $schools,
            SchoolPublicResource::collection($schools->getCollection())->resolve()
        );
    }

    public function classes(PublicSchoolClassesRequest $request, string $schoolId): JsonResponse
    {
        $school = School::query()
            ->whereKey($schoolId)
            ->where('status', 'active')
            ->firstOrFail();

        $validated = $request->validated();
        $perPage = min((int) ($validated['per_page'] ?? 15), 100);
        $sortBy = $validated['sort_by'] ?? 'name';
        $sortDirection = $validated['sort_direction'] ?? 'asc';

        $classes = $school->classes()
            ->where('status', 'active')
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where('name', 'ilike', "%{$search}%"))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated(
            'Data kelas berhasil diambil.',
            $classes,
            SchoolClassPublicResource::collection($classes->getCollection())->resolve()
        );
    }
}
