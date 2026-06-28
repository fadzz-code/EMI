<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class CultureTemplateItem extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = ['culture_template_id', 'title', 'description', 'content_type', 'media_id', 'external_url', 'thumbnail_media_id', 'display_order', 'status', 'created_by', 'updated_by', 'published_at', 'archived_at'];

    protected function casts(): array
    {
        return ['display_order' => 'integer', 'published_at' => 'datetime', 'archived_at' => 'datetime', 'deleted_at' => 'datetime'];
    }

    public function cultureTemplate(): BelongsTo
    {
        return $this->belongsTo(CultureTemplate::class);
    }

    public function media(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class);
    }

    public function thumbnailMedia(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class, 'thumbnail_media_id');
    }

    public function classItems(): HasMany
    {
        return $this->hasMany(ClassCultureItem::class, 'source_culture_template_item_id');
    }
}
