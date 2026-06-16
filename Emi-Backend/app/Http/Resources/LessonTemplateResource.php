<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LessonTemplateResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'module_template_id' => $this->module_template_id,
            'title' => $this->title,
            'description' => $this->description,
            'content_type' => $this->content_type,
            'content_body' => $this->content_type === 'text' ? $this->content_body : null,
            'external_url' => in_array($this->content_type, ['video', 'link'], true) ? $this->external_url : null,
            'media' => $this->media ? [
                'id' => $this->media->id,
                'mime_type' => $this->media->mime_type,
                'visibility' => $this->media->visibility,
            ] : null,
            'sort_order' => $this->sort_order,
            'status' => $this->status,
            'published_at' => $this->published_at?->toISOString(),
            'archived_at' => $this->archived_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
