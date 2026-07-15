<?php

namespace App\Services;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class LearningProgressReportService
{
    public function studentRows(array $filters = [], ?string $forcedClassId = null, ?string $forcedStudentId = null, bool $paginate = true): LengthAwarePaginator|Collection
    {
        $base = $this->studentMetricQuery($filters)
            ->when($filters['school_id'] ?? null, fn ($query, $schoolId) => $query->where('s.id', $schoolId))
            ->when($filters['class_id'] ?? null, fn ($query, $classId) => $query->where('c.id', $classId))
            ->when($forcedClassId, fn ($query, $classId) => $query->where('c.id', $classId))
            ->when($forcedStudentId, fn ($query, $studentId) => $query->where('u.id', $studentId))
            ->when($filters['student_id'] ?? null, fn ($query, $studentId) => $query->where('u.id', $studentId))
            ->when($filters['search'] ?? null, fn ($query, $search) => $query->where(function ($query) use ($search) {
                $query->where('u.full_name', 'ilike', "%{$search}%")->orWhere('c.name', 'ilike', "%{$search}%");
            }));

        $query = DB::query()->fromSub($base, 'students')->select('*');

        if ($filters['learning_status'] ?? null) {
            $status = $filters['learning_status'];
            $query->whereRaw($this->learningStatusSql().' = ?', [$status]);
        }
        if ($filters['quiz_status'] ?? null) {
            $status = $filters['quiz_status'];
            $query->whereRaw($this->quizStatusSql().' = ?', [$status]);
        }

        $sortBy = $filters['sort_by'] ?? 'full_name';
        $direction = $filters['sort_direction'] ?? 'asc';
        $query->orderBy($sortBy, $direction)->orderBy('student_id');

        if (! $paginate) {
            return $query->limit((int) config('dashboard.export_max_rows') + 1)->get()->map(fn ($row) => $this->formatStudentRow($row));
        }

        $paginator = $query->paginate($this->perPage($filters), ['*'], $filters['_page_name'] ?? 'page', $filters['page'] ?? null);
        $paginator->getCollection()->transform(fn ($row) => $this->formatStudentRow($row));

        return $paginator;
    }

    public function classRows(array $filters = [], bool $paginate = true): LengthAwarePaginator|Collection
    {
        $students = $this->studentMetricQuery($filters, $filters['status'] ?? 'active', null);
        $query = DB::query()
            ->fromSub($students, 'students')
            ->selectRaw('class_id, class_name, school_id, school_name')
            ->selectRaw('count(*)::int as active_students')
            ->selectRaw('max(published_modules)::int as published_modules')
            ->selectRaw('round(coalesce(avg(overall_learning_progress_percent), 0)::numeric, 2) as average_learning_progress_percent')
            ->selectRaw('sum(completed_modules)::int as completed_module_count')
            ->selectRaw('max(published_quizzes)::int as published_quizzes')
            ->selectRaw('sum(case when quizzes_attempted > 0 then 1 else 0 end)::int as students_participated_in_quiz')
            ->selectRaw('round(avg(average_best_quiz_score_percent) filter (where average_best_quiz_score_percent is not null)::numeric, 2) as average_quiz_score_percent')
            ->when($filters['school_id'] ?? null, fn ($query, $schoolId) => $query->where('school_id', $schoolId))
            ->when($filters['class_id'] ?? null, fn ($query, $classId) => $query->where('class_id', $classId))
            ->when($filters['search'] ?? null, fn ($query, $search) => $query->where(function ($query) use ($search) {
                $query->where('class_name', 'ilike', "%{$search}%")->orWhere('full_name', 'ilike', "%{$search}%");
            }))
            ->when($filters['learning_status'] ?? null, fn ($query, $status) => $query->whereRaw($this->learningStatusSql().' = ?', [$status]))
            ->when($filters['quiz_status'] ?? null, fn ($query, $status) => $query->whereRaw($this->quizStatusSql().' = ?', [$status]))
            ->groupBy('class_id', 'class_name', 'school_id', 'school_name');

        $sortBy = $filters['sort_by'] ?? 'class_name';
        $direction = $filters['sort_direction'] ?? 'asc';
        $query->orderBy($sortBy, $direction)->orderBy('class_id');

        return $this->paginateOrGet($query, $filters, $paginate);
    }

