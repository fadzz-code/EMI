<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassCultureItem;
use App\Models\CultureTemplate;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CultureTemplateApplyService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function apply(CultureTemplate $template, array $classIds, User $actor, Request $request): array
    {
        $template->load('items');

        if ($template->status !== 'published') {
            throw new ApiException('Template budaya belum published.', 'CULTURE_TEMPLATE_NOT_PUBLISHED', 409);
        }

        $summary = ['applied' => [], 'skipped' => [], 'failed' => []];

        foreach (array_values(array_unique($classIds)) as $classId) {
            try {
                DB::transaction(function () use ($template, $classId, $actor, $request, &$summary) {
                    $class = SchoolClass::query()->with('school')->lockForUpdate()->findOrFail($classId);

                    if ($class->status !== 'active') {
                        throw new ApiException('Kelas tidak aktif.', 'CLASS_INACTIVE', 409);
                    }

                    if ($class->school?->status !== 'active') {
                        throw new ApiException('Sekolah tidak aktif.', 'SCHOOL_INACTIVE', 409);
                    }

                    $appliedCount = 0;

                    foreach ($template->items->where('status', 'published') as $item) {
                        $existing = ClassCultureItem::query()
                            ->where('class_id', $class->id)
                            ->where('source_culture_template_item_id', $item->id)
                            ->exists();

                        if (! $existing) {
                            ClassCultureItem::query()->create([
                                'class_id' => $class->id,
                                'source_culture_template_id' => $template->id,
                                'source_culture_template_item_id' => $item->id,
                                'title' => $item->title,
                                'description' => $item->description,
                                'content_type' => $item->content_type,
                                'media_id' => $item->media_id,
                                'external_url' => $item->external_url,
                                'thumbnail_media_id' => $item->thumbnail_media_id,
                                'display_order' => $item->display_order,
                                'status' => 'published',
                                'published_at' => now(),
                                'created_by' => $actor->id,
                            ]);
                            $appliedCount++;
                        }
                    }

                    if ($appliedCount > 0) {
                        $summary['applied'][] = ['class_id' => $class->id, 'items_count' => $appliedCount];
                        $this->auditLogService->record('culture_template.applied', $template, $actor, null, [
                            'class_id' => $class->id,
                            'items_count' => $appliedCount,
                        ], [], $request);
                    } else {
                        $summary['skipped'][] = ['class_id' => $class->id, 'reason' => 'ALL_ITEMS_ALREADY_APPLIED'];
                    }
                });
            } catch (ApiException $e) {
                $summary['failed'][] = ['class_id' => $classId, 'reason' => $e->errorCode];
            }
        }

        return $summary;
    }
}
