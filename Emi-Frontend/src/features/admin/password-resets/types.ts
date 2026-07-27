import type { ApiPaginationMeta } from "@/lib/api-client";

export type PasswordResetRequestStatus = "pending" | "approved" | "rejected";

export type PasswordResetTargetUser = {
  id: string;
  full_name: string;
  email: string;
  role: "teacher" | "student" | "admin";
  status: string;
};

export type PasswordResetRequester = {
  id: string;
  full_name: string;
  email: string;
  role: string;
};

export type PasswordResetReviewer = {
  id: string;
  full_name: string;
  email: string;
};

export type PasswordResetRequest = {
  id: string;
  status: PasswordResetRequestStatus;
  review_note?: string | null;
  reviewed_at?: string | null;
  created_at?: string | null;
  user?: PasswordResetTargetUser;
  requested_by?: PasswordResetRequester;
  reviewed_by?: PasswordResetReviewer | null;
};

export type PasswordResetRequestFilters = {
  status?: PasswordResetRequestStatus;
  search?: string;
  page?: number;
  per_page?: number;
};

export type PasswordResetRequestList = {
  items: PasswordResetRequest[];
  meta?: ApiPaginationMeta;
};
