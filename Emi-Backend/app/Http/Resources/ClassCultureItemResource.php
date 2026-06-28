<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClassCultureItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'class_id' => $this->class_id,
            'source_template_id' => $this->source_culture_template_id,
            'source_template_item_id' => $this->source_culture_template_item_id,
            'source_culture_template_id' => $this->source_culture_template_id,
            'source_culture_template_item_id' => $this->source_culture_template_item_id,
            'admin_group_id' => $this->admin_group_id,
            'created_scope' => $this->created_scope,
            'title' => $this->title,
            'description' => $this->description,
            'content_type' => $this->content_type,
            'media_id' => $this->media_id,
            'external_url' => $this->external_url,
            'thumbnail_media_id' => $this->thumbnail_media_id,
            'display_order' => $this->display_order,
            'status' => $this->status,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'published_at' => $this->published_at?->toISOString(),
            'archived_at' => $this->archived_at?->toISOString(),
            'media' => new MediaFileResource($this->whenLoaded('media')),
            'school_class' => new SchoolClassResource($this->whenLoaded('schoolClass')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
