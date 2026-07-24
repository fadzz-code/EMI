"use client";

import { useState } from "react";
import Link from "next/link";
import { useForm } from "react-hook-form";

import { ApiError } from "@/lib/api-client";
import { forgotPasswordSchema, type ForgotPasswordFormValues } from "@/lib/validators";
import { Alert, Button, FormField, Input } from "@/components/ui";

import { authService } from "./auth-service";

export function ForgotPasswordForm() {
  const [formError, setFormError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const {
    formState: { errors, isSubmitting },
    handleSubmit,
    register,
    setError,
  } = useForm<ForgotPasswordFormValues>({
    defaultValues: {
      email: "",
    },
  });

  async function onSubmit(values: ForgotPasswordFormValues) {
    setFormError(null);
    setSuccessMessage(null);
    const parsed = forgotPasswordSchema.safeParse(values);

    if (!parsed.success) {
      parsed.error.issues.forEach((issue) => {
        const field = issue.path[0] as keyof ForgotPasswordFormValues;
        setError(field, { message: issue.message });
      });
      return;
    }

    try {
      const message = await authService.forgotPassword(parsed.data);
      setSuccessMessage(message);
    } catch (error) {
      setFormError(
        error instanceof ApiError
          ? error.message
          : "Permintaan gagal diproses. Coba lagi beberapa saat.",
      );
    }
  }

  return (
    <section className="flex flex-col justify-center bg-white px-6 py-10 sm:px-10 lg:px-12">
      <div className="mx-auto grid w-full max-w-sm gap-8">
        <div className="grid gap-4">
          <div className="flex items-center gap-3">
            <div className="grid size-12 place-items-center rounded-[8px] border-4 border-ink bg-[#ffdf9b] text-lg font-black text-[#9b4500] shadow-[4px_4px_0_var(--color-ink)]">
              EMI
            </div>
            <p className="text-xl font-black text-ink">EMI</p>
          </div>
          <div>
            <h1 className="text-3xl font-black tracking-tight text-ink">Lupa Kata Sandi</h1>
            <p className="mt-2 text-sm font-bold text-slate-500">
              Masukkan email akun Anda. Untuk guru dan siswa, permintaan akan diteruskan ke wali kelas atau admin
              untuk disetujui. Untuk admin, silakan hubungi admin lain untuk mereset password Anda.
            </p>
          </div>
        </div>

        <form className="grid gap-5" onSubmit={handleSubmit(onSubmit)}>
          {formError ? (
            <Alert className="border-4 font-bold shadow-[3px_3px_0_var(--color-ink)]" tone="error">
              {formError}
            </Alert>
          ) : null}
          {successMessage ? (
            <Alert className="border-4 font-bold shadow-[3px_3px_0_var(--color-ink)]" tone="success">
              {successMessage}
            </Alert>
          ) : null}
          <FormField error={errors.email?.message} label="Email">
            <Input
              autoComplete="email"
              autoFocus
              className="min-h-12 rounded-[8px] border-4 border-ink bg-[#fcf9f8] text-base focus:ring-[#ffd167]"
              placeholder="Masukkan email"
              type="email"
              {...register("email")}
            />
          </FormField>

          <Button
            className="min-h-12 rounded-[8px] border-4 border-ink bg-[#ff8c42] text-lg font-black text-[#6a2d00] shadow-[4px_4px_0_var(--color-ink)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[#ffa45f] hover:shadow-[2px_2px_0_var(--color-ink)] focus:ring-4 focus:ring-[#ffd167] active:translate-x-[4px] active:translate-y-[4px] active:shadow-none"
            disabled={isSubmitting}
            type="submit"
          >
            {isSubmitting ? "Mengirim..." : "Kirim Permintaan Reset"}
          </Button>
        </form>

        <div className="h-1 rounded-full bg-slate-200" />

        <p className="text-center text-sm font-bold text-slate-600">
          Sudah ingat kata sandi?{" "}
          <Link className="font-black text-[#ff8c42] hover:text-[#e07530] hover:underline" href="/login">
            Kembali ke halaman masuk
          </Link>
        </p>
      </div>
    </section>
  );
}
