"use client";

import { type FormEvent, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Button,
  ErrorState,
  FormField,
  Input,
  LoadingState,
  Textarea,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { settingsService } from "./settings-service";
import { SettingsSectionCard } from "./settings-section-card";
import { roleLabel } from "./settings-utils";

type ProfileForm = {
  full_name: string;
  phone: string;
};

const disabledFieldClass = "bg-slate-100 text-slate-500";

function getInitials(name?: string) {
  return (
    name
      ?.split(" ")
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase())
      .join("") || "AD"
  );
}

function DisabledInput({ value = "Belum tersedia" }: { value?: string }) {
  return <Input className={disabledFieldClass} disabled value={value} />;
}

function DisabledTextarea({ value = "Belum tersedia" }: { value?: string }) {
  return <Textarea className={disabledFieldClass} disabled value={value} />;
}

function SettingsToggle({
  label,
  checked = false,
  helper,
}: {
  label: string;
  checked?: boolean;
  helper?: string;
}) {
  return (
    <div className="flex items-start justify-between gap-4 rounded-lg border-2 border-ink bg-white p-4">
      <div>
        <p className="text-sm font-black text-ink">{label}</p>
        {helper ? <p className="mt-1 text-xs leading-5 text-slate-600">{helper}</p> : null}
      </div>
      <label className="relative inline-flex cursor-not-allowed items-center">
        <input checked={checked} className="peer sr-only" disabled readOnly type="checkbox" />
        <span className="h-7 w-12 rounded-full border-2 border-ink bg-slate-200 transition peer-checked:bg-blue-500" />
        <span className="absolute left-1 h-5 w-5 rounded-full border-2 border-ink bg-white transition peer-checked:translate-x-5" />
      </label>
    </div>
  );
}

function PanelNote({ children }: { children: React.ReactNode }) {
  return (
    <p className="rounded-lg border-2 border-dashed border-ink bg-slate-50 px-4 py-3 text-xs font-semibold leading-5 text-slate-600">
      {children}
    </p>
  );
}

