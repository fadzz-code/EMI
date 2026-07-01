import { apiClient } from "@/lib/api-client";

import type {
  AiKnowledgeFilters,
  AiKnowledgeItem,
  AiKnowledgePayload,
  AiKnowledgeSourceExtraction,
  PaginatedResult,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const knowledgeBaseService = {
  async list(token: string, filters: AiKnowledgeFilters = {}) {
    const response = await apiClient.get<AiKnowledgeItem[]>("/admin/ai/knowledge", {
      token,
      query: {
        search: filters.search,
        category: filters.category,
        status: filters.status,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "updated_at",
        sort_direction: "desc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async create(token: string, payload: AiKnowledgePayload) {
    const response = await apiClient.post<AiKnowledgeItem>("/admin/ai/knowledge", payload, { token });

    if (!response.data) {
      throw new Error("Response Basis AI tidak tersedia.");
    }

    return response.data;
  },

  async update(token: string, itemId: string, payload: AiKnowledgePayload) {
    const response = await apiClient.put<AiKnowledgeItem>(`/admin/ai/knowledge/${itemId}`, payload, {
      token,
    });

    if (!response.data) {
      throw new Error("Response Basis AI tidak tersedia.");
    }

    return response.data;
  },

  async extractKnowledgeSource(
    token: string,
    payload: { source_type: "link" | "pdf"; source_url: string },
  ) {
    const response = await apiClient.post<AiKnowledgeSourceExtraction>(
      "/admin/ai/knowledge/extract-source",
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response ekstraksi sumber tidak tersedia.");
    }

    return response.data;
  },

  async delete(token: string, itemId: string) {
    await apiClient.delete<[]>(`/admin/ai/knowledge/${itemId}`, { token });
  },

  async publish(token: string, itemId: string) {
    const response = await apiClient.post<AiKnowledgeItem>(
      `/admin/ai/knowledge/${itemId}/publish`,
      undefined,
      { token },
    );

    if (!response.data) {
      throw new Error("Response publish Basis AI tidak tersedia.");
    }

    return response.data;
  },

  async archive(token: string, itemId: string) {
    const response = await apiClient.post<AiKnowledgeItem>(
      `/admin/ai/knowledge/${itemId}/archive`,
      undefined,
      { token },
    );

    if (!response.data) {
      throw new Error("Response archive Basis AI tidak tersedia.");
    }

    return response.data;
  },
};
