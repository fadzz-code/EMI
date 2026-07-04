<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AiKnowledgeSourcePage extends Model
{
    use HasUuids;

    protected $fillable = [
        'ai_knowledge_item_id',
        'page_number',
        'content',
        'content_hash',
        'char_count',
        'word_count',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'metadata' => 'array',
        ];
    }

    public function knowledgeItem(): BelongsTo
    {
        return $this->belongsTo(AiKnowledgeItem::class, 'ai_knowledge_item_id');
    }
}
