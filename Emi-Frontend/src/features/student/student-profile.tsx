"use client";

import { Card, CardContent, CardHeader, EmptyState, PageHeader, StatsCard } from "@/components/ui";
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
    <div className="grid gap-6">
      <PageHeader badge="Siswa" description="Kelola dan lihat informasi akun belajar Anda." title="Profil Saya" />

      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatsCard helper="Nama akun belajar" label="Nama" value={formatOptional(user?.full_name)} />
        <StatsCard helper="Email login" label="Email" value={formatOptional(user?.email)} />
        <StatsCard helper="Role akun" label="Role" value={user?.role ? roleLabels[user.role] : "Belum tersedia"} />
        <StatsCard helper="Status akun" label="Status" value={statusLabel(user?.status)} />
      </section>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Kelas & Sekolah</h2>
        </CardHeader>
        <CardContent>
          {schoolName || className ? (
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="rounded-2xl border-2 border-ink bg-white p-4">
                <p className="text-xs font-black uppercase text-slate-500">Sekolah</p>
                <p className="mt-2 text-2xl font-black text-ink">{formatOptional(schoolName)}</p>
              </div>
              <div className="rounded-2xl border-2 border-ink bg-white p-4">
                <p className="text-xs font-black uppercase text-slate-500">Kelas</p>
                <p className="mt-2 text-2xl font-black text-ink">{formatOptional(className)}</p>
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
