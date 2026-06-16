import type { UserRole } from "@/lib/roles";

export type AuthUser = {
  id: string;
  full_name: string;
  email: string;
  role: UserRole;
  status: "pending" | "approved" | "rejected" | "inactive" | string;
  avatar_url?: string | null;
  permissions?: string[];
  school?: Record<string, unknown> | null;
  class?: Record<string, unknown> | null;
};

export type LoginPayload = {
  email: string;
  password: string;
  device_name: string;
};

export type LoginResult = {
  token: string;
  token_type: "Bearer" | string;
  user: AuthUser;
};

export type RegisterPayload = {
  full_name: string;
  email: string;
  password: string;
  password_confirmation: string;
  requested_role: "teacher" | "student";
  school_id: string;
  class_id?: string;
};

export type RegisterResult = {
  user_id: string;
  status: "pending" | string;
};
