<?php

namespace App\Services;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class QuizResultReportService
{
    public function rows(array $filters = [], ?string $forcedClassId = null, ?string $forcedStudentId = null, bool $paginate = true): LengthAwarePaginator|Collection
    {
        $query = $this->baseQuery($filters, $forcedClassId, $forcedStudentId);
        $sortBy = $filters['sort_by'] ?? 'student_name';
        $direction = $filters['sort_direction'] ?? 'asc';

        $query->orderBy($sortBy, $direction)->orderBy('student_id')->orderBy('class_quiz_id');

        if (! $paginate) {
            return $query->limit((int) config('dashboard.export_max_rows') + 1)->get()->map(fn ($row) => $this->formatRow($row));
        }

        $paginator = $query->paginate($this->perPage($filters), ['*'], $filters['_page_name'] ?? 'page', $filters['page'] ?? null);
        $paginator->getCollection()->transform(fn ($row) => $this->formatRow($row));

        return $paginator;
    }

    public function summary(array $filters = [], ?string $forcedClassId = null, ?string $forcedStudentId = null, bool $studentVisibleOnly = false): array
    {
        $rows = DB::query()->fromSub($this->baseQuery($filters, $forcedClassId, $forcedStudentId), 'r');
        if ($studentVisibleOnly) {
            $rows->where('show_result', true);
        }

        $summary = $rows
            ->selectRaw('count(*)::int as eligible_students')
            ->selectRaw('sum(case when attempt_count > 0 then 1 else 0 end)::int as participating_students')
            ->selectRaw('sum(case when final_attempt_count > 0 then 1 else 0 end)::int as finalized_students')
            ->selectRaw('sum(case when attempt_count = 0 then 1 else 0 end)::int as not_attempted_students')
            ->selectRaw('round(case when count(*) > 0 then (sum(case when attempt_count > 0 then 1 else 0 end)::decimal / count(*)) * 100 else 0 end, 2) as participation_rate_percent')
            ->selectRaw('round(case when count(*) > 0 then (sum(case when final_attempt_count > 0 then 1 else 0 end)::decimal / count(*)) * 100 else 0 end, 2) as completion_rate_percent')
            ->selectRaw('round(avg(best_score_percent) filter (where best_score_percent is not null)::numeric, 2) as average_best_score_percent')
            ->selectRaw('max(best_score_percent) as highest_best_score_percent')
            ->selectRaw('min(best_score_percent) as lowest_best_score_percent')
            ->selectRaw('sum(submitted_attempts)::int as submitted_attempts')
            ->selectRaw('sum(expired_attempts)::int as expired_attempts')
            ->selectRaw('sum(in_progress_attempts)::int as in_progress_attempts')
            ->first();

        return [
            'eligible_students' => (int) ($summary->eligible_students ?? 0),
            'participating_students' => (int) ($summary->participating_students ?? 0),
            'finalized_students' => (int) ($summary->finalized_students ?? 0),
            'not_attempted_students' => (int) ($summary->not_attempted_students ?? 0),
            'participation_rate_percent' => (float) ($summary->participation_rate_percent ?? 0),
            'completion_rate_percent' => (float) ($summary->completion_rate_percent ?? 0),
            'average_best_score_percent' => $summary?->average_best_score_percent !== null ? (float) $summary->average_best_score_percent : null,
            'highest_best_score_percent' => $summary?->highest_best_score_percent !== null ? (float) $summary->highest_best_score_percent : null,
            'lowest_best_score_percent' => $summary?->lowest_best_score_percent !== null ? (float) $summary->lowest_best_score_percent : null,
            'submitted_attempts' => (int) ($summary->submitted_attempts ?? 0),
            'expired_attempts' => (int) ($summary->expired_attempts ?? 0),
            'in_progress_attempts' => (int) ($summary->in_progress_attempts ?? 0),
        ];
    }

