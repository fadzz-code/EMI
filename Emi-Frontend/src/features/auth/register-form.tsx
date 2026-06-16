"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useForm, useWatch } from "react-hook-form";

import { ApiError, getFieldError, getFirstApiError } from "@/lib/api-client";
import { registerSchema, type RegisterFormValues } from "@/lib/validators";
import {
  Alert,
  Button,
  Card,
  CardContent,
  CardHeader,
  FormField,
  Input,
  Select,
} from "@/components/ui";

import { authService } from "./auth-service";
import { useAuth } from "./auth-provider";
import type { PublicSchool, PublicSchoolClass } from "./auth-types";

export function RegisterForm({ role }: { role: "teacher" | "student" }) {
  const router = useRouter();
  const { registerStudent, registerTeacher } = useAuth();
  const [formError, setFormError] = useState<string | null>(null);
  const [schools, setSchools] = useState<PublicSchool[]>([]);
  const [classes, setClasses] = useState<PublicSchoolClass[]>([]);
  const [isLoadingSchools, setIsLoadingSchools] = useState(true);
  const [isLoadingClasses, setIsLoadingClasses] = useState(false);
  const [lookupError, setLookupError] = useState<string | null>(null);
  const {
    formState: { errors, isSubmitting },
    control,
    handleSubmit,
    register,
    setError,
    setValue,
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
  const selectedSchoolId = useWatch({
    control,
    name: "school_id",
  });

  useEffect(() => {
    let isMounted = true;

    authService
      .listPublicSchools()
      .then((items) => {
        if (isMounted) {
          setSchools(items);
        }
      })
      .catch((error) => {
        if (isMounted) {
          setLookupError(getFirstApiError(error));
        }
      })
      .finally(() => {
        if (isMounted) {
          setIsLoadingSchools(false);
        }
      });

    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    if (!selectedSchoolId) {
      queueMicrotask(() => {
        setClasses([]);
        setValue("class_id", "");
      });
      return;
    }

    let isMounted = true;
    queueMicrotask(() => {
      if (isMounted) {
        setIsLoadingClasses(true);
        setValue("class_id", "");
      }
    });

    authService
      .listPublicClasses(selectedSchoolId)
      .then((items) => {
        if (isMounted) {
          setClasses(items);
        }
      })
      .catch((error) => {
        if (isMounted) {
          setLookupError(getFirstApiError(error));
          setClasses([]);
        }
      })
      .finally(() => {
        if (isMounted) {
          setIsLoadingClasses(false);
        }
      });

    return () => {
      isMounted = false;
    };
  }, [selectedSchoolId, setValue]);

  function applyBackendErrors(error: ApiError) {
    const fields: Array<keyof RegisterFormValues> = [
      "full_name",
      "email",
      "password",
      "password_confirmation",
      "school_id",
      "class_id",
      "requested_role",
    ];

    fields.forEach((field) => {
      const message = getFieldError(error, field);
      if (message) {
        setError(field, { message });
      }
    });
  }

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
      const payload = {
        full_name: parsed.data.full_name,
        email: parsed.data.email,
        password: parsed.data.password,
        password_confirmation: parsed.data.password_confirmation,
        school_id: parsed.data.school_id,
        class_id: parsed.data.class_id,
      };

      if (role === "teacher") {
        await registerTeacher(payload);
      } else {
        await registerStudent(payload);
      }

      router.replace("/pending-approval");
    } catch (error) {
      if (error instanceof ApiError) {
        applyBackendErrors(error);
      }

      setFormError(getFirstApiError(error));
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
          {lookupError ? <Alert tone="warning">{lookupError}</Alert> : null}
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
          <FormField error={errors.school_id?.message} label="Sekolah">
            <Select disabled={isLoadingSchools} {...register("school_id")}>
              <option value="">
                {isLoadingSchools ? "Memuat sekolah..." : "Pilih sekolah"}
              </option>
              {schools.map((school) => (
                <option key={school.id} value={school.id}>
                  {school.name}
                </option>
              ))}
            </Select>
          </FormField>
          <FormField error={errors.class_id?.message} label="Kelas">
            <Select
              disabled={!selectedSchoolId || isLoadingClasses}
              {...register("class_id")}
            >
              <option value="">
                {isLoadingClasses ? "Memuat kelas..." : "Pilih kelas"}
              </option>
              {classes.map((schoolClass) => (
                <option key={schoolClass.id} value={schoolClass.id}>
                  {schoolClass.name}
                  {schoolClass.academic_year ? ` - ${schoolClass.academic_year}` : ""}
                </option>
              ))}
            </Select>
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
