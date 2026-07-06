"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { BookCheck, BookOpen, ClipboardList, LibraryBig, MessageSquare, Mic } from "lucide-react";

import {
  Alert,
  Card,
  CardContent,
  CardHeader,
  ErrorState,
  LoadingState,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentService } from "./student-service";
import { formatCount, formatPercent } from "./student-utils";

const quickActions = [
  { href: "/student/modules", label: "Modul", title: "Lanjutkan materi", description: "Buka daftar modul dan materi.", icon: BookOpen },
  { href: "/student/quizzes", label: "Kuis", title: "Kerjakan kuis", description: "Cek kuis dan tugas aktif.", icon: ClipboardList },
  { href: "/student/dictionary", label: "Kamus", title: "Cari kosakata", description: "Temukan arti kata Mekongga.", icon: LibraryBig },
  { href: "/student/chatbot", label: "Basis AI", title: "Tanya AI", description: "Tanya asisten cerdas EMI.", icon: MessageSquare },
  { href: "/student/speaking", label: "Speaking", title: "Latihan speaking", description: "Latih dan rekam pelafalan.", icon: Mic },
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
    <div className="grid gap-8">
      <section className="flex flex-col gap-2">
        <p className="text-sm font-black uppercase tracking-[0.08em] text-muted">
          Beranda Belajar
        </p>
        <h1 className="text-3xl font-black leading-tight text-ink md:text-4xl">
          Selamat datang, {user?.full_name ?? "Siswa"}!
        </h1>
        <p className="text-base font-semibold leading-6 text-muted max-w-3xl">
          Lanjutkan perjalanan belajarmu, kerjakan kuis, dan pantau hasil belajarmu di sini.
        </p>
      </section>

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
          <section className="grid gap-6 lg:grid-cols-[1.4fr_0.6fr]">
            <Card className="flex flex-col justify-center overflow-hidden bg-[var(--color-primary-muted)]">
              <CardContent className="p-6 sm:p-8">
                <div className="flex flex-col gap-6 xl:flex-row xl:items-center xl:justify-between">
                  <div className="flex-1">
                    <h2 className="text-2xl font-black text-ink md:text-3xl">
                      {nextModule ? `Lanjut Belajar: ${nextModule.title}` : "Siap mulai belajar?"}
                    </h2>
                    <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-muted">
                      {nextModule
                        ? "Ayo selesaikan materi ini agar progress belajarmu meningkat."
                        : "Semua materi sudah tuntas atau tunggu guru menyiapkan materi baru."}
                    </p>
                    <div className="mt-6 flex flex-col gap-3 sm:flex-row">
                      <Link 
                        className="inline-flex min-h-12 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-primary px-6 py-2 text-sm font-black text-primary-foreground shadow-emi transition-transform hover:-translate-y-0.5" 
                        href={nextModule ? `/student/modules/${nextModule.id}` : "/student/modules"}
                      >
                        {nextModule ? "Lanjut Materi" : "Lihat Modul"} 
                        <BookCheck className="size-5" strokeWidth={2.5} />
                      </Link>
                    </div>
                  </div>
                  <div className="w-full shrink-0 rounded-2xl border-2 border-border bg-surface p-5 shadow-[4px_4px_0px_0px_var(--border)] xl:w-64">
                    <p className="text-[10px] font-black uppercase tracking-widest text-muted">Progress Kelas</p>
                    <p className="mt-1 text-4xl font-black text-ink">{formatPercent(summary.learning.overall_progress_percent)}</p>
                    <div className="mt-4 h-3 overflow-hidden rounded-full bg-border/20">
                      <div
                        className="h-full rounded-full bg-primary"
                        style={{ width: `${Math.min(Math.max(summary.learning.overall_progress_percent ?? 0, 0), 100)}%` }}
                      />
                    </div>
                    <p className="mt-3 text-xs font-bold text-muted">
                      {formatCount(summary.learning.completed_lessons)} dari {formatCount(summary.learning.total_lessons)} materi selesai.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="flex h-full flex-col">
              <CardHeader className="pb-4">
                <h2 className="text-xl font-black text-ink">Ringkasan</h2>
              </CardHeader>
              <CardContent className="flex flex-col gap-3 pb-6">
                <div className="flex flex-1 items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-4">
                  <span className="text-sm font-bold text-muted">Kelas Aktif</span>
                  <span className="text-right font-black text-ink">{summary.class?.name ?? "Belum ada"}</span>
                </div>
                <div className="flex flex-1 items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-4">
                  <span className="text-sm font-bold text-muted">Progress Modul</span>
                  <span className="text-right font-black text-ink">
                    {formatCount(summary.learning.completed_modules)} / {formatCount(summary.learning.published_modules)}
                  </span>
                </div>
                <div className="flex flex-1 items-center justify-between rounded-xl border-2 border-border bg-surface-muted p-4">
                  <span className="text-sm font-bold text-muted">Kuis & Tugas</span>
                  <span className="text-right font-black text-ink">{formatCount(summary.quizzes.available)} Tersedia</span>
                </div>
              </CardContent>
            </Card>
          </section>

          <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
            {quickActions.map((action) => (
              <Link
                className="group flex flex-col rounded-2xl border-2 border-border bg-surface p-5 transition hover:-translate-y-1 hover:shadow-emi"
                href={action.href}
                key={action.href}
              >
                <div className="mb-4 inline-flex size-12 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink transition-colors group-hover:bg-primary group-hover:text-primary-foreground">
                  <action.icon className="size-6" strokeWidth={2.5} />
                </div>
                <h3 className="text-lg font-black text-ink">{action.title}</h3>
                <p className="mt-1 text-sm font-semibold leading-relaxed text-muted">{action.description}</p>
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
