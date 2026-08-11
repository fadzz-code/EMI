"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useForm, useWatch } from "react-hook-form";

import { ApiError, getFieldError, getFirstApiError } from "@/lib/api-client";
import { cn } from "@/lib/utils";
import { registerSchema, type RegisterFormValues } from "@/lib/validators";
import { Alert, Button, FormField, Input, Select } from "@/components/ui";

import { authService } from "./auth-service";
import { useAuth } from "./auth-provider";
import type { PublicSchool, PublicSchoolClass } from "./auth-types";
import {
  AuthBrandMark,
  AuthScreen,
  AuthTopBar,
  RegistrationSteps,
} from "./auth-visuals";

const inputClass =
  "min-h-[56px] rounded-[8px] border-4 border-[#1b1b1b] bg-[#fcf9f8] px-4 text-base focus:ring-[#ffd167]";
const selectClass =
  "min-h-[56px] rounded-[8px] border-4 border-[#1b1b1b] bg-[#fcf9f8] px-4 text-base focus:ring-[#ffd167]";
const PRIVACY_POLICY_VERSION = "2026-08-11";
const submitClass =
  "min-h-[60px] rounded-[8px] border-4 border-[#1b1b1b] bg-[#ff8c42] text-lg font-black text-[#6a2d00] shadow-[6px_6px_0_#1b1b1b] hover:bg-[#ffa45f] focus:ring-4 focus:ring-[#ffd167]";

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
      privacy_policy_accepted: false,
      privacy_policy_version: PRIVACY_POLICY_VERSION,
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
      "privacy_policy_accepted",
      "privacy_policy_version",
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
        privacy_policy_accepted: parsed.data.privacy_policy_accepted,
        privacy_policy_version: parsed.data.privacy_policy_version,
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

  const roleName = role === "teacher" ? "Guru" : "Siswa";
  const formFields = (
    <>
      {formError ? (
        <Alert
          className="border-4 font-bold shadow-[3px_3px_0_#1b1b1b]"
          tone="error"
        >
          {formError}
        </Alert>
      ) : null}
      {lookupError ? (
        <Alert
          className="border-4 font-bold shadow-[3px_3px_0_#1b1b1b]"
          tone="warning"
        >
          {lookupError}
        </Alert>
      ) : null}

      <div className={cn("grid gap-4", role === "teacher" && "sm:grid-cols-2")}>
        <FormField error={errors.full_name?.message} label="Nama lengkap">
          <Input
            autoComplete="name"
            className={inputClass}
            placeholder={`Nama lengkap ${roleName.toLowerCase()}`}
            {...register("full_name")}
          />
        </FormField>
        <FormField error={errors.email?.message} label="Email">
          <Input
            autoComplete="email"
            className={inputClass}
            placeholder="nama@email.com"
            type="email"
            {...register("email")}
          />
        </FormField>
        <FormField error={errors.password?.message} label="Password">
          <Input
            autoComplete="new-password"
            className={inputClass}
            placeholder="Minimal 8 karakter"
            type="password"
            {...register("password")}
          />
        </FormField>
        <FormField
          error={errors.password_confirmation?.message}
          label="Konfirmasi password"
        >
          <Input
            autoComplete="new-password"
            className={inputClass}
            placeholder="Ulangi password"
            type="password"
            {...register("password_confirmation")}
          />
        </FormField>
      </div>

      <section className="grid gap-4 rounded-[10px] border-4 border-[#1b1b1b] bg-[#f0eded] p-4">
        <div>
          <h2 className="text-lg font-black text-[#1b1b1b]">
            Data sekolah dan kelas
          </h2>
          <p className="mt-1 text-sm font-medium leading-6 text-[#564338]">
            Pilih data yang sesuai agar Admin dapat meninjau pendaftaran.
          </p>
        </div>
        <div
          className={cn("grid gap-4", role === "teacher" && "sm:grid-cols-2")}
        >
          <FormField error={errors.school_id?.message} label="Sekolah">
            <Select
              className={selectClass}
              disabled={isLoadingSchools}
              {...register("school_id")}
            >
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
              className={selectClass}
              disabled={!selectedSchoolId || isLoadingClasses}
              {...register("class_id")}
            >
              <option value="">
                {isLoadingClasses ? "Memuat kelas..." : "Pilih kelas"}
              </option>
              {classes.map((schoolClass) => (
                <option key={schoolClass.id} value={schoolClass.id}>
                  {schoolClass.name}
                  {schoolClass.academic_year
                    ? ` - ${schoolClass.academic_year}`
                    : ""}
                </option>
              ))}
            </Select>
          </FormField>
        </div>
      </section>

      <FormField
        error={errors.privacy_policy_accepted?.message}
        label="Persetujuan privasi"
      >
        <label className="flex items-start gap-3 rounded-[8px] border-4 border-[#1b1b1b] bg-white p-4 text-sm font-bold leading-6 text-[#1b1b1b]">
          <input
            className="mt-1 size-5"
            type="checkbox"
            {...register("privacy_policy_accepted")}
          />
          <span>
            Saya menyetujui{" "}
            <Link
              className="font-black text-[#9b4500] underline"
              href="/privacy"
              target="_blank"
            >
              Kebijakan Privasi
            </Link>
            .
          </span>
        </label>
      </FormField>
      <input type="hidden" {...register("privacy_policy_version")} />
    </>
  );

  if (role === "teacher") {
    return (
      <AuthScreen>
        <div className="mx-auto grid min-h-screen w-full max-w-[760px] place-items-center px-4 py-8">
          <section className="w-full overflow-hidden rounded-[12px] border-[6px] border-[#1b1b1b] bg-white shadow-[8px_8px_0_#1b1b1b]">
            <header className="border-b-[6px] border-[#1b1b1b] bg-[#ffd167] px-6 py-7 text-center">
              <AuthBrandMark className="justify-center" />
              <h1 className="mt-5 text-3xl font-black leading-tight text-[#1b1b1b] sm:text-4xl">
                Registrasi Guru
              </h1>
              <p className="mt-2 text-base font-semibold text-[#564338]">
                Mari bergabung dan mulai mengajar.
              </p>
            </header>
            <div className="grid gap-6 p-5 sm:p-8">
              <RegistrationSteps active={2} />
              <div className="rounded-[8px] border-4 border-[#1b1b1b] bg-[#00c291] p-4 text-sm font-bold leading-6 text-[#003c2f] shadow-[4px_4px_0_#1b1b1b]">
                Guru hanya dapat mengelola kelas aktif yang ditetapkan oleh
                Admin. Pastikan sekolah dan kelas yang dipilih sudah benar.
              </div>
              <form className="grid gap-5" onSubmit={handleSubmit(onSubmit)}>
                {formFields}
                <input type="hidden" {...register("requested_role")} />
                <Button
                  className={submitClass}
                  disabled={isSubmitting}
                  type="submit"
                >
                  {isSubmitting ? "Mengirim..." : "Kirim Pendaftaran ->"}
                </Button>
              </form>
              <p className="text-center text-sm font-medium text-[#564338]">
                Sudah punya akun?{" "}
                <Link
                  className="font-black text-[#9b4500] underline"
                  href="/login"
                >
                  Masuk
                </Link>
              </p>
            </div>
          </section>
        </div>
      </AuthScreen>
    );
  }

  return (
    <AuthScreen>
      <AuthTopBar backHref="/register" />
      <section className="mx-auto grid w-full max-w-7xl gap-6 px-4 pb-10 sm:px-8">
        <div className="grid gap-3 lg:grid-cols-[1fr_auto] lg:items-end">
          <div>
            <p className="text-sm font-black uppercase text-[#9b4500]">
              Registrasi Siswa
            </p>
            <h1 className="mt-2 text-4xl font-black leading-tight text-[#1b1b1b] sm:text-5xl">
              Data Diri & Akademik
            </h1>
          </div>
          <div className="w-full lg:w-[520px]">
            <RegistrationSteps active={2} />
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-[1.25fr_0.75fr]">
          <section className="rounded-[12px] border-[6px] border-[#1b1b1b] bg-white p-5 shadow-[8px_8px_0_#1b1b1b] sm:p-8">
            <div className="mb-6 border-b-4 border-[#1b1b1b] pb-4">
              <h2 className="text-2xl font-black text-[#1b1b1b]">
                Lengkapi profil siswa
              </h2>
              <p className="mt-2 text-sm font-medium leading-6 text-[#564338]">
                Data akan diverifikasi Admin sebelum akun bisa digunakan.
              </p>
            </div>
            <form className="grid gap-5" onSubmit={handleSubmit(onSubmit)}>
              {formFields}
              <input type="hidden" {...register("requested_role")} />
              <Button
                className={submitClass}
                disabled={isSubmitting}
                type="submit"
              >
                {isSubmitting ? "Mengirim..." : "Kirim Pendaftaran ->"}
              </Button>
            </form>
            <p className="mt-6 text-center text-sm font-medium text-[#564338]">
              Sudah punya akun?{" "}
              <Link
                className="font-black text-[#9b4500] underline"
                href="/login"
              >
                Masuk
              </Link>
            </p>
          </section>

          <aside className="grid content-start gap-5">
            <div className="rounded-[12px] border-4 border-[#1b1b1b] bg-[#ffdf9b] p-6 shadow-[6px_6px_0_#1b1b1b]">
              <p className="text-sm font-black uppercase text-[#9b4500]">
                Informasi Penting
              </p>
              <p className="mt-3 text-base font-bold leading-7 text-[#1b1b1b]">
                Siswa hanya dapat mengakses kelas aktif yang sudah disetujui.
              </p>
              <p className="mt-2 text-sm font-medium leading-6 text-[#564338]">
                Bila sekolah atau kelas belum muncul, hubungi Admin EMI atau
                guru sekolah.
              </p>
            </div>
            <div className="overflow-hidden rounded-[12px] border-4 border-[#1b1b1b] bg-white shadow-[6px_6px_0_#1b1b1b]">
              <div className="border-b-4 border-[#1b1b1b] bg-[#ff8c42] px-5 py-3 text-sm font-black text-[#6a2d00]">
                Preview alur akun
              </div>
              <div className="grid gap-3 p-5">
                {["Daftar", "Menunggu admin", "Masuk dashboard"].map(
                  (item, index) => (
                    <div
                      className="flex items-center gap-3 rounded-[8px] border-4 border-dashed border-[#1b1b1b] bg-[#fcf9f8] p-3"
                      key={item}
                    >
                      <span className="grid size-9 place-items-center rounded-full border-2 border-[#1b1b1b] bg-[#ffd167] text-sm font-black">
                        {index + 1}
                      </span>
                      <span className="text-sm font-black text-[#1b1b1b]">
                        {item}
                      </span>
                    </div>
                  ),
                )}
              </div>
            </div>
            <div className="rounded-[8px] border-4 border-[#ba1a1a] bg-[#fff0ed] p-4 text-sm font-bold leading-6 text-[#8c1d18]">
              Pastikan email aktif. Status pending belum mendapat token login.
            </div>
          </aside>
        </div>
      </section>
    </AuthScreen>
  );
}
