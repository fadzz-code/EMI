<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiKnowledgeChunk extends Model
{
    use HasUuids;

    protected $fillable = [
        'ai_knowledge_item_id',
        'chunk_index',
        'content',
        'content_hash',
        'character_count',
        'token_estimate',
        'metadata',
        'embedding',
        'embedding_provider',
        'embedding_model',
        'embedding_dimensions',
        'embedded_at',
        'embedding_hash',
        'embedding_error',
    ];

    protected function casts(): array
    {
        return [
            'metadata' => 'array',
            'embedded_at' => 'datetime',
            'embedding_dimensions' => 'integer',
        ];
    }

    public function knowledgeItem(): BelongsTo
    {
        return $this->belongsTo(AiKnowledgeItem::class, 'ai_knowledge_item_id');
    }
}
