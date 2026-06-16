import { apiClient } from "@/lib/api-client";

import type {
  RegistrationRequest,
  RegistrationRequestFilters,
  RegistrationRequestList,
} from "./types";

export const approvalService = {
  async list(
    token: string,
    filters: RegistrationRequestFilters = {},
  ): Promise<RegistrationRequestList> {
    const response = await apiClient.get<RegistrationRequest[]>(
      "/admin/registration-requests",
      {
        token,
        query: {
          status: filters.status ?? "pending",
          requested_role: filters.requested_role,
          search: filters.search,
          page: filters.page ?? 1,
          per_page: filters.per_page ?? 15,
          sort_by: "created_at",
          sort_direction: "desc",
        },
      },
    );

    return {
      items: response.data ?? [],
      meta: response.meta as RegistrationRequestList["meta"],
    };
  },

  async detail(token: string, requestId: string) {
    const response = await apiClient.get<RegistrationRequest>(
      `/admin/registration-requests/${requestId}`,
      { token },
    );

    if (!response.data) {
      throw new Error("Detail permintaan pendaftaran tidak tersedia.");
    }

    return response.data;
  },

  async approve(token: string, requestId: string, reviewNote?: string) {
    const response = await apiClient.post<RegistrationRequest>(
      `/admin/registration-requests/${requestId}/approve`,
      reviewNote ? { review_note: reviewNote } : {},
      { token },
    );

    if (!response.data) {
      throw new Error("Response approval tidak memuat data permintaan.");
    }

    return response.data;
  },

  async reject(token: string, requestId: string, reviewNote: string) {
    const response = await apiClient.post<RegistrationRequest>(
      `/admin/registration-requests/${requestId}/reject`,
      { review_note: reviewNote },
      { token },
    );

    if (!response.data) {
      throw new Error("Response reject tidak memuat data permintaan.");
    }

    return response.data;
  },
};
