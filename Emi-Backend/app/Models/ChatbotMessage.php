<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatbotMessage extends Model
{
    use HasUuids;

    protected $fillable = [
        'chatbot_conversation_id',
        'role',
        'content',
        'citations',
        'retrieval_mode',
        'provider',
        'confidence',
        'fallback_reason',
    ];

    protected function casts(): array
    {
        return [
            'citations' => 'array',
            'confidence' => 'integer',
        ];
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(ChatbotConversation::class, 'chatbot_conversation_id');
    }
}
