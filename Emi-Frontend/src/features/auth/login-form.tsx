"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";

import { ApiError } from "@/lib/api-client";
import { getDashboardPath } from "@/lib/roles";
import { loginSchema, type LoginFormValues } from "@/lib/validators";
import { Alert, Button, Card, CardContent, CardHeader, FormField, Input } from "@/components/ui";

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
    <Card>
      <CardHeader>
        <h2 className="text-2xl font-black text-ink">Masuk ke EMI</h2>
        <p className="mt-2 text-sm text-slate-600">
          Gunakan akun yang sudah disetujui Admin.
        </p>
      </CardHeader>
      <CardContent>
        <form className="grid gap-4" onSubmit={handleSubmit(onSubmit)}>
          {formError ? <Alert tone="error">{formError}</Alert> : null}
          <FormField error={errors.email?.message} label="Email">
            <Input autoComplete="email" type="email" {...register("email")} />
          </FormField>
          <FormField error={errors.password?.message} label="Password">
            <Input autoComplete="current-password" type="password" {...register("password")} />
          </FormField>
          <input type="hidden" {...register("device_name")} />
          <Button disabled={isSubmitting} type="submit">
            {isSubmitting ? "Memproses..." : "Masuk"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
