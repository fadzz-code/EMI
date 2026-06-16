<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class ReportScopeService
{
    public function assertAdminScope(array $filters): array
    {
        $schoolId = $filters['school_id'] ?? null;
        $classId = $filters['class_id'] ?? null;

        if ($classId) {
            $class = SchoolClass::query()->with('school')->findOrFail($classId);
            if ($schoolId && $class->school_id !== $schoolId) {
                throw new ApiException('Kelas tidak berada pada sekolah yang dipilih.', 'SCHOOL_CLASS_MISMATCH', 422);
            }
            $schoolId ??= $class->school_id;
        }

        return ['school_id' => $schoolId, 'class_id' => $classId];
    }

    public function teacherClass(User $teacher): ?SchoolClass
    {
        if ($teacher->role !== 'teacher') {
            throw new ApiException('Scope laporan tidak diizinkan.', 'REPORT_SCOPE_FORBIDDEN', 403);
        }

        $classId = $teacher->activeTeacherClassAssignment?->class_id;

        return $classId ? SchoolClass::query()->with('school')->find($classId) : null;
    }

    public function requireTeacherClass(User $teacher): SchoolClass
    {
        return $this->teacherClass($teacher)
            ?? throw new ApiException('Guru belum memiliki kelas aktif.', 'TEACHER_HAS_NO_ACTIVE_CLASS', 422);
    }

    public function assertTeacherFilters(User $teacher, array $filters): SchoolClass
    {
        $class = $this->requireTeacherClass($teacher);

        if (($filters['class_id'] ?? $class->id) !== $class->id || (($filters['school_id'] ?? $class->school_id) !== $class->school_id)) {
            throw new ApiException('Scope laporan tidak diizinkan.', 'REPORT_SCOPE_FORBIDDEN', 403);
        }

        if (($filters['student_id'] ?? null) && ! DB::table('student_class_memberships')->where('student_id', $filters['student_id'])->where('class_id', $class->id)->where('is_active', true)->exists()) {
            throw new ApiException('Siswa tidak berada pada kelas aktif guru.', 'REPORT_SCOPE_FORBIDDEN', 403);
        }

        if (($filters['quiz_id'] ?? null) && ! DB::table('class_quizzes')->where('id', $filters['quiz_id'])->where('class_id', $class->id)->exists()) {
            throw new ApiException('Kuis tidak berada pada kelas aktif guru.', 'REPORT_SCOPE_FORBIDDEN', 403);
        }

        return $class;
    }

    public function studentClass(User $student): ?SchoolClass
    {
        if ($student->role !== 'student') {
            throw new ApiException('Scope laporan tidak diizinkan.', 'REPORT_SCOPE_FORBIDDEN', 403);
        }

        $classId = $student->activeStudentClassMembership?->class_id;

        return $classId ? SchoolClass::query()->with('school')->find($classId) : null;
    }

    public function requireStudentClass(User $student): SchoolClass
    {
        return $this->studentClass($student)
            ?? throw new ApiException('Siswa belum memiliki kelas aktif.', 'STUDENT_HAS_NO_ACTIVE_CLASS', 422);
    }
}
