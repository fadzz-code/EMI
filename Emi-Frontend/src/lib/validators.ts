import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().email("Email tidak valid."),
  password: z.string().min(1, "Password wajib diisi."),
  device_name: z.string().min(1),
});

export const registerSchema = z
  .object({
    full_name: z.string().min(3, "Nama minimal 3 karakter."),
    email: z.string().email("Email tidak valid."),
    password: z
      .string()
      .min(8, "Password minimal 8 karakter.")
      .regex(/[A-Za-z]/, "Password harus memuat huruf.")
      .regex(/[0-9]/, "Password harus memuat angka."),
    password_confirmation: z
      .string()
      .min(8, "Konfirmasi password wajib diisi."),
    requested_role: z.enum(["teacher", "student"]),
    school_id: z.string().uuid("ID sekolah harus berupa UUID."),
    class_id: z.string().uuid("Pilih kelas yang valid."),
  privacy_policy_accepted: z.boolean().refine((value) => value, {
    message: "Persetujuan kebijakan privasi wajib diberikan.",
  }),

    privacy_policy_version: z.string().min(1),
  })
  .refine((value) => value.password === value.password_confirmation, {
    message: "Konfirmasi password tidak sama.",
    path: ["password_confirmation"],
  });

export const forgotPasswordSchema = z.object({
  email: z.string().email("Email tidak valid."),
});

export const resetPasswordSchema = z
  .object({
    email: z.string().email("Email tidak valid."),
    token: z.string().min(1, "Tautan reset tidak valid."),
    password: z
      .string()
      .min(8, "Password minimal 8 karakter.")
      .regex(/[A-Za-z]/, "Password harus memuat huruf.")
      .regex(/[0-9]/, "Password harus memuat angka."),
    password_confirmation: z
      .string()
      .min(8, "Konfirmasi password wajib diisi."),
  })
  .refine((value) => value.password === value.password_confirmation, {
    message: "Konfirmasi password tidak sama.",
    path: ["password_confirmation"],
  });

export type LoginFormValues = z.infer<typeof loginSchema>;
export type RegisterFormValues = z.infer<typeof registerSchema>;
export type ForgotPasswordFormValues = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordFormValues = z.infer<typeof resetPasswordSchema>;
