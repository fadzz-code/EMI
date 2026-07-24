"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { 
  UserCheck, 
  School, 
  LibraryBig, 
  BrainCircuit, 
  BookOpen, 
  Globe, 
  Activity,
  AlertCircle,
  CheckCircle2
} from "lucide-react";

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
    icon: UserCheck,
    tone: "surface",
    description: "Tinjau pendaftaran guru dan siswa.",
  },
  {
    href: "/admin/schools-classes",
    label: "Kelola Kelas",
    icon: School,
    tone: "surface",
    description: "Sekolah, kelas, guru, dan anggota.",
  },
  {
    href: "/admin/dictionary/import",
    label: "Import Kamus",
    icon: LibraryBig,
    tone: "surface",
    description: "CSV dan ZIP audio kosakata.",
  },
  {
    href: "/admin/knowledge-base",
    label: "Basis AI/RAG",
    icon: BrainCircuit,
    tone: "dark",
    description: "Kelola knowledge manual, link, dan PDF.",
  },
  {
    href: "/admin/modules",
    label: "Modul",
    icon: BookOpen,
    tone: "surface",
    description: "Template materi dan apply ke kelas.",
  },
  {
    href: "/admin/culture/templates",
    label: "Budaya Mekongga",
    icon: Globe,
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
        tone === "success" && "border-success/30 bg-success/10",
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
  const Icon = action.icon;
  return (
    <Link
      className={cn(
        "group flex h-full min-h-32 flex-col justify-between rounded-2xl border-2 border-border bg-surface p-5 text-ink transition hover:-translate-y-1 hover:shadow-emi",
        action.tone === "surface" && "bg-surface text-ink",
      )}
      href={action.href}
    >
      <span
        aria-hidden="true"
        className={cn(
          "flex size-12 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink transition-colors group-hover:bg-primary group-hover:text-primary-foreground",
          action.tone === "surface" && "bg-surface-muted text-ink",
        )}
      >
        <Icon className="size-5" strokeWidth={2.5} />
      </span>
      <span className="mt-4">
        <span className="block text-sm font-black">{action.label}</span>
        <span
          className="mt-1 block text-xs font-semibold leading-5 text-muted"
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
        "group rounded-[var(--radius-control)] border-2 p-4 transition-colors",
        tone === "warning" ? "border-danger/20 bg-danger-muted" : 
        tone === "success" ? "border-success/30 bg-success/10" :
        "border-transparent bg-surface-muted",
        href && "hover:border-border hover:shadow-[2px_2px_0px_0px_var(--border)]"
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-start gap-3">
          {tone === "warning" && <AlertCircle className="size-5 shrink-0 text-danger mt-0.5" />}
          {tone === "success" && <CheckCircle2 className="size-5 shrink-0 text-success-foreground mt-0.5" />}
          {tone === "neutral" && <Activity className="size-5 shrink-0 text-muted mt-0.5" />}
          <div>
            <p className="text-sm font-black text-ink">{label}</p>
            <p className="mt-1 text-sm leading-6 text-muted">{description}</p>
          </div>
        </div>
        <span className={cn(
          "shrink-0 rounded-full border px-2.5 py-1 text-[10px] font-black uppercase tracking-wider",
          tone === "warning" ? "border-danger/30 bg-danger/10 text-danger" : 
          tone === "success" ? "border-success/40 bg-success/20 text-success-foreground" :
          "border-border bg-surface text-ink"
        )}>
          {status}
        </span>
      </div>
    </div>
  );

  if (!href) {
    return content;
  }

  return (
    <Link className="block" href={href}>
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
    <div className="grid gap-8">
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
              tone={summary.quizzes.submitted_attempts > 0 ? "success" : "default"}
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
