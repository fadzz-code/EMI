import { apiClient, apiRequest } from "@/lib/api-client";
import { env } from "@/lib/env";

import type {
  DictionaryCategory,
  DictionaryCategoryFilters,
  DictionaryCategoryPayload,
  DictionaryEntry,
  DictionaryEntryFilters,
  DictionaryEntryPayload,
  DictionaryImportError,
  DictionaryImportFilters,
  DictionaryImportJob,
  DuplicateStrategy,
  MediaFile,
  PaginatedResult,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

const audioMimeByExtension: Record<string, string> = {
  mp3: "audio/mpeg",
  wav: "audio/wav",
  m4a: "audio/mp4",
  ogg: "audio/ogg",
  webm: "audio/webm",
};

function audioUploadFile(file: File) {
  const extension = file.name.split(".").pop()?.toLowerCase() ?? "";
  const expectedMime = audioMimeByExtension[extension];

  if (
    !expectedMime ||
    (file.type &&
      file.type !== "application/octet-stream" &&
      file.type !== "audio/mp3" &&
      file.type !== "audio/mpeg3" &&
      file.type !== "audio/x-mpeg-3")
  ) {
    return file;
  }

  return new File([file], file.name, {
    lastModified: file.lastModified,
    type: expectedMime,
  });
}

export const dictionaryService = {
  async listCategories(token: string, filters: DictionaryCategoryFilters = {}) {
    const response = await apiClient.get<DictionaryCategory[]>(
      "/admin/dictionary/categories",
      {
        token,
        query: {
          search: filters.search,
          status: filters.status,
          page: filters.page ?? 1,
          per_page: filters.per_page ?? 100,
        },
      },
    );

    return paginated(response.data, response.meta);
  },

  async createCategory(token: string, payload: DictionaryCategoryPayload) {
    const response = await apiClient.post<DictionaryCategory>(
      "/admin/dictionary/categories",
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response kategori tidak tersedia.");
    }

    return response.data;
  },

  async listEntries(token: string, filters: DictionaryEntryFilters = {}) {
    const response = await apiClient.get<DictionaryEntry[]>("/admin/dictionary/entries", {
      token,
      query: {
        search: filters.search,
        category_id: filters.category_id,
        status: filters.status,
        has_audio: filters.has_audio,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "indonesia",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async detailEntry(token: string, entryId: string) {
    const response = await apiClient.get<DictionaryEntry>(
      `/admin/dictionary/entries/${entryId}`,
      { token },
    );

    if (!response.data) {
      throw new Error("Detail entri kamus tidak tersedia.");
    }

    return response.data;
  },

  async createEntry(token: string, payload: DictionaryEntryPayload) {
    const response = await apiClient.post<DictionaryEntry>(
      "/admin/dictionary/entries",
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response entri kamus tidak tersedia.");
    }

    return response.data;
  },

  async updateEntry(token: string, entryId: string, payload: DictionaryEntryPayload) {
    const response = await apiClient.put<DictionaryEntry>(
      `/admin/dictionary/entries/${entryId}`,
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response entri kamus tidak tersedia.");
    }

    return response.data;
  },

  async deleteEntry(token: string, entryId: string) {
    await apiClient.delete<[]>(`/admin/dictionary/entries/${entryId}`, { token });
  },

  async uploadAudio(token: string, file: File) {
    const formData = new FormData();
    const uploadFile = audioUploadFile(file);
    formData.append("file", uploadFile, uploadFile.name);
    formData.append("purpose", "audio");
    formData.append("visibility", "public");

    const response = await apiRequest<MediaFile>("/media", {
      method: "POST",
      body: formData,
      token,
    });

    if (!response.data) {
      throw new Error("Response upload audio tidak tersedia.");
    }

    return response.data;
  },

  async downloadTemplate(token: string) {
    const response = await fetch(`${env.apiBaseUrl}/admin/dictionary/imports/template`, {
      headers: {
        Accept: "text/csv",
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error("Template CSV gagal diunduh.");
    }

    return response.blob();
  },

  async previewImport(
    token: string,
    params: {
      csvFile: File;
      audioZip?: File | null;
      duplicateStrategy: DuplicateStrategy;
    },
  ) {
    const formData = new FormData();
    formData.append("csv_file", params.csvFile);
    formData.append("duplicate_strategy", params.duplicateStrategy);

    if (params.audioZip) {
      formData.append("audio_zip", params.audioZip);
    }

    const response = await apiRequest<DictionaryImportJob>(
      "/admin/dictionary/imports/preview",
      {
        method: "POST",
        body: formData,
        token,
        timeoutMs: 60_000,
      },
    );

    if (!response.data) {
      throw new Error("Preview import tidak tersedia.");
    }

    return response.data;
  },

  async confirmImport(token: string, jobId: string) {
    const response = await apiClient.post<DictionaryImportJob>(
      `/admin/dictionary/imports/${jobId}/confirm`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Response konfirmasi import tidak tersedia.");
    }

    return response.data;
  },

  async listImports(token: string, filters: DictionaryImportFilters = {}) {
    const response = await apiClient.get<DictionaryImportJob[]>(
      "/admin/dictionary/imports",
      {
        token,
        query: {
          status: filters.status,
          duplicate_strategy: filters.duplicate_strategy,
          page: filters.page ?? 1,
          per_page: filters.per_page ?? 10,
        },
      },
    );

    return paginated(response.data, response.meta);
  },

  async importErrors(token: string, jobId: string) {
    const response = await apiClient.get<DictionaryImportError[]>(
      `/admin/dictionary/imports/${jobId}/errors`,
      {
        token,
        query: {
          page: 1,
          per_page: 20,
        },
      },
    );

    return paginated(response.data, response.meta);
  },
};
