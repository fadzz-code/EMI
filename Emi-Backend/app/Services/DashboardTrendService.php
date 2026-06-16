<?php

namespace App\Services;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class DashboardTrendService
{
    public function trends(array $period, ?string $schoolId = null, ?string $classId = null): array
    {
        return [
            'registrations' => $this->series('registration_requests', 'created_at', $period, $schoolId, $classId),
            'module_completions' => $this->series('module_progress', 'completed_at', $period, $schoolId, $classId, true),
            'quiz_submissions' => $this->series('quiz_attempts', 'submitted_at', $period, $schoolId, $classId, false, true),
        ];
    }

    private function series(string $table, string $column, array $period, ?string $schoolId, ?string $classId, bool $module = false, bool $quiz = false): array
    {
        $query = DB::table($table)
            ->whereBetween($column, [$period['from'], $period['to']])
            ->selectRaw("date({$column}) as date, count(*)::int as value")
            ->groupByRaw("date({$column})");

        if ($table === 'registration_requests') {
            $query->when($schoolId, fn ($query) => $query->where('school_id', $schoolId))
                ->when($classId, fn ($query) => $query->where('class_id', $classId));
        }

        if ($module) {
            $query->join('class_modules as cm', 'cm.id', '=', "{$table}.class_module_id")
                ->join('classes as c', 'c.id', '=', 'cm.class_id')
                ->when($schoolId, fn ($query) => $query->where('c.school_id', $schoolId))
                ->when($classId, fn ($query) => $query->where('c.id', $classId))
                ->where("{$table}.status", 'completed');
        }

        if ($quiz) {
            $query->join('class_quizzes as cq', 'cq.id', '=', "{$table}.class_quiz_id")
                ->join('classes as c', 'c.id', '=', 'cq.class_id')
                ->when($schoolId, fn ($query) => $query->where('c.school_id', $schoolId))
                ->when($classId, fn ($query) => $query->where('c.id', $classId))
                ->whereIn("{$table}.status", ['submitted', 'expired']);
        }

        $values = $query->pluck('value', 'date');

        return $this->dateRange($period)->map(fn (string $date) => [
            'date' => $date,
            'value' => (int) ($values[$date] ?? 0),
        ])->all();
    }

    private function dateRange(array $period): Collection
    {
        $dates = collect();
        for ($date = $period['from']->startOfDay(); $date->lte($period['to']); $date = $date->addDay()) {
            $dates->push($date->toDateString());
        }

        return $dates;
    }
}
