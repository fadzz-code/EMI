<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatbotMessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'role' => $this->role,
            'content' => $this->content,
            'citations' => $this->citations ?? [],
            'retrieval_mode' => $this->retrieval_mode,
            'provider' => $this->provider,
            'confidence' => $this->confidence,
            'fallback_reason' => $this->fallback_reason,
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