    public function baseQuery(array $filters = [], ?string $forcedClassId = null, ?string $forcedStudentId = null): Builder
    {
        $attempts = DB::table('quiz_attempts')
            ->when($filters['date_from'] ?? null, fn ($query, $date) => $query->whereRaw('coalesce(submitted_at, updated_at, created_at) >= ?', [$date.' 00:00:00']))
            ->when($filters['date_to'] ?? null, fn ($query, $date) => $query->whereRaw('coalesce(submitted_at, updated_at, created_at) <= ?', [$date.' 23:59:59.999999']))
            ->selectRaw('class_quiz_id, student_id')
            ->selectRaw('count(*)::int as attempt_count')
            ->selectRaw("count(*) filter (where status = 'submitted')::int as final_attempt_count")
            ->selectRaw("count(*) filter (where status = 'submitted')::int as submitted_attempts")
            ->selectRaw("count(*) filter (where status = 'expired')::int as expired_attempts")
            ->selectRaw("count(*) filter (where status = 'in_progress')::int as in_progress_attempts")
            ->selectRaw("(array_agg(score_percent order by score_percent desc nulls last, attempt_number asc, id asc) filter (where status = 'submitted' and score_percent is not null))[1] as best_score_percent")
            ->selectRaw("(array_agg(attempt_number order by score_percent desc nulls last, attempt_number asc, id asc) filter (where status = 'submitted' and score_percent is not null))[1] as best_attempt_number")
            ->selectRaw("max(submitted_at) filter (where status = 'submitted') as latest_submitted_at")
            ->selectRaw('(array_agg(status order by coalesce(submitted_at, updated_at) desc, id desc))[1] as latest_status')
            ->groupBy('class_quiz_id', 'student_id');

        return DB::table('student_class_memberships as scm')
            ->join('users as u', fn ($join) => $join->on('u.id', '=', 'scm.student_id')->where('u.role', 'student')->where('u.status', 'approved'))
            ->join('classes as c', fn ($join) => $join->on('c.id', '=', 'scm.class_id')->where('c.status', 'active'))
            ->join('schools as s', fn ($join) => $join->on('s.id', '=', 'c.school_id')->where('s.status', 'active'))
            ->join('class_quizzes as cq', fn ($join) => $join->on('cq.class_id', '=', 'c.id')->where('cq.status', 'published')->whereNull('cq.deleted_at'))
            ->leftJoinSub($attempts, 'qa', fn ($join) => $join->on('qa.class_quiz_id', '=', 'cq.id')->on('qa.student_id', '=', 'u.id'))
            ->where('scm.is_active', true)
            ->when($forcedClassId, fn ($query, $classId) => $query->where('c.id', $classId))
            ->when($forcedStudentId, fn ($query, $studentId) => $query->where('u.id', $studentId))
            ->when($filters['school_id'] ?? null, fn ($query, $schoolId) => $query->where('s.id', $schoolId))
            ->when($filters['class_id'] ?? null, fn ($query, $classId) => $query->where('c.id', $classId))
            ->when($filters['quiz_id'] ?? null, fn ($query, $quizId) => $query->where('cq.id', $quizId))
            ->when($filters['student_id'] ?? null, fn ($query, $studentId) => $query->where('u.id', $studentId))
            ->when($filters['attempt_status'] ?? null, fn ($query, $status) => $query->where('qa.latest_status', $status))
            ->when($filters['status'] ?? null, function ($query, $status) {
                if ($status === 'not_started') {
                    $query->whereRaw('coalesce(qa.attempt_count, 0) = 0');
                } elseif ($status === 'completed') {
                    $query->whereRaw('coalesce(qa.final_attempt_count, 0) > 0');
                } else {
                    $query->where('qa.latest_status', $status);
                }
            })
            ->selectRaw('u.id as student_id, u.full_name as student_name')
            ->selectRaw('s.id as school_id, s.name as school_name, c.id as class_id, c.name as class_name')
            ->selectRaw('cq.id as class_quiz_id, cq.title as quiz_title, cq.show_result')
            ->selectRaw('coalesce(qa.attempt_count, 0)::int as attempt_count')
            ->selectRaw('coalesce(qa.final_attempt_count, 0)::int as final_attempt_count')
            ->selectRaw('coalesce(qa.submitted_attempts, 0)::int as submitted_attempts')
            ->selectRaw('coalesce(qa.expired_attempts, 0)::int as expired_attempts')
            ->selectRaw('coalesce(qa.in_progress_attempts, 0)::int as in_progress_attempts')
            ->selectRaw('qa.best_score_percent, qa.best_attempt_number, qa.latest_status, qa.latest_submitted_at');
    }

    private function formatRow(object $row): array
    {
        return [
            'quiz' => ['id' => $row->class_quiz_id, 'title' => $row->quiz_title, 'show_result' => (bool) $row->show_result],
            'student' => ['id' => $row->student_id, 'full_name' => $row->student_name],
            'school' => ['id' => $row->school_id, 'name' => $row->school_name],
            'class' => ['id' => $row->class_id, 'name' => $row->class_name],
            'best_attempt_number' => $row->best_attempt_number !== null ? (int) $row->best_attempt_number : null,
            'attempt_count' => (int) $row->attempt_count,
            'final_attempt_count' => (int) $row->final_attempt_count,
            'submitted_attempts' => (int) $row->submitted_attempts,
            'expired_attempts' => (int) $row->expired_attempts,
            'in_progress_attempts' => (int) $row->in_progress_attempts,
            'final_attempt' => (int) $row->final_attempt_count > 0,
            'best_score_percent' => $row->best_score_percent !== null ? (float) $row->best_score_percent : null,
            'latest_status' => $row->latest_status,
            'latest_submitted_at' => $row->latest_submitted_at,
        ];
    }

    private function perPage(array $filters): int
    {
        return min((int) ($filters['per_page'] ?? config('dashboard.default_per_page')), (int) config('dashboard.max_per_page'));
    }
}
