import { apiClient } from "@/lib/api-client";

import type {
  PasswordResetRequest,
  PasswordResetRequestFilters,
  PasswordResetRequestList,
} from "./types";

function buildService(basePath: string) {
  return {
    async list(
      token: string,
      filters: PasswordResetRequestFilters = {},
    ): Promise<PasswordResetRequestList> {
      const response = await apiClient.get<PasswordResetRequest[]>(basePath, {
        token,
        query: {
          status: filters.status ?? "pending",
          search: filters.search,
          page: filters.page ?? 1,
          per_page: filters.per_page ?? 15,
          sort_by: "created_at",
          sort_direction: "desc",
        },
      });

      return {
        items: response.data ?? [],
        meta: response.meta as PasswordResetRequestList["meta"],
      };
    },

    async detail(token: string, requestId: string) {
      const response = await apiClient.get<PasswordResetRequest>(
        `${basePath}/${requestId}`,
        { token },
      );

      if (!response.data) {
        throw new Error("Detail permintaan reset password tidak tersedia.");
      }

      return response.data;
    },

    async approve(
      token: string,
      requestId: string,
      payload: { password: string; password_confirmation: string; review_note?: string },
    ) {
      const response = await apiClient.post<PasswordResetRequest>(
        `${basePath}/${requestId}/approve`,
        payload,
        { token },
      );

      if (!response.data) {
        throw new Error("Response approval tidak memuat data permintaan.");
      }

      return response.data;
    },

    async reject(token: string, requestId: string, reviewNote: string) {
      const response = await apiClient.post<PasswordResetRequest>(
        `${basePath}/${requestId}/reject`,
        { review_note: reviewNote },
        { token },
      );

      if (!response.data) {
        throw new Error("Response reject tidak memuat data permintaan.");
      }

      return response.data;
    },
  };
}

export const adminPasswordResetService = buildService("/admin/password-reset-requests");
export const teacherPasswordResetService = buildService("/teacher/password-reset-requests");
