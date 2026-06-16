<?php

namespace App\Services;

use App\Exceptions\ApiException;
use Carbon\CarbonImmutable;

class DashboardPeriodService
{
    public function resolve(array $filters): array
    {
        $today = CarbonImmutable::now('UTC')->startOfDay();
        $from = isset($filters['date_from'])
            ? CarbonImmutable::createFromFormat('Y-m-d', $filters['date_from'], 'UTC')->startOfDay()
            : $today->subDays(max(1, (int) config('dashboard.default_period_days')) - 1);
        $to = isset($filters['date_to'])
            ? CarbonImmutable::createFromFormat('Y-m-d', $filters['date_to'], 'UTC')->endOfDay()
            : $today->endOfDay();

        if ($from->gt($to)) {
            throw new ApiException('Periode laporan tidak valid.', 'INVALID_REPORT_PERIOD', 422);
        }

        if ($from->diffInDays($to) + 1 > (int) config('dashboard.max_period_days')) {
            throw new ApiException('Periode laporan terlalu panjang.', 'REPORT_PERIOD_TOO_LARGE', 422);
        }

        return [
            'from' => $from,
            'to' => $to,
            'date_from' => $from->toDateString(),
            'date_to' => $to->toDateString(),
        ];
    }
}
