import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().email("Email tidak valid."),
  password: z.string().min(1, "Password wajib diisi."),
  device_name: z.string().min(1),
});

export const registerSchema = z.object({
  full_name: z.string().min(3, "Nama minimal 3 karakter."),
  email: z.string().email("Email tidak valid."),
  password: z.string().min(8, "Password minimal 8 karakter."),
  password_confirmation: z.string().min(8, "Konfirmasi password wajib diisi."),
  requested_role: z.enum(["teacher", "student"]),
  school_id: z.string().uuid("ID sekolah harus berupa UUID."),
  class_id: z.string().uuid("ID kelas harus berupa UUID.").optional().or(z.literal("")),
});

export type LoginFormValues = z.infer<typeof loginSchema>;
export type RegisterFormValues = z.infer<typeof registerSchema>;
