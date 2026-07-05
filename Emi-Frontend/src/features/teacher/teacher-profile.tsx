"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Button, Card, CardContent, CardHeader, ErrorState, Input, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import { formatOptional, statusLabel } from "./teacher-utils";

export function TeacherProfile() {
  const { refreshUser, token, user } = useAuth();
  const queryClient = useQueryClient();
  const [success, setSuccess] = useState(false);

  const profileQuery = useQuery({
    queryKey: ["teacher", "profile"],
    queryFn: () => teacherService.profile(token ?? ""),
    enabled: Boolean(token),
  });
  const updateMutation = useMutation({
    mutationFn: (payload: { full_name: string; phone?: string | null }) => teacherService.updateProfile(token ?? "", payload),
    onSuccess: async () => {
      setSuccess(true);
      await queryClient.invalidateQueries({ queryKey: ["teacher", "profile"] });
      await refreshUser();
    },
  });

  const profile = profileQuery.data;

  return (
    <div className="grid gap-6">
      <PageHeader badge="Guru" description="Perbarui identitas guru yang tampil di kelas dan laporan." title="Profil Guru" />

      {profileQuery.isLoading ? <LoadingState title="Memuat profil" /> : null}
      {profileQuery.isError ? <ErrorState description={getFirstApiError(profileQuery.error)} onRetry={() => void profileQuery.refetch()} title="Gagal memuat profil" /> : null}

      {profile ? (
        <div className="grid gap-6 xl:grid-cols-[0.8fr_1.2fr]">
          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Identitas</h2></CardHeader>
            <CardContent>
              <dl className="grid gap-3 text-sm">
                <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Nama</dt><dd className="mt-1 font-bold text-ink">{profile.full_name}</dd></div>
                <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Email</dt><dd className="mt-1 font-bold text-ink">{profile.email}</dd></div>
                <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Role</dt><dd className="mt-1 font-bold text-ink">{formatOptional(profile.role)}</dd></div>
                <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Status</dt><dd className="mt-1 font-bold text-ink">{statusLabel(profile.status)}</dd></div>
                <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Telepon</dt><dd className="mt-1 font-bold text-ink">{formatOptional(profile.phone)}</dd></div>
                <div className="rounded-xl bg-slate-50 p-3"><dt className="font-black uppercase text-slate-500">Avatar</dt><dd className="mt-1 font-bold text-ink">{profile.avatar?.url ? "Tersedia" : "Belum tersedia"}</dd></div>
              </dl>
            </CardContent>
          </Card>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Ubah Profil</h2></CardHeader>
            <CardContent>
              <form
                className="grid gap-4"
                key={`${profile.id}-${profile.updated_at ?? profile.full_name}`}
                onSubmit={(event) => {
                  event.preventDefault();
                  const formData = new FormData(event.currentTarget);
                  const fullName = String(formData.get("full_name") ?? "").trim();
                  const phone = String(formData.get("phone") ?? "").trim();
                  setSuccess(false);
                  updateMutation.mutate({ full_name: fullName, phone: phone || null });
                }}
              >
                {success ? <Alert tone="success">Profil berhasil diperbarui.</Alert> : null}
                {updateMutation.error ? <Alert tone="error">{getFirstApiError(updateMutation.error)}</Alert> : null}
                <label className="grid gap-2 text-sm font-black text-ink">
                  Nama lengkap
                  <Input defaultValue={profile.full_name} name="full_name" required />
                </label>
                <label className="grid gap-2 text-sm font-black text-ink">
                  Nomor telepon
                  <Input defaultValue={profile.phone ?? ""} name="phone" />
                </label>
                <Button disabled={updateMutation.isPending} type="submit">
                  {updateMutation.isPending ? "Menyimpan..." : "Simpan Profil"}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      ) : !profileQuery.isLoading && !profileQuery.isError ? (
        <Alert tone="info">Profil belum tersedia. User aktif: {user?.email ?? "tidak diketahui"}.</Alert>
      ) : null}
    </div>
  );
}
