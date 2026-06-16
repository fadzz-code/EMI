<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Dictionary\ConfirmDictionaryImportRequest;
use App\Http\Requests\Dictionary\ListDictionaryImportErrorsRequest;
use App\Http\Requests\Dictionary\ListDictionaryImportsRequest;
use App\Http\Requests\Dictionary\PreviewDictionaryImportRequest;
use App\Http\Resources\DictionaryImportErrorResource;
use App\Http\Resources\DictionaryImportJobResource;
use App\Models\DictionaryImportJob;
use App\Services\DictionaryImportPreviewService;
use App\Services\DictionaryImportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\StreamedResponse;

class DictionaryImportController extends Controller
{
    public function __construct(
        private readonly DictionaryImportPreviewService $previewService,
        private readonly DictionaryImportService $importService,
    ) {}

    public function template(): StreamedResponse
    {
        Gate::authorize('create', DictionaryImportJob::class);
        $header = implode(',', config('dictionary.csv_header'));

        return response()->streamDownload(function () use ($header): void {
            echo $header."\n";
            echo "makan,eat,monga,Verba,inoi monga kade,saya sedang makan nasi,monga.mp3\n";
        }, 'template_import_kamus_emi.csv', [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    public function preview(PreviewDictionaryImportRequest $request): JsonResponse
    {
        Gate::authorize('create', DictionaryImportJob::class);
        $job = $this->previewService->preview(
            $request->user(),
            $request->file('csv_file'),
            $request->file('audio_zip'),
            $request->validated('duplicate_strategy') ?? 'skip',
            $request,
        );

        return ApiResponse::success('Preview import berhasil dibuat.', new DictionaryImportJobResource($job), 201);
    }

    public function index(ListDictionaryImportsRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', DictionaryImportJob::class);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);

        $jobs = DictionaryImportJob::query()
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['duplicate_strategy'] ?? null, fn ($query, $strategy) => $query->where('duplicate_strategy', $strategy))
            ->when($validated['uploaded_by'] ?? null, fn ($query, $userId) => $query->where('uploaded_by', $userId))
            ->when($validated['date_from'] ?? null, fn ($query, $date) => $query->whereDate('created_at', '>=', $date))
            ->when($validated['date_to'] ?? null, fn ($query, $date) => $query->whereDate('created_at', '<=', $date))
            ->latest()
            ->paginate($perPage);

        return ApiResponse::paginated('Riwayat import kamus berhasil diambil.', $jobs, DictionaryImportJobResource::collection($jobs->getCollection())->resolve());
    }

    public function show(string $id): JsonResponse
    {
        $job = DictionaryImportJob::query()->findOrFail($id);
        Gate::authorize('view', $job);

        return ApiResponse::success('Detail import kamus berhasil diambil.', new DictionaryImportJobResource($job));
    }

    public function errors(ListDictionaryImportErrorsRequest $request, string $id): JsonResponse
    {
        $job = DictionaryImportJob::query()->findOrFail($id);
        Gate::authorize('view', $job);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);

        $errors = $job->errors()
            ->when($validated['row_number'] ?? null, fn ($query, $rowNumber) => $query->where('row_number', $rowNumber))
            ->when($validated['field'] ?? null, fn ($query, $field) => $query->where('field', $field))
            ->when($validated['code'] ?? null, fn ($query, $code) => $query->where('code', $code))
            ->orderByRaw('row_number NULLS FIRST')
            ->orderBy('created_at')
            ->paginate($perPage);

        return ApiResponse::paginated('Error import kamus berhasil diambil.', $errors, DictionaryImportErrorResource::collection($errors->getCollection())->resolve());
    }

    public function confirm(ConfirmDictionaryImportRequest $request, string $id): JsonResponse
    {
        $job = DictionaryImportJob::query()->findOrFail($id);
        Gate::authorize('confirm', $job);
        $job = $this->importService->confirm($job, $request->user(), $request);

        return ApiResponse::success('Import kamus masuk antrean pemrosesan.', new DictionaryImportJobResource($job), 202);
    }
}
