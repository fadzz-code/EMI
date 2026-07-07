<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DictionaryEntryService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly DictionaryAudioService $dictionaryAudioService,
        private readonly DictionaryNormalizer $normalizer,
    ) {}

    public function create(array $data, User $admin, Request $request): DictionaryEntry
    {
        return DB::transaction(function () use ($data, $admin, $request) {
            $this->activeCategory($data['category_id']);
            $this->dictionaryAudioService->validateAudio($data['audio_media_id'] ?? null);

            try {
                $entry = DictionaryEntry::query()->create($this->payload($data) + [
                    'created_by' => $admin->id,
                ]);
            } catch (QueryException $e) {
                throw new ApiException('Entri kamus dengan tiga bahasa tersebut sudah ada.', 'DICTIONARY_DUPLICATE', 409);
            }

            $this->auditLogService->record('dictionary.entry_created', $entry, $admin, null, $entry->only(['indonesia', 'english', 'mekongga', 'status']), [], $request);

            return $entry->load(['category', 'audioMedia']);
        });
    }

    public function update(DictionaryEntry $entry, array $data, User $admin, Request $request): DictionaryEntry
    {
        return DB::transaction(function () use ($entry, $data, $admin, $request) {
            $entry = DictionaryEntry::query()->whereKey($entry->id)->lockForUpdate()->firstOrFail();
            $oldValues = $entry->only(['category_id', 'indonesia', 'english', 'mekongga', 'example_mekongga', 'example_indonesia', 'audio_media_id', 'status']);

            if (isset($data['category_id'])) {
                $this->activeCategory($data['category_id']);
            }

            if (array_key_exists('audio_media_id', $data)) {
                $this->dictionaryAudioService->validateAudio($data['audio_media_id']);
            }

            $merged = array_merge($entry->only([
                'category_id',
                'indonesia',
                'english',
                'mekongga',
                'example_mekongga',
                'example_indonesia',
                'audio_media_id',
                'status',
            ]), $data);

            try {
                $entry->fill($this->payload($merged) + [
                    'updated_by' => $admin->id,
                ])->save();
            } catch (QueryException $e) {
                throw new ApiException('Entri kamus dengan tiga bahasa tersebut sudah ada.', 'DICTIONARY_DUPLICATE', 409);
            }

            $this->auditLogService->record('dictionary.entry_updated', $entry, $admin, $oldValues, $entry->only(['category_id', 'indonesia', 'english', 'mekongga', 'example_mekongga', 'example_indonesia', 'audio_media_id', 'status']), [], $request);

            return $entry->refresh()->load(['category', 'audioMedia']);
        });
    }

    public function delete(DictionaryEntry $entry, User $admin, Request $request): DictionaryEntry
    {
        return DB::transaction(function () use ($entry, $admin, $request) {
            $entry = DictionaryEntry::query()->whereKey($entry->id)->lockForUpdate()->firstOrFail();
            $entry->forceFill(['status' => 'inactive', 'updated_by' => $admin->id])->save();
            $entry->delete();

            $this->auditLogService->record('dictionary.entry_deleted', $entry, $admin, ['status' => 'active'], ['status' => 'inactive'], [], $request);

            return $entry;
        });
    }

    private function activeCategory(string $categoryId): DictionaryCategory
    {
        $category = DictionaryCategory::query()->active()->findOrFail($categoryId);

        return $category;
    }

    public function payload(array $data): array
    {
        $indonesia = $this->normalizer->normalizeDisplay($data['indonesia']) ?? '';
        $english = $this->normalizer->normalizeDisplay($data['english']) ?? '';
        $mekongga = $this->normalizer->normalizeDisplay($data['mekongga']) ?? '';
        $code = $this->normalizer->normalizeDisplay($data['code'] ?? null);

        return [
            'category_id' => $data['category_id'],
            'code' => $code,
            'code_normalized' => $code ? $this->normalizer->normalize($code) : null,
            'indonesia' => $indonesia,
            'english' => $english,
            'mekongga' => $mekongga,
            'indonesia_normalized' => $this->normalizer->normalize($indonesia),
            'english_normalized' => $this->normalizer->normalize($english),
            'mekongga_normalized' => $this->normalizer->normalize($mekongga),
            'example_mekongga' => $this->normalizer->normalizeDisplay($data['example_mekongga'] ?? null),
            'example_indonesia' => $this->normalizer->normalizeDisplay($data['example_indonesia'] ?? null),
            'audio_media_id' => $data['audio_media_id'] ?? null,
            'status' => $data['status'] ?? 'active',
        ];
    }
}
