<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CultureTemplateItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'culture_template_id' => $this->culture_template_id,
            'title' => $this->title,
            'description' => $this->description,
            'content_type' => $this->content_type,
            'media_id' => $this->media_id,
            'external_url' => $this->external_url,
            'display_order' => $this->display_order,
            'status' => $this->status,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'published_at' => $this->published_at?->toISOString(),
            'archived_at' => $this->archived_at?->toISOString(),
            'media' => new MediaFileResource($this->whenLoaded('media')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
