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
import { AuthBrandMark } from "./auth-visuals";

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
    <section className="overflow-hidden rounded-[12px] border-4 border-[#1b1b1b] bg-white shadow-[8px_8px_0_#1b1b1b]">
      <div className="h-4 border-b-4 border-[#1b1b1b] bg-[#00c291]" />
      <div className="grid gap-6 px-6 py-8 sm:px-10">
        <div className="grid justify-items-center gap-4 text-center">
          <AuthBrandMark className="justify-center" />
          <div>
            <h1 className="text-3xl font-black leading-tight text-[#1b1b1b] sm:text-4xl">
              Selamat Datang di EMI
            </h1>
            <p className="mt-2 text-base font-medium text-[#564338]">
              Platform E-Learning Mekongga Indonesia
            </p>
          </div>
        </div>

        <form className="grid gap-4" onSubmit={handleSubmit(onSubmit)}>
          {formError ? (
            <Alert className="border-4 font-bold shadow-[3px_3px_0_#1b1b1b]" tone="error">
              {formError}
            </Alert>
          ) : null}
          <FormField error={errors.email?.message} label="Email">
            <Input
              autoComplete="email"
              className="min-h-[60px] rounded-[8px] border-4 border-[#1b1b1b] bg-[#fcf9f8] text-base focus:ring-[#ffd167]"
              placeholder="nama@email.com"
              type="email"
              {...register("email")}
            />
          </FormField>
          <FormField error={errors.password?.message} label="Password">
            <Input
              autoComplete="current-password"
              className="min-h-[60px] rounded-[8px] border-4 border-[#1b1b1b] bg-[#fcf9f8] text-base focus:ring-[#ffd167]"
              placeholder="Masukkan password"
              type="password"
              {...register("password")}
            />
          </FormField>
          <input type="hidden" {...register("device_name")} />
          <Button
            className="mt-2 min-h-[60px] rounded-[8px] border-4 border-[#1b1b1b] bg-[#ff8c42] text-lg font-black text-[#6a2d00] shadow-[6px_6px_0_#1b1b1b] hover:bg-[#ffa45f] focus:ring-4 focus:ring-[#ffd167]"
            disabled={isSubmitting}
            type="submit"
          >
            {isSubmitting ? "Memproses..." : "Masuk ->"}
          </Button>
        </form>

        <div className="grid gap-4 text-center">
          <div className="h-1 rounded-full bg-[#1b1b1b]" />
          <p className="text-sm font-medium text-[#564338]">
            Belum punya akun?{" "}
            <Link className="font-black text-[#9b4500] underline" href="/register">
              Daftar sekarang
            </Link>
          </p>
        </div>
      </div>
    </section>
  );
}
