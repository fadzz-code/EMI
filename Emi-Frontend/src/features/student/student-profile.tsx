"use client";

import { type FormEvent, useState } from "react";
import { GraduationCap, School } from "lucide-react";
import { useMutation, useQueryClient } from "@tanstack/react-query";

import { Button, Card, CardContent, CardHeader, EmptyState, Input, MutationAlert, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { authService } from "@/features/auth/auth-service";
import { DeleteAccountForm } from "@/features/auth/delete-account-form";
import { ProfileAvatarUpload } from "@/features/auth/profile-avatar-upload";
import { ProfilePasswordForm } from "@/features/auth/profile-password-form";
import { getFirstApiError } from "@/lib/api-client";
import { roleLabels } from "@/lib/roles";

import { formatOptional } from "./student-utils";

const PROFILE_QUERY_KEY = ["student", "profile"];

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
  const { token, user } = useAuth();
  const queryClient = useQueryClient();
  const [success, setSuccess] = useState(false);
  const schoolName = user?.active_school?.name;
  const className = user?.active_class?.name;

  const updateMutation = useMutation({
    mutationFn: (payload: { full_name: string; phone?: string | null }) => authService.updateProfile(token ?? "", payload),
    onSuccess: async () => {
      setSuccess(true);
      await queryClient.invalidateQueries({ queryKey: PROFILE_QUERY_KEY });
    },
  });

  function submitProfile(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSuccess(false);
    const data = new FormData(event.currentTarget);
    updateMutation.mutate({
      full_name: String(data.get("full_name") ?? "").trim(),
      phone: String(data.get("phone") ?? "").trim() || null,
    });
  }

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

      <div className="grid gap-6 xl:grid-cols-2">
        <Card>
          <CardHeader>
            <h2 className="text-xl font-black text-ink">Foto Profil</h2>
          </CardHeader>
          <CardContent>
            <ProfileAvatarUpload avatarUrl={user?.avatar?.url} fullName={user?.full_name} invalidateKey={PROFILE_QUERY_KEY} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <h2 className="text-xl font-black text-ink">Ubah Profil</h2>
          </CardHeader>
          <CardContent>
            <form className="grid gap-4" key={user?.id} onSubmit={submitProfile}>
              {success ? <MutationAlert eventKey={updateMutation.submittedAt} tone="success">Profil berhasil diperbarui.</MutationAlert> : null}
              {updateMutation.error ? <MutationAlert eventKey={updateMutation.submittedAt} tone="error">{getFirstApiError(updateMutation.error)}</MutationAlert> : null}
              <label className="grid gap-2 text-sm font-black text-ink">
                Nama lengkap
                <Input defaultValue={user?.full_name} name="full_name" required />
              </label>
              <label className="grid gap-2 text-sm font-black text-ink">
                Nomor telepon
                <Input defaultValue={user?.phone ?? ""} name="phone" placeholder="Belum diisi" />
              </label>
              <Button disabled={updateMutation.isPending} type="submit">
                {updateMutation.isPending ? "Menyimpan..." : "Simpan Profil"}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 xl:grid-cols-2">
        <Card>
          <CardHeader>
            <h2 className="text-xl font-black text-ink">Ubah Password</h2>
          </CardHeader>
          <CardContent>
            <ProfilePasswordForm />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <h2 className="text-xl font-black text-ink">Hapus Akun</h2>
          </CardHeader>
          <CardContent>
            <DeleteAccountForm />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
