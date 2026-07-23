"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation } from "@tanstack/react-query";

import { Alert, Button, Card, CardContent, CardHeader, Input, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { authService } from "@/features/auth/auth-service";
import { getFirstApiError } from "@/lib/api-client";

export function StudentProfile() {
  const { token, user, refreshUser, logout } = useAuth();
  const router = useRouter();
  const [message, setMessage] = useState<string | null>(null);
  const profileMutation = useMutation({
    mutationFn: (payload: { full_name: string; phone: string | null }) => authService.updateProfile(token ?? "", payload),
    onSuccess: async () => { await refreshUser(); setMessage("Profil berhasil diperbarui."); },
  });
  const passwordMutation = useMutation({
    mutationFn: (payload: { current_password: string; password: string; password_confirmation: string }) => authService.updatePassword(token ?? "", payload),
    onSuccess: () => setMessage("Password berhasil diperbarui."),
  });
  const avatarMutation = useMutation({
    mutationFn: (file: File) => authService.uploadAvatar(token ?? "", file),
    onSuccess: async () => { await refreshUser(); setMessage("Avatar berhasil diperbarui."); },
  });
  const deleteAvatarMutation = useMutation({
    mutationFn: () => authService.deleteAvatar(token ?? ""),
    onSuccess: async () => { await refreshUser(); setMessage("Avatar berhasil dihapus."); },
  });
  const accountMutation = useMutation({
    mutationFn: (password: string) => authService.deleteAccount(token ?? "", password),
    onSuccess: async () => { await logout(); router.replace("/login"); },
  });
  const error = profileMutation.error || passwordMutation.error || avatarMutation.error || deleteAvatarMutation.error || accountMutation.error;

  return (
    <div className="grid gap-6">
      <PageHeader badge="Siswa" description="Kelola informasi dan keamanan akun belajar Anda." title="Profil Saya" />
      {message ? <Alert tone="success">{message}</Alert> : null}
      {error ? <Alert tone="error">{getFirstApiError(error)}</Alert> : null}

      <Card><CardHeader><h2 className="text-xl font-black text-ink">Profil dan Telepon</h2></CardHeader><CardContent>
        <form className="grid gap-4" onSubmit={(event) => { event.preventDefault(); setMessage(null); const data = new FormData(event.currentTarget); profileMutation.mutate({ full_name: String(data.get("full_name")), phone: String(data.get("phone")) || null }); }}>
          <Input defaultValue={user?.full_name} name="full_name" placeholder="Nama lengkap" required />
          <Input defaultValue={user?.phone ?? ""} name="phone" placeholder="Nomor telepon" type="tel" />
          <Button disabled={profileMutation.isPending} type="submit">Simpan Profil</Button>
        </form>
      </CardContent></Card>

      <Card><CardHeader><h2 className="text-xl font-black text-ink">Avatar</h2></CardHeader><CardContent>
        <div className="flex flex-wrap items-center gap-4">
          {user?.avatar?.url ? <img alt={`Avatar ${user.full_name}`} className="size-24 rounded-full border-2 border-ink object-cover" src={user.avatar.url} /> : <div className="flex size-24 items-center justify-center rounded-full border-2 border-ink bg-slate-100 font-black">Belum ada</div>}
          <Input accept="image/jpeg,image/png,image/webp" aria-label="Pilih avatar" onChange={(event) => { const file = event.target.files?.[0]; if (file) avatarMutation.mutate(file); }} type="file" />
          {user?.avatar ? <Button disabled={deleteAvatarMutation.isPending} onClick={() => { if (confirm("Hapus avatar saat ini?")) deleteAvatarMutation.mutate(); }} type="button" variant="secondary">Hapus Avatar</Button> : null}
        </div>
      </CardContent></Card>

      <Card><CardHeader><h2 className="text-xl font-black text-ink">Ganti Password</h2></CardHeader><CardContent>
        <form className="grid gap-4" onSubmit={(event) => { event.preventDefault(); setMessage(null); const form = event.currentTarget; const data = new FormData(form); const password = String(data.get("password")); const confirmation = String(data.get("password_confirmation")); if (password !== confirmation) return setMessage("Konfirmasi password tidak sama."); passwordMutation.mutate({ current_password: String(data.get("current_password")), password, password_confirmation: confirmation }, { onSuccess: () => form.reset() }); }}>
          <Input autoComplete="current-password" name="current_password" placeholder="Password lama" required type="password" />
          <Input autoComplete="new-password" minLength={8} name="password" placeholder="Password baru, minimal 8 karakter dengan huruf dan angka" required type="password" />
          <Input autoComplete="new-password" minLength={8} name="password_confirmation" placeholder="Konfirmasi password baru" required type="password" />
          <Button disabled={passwordMutation.isPending} type="submit">Ubah Password</Button>
        </form>
      </CardContent></Card>

      <Card className="border-red-700"><CardHeader><h2 className="text-xl font-black text-red-700">Hapus Akun</h2></CardHeader><CardContent>
        <p className="mb-4 text-sm font-bold text-slate-600">Akun akan dinonaktifkan dan semua sesi dicabut. Masukkan password lalu konfirmasi.</p>
        <form className="grid gap-4" onSubmit={(event) => { event.preventDefault(); const password = String(new FormData(event.currentTarget).get("current_password")); if (window.confirm("Hapus akun Anda? Tindakan ini akan menonaktifkan akun dan mengeluarkan Anda.")) accountMutation.mutate(password); }}>
          <Input autoComplete="current-password" name="current_password" placeholder="Password saat ini" required type="password" />
          <Button className="bg-red-700 hover:bg-red-800" disabled={accountMutation.isPending} type="submit">Hapus Akun</Button>
        </form>
      </CardContent></Card>
    </div>
  );
}
