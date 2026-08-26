<?php

namespace App\Services;

use App\Models\ClassModule;
use App\Models\DictionaryCategory;
use App\Models\User;
use Carbon\CarbonInterface;

class OfflineManifestService
{
    public function __construct(private readonly LearningAccessService $accessService) {}

    public function build(User $student): array
    {
        $modules = $this->modules($student);
        $dictionaries = $this->dictionaries();

        return [
            'schema' => 'emi.offline-manifest',
            'schema_version' => 1,
            'generated_at' => now()->toISOString(),
            'modules' => $modules,
            'dictionaries' => $dictionaries,
        ];
    }

    private function modules(User $student): array
    {
        $classId = $this->accessService->studentClassId($student);

        if (! $classId) {
            return [];
        }

        return ClassModule::query()
            ->with([
                'lessons' => fn ($query) => $query->where('status', 'published')->with('media')->orderBy('sort_order')->orderBy('id'),
            ])
            ->where('class_id', $classId)
            ->where('status', 'published')
            ->whereHas('schoolClass', fn ($query) => $query->where('status', 'active')->whereHas('school', fn ($school) => $school->where('status', 'active')))
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->map(function (ClassModule $module): array {
                $snapshot = [
                    'id' => $module->id,
                    'title' => $module->title,
                    'description' => $module->description,
                    'status' => $module->status,
                    'sort_order' => $module->sort_order,
                    'published_at' => $this->timestamp($module->published_at),
                    'updated_at' => $this->timestamp($module->updated_at),
                    'lessons' => $module->lessons->map(fn ($lesson) => [
                        'id' => $lesson->id,
                        'title' => $lesson->title,
                        'description' => $lesson->description,
                        'content_type' => $lesson->content_type,
                        'content_body' => $lesson->content_body,
                        'media_id' => $lesson->media_id,
                        'external_url' => $lesson->external_url,
                        'sort_order' => $lesson->sort_order,
                        'status' => $lesson->status,
                        'published_at' => $this->timestamp($lesson->published_at),
                        'updated_at' => $this->timestamp($lesson->updated_at),
                        'media' => $this->mediaSnapshot($lesson->media),
                    ])->all(),
                ];

                return [
                    'id' => $module->id,
                    'version' => hash('sha256', json_encode($snapshot, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR)),
                    'updated_at' => $this->latestTimestamp($snapshot),
                ];
            })
            ->all();
    }

    private function dictionaries(): array
    {
        return DictionaryCategory::query()
            ->active()
            ->with(['entries' => fn ($query) => $query->active()->with(['audioMedia', 'sentenceExamples.audioMedia'])->orderBy('id')])
            ->orderBy('id')
            ->get()
            ->map(function (DictionaryCategory $category): array {
                $snapshot = [
                    'id' => $category->id,
                    'name' => $category->name,
                    'slug' => $category->slug,
                    'description' => $category->description,
                    'status' => $category->status,
                    'updated_at' => $this->timestamp($category->updated_at),
                    'entries' => $category->entries->map(fn ($entry) => [
                        'id' => $entry->id,
                        'code' => $entry->code,
                        'indonesia' => $entry->indonesia,
                        'english' => $entry->english,
                        'mekongga' => $entry->mekongga,
                        'example_mekongga' => $entry->example_mekongga,
                        'example_indonesia' => $entry->example_indonesia,
                        'audio_media_id' => $entry->audio_media_id,
                        'status' => $entry->status,
                        'updated_at' => $this->timestamp($entry->updated_at),
                        'audio' => $this->mediaSnapshot($entry->audioMedia),
                        'sentences' => $entry->sentenceExamples->map(fn ($sentence) => [
                            'id' => $sentence->id,
                            'code' => $sentence->code,
                            'example_mekongga' => $sentence->example_mekongga,
                            'example_indonesia' => $sentence->example_indonesia,
                            'status' => $sentence->status,
                            'audio_media_id' => $sentence->audio_media_id,
                            'updated_at' => $this->timestamp($sentence->updated_at),
                            'audio' => $this->mediaSnapshot($sentence->audioMedia),
                        ])->all(),
                    ])->all(),
                ];

                return [
                    'id' => $category->id,
                    'version' => hash('sha256', json_encode($snapshot, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR)),
                    'updated_at' => $this->latestTimestamp($snapshot),
                ];
            })
            ->all();
    }

    private function mediaSnapshot($media): ?array
    {
        if (! $media) {
            return null;
        }

        return [
            'id' => $media->id,
            'purpose' => $media->purpose,
            'original_name' => $media->original_name,
            'stored_name' => $media->stored_name,
            'mime_type' => $media->mime_type,
            'extension' => $media->extension,
            'size_bytes' => $media->size_bytes,
            'checksum_sha256' => $media->checksum_sha256,
            'visibility' => $media->visibility,
            'metadata' => $media->metadata,
            'updated_at' => $this->timestamp($media->updated_at),
        ];
    }

    private function latestTimestamp(array $snapshot): ?string
    {
        $timestamps = [];
        array_walk_recursive($snapshot, function ($value, $key) use (&$timestamps) {
            if ($key === 'updated_at' && is_string($value)) {
                $timestamps[] = $value;
            }
        });

        rsort($timestamps, SORT_STRING);

        return $timestamps[0] ?? null;
    }

    private function timestamp(?CarbonInterface $value): ?string
    {
        return $value?->toISOString();
    }
}
