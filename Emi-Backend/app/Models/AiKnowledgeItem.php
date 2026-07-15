<?php

namespace App\Models;

use Database\Factories\AiKnowledgeItemFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class AiKnowledgeItem extends Model
{
    /** @use HasFactory<AiKnowledgeItemFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'title',
        'category',
        'content',
        'source_type',
        'source_url',
        'status',
        'created_by',
        'updated_by',
    ];

    protected function casts(): array
    {
        return [
            'deleted_at' => 'datetime',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function chunks(): HasMany
    {
        return $this->hasMany(AiKnowledgeChunk::class);
    }

    public function sourcePages(): HasMany
    {
        return $this->hasMany(AiKnowledgeSourcePage::class)->orderBy('page_number');
    }

    public function scopeDraft(Builder $query): Builder
    {
        return $query->where('status', 'draft');
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('status', 'published');
    }

    public function scopeArchived(Builder $query): Builder
    {
        return $query->where('status', 'archived');
    }

    public function processingStatus(): ?string
    {
        if (! in_array($this->source_type, ['pdf', 'link'], true)) {
            return null;
        }

        return $this->isReadyForPublication() ? 'ready' : 'failed';
    }

    public function isReadyForPublication(): bool
    {
        if (in_array($this->source_type, ['manual', 'link'], true)) {
            return trim((string) $this->content) !== '' && $this->chunks()->exists();
        }

        if ($this->source_type === 'pdf') {
            if ($this->sourcePages()->exists()) {
                return $this->chunks()
                    ->where(fn ($query) => $query->whereNull('metadata->searchable')->orWhere('metadata->searchable', true))
                    ->exists();
            }

            $content = trim((string) $this->content);

            return $content !== ''
                && ! str_starts_with($content, 'Dokumen PDF telah diproses')
                && $this->chunks()->exists();
        }

        return false;
    }
}
