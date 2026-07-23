"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";

import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  EmptyState,
  ErrorState,
  FilterPanel,
  Input,
  LoadingState,
  Pagination,
  Select,
  Table,
  TableCell,
  TableHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { classService, schoolService } from "@/features/admin/management/management-service";
import { getFirstApiError } from "@/lib/api-client";
import type { ApiPaginationMeta } from "@/lib/api-client";

import { progressReportService } from "./progress-service";
import { ProgressBar, ProgressSummaryCards } from "./progress-summary-cards";
import {
  formatDateTime,
  formatNumber,
  formatPercent,
  latestActivity,
  learningStatus,
  learningStatusLabel,
  statusTone,
} from "./progress-utils";
import type { LearningStatus } from "./types";

function paginatedOverview<T>(page: { data: T[]; meta: ApiPaginationMeta }) {
  return { items: page.data, meta: page.meta };
}

export function ProgressOverview() {
  const { token } = useAuth();
  const [page, setPage] = useState(1);
  const [classPage, setClassPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [schoolId, setSchoolId] = useState("");
  const [classId, setClassId] = useState("");
  const [learningStatusFilter, setLearningStatusFilter] = useState<LearningStatus | "">("");

  const studentFilters = useMemo(
    () => ({
      school_id: schoolId,
      class_id: classId,
      search,
      learning_status: learningStatusFilter,
      page,
      per_page: 12,
    }),
    [classId, learningStatusFilter, page, schoolId, search],
  );

  const classFilters = useMemo(
    () => ({
      school_id: schoolId,
      search,
      page: classPage,
      per_page: 8,
    }),
    [classPage, schoolId, search],
  );

  const overviewQuery = useQuery({
    queryKey: ["admin", "progress", "overview", studentFilters, classFilters],
    queryFn: () => progressReportService.overview(token ?? "", {
      ...studentFilters,
      student_page: page,
      student_per_page: 12,
      class_page: classPage,
      class_per_page: 8,
    }),
    enabled: Boolean(token),
  });
  const summaryQuery = { ...overviewQuery, data: overviewQuery.data?.summary };
  const studentsQuery = { ...overviewQuery, data: overviewQuery.data ? paginatedOverview(overviewQuery.data.students) : undefined };
  const classesQuery = { ...overviewQuery, data: overviewQuery.data ? paginatedOverview(overviewQuery.data.classes) : undefined };

  const schoolsQuery = useQuery({
    queryKey: ["admin", "progress", "school-options"],
    queryFn: () => schoolService.list(token ?? "", { status: "active", per_page: 100 }),
    enabled: Boolean(token),
  });

  const classOptionsQuery = useQuery({
    queryKey: ["admin", "progress", "class-options", schoolId],
    queryFn: () =>
      classService.list(token ?? "", {
        status: "active",
        school_id: schoolId,
        per_page: 100,
      }),
    enabled: Boolean(token),
  });

  const students = studentsQuery.data?.items ?? [];
  const studentMeta = studentsQuery.data?.meta;
  const classes = classesQuery.data?.items ?? [];
  const classMeta = classesQuery.data?.meta;
  const schoolOptions = schoolsQuery.data?.items ?? [];
  const classOptions = classOptionsQuery.data?.items ?? [];
  function applyFilters() {
    setPage(1);
    setClassPage(1);
    setSearch(searchInput.trim());
  }

  function printReport() {
    void progressReportService.downloadPdf(token ?? "", "/admin/reports/progress/pdf", studentFilters);
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="yellow">ADMIN-17</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Progress Siswa</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Pantau progress global, daftar siswa, dan ringkasan kelas untuk kebutuhan laporan admin.
          </p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <Button
            disabled={summaryQuery.isLoading || studentsQuery.isLoading}
            onClick={printReport}
          >
            Cetak PDF
          </Button>
        </div>
      </header>

      {summaryQuery.isLoading ? <LoadingState title="Memuat ringkasan progress" /> : null}
      {summaryQuery.isError ? (
        <ErrorState
          description={getFirstApiError(summaryQuery.error)}
          onRetry={() => void summaryQuery.refetch()}
          title="Gagal memuat ringkasan"
        />
      ) : null}
      {!summaryQuery.isLoading && !summaryQuery.isError ? (
        <ProgressSummaryCards summary={summaryQuery.data} />
      ) : null}

      <FilterPanel className="xl:grid-cols-[1.4fr_1fr_1fr_1fr_auto]">
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Cari siswa / kelas</span>
          <Input
            onChange={(event) => setSearchInput(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                applyFilters();
              }
            }}
            placeholder="Nama siswa atau kelas"
            value={searchInput}
          />
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Sekolah</span>
          <Select
            onChange={(event) => {
              setSchoolId(event.target.value);
              setClassId("");
              setPage(1);
              setClassPage(1);
            }}
            value={schoolId}
          >
            <option value="">Semua sekolah</option>
            {schoolOptions.map((school) => (
              <option key={school.id} value={school.id}>
                {school.name}
              </option>
            ))}
          </Select>
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Kelas</span>
          <Select
            onChange={(event) => {
              setClassId(event.target.value);
              setPage(1);
            }}
            value={classId}
          >
            <option value="">Semua kelas</option>
            {classOptions.map((schoolClass) => (
              <option key={schoolClass.id} value={schoolClass.id}>
                {schoolClass.name}
              </option>
            ))}
          </Select>
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Status belajar</span>
          <Select
            onChange={(event) => {
              setLearningStatusFilter(event.target.value as LearningStatus | "");
              setPage(1);
            }}
            value={learningStatusFilter}
          >
            <option value="">Semua status</option>
            <option value="not_started">Belum mulai</option>
            <option value="in_progress">Berjalan</option>
            <option value="completed">Selesai</option>
          </Select>
        </label>
        <div className="flex items-end">
          <Button className="w-full" onClick={applyFilters} variant="secondary">
            Terapkan
          </Button>
        </div>
      </FilterPanel>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Daftar Progress Siswa</h2>
        </CardHeader>
        <CardContent>
          {studentsQuery.isLoading ? <LoadingState title="Memuat progress siswa" /> : null}
          {studentsQuery.isError ? (
            <ErrorState
              description={getFirstApiError(studentsQuery.error)}
              onRetry={() => void studentsQuery.refetch()}
              title="Gagal memuat progress siswa"
            />
          ) : null}
          {!studentsQuery.isLoading && !studentsQuery.isError ? (
            students.length === 0 ? (
              <EmptyState
                description="Belum ada progress siswa sesuai filter saat ini."
                title="Progress siswa kosong"
              />
            ) : (
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Siswa</th>
                      <th className="px-4 py-3">Sekolah / Kelas</th>
                      <th className="px-4 py-3">Progress Modul</th>
                      <th className="px-4 py-3">Nilai Kuis</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Aktivitas Terakhir</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {students.map((student) => {
                      const status = learningStatus(student);

                      return (
                        <tr key={student.student_id}>
                          <TableCell>
                            <p className="font-black text-ink">{student.full_name}</p>
                            <p className="mt-1 text-xs text-slate-600">Email belum tersedia di laporan progress.</p>
                          </TableCell>
                          <TableCell>
                            <p className="font-bold text-ink">{student.school.name}</p>
                            <p className="text-xs text-slate-600">{student.class.name}</p>
                          </TableCell>
                          <TableCell>
                            <ProgressBar value={student.overall_learning_progress_percent} />
                            <p className="mt-1 text-xs text-slate-600">
                              {student.completed_modules}/{student.published_modules} modul selesai
                            </p>
                          </TableCell>
                          <TableCell>
                            <p className="font-black text-ink">
                              {formatPercent(student.average_best_quiz_score_percent)}
                            </p>
                            <p className="text-xs text-slate-600">
                              {student.quizzes_completed}/{student.published_quizzes} kuis selesai
                            </p>
                          </TableCell>
                          <TableCell>
                            <Badge tone={statusTone(status)}>{learningStatusLabel(status)}</Badge>
                          </TableCell>
                          <TableCell>{formatDateTime(latestActivity(student))}</TableCell>
                          <TableCell>
                            <Link
                              className="inline-flex min-h-9 items-center rounded-lg border-2 border-ink bg-white px-3 py-1 text-xs font-black text-ink hover:bg-yellow-100"
                              href={`/admin/progress/students/${student.student_id}`}
                            >
                              Detail Siswa
                            </Link>
                          </TableCell>
                        </tr>
                      );
                    })}
                  </tbody>
                </Table>
                <Pagination
                  onPageChange={setPage}
                  page={studentMeta?.current_page ?? page}
                  totalPages={studentMeta?.last_page ?? 1}
                />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Ringkasan Progress Kelas</h2>
          <p className="text-sm text-slate-600">
            Bandingkan progress modul dan kuis antar kelas dari filter yang sama.
          </p>
        </CardHeader>
        <CardContent>
          {classesQuery.isLoading ? <LoadingState title="Memuat progress kelas" /> : null}
          {classesQuery.isError ? (
            <ErrorState
              description={getFirstApiError(classesQuery.error)}
              onRetry={() => void classesQuery.refetch()}
              title="Gagal memuat progress kelas"
            />
          ) : null}
          {!classesQuery.isLoading && !classesQuery.isError ? (
            classes.length === 0 ? (
              <EmptyState
                description="Belum ada kelas sesuai filter saat ini."
                title="Progress kelas kosong"
              />
            ) : (
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Kelas</th>
                      <th className="px-4 py-3">Siswa</th>
                      <th className="px-4 py-3">Progress Modul</th>
                      <th className="px-4 py-3">Kuis</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {classes.map((schoolClass) => (
                      <tr key={schoolClass.class_id}>
                        <TableCell>
                          <p className="font-black text-ink">{schoolClass.class_name}</p>
                          <p className="text-xs text-slate-600">{schoolClass.school_name}</p>
                        </TableCell>
                        <TableCell>{formatNumber(schoolClass.active_students)}</TableCell>
                        <TableCell>
                          <ProgressBar value={schoolClass.average_learning_progress_percent} />
                          <p className="mt-1 text-xs text-slate-600">
                            {formatNumber(schoolClass.completed_module_count)} modul selesai
                          </p>
                        </TableCell>
                        <TableCell>
                          <p className="font-black text-ink">
                            {formatPercent(schoolClass.average_quiz_score_percent)}
                          </p>
                          <p className="text-xs text-slate-600">
                            {formatNumber(schoolClass.students_participated_in_quiz)} siswa ikut kuis
                          </p>
                        </TableCell>
                        <TableCell>
                          <Link
                            className="inline-flex min-h-9 items-center rounded-lg border-2 border-ink bg-white px-3 py-1 text-xs font-black text-ink hover:bg-yellow-100"
                            href={`/admin/progress/classes/${schoolClass.class_id}`}
                          >
                            Detail Kelas
                          </Link>
                        </TableCell>
                      </tr>
                    ))}
                  </tbody>
                </Table>
                <Pagination
                  onPageChange={setClassPage}
                  page={classMeta?.current_page ?? classPage}
                  totalPages={classMeta?.last_page ?? 1}
                />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>

    </div>
  );
}
