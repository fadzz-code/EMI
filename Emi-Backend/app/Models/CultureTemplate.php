<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class CultureTemplate extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = ['title', 'description', 'status', 'created_by', 'updated_by', 'published_at', 'archived_at'];

    protected function casts(): array
    {
        return ['published_at' => 'datetime', 'archived_at' => 'datetime', 'deleted_at' => 'datetime'];
    }

    public function items(): HasMany
    {
        return $this->hasMany(CultureTemplateItem::class)->orderBy('display_order');
    }

    public function classItems(): HasMany
    {
        return $this->hasMany(ClassCultureItem::class, 'source_culture_template_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
