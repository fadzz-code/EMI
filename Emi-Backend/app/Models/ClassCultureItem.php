<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class ClassCultureItem extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = ['class_id', 'source_culture_template_id', 'source_culture_template_item_id', 'title', 'description', 'content_type', 'media_id', 'external_url', 'thumbnail_media_id', 'display_order', 'status', 'created_by', 'updated_by', 'published_at', 'archived_at'];

    protected function casts(): array
    {
        return ['display_order' => 'integer', 'published_at' => 'datetime', 'archived_at' => 'datetime', 'deleted_at' => 'datetime'];
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function sourceTemplate(): BelongsTo
    {
        return $this->belongsTo(CultureTemplate::class, 'source_culture_template_id');
    }

    public function sourceTemplateItem(): BelongsTo
    {
        return $this->belongsTo(CultureTemplateItem::class, 'source_culture_template_item_id');
    }

    public function media(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class);
    }
}
