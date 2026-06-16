"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";

import { ApiError } from "@/lib/api-client";
import { registerSchema, type RegisterFormValues } from "@/lib/validators";
import { Alert, Button, Card, CardContent, CardHeader, FormField, Input } from "@/components/ui";

import { useAuth } from "./auth-provider";

export function RegisterForm({ role }: { role: "teacher" | "student" }) {
  const router = useRouter();
  const { register: registerAccount } = useAuth();
  const [formError, setFormError] = useState<string | null>(null);
  const {
    formState: { errors, isSubmitting },
    handleSubmit,
    register,
    setError,
  } = useForm<RegisterFormValues>({
    defaultValues: {
      full_name: "",
      email: "",
      password: "",
      password_confirmation: "",
      requested_role: role,
      school_id: "",
      class_id: "",
    },
  });

  async function onSubmit(values: RegisterFormValues) {
    setFormError(null);
    const parsed = registerSchema.safeParse(values);

    if (!parsed.success) {
      parsed.error.issues.forEach((issue) => {
        const field = issue.path[0] as keyof RegisterFormValues;
        setError(field, { message: issue.message });
      });
      return;
    }

    try {
      await registerAccount({
        ...parsed.data,
        class_id: parsed.data.class_id || undefined,
      });
      router.replace("/pending-approval");
    } catch (error) {
      setFormError(
        error instanceof ApiError
          ? error.message
          : "Pendaftaran gagal. Periksa data lalu coba lagi.",
      );
    }
  }

  return (
    <Card>
      <CardHeader>
        <h2 className="text-2xl font-black text-ink">
          Daftar sebagai {role === "teacher" ? "Guru" : "Siswa"}
        </h2>
        <p className="mt-2 text-sm text-slate-600">
          Akun baru akan berstatus pending sampai disetujui Admin.
        </p>
      </CardHeader>
      <CardContent>
        <form className="grid gap-4" onSubmit={handleSubmit(onSubmit)}>
          {formError ? <Alert tone="error">{formError}</Alert> : null}
          <FormField error={errors.full_name?.message} label="Nama lengkap">
            <Input autoComplete="name" {...register("full_name")} />
          </FormField>
          <FormField error={errors.email?.message} label="Email">
            <Input autoComplete="email" type="email" {...register("email")} />
          </FormField>
          <FormField error={errors.password?.message} label="Password">
            <Input autoComplete="new-password" type="password" {...register("password")} />
          </FormField>
          <FormField
            error={errors.password_confirmation?.message}
            label="Konfirmasi password"
          >
            <Input
              autoComplete="new-password"
              type="password"
              {...register("password_confirmation")}
            />
          </FormField>
          <FormField error={errors.school_id?.message} label="UUID sekolah">
            <Input placeholder="Dari endpoint public/schools" {...register("school_id")} />
          </FormField>
          <FormField error={errors.class_id?.message} label="UUID kelas">
            <Input placeholder="Dari endpoint public/schools/{school_id}/classes" {...register("class_id")} />
          </FormField>
          <input type="hidden" {...register("requested_role")} />
          <Button disabled={isSubmitting} type="submit">
            {isSubmitting ? "Mengirim..." : "Kirim Pendaftaran"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
