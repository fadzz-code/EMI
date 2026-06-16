import type { ApiPaginationMeta } from "@/lib/api-client";
import type { PublicSchool, PublicSchoolClass } from "@/features/auth/auth-types";

export type RegistrationRequestStatus = "pending" | "approved" | "rejected";
export type RegistrationRequestedRole = "teacher" | "student";

export type RegistrationRequestUser = {
  id: string;
  full_name: string;
  email: string;
  role: RegistrationRequestedRole;
  status: string;
};

export type RegistrationReviewer = {
  id: string;
  full_name: string;
  email: string;
};

export type RegistrationRequest = {
  id: string;
  requested_role: RegistrationRequestedRole;
  status: RegistrationRequestStatus;
  review_note?: string | null;
  reviewed_at?: string | null;
  created_at?: string | null;
  user?: RegistrationRequestUser;
  school?: PublicSchool | null;
  school_class?: PublicSchoolClass | null;
  reviewed_by?: RegistrationReviewer | null;
};

export type RegistrationRequestFilters = {
  status?: RegistrationRequestStatus;
  requested_role?: RegistrationRequestedRole | "";
  search?: string;
  page?: number;
  per_page?: number;
};

export type RegistrationRequestList = {
  items: RegistrationRequest[];
  meta?: ApiPaginationMeta;
};
