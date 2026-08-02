"use client";

import { type FormEvent, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, ErrorState, FormField, Input, LoadingState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { ProfileAvatarUpload } from "@/features/auth/profile-avatar-upload";
import { getFirstApiError } from "@/lib/api-client";

import { settingsService } from "./settings-service";
import { SettingsSectionCard } from "./settings-section-card";
import { roleLabel } from "./settings-utils";

const disabledFieldClass = "bg-surface-muted text-muted";

export function SettingsPage() {
  const { token, refreshUser } = useAuth();
  const queryClient = useQueryClient();
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [bannerPreview, setBannerPreview] = useState<string | null>(null);

  const userQuery = useQuery({ queryKey: ["admin", "settings", "profile"], queryFn: () => settingsService.currentUser(token ?? ""), enabled: Boolean(token) });
  const settingsQuery = useQuery({ queryKey: ["admin", "settings"], queryFn: () => settingsService.settings(token ?? ""), enabled: Boolean(token) });

  const invalidate = async (message: string) => {
    setSuccessMessage(message);
    await queryClient.invalidateQueries({ queryKey: ["admin", "settings"] });
  };

  const profileMutation = useMutation({
    mutationFn: (payload: { full_name: string; phone: string | null }) => settingsService.updateProfile(token ?? "", payload),
    onSuccess: async () => {
      setSuccessMessage("Profil admin berhasil disimpan.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "settings", "profile"] });
      await refreshUser();
    },
  });
  const appMutation = useMutation({ mutationFn: (payload: Parameters<typeof settingsService.updateApplication>[1]) => settingsService.updateApplication(token ?? "", payload), onSuccess: () => invalidate("Pengaturan aplikasi berhasil disimpan.") });
  const bannerMutation = useMutation({ mutationFn: (payload: FormData) => settingsService.updateBanner(token ?? "", payload), onSuccess: () => invalidate("Banner login berhasil disimpan.") });
  const securityMutation = useMutation({ mutationFn: (payload: Parameters<typeof settingsService.updateSecurity>[1]) => settingsService.updateSecurity(token ?? "", payload), onSuccess: () => invalidate("Preferensi keamanan berhasil disimpan.") });
  const passwordMutation = useMutation({ mutationFn: (payload: Parameters<typeof settingsService.updatePassword>[1]) => settingsService.updatePassword(token ?? "", payload), onSuccess: () => setSuccessMessage("Password berhasil diperbarui.") });

  const user = userQuery.data;
  const settings = settingsQuery.data;
  const error = userQuery.error || settingsQuery.error || profileMutation.error || appMutation.error || bannerMutation.error || securityMutation.error || passwordMutation.error;
  const loading = userQuery.isLoading || settingsQuery.isLoading;

  function formData(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSuccessMessage(null);
    return new FormData(event.currentTarget);
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <Badge tone="blue">ADMIN-19</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Pengaturan Sistem</h1>
          <p className="mt-2 text-sm leading-6 text-muted">Atur preferensi dasar sistem EMI.</p>
        </div>
        <Badge tone="neutral">Functional-first</Badge>
      </header>
      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {error ? <Alert tone="error">{getFirstApiError(error)}</Alert> : null}
      {loading ? <LoadingState title="Memuat pengaturan sistem" /> : null}
      {userQuery.isError || settingsQuery.isError ? <ErrorState description={getFirstApiError(error)} onRetry={() => { void userQuery.refetch(); void settingsQuery.refetch(); }} title="Gagal memuat pengaturan" /> : null}

      {!loading && user && settings ? (
        <div className="grid gap-6">
          <SettingsSectionCard badge="Bisa disimpan" description="Konfigurasi aplikasi tersimpan di database." title="Pengaturan Aplikasi">
            <form className="grid gap-4 md:grid-cols-2" onSubmit={(event) => {
              const data = formData(event);
              appMutation.mutate({ name: String(data.get("name") ?? ""), subtitle: String(data.get("subtitle") ?? ""), active_academic_year: String(data.get("active_academic_year") ?? ""), timezone: String(data.get("timezone") ?? "") });
            }}>
              <FormField label="Nama Aplikasi"><Input defaultValue={settings.application.name} name="name" required /></FormField>
              <FormField label="Subtitle / Slogan"><Input defaultValue={settings.application.subtitle} name="subtitle" /></FormField>
              <FormField label="Tahun Ajaran Aktif"><Input defaultValue={settings.application.active_academic_year} name="active_academic_year" required /></FormField>
              <FormField label="Zona Waktu"><Input defaultValue={settings.application.timezone} name="timezone" required /></FormField>
              <Button className="md:col-span-2" disabled={appMutation.isPending} type="submit">{appMutation.isPending ? "Menyimpan..." : "Simpan Pengaturan Aplikasi"}</Button>
            </form>
          </SettingsSectionCard>

          <SettingsSectionCard badge="Bisa disimpan" description="Nama dan telepon admin dapat diperbarui. Email tetap read-only." title="Profil Admin">
            <form className="grid gap-5 lg:grid-cols-[260px_1fr]" onSubmit={(event) => {
              const data = formData(event);
              profileMutation.mutate({ full_name: String(data.get("full_name") ?? "").trim(), phone: String(data.get("phone") ?? "").trim() || null });
            }}>
              <div className="rounded-2xl border-2 border-border bg-[var(--color-primary-muted)] p-5">
                <ProfileAvatarUpload avatarUrl={user.avatar?.url} fullName={user.full_name} invalidateKey={["admin", "settings", "profile"]} />
                <h2 className="mt-4 text-lg font-black text-ink">{user.full_name}</h2>
                <p className="mt-1 text-sm font-semibold text-muted">{user.email}</p>
                <Badge className="mt-4" tone="blue">{roleLabel(user.role)}</Badge>
              </div>
              <div className="grid gap-4 md:grid-cols-2">
                <FormField label="Nama Lengkap"><Input defaultValue={user.full_name} name="full_name" required /></FormField>
                <FormField label="Email Kantor"><Input className={disabledFieldClass} disabled value={user.email} /></FormField>
                <FormField label="Telepon Admin"><Input defaultValue={user.phone ?? ""} name="phone" placeholder="Belum diisi" /></FormField>
                <FormField label="Status Akun"><Input className={disabledFieldClass} disabled value={user.status} /></FormField>
                <Button className="md:col-span-2" disabled={profileMutation.isPending} type="submit">{profileMutation.isPending ? "Menyimpan..." : "Simpan Profil"}</Button>
              </div>
            </form>
          </SettingsSectionCard>

          <SettingsSectionCard badge="Bisa disimpan" description="Banner login dapat diunggah dan diaktifkan." title="Pengaturan Banner Login">
            <form className="grid gap-5 lg:grid-cols-[320px_1fr]" onSubmit={(event) => {
              const data = formData(event);
              data.set("enabled", data.get("enabled") ? "1" : "0");
              bannerMutation.mutate(data);
            }}>
              <div className="rounded-2xl border-2 border-border bg-surface-muted p-5">
                <p className="text-xs font-black uppercase text-muted">Preview banner</p>
                <div className="mt-3 overflow-hidden rounded-xl border-2 border-dashed border-border bg-surface p-4">
                  {bannerPreview || settings.banner.image_url ? <img alt="Preview banner login" className="max-h-40 w-full rounded object-cover" src={bannerPreview ?? settings.banner.image_url ?? ""} /> : <p className="text-sm font-bold text-muted">Banner belum diunggah.</p>}
                </div>
                <Input className="mt-4" name="file" onChange={(event) => setBannerPreview(event.target.files?.[0] ? URL.createObjectURL(event.target.files[0]) : null)} type="file" />
              </div>
              <div className="grid gap-4">
                <label className="flex items-center gap-3 text-sm font-black text-ink"><input defaultChecked={settings.banner.enabled} name="enabled" type="checkbox" /> Aktifkan Banner</label>
                <Button disabled={bannerMutation.isPending} type="submit">{bannerMutation.isPending ? "Menyimpan..." : "Simpan Banner"}</Button>
                <div className="grid gap-2 text-xs font-semibold text-muted">
                  {settings.activity_logs.map((log) => <p key={log.id}>{new Date(log.created_at).toLocaleString("id-ID")} · {log.admin} · {log.title} · {log.status ? "aktif" : "nonaktif"}</p>)}
                </div>
              </div>
            </form>
          </SettingsSectionCard>

          <SettingsSectionCard badge="Bisa disimpan" description="Password dan preferensi keamanan admin." title="Keamanan">
            <div className="grid gap-5 lg:grid-cols-2">
              <form className="grid gap-3" onSubmit={(event) => {
                const data = formData(event);
                passwordMutation.mutate({ current_password: String(data.get("current_password") ?? ""), password: String(data.get("password") ?? ""), password_confirmation: String(data.get("password_confirmation") ?? "") });
              }}>
                <Input name="current_password" placeholder="Password lama" type="password" required />
                <Input name="password" placeholder="Password baru" type="password" required />
                <Input name="password_confirmation" placeholder="Konfirmasi password baru" type="password" required />
                <Button disabled={passwordMutation.isPending} type="submit">Ubah Password</Button>
              </form>
              <form className="grid gap-3" onSubmit={(event) => {
                const data = formData(event);
                securityMutation.mutate({ new_login_alert: Boolean(data.get("new_login_alert")), weekly_report_email: Boolean(data.get("weekly_report_email")) });
              }}>
                <label className="flex items-center gap-3 text-sm font-black text-ink"><input defaultChecked={settings.security.new_login_alert} name="new_login_alert" type="checkbox" /> Peringatan Login Baru</label>
                <label className="flex items-center gap-3 text-sm font-black text-ink"><input defaultChecked={settings.security.weekly_report_email} name="weekly_report_email" type="checkbox" /> Email Laporan Mingguan</label>
                <Button disabled={securityMutation.isPending} type="submit">Simpan Keamanan</Button>
              </form>
            </div>
          </SettingsSectionCard>
        </div>
      ) : null}
    </div>
  );
}
