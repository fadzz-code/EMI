import { apiClient } from "@/lib/api-client";
import type { TeacherMediaFile } from "@/features/teacher/types";

import type { AdminSpeakingExercise, AdminSpeakingExercisePayload, PaginatedResult } from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const adminSpeakingService = {
  async exercises(token: string, filters: { status?: string } = {}) {
    const response = await apiClient.get<AdminSpeakingExercise[]>("/admin/speaking/exercises", {
      token,
      query: {
        per_page: 100,
        status: filters.status,
      },
    });

    return paginated(response.data, response.meta);
  },

  async createExercise(token: string, payload: AdminSpeakingExercisePayload) {
    const response = await apiClient.post<AdminSpeakingExercise>("/admin/speaking/exercises", payload, { token });
    if (!response.data) throw new Error("Template speaking tidak tersedia.");
    return response.data;
  },

  async updateExercise(token: string, exerciseId: string, payload: AdminSpeakingExercisePayload) {
    const response = await apiClient.patch<AdminSpeakingExercise>(`/admin/speaking/exercises/${exerciseId}`, payload, { token });
    if (!response.data) throw new Error("Template speaking tidak tersedia.");
    return response.data;
  },

  async archiveExercise(token: string, exerciseId: string) {
    const response = await apiClient.patch<AdminSpeakingExercise>(`/admin/speaking/exercises/${exerciseId}/archive`, {}, { token });
    if (!response.data) throw new Error("Template speaking tidak tersedia.");
    return response.data;
  },

  async uploadReferenceAudio(token: string, file: File) {
    const formData = new FormData();
    formData.append("file", file, file.name);
    formData.append("purpose", "speaking_reference_audio");
    formData.append("visibility", "public");

    const response = await apiClient.post<TeacherMediaFile>("/media", formData, { token, timeoutMs: 60_000 });
    if (!response.data) throw new Error("Gagal mengunggah audio penutur asli.");
    return response.data;
  },
};
