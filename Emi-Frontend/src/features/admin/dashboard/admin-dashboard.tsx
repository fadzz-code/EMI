"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import {
  Card,
  CardContent,
  CardHeader,
  EmptyState,
  ErrorState,
  LoadingState,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { cn } from "@/lib/utils";

import { progressReportService } from "../progress/progress-service";
import { formatDateTime, formatNumber, formatPercent } from "../progress/progress-utils";
import type { DashboardSummary } from "../progress/types";

type StatTone = "default" | "warning" | "success";

const quickActions = [
  {
    href: "/admin/approvals",
    label: "Persetujuan Akun",
    marker: "PA",
    tone: "primary",
    description: "Tinjau pendaftaran guru dan siswa.",
  },
  {
    href: "/admin/schools-classes",
    label: "Kelola Kelas",
    marker: "KK",
    tone: "surface",
    description: "Sekolah, kelas, guru, dan anggota.",
  },
  {
    href: "/admin/dictionary/import",
    label: "Import Kamus",
    marker: "IK",
    tone: "surface",
    description: "CSV dan ZIP audio kosakata.",
  },
  {
    href: "/admin/knowledge-base",
    label: "Basis AI/RAG",
    marker: "AI",
    tone: "dark",
    description: "Kelola knowledge manual, link, dan PDF.",
  },
  {
    href: "/admin/modules",
    label: "Modul",
    marker: "MO",
    tone: "surface",
    description: "Template materi dan apply ke kelas.",
  },
  {
    href: "/admin/culture/templates",
    label: "Budaya Mekongga",
    marker: "BM",
    tone: "surface",
    description: "Konten budaya untuk kelas dan siswa.",
  },
] as const;

function isSummaryEmpty(summary: DashboardSummary) {
  return (
    summary.overview.active_schools === 0 &&
    summary.overview.active_classes === 0 &&
    summary.overview.active_teachers === 0 &&
    summary.overview.active_students === 0 &&
    summary.overview.pending_registration_requests === 0 &&
    summary.learning.students_with_learning_activity === 0 &&
    summary.learning.completed_modules === 0 &&
    summary.quizzes.final_attempts === 0 &&
    summary.quizzes.submitted_attempts === 0
  );
}

function DashboardStat({
  helper,
  label,
  tone = "default",
  value,
}: {
  helper: string;
  label: string;
  tone?: StatTone;
  value: string;
}) {
  return (
    <div
      className={cn(
        "rounded-[var(--radius-card)] border-2 border-border bg-surface p-4 shadow-emi flex flex-col justify-between",
        tone === "warning" && "bg-danger-muted text-danger border-danger/20",
        tone === "success" && "bg-green-50 border-green-200",
      )}
    >
      <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">{label}</p>
      <p className="mt-3 text-3xl font-black text-ink">{value}</p>
      <p className="mt-2 text-sm font-semibold text-muted">{helper}</p>
    </div>
  );
}

function QuickActionCard({
  action,
}: {
  action: (typeof quickActions)[number];
}) {
  return (
    <Link
      className={cn(
        "flex min-h-32 flex-col justify-between rounded-[var(--radius-card)] border-2 border-border p-4 shadow-emi transition hover:-translate-y-0.5",
        action.tone === "primary" && "bg-primary text-primary-foreground",
        action.tone === "surface" && "bg-surface text-ink",
        action.tone === "dark" && "bg-ink text-paper",
      )}
      href={action.href}
    >
      <span
        aria-hidden="true"
        className={cn(
          "flex size-11 items-center justify-center rounded-full border-2 border-border bg-surface text-xs font-black text-ink shadow-[2px_2px_0_var(--border)]",
          action.tone === "primary" && "bg-surface text-primary-foreground",
          action.tone === "dark" && "bg-surface text-ink",
        )}
      >
        {action.marker}
      </span>
      <span>
        <span className="block text-sm font-black">{action.label}</span>
        <span
          className={cn(
            "mt-1 block text-xs font-semibold leading-5",
            action.tone === "dark" ? "text-paper/80" : "text-muted",
          )}
        >
          {action.description}
        </span>
      </span>
    </Link>
  );
}

