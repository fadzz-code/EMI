<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class SpeakingReportService
{
    public function studentSummary(array $filters = []): array
    {
        $query = $this->attempts($filters)
            ->join('users as u', 'u.id', '=', 'sa.student_id')
            ->selectRaw('u.id as student_id, u.full_name')
            ->selectRaw('count(*)::int as attempt_count')
            ->selectRaw("count(*) filter (where sa.analysis_status = 'completed')::int as analyzed_attempts")
            ->selectRaw("count(*) filter (where sa.review_status = 'reviewed')::int as reviewed_attempts")
            ->selectRaw("round(avg(sa.ai_score) filter (where sa.analysis_status = 'completed' and sa.ai_score is not null)::numeric, 2) as average_ai_score")
            ->selectRaw("round(avg(sa.teacher_score) filter (where sa.review_status = 'reviewed' and sa.teacher_score is not null)::numeric, 2) as average_teacher_score")
            ->groupBy('u.id', 'u.full_name')
            ->orderBy('u.full_name')->orderBy('u.id');

        return $this->page($query->paginate($this->perPage($filters)));
    }

    public function classSummary(array $filters = []): array
    {
        $query = $this->attempts($filters)
            ->join('classes as c', 'c.id', '=', 'se.classroom_id')
            ->join('schools as s', 's.id', '=', 'c.school_id')
            ->selectRaw('c.id as class_id, c.name as class_name, s.id as school_id, s.name as school_name')
            ->selectRaw('count(*)::int as attempt_count, count(distinct sa.student_id)::int as participating_students')
            ->selectRaw("round(avg(sa.ai_score) filter (where sa.analysis_status = 'completed' and sa.ai_score is not null)::numeric, 2) as average_ai_score")
            ->selectRaw("round(avg(sa.teacher_score) filter (where sa.review_status = 'reviewed' and sa.teacher_score is not null)::numeric, 2) as average_teacher_score")
            ->groupBy('c.id', 'c.name', 's.id', 's.name')
            ->orderBy('c.name')->orderBy('c.id');

        return $this->page($query->paginate($this->perPage($filters)));
    }

    private function attempts(array $filters)
    {
        return DB::table('speaking_attempts as sa')
            ->join('speaking_exercises as se', 'se.id', '=', 'sa.speaking_exercise_id')
            ->whereNull('sa.deleted_at')
            ->when($filters['analysis_status'] ?? null, fn ($query, $status) => $query->where('sa.analysis_status', $status))
            ->when($filters['review_status'] ?? null, fn ($query, $status) => $query->where('sa.review_status', $status))
            ->when($filters['school_id'] ?? null, fn ($query, $id) => $query->whereIn('se.classroom_id', DB::table('classes')->where('school_id', $id)->select('id')))
            ->when($filters['class_id'] ?? null, fn ($query, $id) => $query->where('se.classroom_id', $id))
            ->when($filters['date_from'] ?? null, fn ($query, $date) => $query->where('sa.created_at', '>=', $date.' 00:00:00'))
            ->when($filters['date_to'] ?? null, fn ($query, $date) => $query->where('sa.created_at', '<=', $date.' 23:59:59.999999'));
    }

    private function page($paginator): array
    {
        $data = collect($paginator->items())->map(fn ($row) => collect((array) $row)->map(fn ($value, $key) => str_starts_with($key, 'average_') ? ($value !== null ? (float) $value : null) : $value)->all())->all();

        return ['data' => $data, 'meta' => ['current_page' => $paginator->currentPage(), 'per_page' => $paginator->perPage(), 'total' => $paginator->total(), 'last_page' => $paginator->lastPage()]];
    }

    private function perPage(array $filters): int
    {
        return min((int) ($filters['per_page'] ?? config('dashboard.default_per_page')), (int) config('dashboard.max_per_page'));
    }
}
