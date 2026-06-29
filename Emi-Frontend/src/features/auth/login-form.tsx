"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";

import { ApiError } from "@/lib/api-client";
import { getDashboardPath } from "@/lib/roles";
import { loginSchema, type LoginFormValues } from "@/lib/validators";
import { Alert, Button, FormField, Input } from "@/components/ui";

import { useAuth } from "./auth-provider";

export function LoginForm() {
  const router = useRouter();
  const { login } = useAuth();
  const [formError, setFormError] = useState<string | null>(null);
  const {
    formState: { errors, isSubmitting },
    handleSubmit,
    register,
    setError,
  } = useForm<LoginFormValues>({
    defaultValues: {
      email: "",
      password: "",
      device_name: "EMI Web",
    },
  });

  async function onSubmit(values: LoginFormValues) {
    setFormError(null);
    const parsed = loginSchema.safeParse(values);

    if (!parsed.success) {
      parsed.error.issues.forEach((issue) => {
        const field = issue.path[0] as keyof LoginFormValues;
        setError(field, { message: issue.message });
      });
      return;
    }

    try {
      const user = await login(parsed.data);
      router.replace(getDashboardPath(user.role));
    } catch (error) {
      setFormError(
        error instanceof ApiError
          ? error.message
          : "Login gagal. Periksa email dan password.",
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
            <h1 className="text-3xl font-black tracking-tight text-ink">Selamat Datang di EMI</h1>
            <p className="mt-2 text-sm font-bold text-slate-500">Platform E-Learning Mekongga Indonesia</p>
          </div>
        </div>

        <form className="grid gap-5" onSubmit={handleSubmit(onSubmit)}>
          {formError ? (
            <Alert className="border-4 font-bold shadow-[3px_3px_0_var(--color-ink)]" tone="error">
              {formError}
            </Alert>
          ) : null}
          <FormField error={errors.email?.message} label="Email">
            <Input
              autoComplete="email"
              className="min-h-12 rounded-[8px] border-4 border-ink bg-[#fcf9f8] text-base focus:ring-[#ffd167]"
              placeholder="guru@emi.test"
              type="email"
              {...register("email")}
            />
          </FormField>
          <FormField error={errors.password?.message} label="Kata Sandi">
            <Input
              autoComplete="current-password"
              className="min-h-12 rounded-[8px] border-4 border-ink bg-[#fcf9f8] text-base focus:ring-[#ffd167]"
              placeholder="•••••••••••"
              type="password"
              {...register("password")}
            />
          </FormField>
          <input type="hidden" {...register("device_name")} />

          <div className="flex justify-end">
            <button className="text-sm font-bold text-slate-500 hover:text-ink hover:underline" type="button">Lupa kata sandi?</button>
          </div>

          <Button
            className="min-h-12 rounded-[8px] border-4 border-ink bg-[#ff8c42] text-lg font-black text-[#6a2d00] shadow-[4px_4px_0_var(--color-ink)] hover:translate-x-[2px] hover:translate-y-[2px] hover:bg-[#ffa45f] hover:shadow-[2px_2px_0_var(--color-ink)] focus:ring-4 focus:ring-[#ffd167] active:translate-x-[4px] active:translate-y-[4px] active:shadow-none"
            disabled={isSubmitting}
            type="submit"
          >
            {isSubmitting ? "Memproses..." : "Masuk →"}
          </Button>
        </form>

        <div className="h-1 rounded-full bg-slate-200" />

        <p className="text-center text-sm font-bold text-slate-600">
          Belum punya akun?{" "}
          <Link className="font-black text-[#ff8c42] hover:text-[#e07530] hover:underline" href="/register">
            Daftar sekarang
          </Link>
        </p>
      </div>
    </section>
  );
}
