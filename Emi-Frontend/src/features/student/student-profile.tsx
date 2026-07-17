"use client";

import { GraduationCap, School } from "lucide-react";

import { Card, CardContent, CardHeader, EmptyState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { roleLabels } from "@/lib/roles";

import { formatOptional } from "./student-utils";

function statusLabel(status: string | null | undefined) {
  if (status === "approved") {
    return "Disetujui";
  }

  if (status === "pending") {
    return "Menunggu Persetujuan";
  }

  if (status === "rejected") {
    return "Ditolak";
  }

  if (status === "inactive") {
    return "Nonaktif";
  }

  return formatOptional(status);
}

export function StudentProfile() {
  const { user } = useAuth();
  const schoolName = user?.active_school?.name;
  const className = user?.active_class?.name;

  return (
    <div className="grid gap-8">
      <PageHeader badge="Siswa" description="Kelola dan lihat informasi akun belajar Anda." title="Profil Saya" />

      <section className="grid auto-rows-fr gap-4 md:grid-cols-2 xl:grid-cols-3">
        <Card className="min-w-0">
          <CardContent className="min-w-0">
            <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Nama</p>
            <p className="mt-3 break-words text-xl font-black leading-7 text-ink sm:text-2xl">{formatOptional(user?.full_name)}</p>
            <p className="mt-2 text-sm text-muted">Nama akun belajar</p>
          </CardContent>
        </Card>
        <Card className="min-w-0 md:col-span-2 xl:col-span-1">
          <CardContent className="min-w-0">
            <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Email</p>
            <p className="mt-3 break-all text-base font-black leading-6 text-ink sm:text-lg">{formatOptional(user?.email)}</p>
            <p className="mt-2 text-sm text-muted">Email login</p>
          </CardContent>
        </Card>
        <Card className="min-w-0">
          <CardContent>
            <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Akun</p>
            <div className="mt-3 grid grid-cols-2 gap-4">
              <div className="min-w-0">
                <p className="text-xs font-bold text-muted">Role</p>
                <p className="mt-1 break-words text-lg font-black text-ink">{user?.role ? roleLabels[user.role] : "Belum tersedia"}</p>
              </div>
              <div className="min-w-0">
                <p className="text-xs font-bold text-muted">Status</p>
                <p className="mt-1 break-words text-lg font-black text-ink">{statusLabel(user?.status)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </section>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Kelas & Sekolah</h2>
        </CardHeader>
        <CardContent>
          {schoolName || className ? (
            <div className="grid auto-rows-fr gap-4 sm:grid-cols-2">
              <div className="flex h-full items-center gap-4 rounded-2xl border-2 border-border bg-surface-muted p-5">
                <div className="inline-flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface text-ink">
                  <School className="size-6" strokeWidth={2.5} />
                </div>
                <div className="min-w-0">
                  <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Sekolah</p>
                  <p className="mt-1 break-words text-xl font-black leading-7 text-ink sm:text-2xl">{formatOptional(schoolName)}</p>
                </div>
              </div>
              <div className="flex h-full items-center gap-4 rounded-2xl border-2 border-border bg-surface-muted p-5">
                <div className="inline-flex size-12 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface text-ink">
                  <GraduationCap className="size-6" strokeWidth={2.5} />
                </div>
                <div className="min-w-0">
                  <p className="text-xs font-black uppercase tracking-[0.08em] text-muted">Kelas</p>
                  <p className="mt-1 break-words text-xl font-black leading-7 text-ink sm:text-2xl">{formatOptional(className)}</p>
                </div>
              </div>
            </div>
          ) : (
            <EmptyState description="Data kelas atau sekolah belum tersedia." title="Kelas atau sekolah belum tersedia" />
          )}
        </CardContent>
      </Card>
    </div>
  );
}
