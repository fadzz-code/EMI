import type { UserRole } from "@/lib/roles";

export type AuthUser = {
  id: string;
  full_name: string;
  email: string;
  role: UserRole;
  status: "pending" | "approved" | "rejected" | "inactive" | string;
  phone?: string | null;
  password_must_change?: boolean;
  avatar?: {
    id: string;
    url: string;
  } | null;
  permissions?: string[];
  active_school?: PublicSchool | null;
  active_class?: PublicSchoolClass | null;
  active_assignment?: Record<string, unknown> | null;
  active_membership?: Record<string, unknown> | null;
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
  class_id: string;
  privacy_policy_accepted: boolean;
  privacy_policy_version: string;
};

export type RegisterResult = {
  user_id: string;
  status: "pending" | string;
};

export type ForgotPasswordPayload = {
  email: string;
};

export type PublicSchool = {
  id: string;
  name: string;
  address?: string | null;
  phone?: string | null;
};

export type PublicSchoolClass = {
  id: string;
  school_id: string;
  name: string;
  grade_level?: string | number | null;
  academic_year?: string | null;
};
