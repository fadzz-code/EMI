<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminCultureItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->admin_group_id,
            'title' => $this->title,
            'description' => $this->description,
            'content_type' => $this->content_type,
            'media' => $this->relationLoaded('media') && $this->media ? new MediaFileResource($this->media) : null,
            'external_url' => $this->external_url,
            'display_order' => $this->display_order,
            'status' => $this->status,
            'classes_count' => $this->classes_count ?? 0,
            'published_classes_count' => $this->published_classes_count ?? 0,
            'published_at' => $this->published_at?->toISOString(),
            'archived_at' => $this->archived_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
