<?php

namespace App\Http\Resources;

use App\Services\MediaAccessService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MediaFileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'purpose' => $this->purpose,
            'original_name' => $this->original_name,
            'mime_type' => $this->mime_type,
            'extension' => $this->extension,
            'size_bytes' => $this->size_bytes,
            'visibility' => $this->visibility,
            'url' => $this->isPublic()
                ? app(MediaAccessService::class)->publicUrl($this->resource)
                : ($this->purpose === 'culture_media' ? app(MediaAccessService::class)->temporaryUrl($this->resource, now()->addMinutes((int) config('media.signed_url_ttl_minutes')), 'inline') : null),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