    public function schoolRows(array $filters = [], bool $paginate = true): LengthAwarePaginator|Collection
    {
        $students = $this->studentMetricQuery($filters, null, $filters['status'] ?? 'active');
        $query = DB::query()
            ->fromSub($students, 'students')
            ->selectRaw('school_id, school_name')
            ->selectRaw('count(distinct class_id)::int as active_classes')
            ->selectRaw('count(*)::int as active_students')
            ->selectRaw("(select count(*) from class_modules cm join classes c2 on c2.id = cm.class_id where c2.school_id = students.school_id and cm.status = 'published' and cm.deleted_at is null)::int as published_modules")
            ->selectRaw('round(coalesce(avg(overall_learning_progress_percent), 0)::numeric, 2) as average_learning_progress_percent')
            ->selectRaw('round(coalesce(avg(case when published_modules > 0 then (completed_modules::decimal / published_modules) * 100 else 0 end), 0)::numeric, 2) as module_completion_rate_percent')
            ->selectRaw("(select count(*) from class_quizzes cq join classes c2 on c2.id = cq.class_id where c2.school_id = students.school_id and cq.status = 'published' and cq.deleted_at is null)::int as published_quizzes")
            ->selectRaw('round(coalesce(avg(case when published_quizzes > 0 then (quizzes_attempted::decimal / published_quizzes) * 100 else 0 end), 0)::numeric, 2) as quiz_participation_rate_percent')
            ->selectRaw('round(avg(average_best_quiz_score_percent) filter (where average_best_quiz_score_percent is not null)::numeric, 2) as average_quiz_score_percent')
            ->when($filters['search'] ?? null, fn ($query, $search) => $query->where('school_name', 'ilike', "%{$search}%"))
            ->groupBy('school_id', 'school_name');

        $sortBy = $filters['sort_by'] ?? 'school_name';
        $direction = $filters['sort_direction'] ?? 'asc';
        $query->orderBy($sortBy, $direction)->orderBy('school_id');

        return $this->paginateOrGet($query, $filters, $paginate);
    }

    public function overviewSummary(array $filters = []): array
    {
        $summary = DB::query()->fromSub($this->studentMetricQuery($filters), 'students')
            ->when($filters['school_id'] ?? null, fn ($query, $id) => $query->where('school_id', $id))
            ->when($filters['class_id'] ?? null, fn ($query, $id) => $query->where('class_id', $id))
            ->when($filters['search'] ?? null, fn ($query, $search) => $query->where(function ($query) use ($search) {
                $query->where('full_name', 'ilike', "%{$search}%")->orWhere('class_name', 'ilike', "%{$search}%");
            }))
            ->when($filters['learning_status'] ?? null, fn ($query, $status) => $query->whereRaw($this->learningStatusSql().' = ?', [$status]))
            ->when($filters['quiz_status'] ?? null, fn ($query, $status) => $query->whereRaw($this->quizStatusSql().' = ?', [$status]))
            ->selectRaw('count(*)::int as active_students')
            ->selectRaw('round(coalesce(avg(overall_learning_progress_percent), 0)::numeric, 2) as average_module_progress_percent')
            ->selectRaw('round(avg(average_best_quiz_score_percent) filter (where average_best_quiz_score_percent is not null)::numeric, 2) as average_best_final_quiz_score_percent')
            ->first();

        return [
            'active_students' => (int) ($summary->active_students ?? 0),
            'average_module_progress_percent' => (float) ($summary->average_module_progress_percent ?? 0),
            'average_best_final_quiz_score_percent' => $summary?->average_best_final_quiz_score_percent !== null ? (float) $summary->average_best_final_quiz_score_percent : null,
        ];
    }

    public function averageProgress(?string $schoolId = null, ?string $classId = null): float
    {
        $query = DB::query()->fromSub($this->studentMetricQuery(), 'students')
            ->when($schoolId, fn ($query) => $query->where('school_id', $schoolId))
            ->when($classId, fn ($query) => $query->where('class_id', $classId));

        return round((float) ($query->avg('overall_learning_progress_percent') ?? 0), 2);
    }

