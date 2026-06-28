<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class AdminCultureItem extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = ['admin_group_id', 'title', 'description', 'content_type', 'media_id', 'external_url', 'display_order', 'status', 'created_by', 'updated_by', 'published_at', 'archived_at'];

    protected function casts(): array
    {
        return ['display_order' => 'integer', 'published_at' => 'datetime', 'archived_at' => 'datetime', 'deleted_at' => 'datetime'];
    }

    public function media(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class);
    }
}
