"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";

import { Alert, Badge, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState, PageHeader, StatsCard } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import { formatCount, formatDate, formatOptional, formatPercent } from "./student-utils";

const linkClass = "inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-blue-600 px-4 py-2 text-sm font-black text-white shadow-brutal hover:bg-blue-700";
const secondaryLinkClass = "inline-flex min-h-12 items-center justify-center rounded-xl border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal hover:bg-yellow-200";

const quickActions = [
  { href: "/student/modules", label: "Modul", title: "Lanjutkan materi", description: "Buka daftar modul dan pilih materi berikutnya." },
  { href: "/student/quizzes", label: "Kuis", title: "Kerjakan kuis", description: "Cek kuis aktif, batas waktu, dan hasil terakhir." },
  { href: "/student/dictionary", label: "Kamus", title: "Cari kosakata", description: "Temukan arti kata Mekongga, Indonesia, dan Inggris." },
  { href: "/student/chatbot", label: "Basis AI", title: "Tanya materi", description: "Ajukan pertanyaan berbasis sumber pengetahuan EMI." },
  { href: "/student/speaking", label: "Speaking", title: "Latihan pelafalan", description: "Rekam suara, lihat skor awal AI, lalu tunggu feedback guru." },
];

export function StudentDashboard() {
  const { token, user } = useAuth();
  const dashboardQuery = useQuery({
    queryKey: ["student", "dashboard"],
    queryFn: () => studentService.dashboard(token ?? ""),
    enabled: Boolean(token),
  });
  const modulesQuery = useQuery({
    queryKey: ["student", "modules", "dashboard"],
    queryFn: () => studentService.modules(token ?? ""),
    enabled: Boolean(token),
  });

  const summary = dashboardQuery.data;
  const nextModule = modulesQuery.data?.items.find((module) => module.progress.status !== "completed") ?? modulesQuery.data?.items[0];

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Siswa"
        description="Belajar dari modul kelas aktif dan pantau progress pribadi."
        title={`Halo, ${user?.full_name ?? "Siswa"}`}
      />

      {dashboardQuery.isLoading ? <LoadingState title="Memuat dashboard siswa" /> : null}
      {dashboardQuery.isError ? (
        <ErrorState
          description={getFirstApiError(dashboardQuery.error)}
          onRetry={() => void dashboardQuery.refetch()}
          title="Gagal memuat dashboard siswa"
        />
      ) : null}

      {summary ? (
        <>
          <Card className="overflow-hidden bg-[var(--color-primary-muted)]">
            <CardContent>
              <div className="grid gap-5 xl:grid-cols-[1.4fr_0.8fr] xl:items-center">
                <div>
                  <Badge tone="yellow">Beranda Belajar</Badge>
                  <h2 className="mt-3 text-2xl font-black text-ink md:text-4xl">
                    {nextModule ? `Lanjutkan: ${nextModule.title}` : "Mulai perjalanan belajar Mekongga"}
                  </h2>
                  <p className="mt-3 max-w-3xl text-sm leading-6 text-muted">
                    {nextModule
                      ? "Selesaikan materi berikutnya, lalu lanjutkan kuis, kamus, budaya, chatbot, atau speaking dari satu tempat."
                      : "Saat modul tersedia, rekomendasi belajar dan tombol lanjut akan tampil di sini."}
                  </p>
                  <div className="mt-5 flex flex-col gap-3 sm:flex-row">
                    <Link className={linkClass} href={nextModule ? `/student/modules/${nextModule.id}` : "/student/modules"}>
                      {nextModule ? "Lanjut Belajar" : "Lihat Modul"}
                    </Link>
                    <Link className={secondaryLinkClass} href="/student/quizzes">Cek Kuis</Link>
                  </div>
                </div>
                <div className="rounded-2xl border-2 border-ink bg-white p-4 shadow-brutal-sm">
                  <p className="text-xs font-black uppercase text-muted-foreground">Progress kelas</p>
                  <p className="mt-2 text-4xl font-black text-ink">{formatPercent(summary.learning.overall_progress_percent)}</p>
                  <div className="mt-4 h-3 overflow-hidden rounded-full border border-ink bg-yellow-100">
                    <div
                      className="h-full rounded-full bg-blue-600"
                      style={{ width: `${Math.min(Math.max(summary.learning.overall_progress_percent ?? 0, 0), 100)}%` }}
                    />
                  </div>
                  <p className="mt-3 text-sm text-muted">
                    {formatCount(summary.learning.completed_lessons)} dari {formatCount(summary.learning.total_lessons)} materi selesai.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatsCard helper={summary.class?.school?.name ?? "Kelas aktif"} label="Kelas" value={summary.class?.name ?? "Belum tersedia"} />
            <StatsCard helper="Modul tersedia untuk kelas aktif" label="Modul" value={formatCount(summary.learning.published_modules)} />
            <StatsCard helper={`${formatCount(summary.learning.completed_lessons)} dari ${formatCount(summary.learning.total_lessons)} materi`} label="Progress" value={formatPercent(summary.learning.overall_progress_percent)} />
            <StatsCard helper="Kuis yang dapat diakses" label="Kuis" value={formatCount(summary.quizzes.available)} />
          </section>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Lanjut Belajar</h2>
            </CardHeader>
            <CardContent>
              {summary.empty_state || !summary.class ? (
                <EmptyState
                  description="Belum ada kelas aktif yang terhubung dengan akun siswa ini. Minta Admin menempatkan siswa ke kelas."
                  title="Kelas belum tersedia"
                />
              ) : !nextModule ? (
                <EmptyState
                  description="Belum ada modul published untuk kelas aktif. Tunggu Admin/Guru menyiapkan materi."
                  title="Modul belum tersedia"
                />
              ) : (
                <div className="grid gap-4">
                  <div className="rounded-2xl border-2 border-ink bg-white p-4">
                    <p className="text-xs font-black uppercase text-slate-500">Rekomendasi belajar</p>
                    <h3 className="mt-2 text-2xl font-black text-ink">{nextModule.title}</h3>
                    <p className="mt-2 text-sm leading-6 text-slate-600">{formatOptional(nextModule.description)}</p>
                    <p className="mt-3 text-sm font-bold text-ink">Progress: {formatPercent(nextModule.progress.progress_percent)}</p>
                    <div className="mt-3 h-2 overflow-hidden rounded-full bg-slate-100">
                      <div
                        className="h-full rounded-full bg-blue-600"
                        style={{ width: `${Math.min(Math.max(nextModule.progress.progress_percent ?? 0, 0), 100)}%` }}
                      />
                    </div>
                  </div>
                  <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                    <Link className={linkClass} href={`/student/modules/${nextModule.id}`}>Lanjut Belajar</Link>
                    <Link className={secondaryLinkClass} href="/student/modules">Modul Saya</Link>
                    <Link className={secondaryLinkClass} href="/student/quizzes">Kuis & LKPD</Link>
                    <Link className={secondaryLinkClass} href="/student/dictionary">Kamus Mekongga</Link>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <section className="grid gap-4 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <h2 className="text-lg font-black text-ink">Ringkasan Modul</h2>
              </CardHeader>
              <CardContent>
                <div className="grid gap-3 sm:grid-cols-3">
                  <StatsCard helper="Belum dimulai" label="Baru" value={formatCount(summary.learning.not_started_modules)} />
                  <StatsCard helper="Sedang dipelajari" label="Berjalan" value={formatCount(summary.learning.in_progress_modules)} />
                  <StatsCard helper="Sudah selesai" label="Selesai" value={formatCount(summary.learning.completed_modules)} />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-lg font-black text-ink">Kuis & Deadline</h2>
              </CardHeader>
              <CardContent>
                {(summary.upcoming_deadlines ?? []).length === 0 ? (
                  <EmptyState description="Belum ada batas waktu kuis yang perlu dikejar saat ini." title="Tidak ada deadline" />
                ) : (
                  <div className="grid gap-3">
                    {summary.upcoming_deadlines?.map((deadline) => (
                      <div className="rounded-xl border border-slate-200 bg-white p-3" key={deadline.id}>
                        <p className="font-black text-ink">{deadline.title}</p>
                        <p className="text-sm text-slate-600">Ditutup: {formatDate(deadline.close_at)}</p>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </section>

          <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
            {quickActions.map((action) => (
              <Link
                className="rounded-2xl border-2 border-ink bg-white p-4 shadow-brutal transition hover:-translate-y-0.5 hover:bg-yellow-50"
                href={action.href}
                key={action.href}
              >
                <Badge tone="yellow">{action.label}</Badge>
                <h3 className="mt-3 text-lg font-black text-ink">{action.title}</h3>
                <p className="mt-2 text-sm leading-6 text-muted">{action.description}</p>
              </Link>
            ))}
          </section>

          <Alert tone="info">
            Speaking memakai skor awal AI dan tinjauan guru. Nilai kuis yang belum ditampilkan tetap mengikuti pengaturan guru.
          </Alert>
        </>
      ) : null}
    </div>
  );
}