export function SettingsPage() {
  const { token, refreshUser } = useAuth();
  const queryClient = useQueryClient();
  const formRef = useRef<HTMLFormElement>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [profileNameError, setProfileNameError] = useState<string | null>(null);

  const userQuery = useQuery({
    queryKey: ["admin", "settings", "profile"],
    queryFn: () => settingsService.currentUser(token ?? ""),
    enabled: Boolean(token),
  });

  const updateProfileMutation = useMutation({
    mutationFn: (payload: ProfileForm) =>
      settingsService.updateProfile(token ?? "", {
        full_name: payload.full_name.trim(),
        phone: payload.phone.trim() || null,
      }),
    onSuccess: async (user) => {
      setSuccessMessage(`Pengaturan profil ${user.full_name} berhasil disimpan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "settings", "profile"] });
      await refreshUser();
    },
  });

  const user = userQuery.data;

  function submitSettings(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSuccessMessage(null);
    setProfileNameError(null);
    updateProfileMutation.reset();

    const data = new FormData(event.currentTarget);
    const payload = {
      full_name: String(data.get("full_name") ?? "").trim(),
      phone: String(data.get("phone") ?? "").trim(),
    };

    if (!payload.full_name) {
      setProfileNameError("Nama lengkap wajib diisi.");
      return;
    }

    updateProfileMutation.mutate(payload);
  }

  function cancelChanges() {
    formRef.current?.reset();
    setSuccessMessage(null);
    setProfileNameError(null);
    updateProfileMutation.reset();
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <Badge tone="yellow">ADMIN-19</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Pengaturan Sistem</h1>
          <p className="mt-2 text-sm leading-6 text-slate-600">
            Atur preferensi dasar sistem EMI.
          </p>
        </div>
        <Badge tone="neutral">Functional-first</Badge>
      </header>

      <Alert tone="info">
        Pengaturan sistem penuh belum tersedia. Field konfigurasi ditampilkan read-only,
        sementara data profil admin tetap bisa disimpan.
      </Alert>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {updateProfileMutation.error ? (
        <Alert tone="error">{getFirstApiError(updateProfileMutation.error)}</Alert>
      ) : null}

      {userQuery.isLoading ? <LoadingState title="Memuat pengaturan sistem" /> : null}
      {userQuery.isError ? (
        <ErrorState
          description={getFirstApiError(userQuery.error)}
          onRetry={() => void userQuery.refetch()}
          title="Gagal memuat pengaturan"
        />
      ) : null}

      {!userQuery.isLoading && !userQuery.isError ? (
        <form
          className="grid gap-6"
          key={`${user?.id ?? "settings"}-${user?.full_name ?? ""}-${user?.phone ?? ""}`}
          onSubmit={submitSettings}
          ref={formRef}
        >
          <SettingsSectionCard
            badge="Read-only"
            description="Konfigurasi aplikasi belum bisa disimpan dari layar ini."
            title="Pengaturan Aplikasi"
          >
            <div className="grid gap-4 md:grid-cols-2">
              <FormField label="Nama Aplikasi">
                <DisabledInput />
              </FormField>
              <FormField label="Subtitle / Slogan">
                <DisabledInput />
              </FormField>
              <FormField label="Tahun Ajaran Aktif">
                <DisabledInput />
              </FormField>
              <FormField label="Zona Waktu">
                <DisabledInput />
              </FormField>
            </div>
          </SettingsSectionCard>

          <SettingsSectionCard
            badge="Bisa disimpan"
            description="Nama dan telepon admin dapat diperbarui. Email kantor tetap read-only."
            title="Profil Admin"
          >
            {user ? (
              <div className="grid gap-5 lg:grid-cols-[260px_1fr]">
                <div className="rounded-lg border-2 border-ink bg-yellow-100 p-5">
                  <div className="flex h-20 w-20 items-center justify-center rounded-full border-2 border-ink bg-white text-2xl font-black text-ink shadow-brutal">
                    {getInitials(user.full_name)}
                  </div>
                  <h2 className="mt-4 text-lg font-black text-ink">{user.full_name}</h2>
                  <p className="mt-1 text-sm font-semibold text-slate-600">{user.email}</p>
                  <Badge className="mt-4" tone="blue">
                    {roleLabel(user.role)}
                  </Badge>
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                  <FormField error={profileNameError ?? undefined} label="Nama Lengkap">
                    <Input defaultValue={user.full_name} name="full_name" required />
                  </FormField>
                  <FormField label="Email Kantor">
                    <Input className={disabledFieldClass} disabled value={user.email} />
                  </FormField>
                  <FormField label="Telepon Admin">
                    <Input
                      defaultValue={user.phone ?? ""}
                      name="phone"
                      placeholder="Belum diisi"
                    />
                  </FormField>
                  <FormField label="Status Akun">
                    <Input className={disabledFieldClass} disabled value={user.status} />
                  </FormField>
                </div>
              </div>
            ) : (
              <PanelNote>Profil admin belum tersedia.</PanelNote>
            )}
          </SettingsSectionCard>

          <SettingsSectionCard
            badge="Belum tersedia"
            description="Banner login belum bisa diunggah atau disimpan dari layar ini."
            title="Pengaturan Banner Login"
          >
            <div className="grid gap-5 lg:grid-cols-[320px_1fr]">
              <div className="rounded-lg border-2 border-ink bg-blue-50 p-5">
                <p className="text-xs font-black uppercase text-slate-500">Preview banner</p>
                <div className="mt-3 rounded-lg border-2 border-dashed border-ink bg-white p-6">
                  <p className="text-lg font-black text-ink">Belum tersedia</p>
                  <p className="mt-2 text-sm leading-6 text-slate-600">
                    Preview akan aktif setelah konfigurasi banner login tersedia.
                  </p>
                </div>
                <Button className="mt-4 w-full" disabled variant="ghost">
                  Upload Banner Baru
                </Button>
              </div>

              <div className="grid gap-4">
                <FormField label="Judul Banner">
                  <DisabledInput />
                </FormField>
                <FormField label="Sub-teks Banner">
                  <DisabledTextarea />
                </FormField>
                <SettingsToggle
                  helper="Toggle belum aktif karena konfigurasi banner belum tersedia."
                  label="Aktifkan Banner"
                />
                <PanelNote>
                  Riwayat banner belum tersedia. Versi banner dan audit perubahannya belum dapat ditampilkan.
                </PanelNote>
              </div>
            </div>
          </SettingsSectionCard>

          <SettingsSectionCard
            badge="Terbatas"
            description="Aksi keamanan sistem belum tersedia sebagai pengaturan tersimpan."
            title="Keamanan"
          >
            <div className="grid gap-4 lg:grid-cols-[280px_1fr]">
              <div className="grid gap-3">
                <Button disabled variant="ghost">
                  Ubah Password Sistem / Admin
                </Button>
                <Button disabled variant="ghost">
                  Log Aktivitas Admin
                </Button>
              </div>
              <div className="grid gap-3">
                <SettingsToggle
                  helper="Preferensi notifikasi login belum tersedia."
                  label="Peringatan Login Baru"
                />
                <SettingsToggle
                  helper="Preferensi email laporan belum tersedia."
                  label="Email Laporan Mingguan"
                />
              </div>
            </div>
          </SettingsSectionCard>

          <div className="flex flex-col-reverse gap-3 rounded-lg border-2 border-ink bg-white p-4 shadow-brutal sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs font-semibold leading-5 text-slate-600">
              Tombol simpan hanya mengirim field profil admin yang sudah didukung.
            </p>
            <div className="flex gap-3">
              <Button onClick={cancelChanges} type="button" variant="ghost">
                Batalkan
              </Button>
              <Button disabled={updateProfileMutation.isPending || !user} type="submit">
                {updateProfileMutation.isPending ? "Menyimpan..." : "Simpan Pengaturan"}
              </Button>
            </div>
          </div>
        </form>
      ) : null}
    </div>
  );
}
