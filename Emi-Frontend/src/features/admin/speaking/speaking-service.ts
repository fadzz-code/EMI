import { apiClient } from "@/lib/api-client";
import type { TeacherMediaFile } from "@/features/teacher/types";

import type { AdminSpeakingExercise, AdminSpeakingExercisePayload, PaginatedResult, SpeakingClassReportRow, SpeakingReportFilters, SpeakingStudentReportRow } from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

function reportQuery(filters: SpeakingReportFilters) {
  return { ...filters, page: filters.page ?? 1, per_page: filters.per_page ?? 10 };
}

export const adminSpeakingService = {
  async studentReports(token: string, filters: SpeakingReportFilters = {}) {
    const response = await apiClient.get<{ students: { data?: SpeakingStudentReportRow[]; meta?: unknown } }>("/admin/reports/speaking/students", { token, query: reportQuery(filters) });
    if (!response.data) throw new Error("Laporan speaking siswa tidak tersedia.");
    return paginated(response.data.students.data, response.data.students.meta);
  },

  async classReports(token: string, filters: SpeakingReportFilters = {}) {
    const response = await apiClient.get<{ classes: { data?: SpeakingClassReportRow[]; meta?: unknown } }>("/admin/reports/speaking/classes", { token, query: reportQuery(filters) });
    if (!response.data) throw new Error("Laporan speaking kelas tidak tersedia.");
    return paginated(response.data.classes.data, response.data.classes.meta);
  },

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
