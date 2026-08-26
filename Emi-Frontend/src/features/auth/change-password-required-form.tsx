"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

import { ApiError, apiClient, getFirstApiError } from "@/lib/api-client";
import { getDashboardPath } from "@/lib/roles";
import { Button, FormField, Input, MutationAlert } from "@/components/ui";

import { useAuth } from "./auth-provider";

export function ChangePasswordRequiredForm() {
  const router = useRouter();
  const { token, user, isBootstrapping, refreshUser, logout } = useAuth();
  const [currentPassword, setCurrentPassword] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");
  const [formError, setFormError] = useState<string | null>(null);
  const [submitCount, setSubmitCount] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (isBootstrapping) {
      return;
    }

    if (!user) {
      router.replace("/login");
      return;
    }

    if (!user.password_must_change) {
      router.replace(getDashboardPath(user.role));
    }
  }, [isBootstrapping, router, user]);

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitCount((count) => count + 1);
    setFormError(null);

    if (password !== passwordConfirmation) {
      setFormError("Konfirmasi kata sandi tidak sama.");
      return;
    }

    setIsSubmitting(true);

    try {
      await apiClient.put(
        "/auth/password",
        {
          current_password: currentPassword,
          password,
          password_confirmation: passwordConfirmation,
        },
        { token },
      );

      const refreshed = await refreshUser();
      router.replace(refreshed ? getDashboardPath(refreshed.role) : "/login");
    } catch (error) {
      setFormError(error instanceof ApiError ? getFirstApiError(error) : "Gagal mengganti kata sandi.");
    } finally {
      setIsSubmitting(false);
    }
  }

  if (isBootstrapping || !user) {
    return null;
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-100 p-4">
      <div className="w-full max-w-md rounded-[24px] border-4 border-ink bg-white p-8 shadow-[12px_12px_0_var(--color-ink)]">
        <h1 className="text-2xl font-black text-ink">Wajib Ganti Kata Sandi</h1>
        <p className="mt-2 text-sm font-bold text-slate-500">
          Kata sandi Anda baru saja direset oleh {user.role === "student" ? "guru atau admin" : "admin"}. Untuk
          keamanan akun, silakan buat kata sandi baru yang hanya Anda ketahui sebelum melanjutkan.
        </p>

        <form className="mt-6 grid gap-4" onSubmit={onSubmit}>
          {formError ? <MutationAlert eventKey={submitCount} tone="error">{formError}</MutationAlert> : null}
          <FormField label="Kata sandi sementara (dari guru/admin)">
            <Input
              autoComplete="current-password"
              autoFocus
              onChange={(event) => setCurrentPassword(event.target.value)}
              required
              type="password"
              value={currentPassword}
            />
          </FormField>
          <FormField label="Kata sandi baru">
            <Input
              autoComplete="new-password"
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Minimal 8 karakter, ada huruf dan angka"
              required
              type="password"
              value={password}
            />
          </FormField>
          <FormField label="Konfirmasi kata sandi baru">
            <Input
              autoComplete="new-password"
              onChange={(event) => setPasswordConfirmation(event.target.value)}
              required
              type="password"
              value={passwordConfirmation}
            />
          </FormField>

          <Button disabled={isSubmitting} type="submit">
            {isSubmitting ? "Menyimpan..." : "Simpan Kata Sandi Baru"}
          </Button>
        </form>

        <button
          className="mt-4 w-full text-center text-sm font-bold text-slate-500 hover:text-ink hover:underline"
          onClick={() => void logout()}
          type="button"
        >
          Keluar
        </button>
      </div>
    </div>
  );
}
