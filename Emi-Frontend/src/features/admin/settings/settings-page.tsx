"use client";

import { type FormEvent, useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Badge, Button, ErrorState, FormField, Input, LoadingState, MutationAlert } from "@/components/ui";
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
  const [profileSuccess, setProfileSuccess] = useState<string | null>(null);
  const [bannerSuccess, setBannerSuccess] = useState<string | null>(null);
  const [passwordSuccess, setPasswordSuccess] = useState<string | null>(null);
  const [bannerPreview, setBannerPreview] = useState<string | null>(null);
  const [bannerFileError, setBannerFileError] = useState<string | null>(null);

  useEffect(() => () => {
    if (bannerPreview) URL.revokeObjectURL(bannerPreview);
  }, [bannerPreview]);

  const userQuery = useQuery({ queryKey: ["admin", "settings", "profile"], queryFn: () => settingsService.currentUser(token ?? ""), enabled: Boolean(token) });
  const settingsQuery = useQuery({ queryKey: ["admin", "settings"], queryFn: () => settingsService.settings(token ?? ""), enabled: Boolean(token) });

  const profileMutation = useMutation({
    mutationFn: (payload: { full_name: string; phone: string | null }) => settingsService.updateProfile(token ?? "", payload),
    onSuccess: async () => {
      setProfileSuccess("Profil admin berhasil disimpan.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "settings", "profile"] });
      await refreshUser();
    },
  });
  const bannerMutation = useMutation({
    mutationFn: (payload: FormData) => settingsService.updateBanner(token ?? "", payload),
    onSuccess: async () => {
      setBannerSuccess("Tampilan halaman masuk berhasil disimpan.");
      setBannerPreview(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "settings"] });
    },
  });
  const passwordMutation = useMutation({
    mutationFn: (payload: Parameters<typeof settingsService.updatePassword>[1]) => settingsService.updatePassword(token ?? "", payload),
    onSuccess: () => setPasswordSuccess("Password berhasil diperbarui."),
  });

  const user = userQuery.data;
  const settings = settingsQuery.data;
  const loading = userQuery.isLoading || settingsQuery.isLoading;
  const loadError = userQuery.error || settingsQuery.error;

  function formData(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    return new FormData(event.currentTarget);
  }

  return (
    <div className="grid gap-6">
      <header>
        <h1 className="text-3xl font-black text-ink">Pengaturan</h1>
        <p className="mt-2 text-sm leading-6 text-muted">Kelola profil, tampilan halaman masuk, dan keamanan akun.</p>
      </header>

      {loading ? <LoadingState title="Memuat pengaturan" /> : null}
      {loadError ? <ErrorState description={getFirstApiError(loadError)} onRetry={() => { void userQuery.refetch(); void settingsQuery.refetch(); }} title="Gagal memuat pengaturan" /> : null}

      {!loading && user && settings ? (
        <div className="grid gap-6">
          <SettingsSectionCard description="Perbarui informasi yang digunakan untuk akun admin." title="Profil admin">
            <form className="grid gap-5 lg:grid-cols-[240px_1fr]" onSubmit={(event) => {
              setProfileSuccess(null);
              profileMutation.reset();
              const data = formData(event);
              profileMutation.mutate({ full_name: String(data.get("full_name") ?? "").trim(), phone: String(data.get("phone") ?? "").trim() || null });
            }}>
              <div className="rounded-2xl border-2 border-border bg-[var(--color-primary-muted)] p-5">
                <ProfileAvatarUpload avatarUrl={user.avatar?.url} fullName={user.full_name} invalidateKey={["admin", "settings", "profile"]} />
                <h2 className="mt-4 text-lg font-black text-ink">{user.full_name}</h2>
                <p className="mt-1 break-all text-sm font-semibold text-muted">{user.email}</p>
              </div>
              <div className="grid gap-4 md:grid-cols-2">
                <FormField label="Nama lengkap"><Input defaultValue={user.full_name} name="full_name" required /></FormField>
                <FormField label="Nomor telepon"><Input defaultValue={user.phone ?? ""} name="phone" placeholder="Belum diisi" type="tel" /></FormField>
                <FormField label="Email"><Input className={disabledFieldClass} disabled value={user.email} /></FormField>
                <FormField label="Role dan status"><div className="flex min-h-11 items-center gap-2 rounded-xl border-2 border-border bg-surface-muted px-3"><Badge tone="blue">{roleLabel(user.role)}</Badge><Badge tone="neutral">{user.status}</Badge></div></FormField>
                <div className="grid gap-3 md:col-span-2">
                  <MutationAlert eventKey={profileMutation.submittedAt} tone="success" visible={Boolean(profileSuccess)}>{profileSuccess}</MutationAlert>
                  <MutationAlert eventKey={profileMutation.submittedAt} tone="error" visible={Boolean(profileMutation.error)}>{getFirstApiError(profileMutation.error)}</MutationAlert>
                  <Button disabled={profileMutation.isPending} type="submit">{profileMutation.isPending ? "Menyimpan..." : "Simpan profil"}</Button>
                </div>
              </div>
            </form>
          </SettingsSectionCard>

          <SettingsSectionCard description="Banner tampil di panel kanan halaman masuk pada layar desktop." title="Tampilan halaman masuk">
            <form className="grid gap-5 lg:grid-cols-[minmax(280px,420px)_1fr]" onSubmit={(event) => {
              setBannerSuccess(null);
              bannerMutation.reset();
              const data = formData(event);
              data.set("enabled", data.get("enabled") ? "1" : "0");
              bannerMutation.mutate(data);
            }}>
              <div>
                <div className="aspect-[4/3] overflow-hidden rounded-2xl border-2 border-dashed border-border bg-surface-muted">
                  {bannerPreview || settings.banner.image_url ? <img alt="Preview banner halaman masuk" className="h-full w-full object-cover" src={bannerPreview ?? settings.banner.image_url ?? ""} /> : <div className="grid h-full place-items-center p-6 text-center text-sm font-bold text-muted">Banner belum diunggah.</div>}
                </div>
                <p className="mt-2 text-xs font-semibold text-muted">Rasio rekomendasi 4:3. JPG, PNG, atau WebP, maksimal 5 MB.</p>
              </div>
              <div className="grid content-start gap-4">
                <label className="flex items-center justify-between gap-4 rounded-xl border-2 border-border p-4 text-sm font-black text-ink">
                  Aktifkan banner
                  <input defaultChecked={settings.banner.enabled} name="enabled" type="checkbox" />
                </label>
                <FormField error={bannerFileError ?? undefined} label={settings.banner.image_url ? "Ganti gambar" : "Upload gambar"}>
                  <Input accept="image/jpeg,image/png,image/webp" name="file" onChange={(event) => {
                    const file = event.target.files?.[0];
                    setBannerFileError(null);
                    if (file && file.size > 5 * 1024 * 1024) {
                      event.target.value = "";
                      setBannerFileError("Ukuran gambar maksimal 5 MB.");
                      setBannerPreview(null);
                      return;
                    }
                    setBannerPreview(file ? URL.createObjectURL(file) : null);
                  }} type="file" />
                </FormField>
                <MutationAlert eventKey={bannerMutation.submittedAt} tone="success" visible={Boolean(bannerSuccess)}>{bannerSuccess}</MutationAlert>
                <MutationAlert eventKey={bannerMutation.submittedAt} tone="error" visible={Boolean(bannerMutation.error)}>{getFirstApiError(bannerMutation.error)}</MutationAlert>
                <Button disabled={bannerMutation.isPending || Boolean(bannerFileError)} type="submit">{bannerMutation.isPending ? "Menyimpan..." : "Simpan tampilan"}</Button>
              </div>
            </form>
          </SettingsSectionCard>

          <SettingsSectionCard description="Gunakan minimal 8 karakter dan hindari password yang mudah ditebak." title="Keamanan akun">
            <form className="grid gap-4 md:grid-cols-3" onSubmit={(event) => {
              setPasswordSuccess(null);
              passwordMutation.reset();
              const data = formData(event);
              passwordMutation.mutate({ current_password: String(data.get("current_password") ?? ""), password: String(data.get("password") ?? ""), password_confirmation: String(data.get("password_confirmation") ?? "") });
            }}>
              <FormField label="Password saat ini"><Input autoComplete="current-password" name="current_password" required type="password" /></FormField>
              <FormField label="Password baru"><Input autoComplete="new-password" minLength={8} name="password" required type="password" /></FormField>
              <FormField label="Konfirmasi password baru"><Input autoComplete="new-password" minLength={8} name="password_confirmation" required type="password" /></FormField>
              <div className="grid gap-3 md:col-span-3">
                <MutationAlert eventKey={passwordMutation.submittedAt} tone="success" visible={Boolean(passwordSuccess)}>{passwordSuccess}</MutationAlert>
                <MutationAlert eventKey={passwordMutation.submittedAt} tone="error" visible={Boolean(passwordMutation.error)}>{getFirstApiError(passwordMutation.error)}</MutationAlert>
                <Button disabled={passwordMutation.isPending} type="submit">{passwordMutation.isPending ? "Memperbarui..." : "Ubah password"}</Button>
              </div>
            </form>
          </SettingsSectionCard>

          <SettingsSectionCard description="Lima perubahan banner terbaru oleh admin." title="Aktivitas terbaru">
            <div className="divide-y-2 divide-border">
              {settings.activity_logs.slice(0, 5).map((log) => (
                <div className="flex flex-col gap-1 py-3 first:pt-0 last:pb-0 sm:flex-row sm:items-center sm:justify-between" key={log.id}>
                  <div><p className="text-sm font-black text-ink">{log.title}</p><p className="text-xs font-semibold text-muted">{log.admin}</p></div>
                  <div className="flex items-center gap-2"><Badge tone={log.status ? "blue" : "neutral"}>{log.status ? "Aktif" : "Nonaktif"}</Badge><time className="text-xs font-semibold text-muted">{new Date(log.created_at).toLocaleString("id-ID")}</time></div>
                </div>
              ))}
              {settings.activity_logs.length === 0 ? <p className="text-sm font-semibold text-muted">Belum ada aktivitas.</p> : null}
            </div>
          </SettingsSectionCard>
        </div>
      ) : null}
    </div>
  );
}