    public function studentMetricQuery(array $filters = [], ?string $classStatus = 'active', ?string $schoolStatus = 'active'): Builder
    {
        $from = isset($filters['date_from']) ? $filters['date_from'].' 00:00:00' : null;
        $to = isset($filters['date_to']) ? $filters['date_to'].' 23:59:59.999999' : null;
        $progressPeriod = ($from ? " and coalesce(mp.completed_at, mp.updated_at, mp.created_at) >= '{$from}'" : '').($to ? " and coalesce(mp.completed_at, mp.updated_at, mp.created_at) <= '{$to}'" : '');
        $attemptPeriod = ($from ? " and coalesce(qa.submitted_at, qa.updated_at, qa.created_at) >= '{$from}'" : '').($to ? " and coalesce(qa.submitted_at, qa.updated_at, qa.created_at) <= '{$to}'" : '');
        $publishedModules = "(select count(*) from class_modules cm where cm.class_id = c.id and cm.status = 'published' and cm.deleted_at is null)";
        $progressSum = "(select coalesce(sum(mp.progress_percent), 0) from module_progress mp join class_modules cm on cm.id = mp.class_module_id and cm.status = 'published' and cm.deleted_at is null where mp.student_id = u.id and cm.class_id = c.id{$progressPeriod})";

        return DB::table('users as u')
            ->join('student_class_memberships as scm', fn ($join) => $join->on('scm.student_id', '=', 'u.id')->where('scm.is_active', true))
            ->join('classes as c', fn ($join) => $join->on('c.id', '=', 'scm.class_id')->when($classStatus, fn ($join) => $join->where('c.status', $classStatus)))
            ->join('schools as s', fn ($join) => $join->on('s.id', '=', 'c.school_id')->when($schoolStatus, fn ($join) => $join->where('s.status', $schoolStatus)))
            ->where('u.role', 'student')
            ->where('u.status', 'approved')
            ->selectRaw('u.id as student_id, u.full_name, u.email, u.status as student_status, c.id as class_id, c.name as class_name, s.id as school_id, s.name as school_name')
            ->selectRaw("{$publishedModules}::int as published_modules")
            ->selectRaw("(select count(*) from module_progress mp join class_modules cm on cm.id = mp.class_module_id and cm.status = 'published' and cm.deleted_at is null where mp.student_id = u.id and cm.class_id = c.id and mp.progress_percent > 0{$progressPeriod})::int as started_modules")
            ->selectRaw("(select count(*) from module_progress mp join class_modules cm on cm.id = mp.class_module_id and cm.status = 'published' and cm.deleted_at is null where mp.student_id = u.id and cm.class_id = c.id and mp.status = 'completed'{$progressPeriod})::int as completed_modules")
            ->selectRaw("(select count(*) from module_progress mp join class_modules cm on cm.id = mp.class_module_id and cm.status = 'published' and cm.deleted_at is null where mp.student_id = u.id and cm.class_id = c.id and mp.status = 'in_progress'{$progressPeriod})::int as in_progress_modules")
            ->selectRaw("greatest({$publishedModules} - (select count(*) from module_progress mp join class_modules cm on cm.id = mp.class_module_id and cm.status = 'published' and cm.deleted_at is null where mp.student_id = u.id and cm.class_id = c.id and mp.progress_percent > 0{$progressPeriod}), 0)::int as not_started_modules")
            ->selectRaw("round(case when {$publishedModules} > 0 then ({$progressSum}::decimal / {$publishedModules}) else 0 end, 2) as overall_learning_progress_percent")
            ->selectRaw("(select count(*) from lesson_progress lp join class_lessons cl on cl.id = lp.class_lesson_id and cl.status = 'published' and cl.deleted_at is null join class_modules cm on cm.id = cl.class_module_id and cm.status = 'published' and cm.deleted_at is null where lp.student_id = u.id and cm.class_id = c.id and lp.status = 'completed')::int as completed_lessons")
            ->selectRaw("(select count(*) from class_lessons cl join class_modules cm on cm.id = cl.class_module_id and cm.status = 'published' and cm.deleted_at is null where cm.class_id = c.id and cl.status = 'published' and cl.deleted_at is null)::int as total_published_lessons")
            ->selectRaw('(select max(greatest(coalesce(mp.completed_at, mp.updated_at, mp.created_at), coalesce(mp.last_calculated_at, mp.created_at))) from module_progress mp join class_modules cm on cm.id = mp.class_module_id where mp.student_id = u.id and cm.class_id = c.id) as last_learning_activity_at')
            ->selectRaw("(select count(*) from class_quizzes cq where cq.class_id = c.id and cq.status = 'published' and cq.deleted_at is null)::int as published_quizzes")
            ->selectRaw("(select count(distinct qa.class_quiz_id) from quiz_attempts qa join class_quizzes cq on cq.id = qa.class_quiz_id and cq.status = 'published' and cq.deleted_at is null where qa.student_id = u.id and cq.class_id = c.id{$attemptPeriod})::int as quizzes_attempted")
            ->selectRaw("(select count(distinct qa.class_quiz_id) from quiz_attempts qa join class_quizzes cq on cq.id = qa.class_quiz_id and cq.status = 'published' and cq.deleted_at is null where qa.student_id = u.id and cq.class_id = c.id and qa.status = 'submitted'{$attemptPeriod})::int as quizzes_completed")
            ->selectRaw("(select count(*) from (select max(qa.score_percent) as best_score from quiz_attempts qa join class_quizzes cq on cq.id = qa.class_quiz_id and cq.status = 'published' and cq.deleted_at is null where qa.student_id = u.id and cq.class_id = c.id and qa.status = 'submitted'{$attemptPeriod} group by qa.class_quiz_id) best_scores where best_score is not null)::int as submitted_quiz_count")
            ->selectRaw("(select round(avg(best_score)::numeric, 2) from (select max(qa.score_percent) as best_score from quiz_attempts qa join class_quizzes cq on cq.id = qa.class_quiz_id and cq.status = 'published' and cq.deleted_at is null where qa.student_id = u.id and cq.class_id = c.id and qa.status = 'submitted'{$attemptPeriod} group by qa.class_quiz_id) best_scores) as average_best_quiz_score_percent")
            ->selectRaw("(select max(coalesce(qa.submitted_at, qa.updated_at)) from quiz_attempts qa join class_quizzes cq on cq.id = qa.class_quiz_id and cq.status = 'published' and cq.deleted_at is null where qa.student_id = u.id and cq.class_id = c.id{$attemptPeriod}) as last_quiz_activity_at");
    }

