"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import {
  Alert,
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
        "rounded-[var(--radius-card)] border-2 border-border bg-surface p-4 shadow-emi",
        tone === "warning" && "bg-danger-muted text-danger",
        tone === "success" && "bg-green-50",
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
      <section className="relative overflow-hidden rounded-[var(--radius-card)] border-2 border-border bg-accent p-6 shadow-emi md:p-8">
        <div className="absolute -right-10 bottom-0 size-40 rounded-full border-2 border-border bg-primary opacity-60 blur-sm" />
        <div className="absolute -left-8 -top-8 size-28 rounded-full border-2 border-border bg-success opacity-50 blur-sm" />
        <div className="relative max-w-3xl">
          <p className="text-xs font-black uppercase tracking-[0.12em] text-accent-foreground">
            Beranda Admin
          </p>
          <h1 className="mt-3 text-3xl font-black leading-tight text-accent-foreground md:text-5xl">
            Elearning Mekongga Indonesia
          </h1>
          <p className="mt-3 text-lg font-bold text-accent-foreground">
            Halo, {user?.full_name ?? "Admin"}!
          </p>
          <p className="mt-2 max-w-2xl text-sm font-semibold leading-6 text-accent-foreground md:text-base">
            Pantau data sekolah, kelas, akun, materi, kuis, dan progress dari Laravel API.
            Dashboard ini tidak memakai angka dummy.
          </p>
          {summary?.generated_at ? (
            <p className="mt-4 inline-flex rounded-full border border-border bg-surface px-3 py-1 text-xs font-black text-ink">
              Data diperbarui {formatDateTime(summary.generated_at)}
            </p>
          ) : null}
        </div>
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

          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            <DashboardStat
              helper={`${formatNumber(summary.overview.active_teachers)} guru aktif`}
              label="Total Siswa"
              value={formatNumber(summary.overview.active_students)}
            />
            <DashboardStat
              helper={`${formatNumber(summary.overview.active_schools)} sekolah aktif`}
              label="Total Kelas"
              value={formatNumber(summary.overview.active_classes)}
            />
            <DashboardStat
              helper="Permintaan registrasi guru/siswa yang perlu ditinjau."
              label="Akun Menunggu"
              tone={summary.overview.pending_registration_requests > 0 ? "warning" : "success"}
              value={formatNumber(summary.overview.pending_registration_requests)}
            />
            <DashboardStat
              helper={`${formatNumber(summary.learning.students_with_learning_activity)} siswa sudah mulai belajar`}
              label="Progress Modul"
              value={formatPercent(summary.learning.average_learning_progress_percent)}
            />
            <DashboardStat
              helper={`${formatNumber(summary.learning.completed_modules)} penyelesaian modul tercatat`}
              label="Modul Selesai"
              value={formatNumber(summary.learning.completed_modules)}
            />
            <DashboardStat
              helper={`${formatPercent(summary.quizzes.participation_rate_percent)} partisipasi kuis`}
              label="Rata-rata Kuis"
              value={formatPercent(summary.quizzes.average_score_percent)}
            />
          </section>

          <section className="grid gap-6 xl:grid-cols-[1fr_1fr]">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <h2 className="text-xl font-black text-ink">Tindakan Cepat</h2>
                    <p className="mt-1 text-sm font-semibold text-muted">
                      Jalur cepat ke fitur admin yang sudah aktif.
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
                <div className="grid gap-4 sm:grid-cols-2">
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
                  Status ringkas dari data summary backend.
                </p>
              </CardHeader>
              <CardContent>
                <div className="grid gap-3">
                  <OperationalSignal
                    description="Pendaftaran baru tidak disembunyikan sebagai angka demo; buka daftar persetujuan untuk meninjau."
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
                    description={`${formatNumber(summary.learning.students_with_learning_activity)} siswa punya aktivitas belajar. Rata-rata progress modul ${formatPercent(summary.learning.average_learning_progress_percent)}.`}
                    href="/admin/progress"
                    label="Progress belajar"
                    status={formatPercent(summary.learning.average_learning_progress_percent)}
                    tone={summary.learning.students_with_learning_activity > 0 ? "success" : "neutral"}
                  />
                  <OperationalSignal
                    description={`${formatNumber(summary.quizzes.submitted_attempts)} attempt submitted dan ${formatNumber(summary.quizzes.final_attempts)} attempt final tercatat.`}
                    href="/admin/progress"
                    label="Aktivitas kuis"
                    status={formatPercent(summary.quizzes.participation_rate_percent)}
                    tone={summary.quizzes.submitted_attempts > 0 ? "success" : "neutral"}
                  />
                  <OperationalSignal
                    description="Speaking tetap diposisikan sebagai AI-assisted initial scoring dengan guru sebagai reviewer."
                    label="Laporan speaking admin"
                    status={summary.capabilities.speaking_reports ? "Tersedia" : "Belum tersedia"}
                    tone={summary.capabilities.speaking_reports ? "success" : "neutral"}
                  />
                </div>
              </CardContent>
            </Card>
          </section>

          <Alert tone="info">
            Data dashboard diambil dari endpoint existing <strong>/admin/dashboard/summary</strong>.
            Jika ada angka 0 atau status belum tersedia, itu mencerminkan response backend saat ini.
          </Alert>

          <section className="grid gap-4 md:grid-cols-3">
            <StatsCard
              helper="Sekolah aktif dari summary backend"
              label="Sekolah"
              value={formatNumber(summary.overview.active_schools)}
            />
            <StatsCard
              helper="Guru aktif dari summary backend"
              label="Guru"
              value={formatNumber(summary.overview.active_teachers)}
            />
            <StatsCard
              helper={`${formatNumber(summary.quizzes.expired_attempts)} expired, ${formatNumber(summary.quizzes.in_progress_attempts)} berjalan`}
              label="Attempt Kuis"
              value={formatNumber(summary.quizzes.final_attempts)}
            />
          </section>
        </>
      ) : null}
    </div>
  );
}
