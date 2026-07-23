"use client";

import Link from "next/link";
import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  EmptyState,
  ErrorState,
  LoadingState,
  Pagination,
  Table,
  TableCell,
  TableHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { userStatusLabel } from "@/features/admin/management/management-utils";
import { getFirstApiError } from "@/lib/api-client";

import { progressReportService } from "./progress-service";
import { ProgressBar } from "./progress-summary-cards";
import {
  formatDateTime,
  formatNumber,
  formatPercent,
  latestActivity,
  learningStatus,
  learningStatusLabel,
  statusTone,
} from "./progress-utils";

export function ProgressStudentDetail({ studentId }: { studentId: string }) {
  const { token } = useAuth();
  const [quizPage, setQuizPage] = useState(1);

  const detailQuery = useQuery({
    queryKey: ["admin", "progress", "student-detail", studentId, quizPage],
    queryFn: () => progressReportService.studentDetail(token ?? "", studentId, { quiz_page: quizPage, quiz_per_page: 10 }),
    enabled: Boolean(token && studentId),
  });
  const userQuery = { ...detailQuery, data: detailQuery.data?.student };
  const progressQuery = { ...detailQuery, data: detailQuery.data?.progress };
  const quizResultsQuery = { ...detailQuery, data: detailQuery.data ? { items: detailQuery.data.quizzes.data, meta: detailQuery.data.quizzes.meta, summary: detailQuery.data.quiz_summary } : undefined };
  const user = userQuery.data;
  const progress = progressQuery.data ?? null;
  const status = progress ? learningStatus(progress) : null;
  const quizRows = quizResultsQuery.data?.items ?? [];
  const quizMeta = quizResultsQuery.data?.meta;
  const quizSummary = quizResultsQuery.data?.summary;

  function printReport() {
    void progressReportService.downloadPdf(token ?? "", `/admin/reports/progress/students/${studentId}/pdf`);
  }

  return (
    <div className="grid gap-6">
      <Link
        className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100"
        href="/admin/progress"
      >
        Kembali ke Progress
      </Link>

      {userQuery.isLoading ? <LoadingState title="Memuat identitas siswa" /> : null}
      {userQuery.isError ? (
        <ErrorState
          description={getFirstApiError(userQuery.error)}
          onRetry={() => void userQuery.refetch()}
          title="Gagal memuat siswa"
        />
      ) : null}

      {user ? (
        <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <div className="flex flex-wrap gap-2">
              <Badge tone="yellow">ADMIN-18</Badge>
              <Badge tone={statusTone(user.status)}>{userStatusLabel(user.status)}</Badge>
            </div>
            <h1 className="mt-2 text-3xl font-black text-ink">{user.full_name}</h1>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              {user.email} | {progress?.school.name ?? "Sekolah belum tersedia"} |{" "}
              {progress?.class.name ?? "Kelas belum tersedia"}
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <Button
              disabled={userQuery.isLoading || progressQuery.isLoading || quizResultsQuery.isLoading}
              onClick={printReport}
            >
              Cetak PDF
            </Button>
          </div>
        </header>
      ) : null}

      {progressQuery.isLoading ? <LoadingState title="Memuat progress siswa" /> : null}
      {progressQuery.isError ? (
        <ErrorState
          description={getFirstApiError(progressQuery.error)}
          onRetry={() => void progressQuery.refetch()}
          title="Gagal memuat progress siswa"
        />
      ) : null}
      {!progressQuery.isLoading && !progressQuery.isError ? (
        progress ? (
          <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-slate-500">Progress Modul</p>
                <div className="mt-3">
                  <ProgressBar value={progress.overall_learning_progress_percent} />
                </div>
                <p className="mt-2 text-sm text-slate-600">
                  {progress.completed_modules}/{progress.published_modules} modul selesai.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-slate-500">Pelajaran Selesai</p>
                <p className="mt-3 text-3xl font-black text-ink">
                  {formatNumber(progress.completed_lessons)}
                </p>
                <p className="mt-2 text-sm text-slate-600">
                  Dari {formatNumber(progress.total_published_lessons)} pelajaran terbit.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-slate-500">Rata-rata Kuis</p>
                <p className="mt-3 text-3xl font-black text-ink">
                  {formatPercent(progress.average_best_quiz_score_percent)}
                </p>
                <p className="mt-2 text-sm text-slate-600">
                  {progress.quizzes_completed}/{progress.published_quizzes} kuis selesai.
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-slate-500">Status Belajar</p>
                <div className="mt-3">
                  <Badge tone={statusTone(status)}>{learningStatusLabel(status)}</Badge>
                </div>
                <p className="mt-2 text-sm text-slate-600">
                  Aktivitas terakhir: {formatDateTime(latestActivity(progress))}
                </p>
              </CardContent>
            </Card>
          </section>
        ) : (
          <EmptyState
            description="Endpoint progress tidak mengembalikan baris untuk siswa ini."
            title="Progress siswa belum tersedia"
          />
        )
      ) : null}

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Riwayat Kuis</h2>
          <p className="text-sm text-slate-600">
            Satu baris per siswa dan class quiz; backend memilih best final attempt.
          </p>
        </CardHeader>
        <CardContent>
          {quizResultsQuery.isLoading ? <LoadingState title="Memuat hasil kuis" /> : null}
          {quizResultsQuery.isError ? (
            <ErrorState
              description={getFirstApiError(quizResultsQuery.error)}
              onRetry={() => void quizResultsQuery.refetch()}
              title="Gagal memuat hasil kuis"
            />
          ) : null}
          {!quizResultsQuery.isLoading && !quizResultsQuery.isError ? (
            quizRows.length === 0 ? (
              <EmptyState
                description="Belum ada hasil kuis untuk siswa ini."
                title="Riwayat kuis kosong"
              />
            ) : (
              <div className="grid gap-4">
                {quizSummary ? (
                  <div className="grid gap-4 md:grid-cols-3">
                    <Card>
                      <CardContent>
                        <p className="text-xs font-black uppercase text-slate-500">Partisipasi</p>
                        <p className="mt-3 text-2xl font-black text-ink">
                          {formatPercent(quizSummary.participation_rate_percent)}
                        </p>
                      </CardContent>
                    </Card>
                    <Card>
                      <CardContent>
                        <p className="text-xs font-black uppercase text-slate-500">Completion</p>
                        <p className="mt-3 text-2xl font-black text-ink">
                          {formatPercent(quizSummary.completion_rate_percent)}
                        </p>
                      </CardContent>
                    </Card>
                    <Card>
                      <CardContent>
                        <p className="text-xs font-black uppercase text-slate-500">Best Average</p>
                        <p className="mt-3 text-2xl font-black text-ink">
                          {formatPercent(quizSummary.average_best_score_percent)}
                        </p>
                      </CardContent>
                    </Card>
                  </div>
                ) : null}
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Kuis</th>
                      <th className="px-4 py-3">Attempt</th>
                      <th className="px-4 py-3">Nilai</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Submit Terakhir</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {quizRows.map((row) => (
                      <tr key={row.quiz.id}>
                        <TableCell>
                          <p className="font-black text-ink">{row.quiz.title}</p>
                          <p className="text-xs text-slate-600">{row.class.name}</p>
                        </TableCell>
                        <TableCell>
                          {row.attempt_count} attempt
                          {row.best_attempt_number ? ` | terbaik #${row.best_attempt_number}` : ""}
                        </TableCell>
                        <TableCell>{formatPercent(row.best_score_percent)}</TableCell>
                        <TableCell>
                          <Badge tone={statusTone(row.latest_status)}>
                            {row.latest_status ?? "Belum mulai"}
                          </Badge>
                        </TableCell>
                        <TableCell>{formatDateTime(row.latest_submitted_at)}</TableCell>
                      </tr>
                    ))}
                  </tbody>
                </Table>
                <Pagination
                  onPageChange={setQuizPage}
                  page={quizMeta?.current_page ?? quizPage}
                  totalPages={quizMeta?.last_page ?? 1}
                />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Riwayat Speaking</h2>
        </CardHeader>
        <CardContent>
          <Alert tone="info">
            Speaking report belum aktif di backend fase ini (`speaking_reports=false`), jadi
            riwayat speaking tidak ditampilkan sebagai data palsu.
          </Alert>
        </CardContent>
      </Card>

    </div>
  );
}