    private function learningStatusSql(): string
    {
        return "case when published_modules > 0 and completed_modules = published_modules then 'completed' when started_modules > 0 then 'in_progress' else 'not_started' end";
    }

    private function quizStatusSql(): string
    {
        return "case when published_quizzes > 0 and quizzes_completed = published_quizzes then 'completed' when quizzes_attempted > 0 then 'in_progress' else 'not_started' end";
    }

    private function formatStudentRow(object $row): array
    {
        return [
            'student_id' => $row->student_id,
            'full_name' => $row->full_name,
            'email' => $row->email,
            'student_status' => $row->student_status,
            'learning_status' => match (true) {
                (int) $row->published_modules > 0 && (int) $row->completed_modules === (int) $row->published_modules => 'completed',
                (int) $row->started_modules > 0 => 'in_progress',
                default => 'not_started',
            },
            'school' => ['id' => $row->school_id, 'name' => $row->school_name],
            'class' => ['id' => $row->class_id, 'name' => $row->class_name],
            'published_modules' => (int) $row->published_modules,
            'started_modules' => (int) $row->started_modules,
            'completed_modules' => (int) $row->completed_modules,
            'in_progress_modules' => (int) $row->in_progress_modules,
            'not_started_modules' => (int) $row->not_started_modules,
            'overall_learning_progress_percent' => (float) $row->overall_learning_progress_percent,
            'completed_lessons' => (int) $row->completed_lessons,
            'total_published_lessons' => (int) $row->total_published_lessons,
            'published_quizzes' => (int) $row->published_quizzes,
            'quizzes_attempted' => (int) $row->quizzes_attempted,
            'quizzes_completed' => (int) $row->quizzes_completed,
            'submitted_quiz_count' => (int) $row->submitted_quiz_count,
            'average_best_quiz_score_percent' => $row->average_best_quiz_score_percent !== null ? (float) $row->average_best_quiz_score_percent : null,
            'average_quiz_score_out_of_100' => $row->average_best_quiz_score_percent !== null ? (float) $row->average_best_quiz_score_percent : null,
            'last_learning_activity_at' => $row->last_learning_activity_at,
            'last_quiz_activity_at' => $row->last_quiz_activity_at,
        ];
    }

    private function paginateOrGet(Builder $query, array $filters, bool $paginate): LengthAwarePaginator|Collection
    {
        if (! $paginate) {
            return $query->limit((int) config('dashboard.export_max_rows') + 1)->get();
        }

        return $query->paginate($this->perPage($filters));
    }

    private function perPage(array $filters): int
    {
        return min((int) ($filters['per_page'] ?? config('dashboard.default_per_page')), (int) config('dashboard.max_per_page'));
    }
}
