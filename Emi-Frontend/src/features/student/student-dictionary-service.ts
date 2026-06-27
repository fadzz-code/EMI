import { apiClient } from "@/lib/api-client";

import type { DictionaryEntry, DictionaryEntryFilters, PaginatedResult } from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const studentDictionaryService = {
  async entries(token: string, filters: DictionaryEntryFilters = {}) {
    const response = await apiClient.get<DictionaryEntry[]>("/dictionary", {
      token,
      query: {
        search: filters.search,
        language: filters.language ?? "all",
        category_id: filters.category_id,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 12,
        sort_by: "indonesia",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async detail(token: string, entryId: string) {
    const response = await apiClient.get<DictionaryEntry>(`/dictionary/${entryId}`, {
      token,
    });

    if (!response.data) {
      throw new Error("Detail kamus tidak tersedia.");
    }

    return response.data;
  },
};