function OperationalSignal({
  description,
  href,
  label,
  status,
  tone = "neutral",
}: {
  description: string;
  href?: string;
  label: string;
  status: string;
  tone?: "neutral" | "warning" | "success";
}) {
  const content = (
    <div
      className={cn(
        "rounded-[var(--radius-control)] border-2 border-transparent bg-surface-muted p-4",
        tone === "warning" && "bg-danger-muted",
        tone === "success" && "bg-green-50",
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-sm font-black text-ink">{label}</p>
          <p className="mt-1 text-sm leading-6 text-muted">{description}</p>
        </div>
        <span className="shrink-0 rounded-full border border-border bg-surface px-2.5 py-1 text-xs font-black text-ink">
          {status}
        </span>
      </div>
    </div>
  );

  if (!href) {
    return content;
  }

  return (
    <Link className="block transition hover:-translate-y-0.5" href={href}>
      {content}
    </Link>
  );
}

export function AdminDashboard() {
  const { token, user } = useAuth();
  const summaryQuery = useQuery({
    queryKey: ["admin", "dashboard", "summary"],
    queryFn: () => progressReportService.dashboardSummary(token ?? ""),
    enabled: Boolean(token),
  });

  const summary = summaryQuery.data;

  return (
    <div className="grid gap-6">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">
          Beranda Admin
        </p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">
          Halo, {user?.full_name ?? "Admin"}!
        </h1>
        <p className="text-base font-semibold leading-6 text-muted max-w-3xl">
          Pantau data sekolah, kelas, akun, materi, kuis, dan progress dari Laravel API.
        </p>
        {summary?.generated_at ? (
          <p className="text-xs font-bold text-muted">
            Update terakhir: {formatDateTime(summary.generated_at)}
          </p>
        ) : null}
      </section>

      {summaryQuery.isLoading ? <LoadingState title="Memuat dashboard admin" /> : null}
      {summaryQuery.isError ? (
        <ErrorState
          description={getFirstApiError(summaryQuery.error)}
          onRetry={() => void summaryQuery.refetch()}
          title="Gagal memuat dashboard admin"
        />
      ) : null}

      {summary ? (
        <>
          {isSummaryEmpty(summary) ? (
            <EmptyState
              description="Endpoint summary sudah terhubung, tetapi belum ada data aktif. Isi data sekolah, kelas, pengguna, modul, dan kuis untuk melihat ringkasan operasional."
              title="Belum ada data operasional"
            />
          ) : null}

          <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <DashboardStat
              helper="Siswa teregistrasi"
              label="Siswa"
              value={formatNumber(summary.overview.active_students)}
            />
            <DashboardStat
              helper="Guru teregistrasi"
              label="Guru"
              value={formatNumber(summary.overview.active_teachers)}
            />
            <DashboardStat
              helper="Sekolah terdaftar"
              label="Sekolah"
              value={formatNumber(summary.overview.active_schools)}
            />
            <DashboardStat
              helper="Kelas aktif"
              label="Kelas"
              value={formatNumber(summary.overview.active_classes)}
            />
            <DashboardStat
              helper="Butuh review"
              label="Persetujuan"
              tone={summary.overview.pending_registration_requests > 0 ? "warning" : "success"}
              value={formatNumber(summary.overview.pending_registration_requests)}
            />
            <DashboardStat
              helper="Submission kuis"
              label="Kuis"
              value={formatNumber(summary.quizzes.submitted_attempts)}
            />
          </section>

          <section className="grid gap-6 xl:grid-cols-[1fr_1fr]">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <h2 className="text-xl font-black text-ink">Aksi Cepat</h2>
                    <p className="mt-1 text-sm font-semibold text-muted">
                      Jalur cepat ke fitur admin utama.
                    </p>
                  </div>
                  {summary.overview.pending_registration_requests > 0 ? (
                    <span className="rounded-full border border-danger bg-danger-muted px-3 py-1 text-xs font-black text-danger">
                      {formatNumber(summary.overview.pending_registration_requests)} perlu review
                    </span>
                  ) : null}
                </div>
              </CardHeader>
              <CardContent>
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-2">
                  {quickActions.map((action) => (
                    <QuickActionCard action={action} key={action.href} />
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Sinyal Operasional</h2>
                <p className="mt-1 text-sm font-semibold text-muted">
                  Status ringkas operasional sistem.
                </p>
              </CardHeader>
              <CardContent>
                <div className="grid gap-3">
                  <OperationalSignal
                    description="Pendaftaran baru yang butuh persetujuan manual."
                    href="/admin/approvals"
                    label="Persetujuan akun"
                    status={
                      summary.overview.pending_registration_requests > 0
                        ? `${formatNumber(summary.overview.pending_registration_requests)} pending`
                        : "Terkendali"
                    }
                    tone={summary.overview.pending_registration_requests > 0 ? "warning" : "success"}
                  />
                  <OperationalSignal
                    description="Data progress pembelajaran dan partisipasi aktif."
                    href="/admin/progress"
                    label="Progress belajar"
                    status={formatPercent(summary.learning.average_learning_progress_percent)}
                    tone={summary.learning.students_with_learning_activity > 0 ? "success" : "neutral"}
                  />
                  <OperationalSignal
                    description="Data penyelesaian materi kuis."
                    href="/admin/progress"
                    label="Aktivitas kuis"
                    status={formatPercent(summary.quizzes.participation_rate_percent)}
                    tone={summary.quizzes.submitted_attempts > 0 ? "success" : "neutral"}
                  />
                </div>
              </CardContent>
            </Card>
          </section>
        </>
      ) : null}
    </div>
  );
}
