"use client";

import { useQuery } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Card,
  CardContent,
  CardHeader,
  EmptyState,
  ErrorState,
  LoadingState,
  StatsCard,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { TeacherClassNav } from "./teacher-class-nav";
import { teacherService } from "./teacher-service";
import {
  formatCount,
  formatOptional,
  formatPercent,
  statusLabel,
  teacherStatusTone,
} from "./teacher-utils";
import { teacherProgressKey } from "./teacher-workflow";

export function TeacherClassDetail({ classId }: { classId: string }) {
  const { token } = useAuth();
  const classQuery = useQuery({
    queryKey: ["teacher", "classes", classId],
    queryFn: () => teacherService.classDetail(token ?? "", classId),
    enabled: Boolean(token && classId),
  });
  const studentsQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "students"],
    queryFn: () => teacherService.classStudents(token ?? "", classId),
    enabled: Boolean(token && classId),
  });
  const modulesQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "modules"],
    queryFn: () => teacherService.classModules(token ?? "", classId),
    enabled: Boolean(token && classId),
  });
  const quizzesQuery = useQuery({
    queryKey: ["teacher", "classes", classId, "quizzes"],
    queryFn: () => teacherService.classQuizzes(token ?? "", classId),
    enabled: Boolean(token && classId),
  });
  const progressQuery = useQuery({
    queryKey: teacherProgressKey(classId, { page: 1 }),
    queryFn: () =>
      teacherService.studentProgress(token ?? "", {
        class_id: classId,
        page: 1,
      }),
    enabled: Boolean(token && classId),
  });

  const teacherClass = classQuery.data;
  const students = studentsQuery.data?.items ?? [];
  const modules = modulesQuery.data?.items ?? [];
  const quizzes = quizzesQuery.data?.items ?? [];
  const progressRows = progressQuery.data?.items ?? [];

  return (
    <div className="grid gap-8">
      {classQuery.isLoading ? (
        <LoadingState title="Memuat detail kelas" />
      ) : null}
      {classQuery.isError ? (
        <ErrorState
          description={getFirstApiError(classQuery.error)}
          onRetry={() => void classQuery.refetch()}
          title="Gagal memuat detail kelas"
        />
      ) : null}

      {teacherClass ? (
        <>
          <header className="grid gap-4 rounded-2xl border-2 border-border bg-[var(--color-primary-muted)] p-6 shadow-emi sm:p-8">
            <div>
              <Badge
                tone={teacherClass.status === "active" ? "blue" : "neutral"}
              >
                {statusLabel(teacherClass.status)}
              </Badge>
              <h1 className="mt-2 text-3xl font-black leading-tight text-ink md:text-4xl">
                {teacherClass.name}
              </h1>
              <p className="mt-2 text-base font-semibold leading-6 text-muted">
                {formatOptional(teacherClass.school?.name)} | Tahun ajaran{" "}
                {formatOptional(teacherClass.academic_year)}
              </p>
            </div>
          </header>

          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatsCard
              helper="Dari detail kelas"
              label="Sekolah"
              value={formatOptional(teacherClass.school?.name)}
            />
            <StatsCard
              helper="Assignment aktif"
              label="Guru"
              value={formatOptional(
                teacherClass.active_teacher_assignment?.teacher?.full_name,
              )}
            />
            <StatsCard
              helper="Siswa aktif di kelas"
              label="Siswa"
              value={formatCount(
                teacherClass.active_students_count ?? students.length,
              )}
            />
            <StatsCard
              helper="Materi yang tersedia"
              label="Modul"
              value={formatCount(modules.length)}
            />
          </section>

          <TeacherClassNav classId={classId} />

          <section className="grid gap-6 xl:grid-cols-2">
            <Card className="flex h-full flex-col">
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Siswa Kelas</h2>
              </CardHeader>
              <CardContent>
                {studentsQuery.isLoading ? (
                  <LoadingState title="Memuat siswa" />
                ) : null}
                {studentsQuery.isError ? (
                  <ErrorState
                    description={getFirstApiError(studentsQuery.error)}
                    onRetry={() => void studentsQuery.refetch()}
                    title="Gagal memuat siswa"
                  />
                ) : null}
                {!studentsQuery.isLoading && !studentsQuery.isError ? (
                  students.length === 0 ? (
                    <EmptyState
                      description="Belum ada siswa aktif di kelas ini."
                      title="Siswa kosong"
                    />
                  ) : (
                    <div className="grid gap-3">
                      {students.map((membership) => (
                        <div
                          className="rounded-xl border-2 border-border bg-surface-muted p-3"
                          key={membership.membership_id}
                        >
                          <p className="font-black text-ink">
                            {membership.student.full_name}
                          </p>
                          <p className="text-sm text-muted">
                            {membership.student.email}
                          </p>
                          <p className="mt-1 text-xs font-bold text-muted">
                            {statusLabel(membership.student.status)}
                          </p>
                        </div>
                      ))}
                    </div>
                  )
                ) : null}
              </CardContent>
            </Card>

            <Card className="flex h-full flex-col">
              <CardHeader>
                <h2 className="text-xl font-black text-ink">
                  Progress Belajar
                </h2>
              </CardHeader>
              <CardContent>
                {progressQuery.isLoading ? (
                  <LoadingState title="Memuat progress" />
                ) : null}
                {progressQuery.isError ? (
                  <ErrorState
                    description={getFirstApiError(progressQuery.error)}
                    onRetry={() => void progressQuery.refetch()}
                    title="Gagal memuat progress"
                  />
                ) : null}
                {!progressQuery.isLoading && !progressQuery.isError ? (
                  progressRows.length === 0 ? (
                    <EmptyState
                      description="Belum ada laporan progress siswa untuk kelas ini."
                      title="Progress belum tersedia"
                    />
                  ) : (
                    <div className="grid gap-3">
                      {progressRows.slice(0, 8).map((row, index) => (
                        <div
                          className="rounded-xl border-2 border-border bg-surface-muted p-3"
                          key={row.student_id ?? index}
                        >
                          <div className="flex items-start justify-between gap-3">
                            <div>
                              <p className="font-black text-ink">
                                {formatOptional(row.full_name)}
                              </p>
                              <p className="text-sm text-muted">
                                {formatOptional(row.class?.name)}
                              </p>
                            </div>
                            <Badge tone="blue">
                              {formatPercent(
                                row.overall_learning_progress_percent,
                              )}
                            </Badge>
                          </div>
                          <p className="mt-2 text-xs text-muted">
                            Modul: {formatCount(row.completed_modules)} /{" "}
                            {formatCount(row.published_modules)} | Kuis selesai:{" "}
                            {formatCount(row.quizzes_completed)}
                          </p>
                        </div>
                      ))}
                    </div>
                  )
                ) : null}
              </CardContent>
            </Card>
          </section>

          <section className="grid gap-6 xl:grid-cols-2">
            <Card className="flex h-full flex-col">
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Modul Kelas</h2>
              </CardHeader>
              <CardContent>
                {modulesQuery.isLoading ? (
                  <LoadingState title="Memuat modul" />
                ) : null}
                {modulesQuery.isError ? (
                  <ErrorState
                    description={getFirstApiError(modulesQuery.error)}
                    onRetry={() => void modulesQuery.refetch()}
                    title="Gagal memuat modul"
                  />
                ) : null}
                {!modulesQuery.isLoading && !modulesQuery.isError ? (
                  modules.length === 0 ? (
                    <EmptyState
                      description="Belum ada modul kelas yang bisa dikelola."
                      title="Modul belum tersedia"
                    />
                  ) : (
                    <div className="grid gap-3">
                      {modules.map((module) => (
                        <div
                          className="rounded-xl border-2 border-border bg-surface-muted p-3"
                          key={module.id}
                        >
                          <Badge tone={teacherStatusTone(module.status)}>
                            {statusLabel(module.status)}
                          </Badge>
                          <p className="mt-2 font-black text-ink">
                            {module.title}
                          </p>
                          <p className="text-sm text-muted">
                            {formatOptional(module.description)}
                          </p>
                        </div>
                      ))}
                    </div>
                  )
                ) : null}
              </CardContent>
            </Card>

            <Card className="flex h-full flex-col">
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Kuis Kelas</h2>
              </CardHeader>
              <CardContent>
                {quizzesQuery.isLoading ? (
                  <LoadingState title="Memuat kuis" />
                ) : null}
                {quizzesQuery.isError ? (
                  <ErrorState
                    description={getFirstApiError(quizzesQuery.error)}
                    onRetry={() => void quizzesQuery.refetch()}
                    title="Gagal memuat kuis"
                  />
                ) : null}
                {!quizzesQuery.isLoading && !quizzesQuery.isError ? (
                  quizzes.length === 0 ? (
                    <EmptyState
                      description="Belum ada kuis kelas yang bisa ditinjau."
                      title="Kuis belum tersedia"
                    />
                  ) : (
                    <div className="grid gap-3">
                      {quizzes.map((quiz) => (
                        <div
                          className="rounded-xl border-2 border-border bg-surface-muted p-3"
                          key={quiz.id}
                        >
                          <Badge
                            tone={
                              quiz.status === "published" ? "blue" : "neutral"
                            }
                          >
                            {statusLabel(quiz.status)}
                          </Badge>
                          <p className="mt-2 font-black text-ink">
                            {quiz.title}
                          </p>
                          <p className="text-sm text-muted">
                            {formatOptional(quiz.description)}
                          </p>
                          <p className="mt-2 text-xs text-muted">
                            Soal: {formatCount(quiz.questions_count)} | Attempt:{" "}
                            {formatCount(quiz.attempts_count)}
                          </p>
                        </div>
                      ))}
                    </div>
                  )
                ) : null}
              </CardContent>
            </Card>
          </section>

          <Alert tone="info">
            Detail kelas ini berfungsi sebagai ringkasan cepat. Untuk mengelola
            materi atau kuis, gunakan menu Modul dan Kuis.
          </Alert>
        </>
      ) : null}
    </div>
  );
}
