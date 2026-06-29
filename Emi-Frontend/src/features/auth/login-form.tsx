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
    <section className="flex min-h-[640px] flex-col justify-center bg-white px-6 py-10 sm:px-10 lg:px-14">
      <div className="mx-auto grid w-full max-w-md gap-8">
        <div className="grid gap-5">
          <div className="flex items-center gap-3">
            <div className="grid size-14 place-items-center rounded-2xl bg-emerald-600 text-xl font-black text-white shadow-lg shadow-emerald-100">EMI</div>
            <div>
              <p className="text-lg font-black text-ink">EMI</p>
              <p className="text-sm font-semibold text-slate-500">EMI — Elearning Mekongga Indonesia</p>
            </div>
          </div>
          <div>
            <h1 className="text-3xl font-black tracking-tight text-ink sm:text-4xl">Selamat Datang di EMI</h1>
            <p className="mt-3 text-base font-medium text-slate-600">Platform E-Learning Mekongga Indonesia</p>
          </div>
        </div>

        <form className="grid gap-5" onSubmit={handleSubmit(onSubmit)}>
          {formError ? <Alert tone="error">{formError}</Alert> : null}
          <FormField error={errors.email?.message} label="Email">
            <Input
              autoComplete="email"
              className="min-h-12 rounded-2xl border-slate-200 bg-slate-50 text-base focus:ring-emerald-100"
              placeholder="guru@emi.test"
              type="email"
              {...register("email")}
            />
          </FormField>
          <FormField error={errors.password?.message} label="Password">
            <Input
              autoComplete="current-password"
              className="min-h-12 rounded-2xl border-slate-200 bg-slate-50 text-base focus:ring-emerald-100"
              placeholder="•••••••••••"
              type="password"
              {...register("password")}
            />
          </FormField>
          <input type="hidden" {...register("device_name")} />
          <Button
            className="min-h-12 rounded-2xl border-0 bg-emerald-600 text-base font-black text-white shadow-lg shadow-emerald-100 hover:bg-emerald-700 focus:ring-4 focus:ring-emerald-100"
            disabled={isSubmitting}
            type="submit"
          >
            {isSubmitting ? "Memproses..." : "Masuk →"}
          </Button>
        </form>

        <p className="text-center text-sm font-medium text-slate-600">
          Belum punya akun?{" "}
          <Link className="font-black text-emerald-700 hover:text-emerald-800" href="/register">
            Daftar sekarang
          </Link>
        </p>
      </div>
    </section>
  );
}
