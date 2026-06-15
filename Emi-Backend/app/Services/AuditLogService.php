<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

class AuditLogService
{
    private array $sensitiveKeys = [
        'password',
        'remember_token',
        'token',
        'api_key',
        'credential',
    ];

    public function record(
        string $action,
        Model $auditable,
        ?User $actor = null,
        ?array $oldValues = null,
        ?array $newValues = null,
        array $metadata = [],
        ?Request $request = null,
    ): AuditLog {
        return AuditLog::query()->create([
            'actor_id' => $actor?->id,
            'action' => $action,
            'auditable_type' => $auditable::class,
            'auditable_id' => $auditable->getKey(),
            'old_values' => $this->sanitize($oldValues),
            'new_values' => $this->sanitize($newValues),
            'metadata' => $this->sanitize($metadata),
            'ip_address' => $request?->ip(),
            'user_agent' => $request?->userAgent(),
            'created_at' => now(),
        ]);
    }

    private function sanitize(?array $values): ?array
    {
        if ($values === null) {
            return null;
        }

        return collect($values)
            ->reject(fn (mixed $value, string $key) => in_array($key, $this->sensitiveKeys, true))
            ->map(fn (mixed $value) => is_array($value) ? $this->sanitize($value) : $value)
            ->all();
    }
}
