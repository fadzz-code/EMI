import { apiClient, type ApiPaginationMeta } from "@/lib/api-client";
import type { AdminCultureTemplate, AdminCultureTemplateItem } from "./types";
import type { MediaFile } from "@/features/admin/quizzes/types";

export const adminCultureService = {
  async getTemplates(token: string, search?: string) {
    const response = await apiClient.get<AdminCultureTemplate[]>("/admin/culture-templates", {
      token,
      query: { search, per_page: 50 },
    });
    return {
      items: response.data ?? [],
      meta: response.meta as ApiPaginationMeta,
    };
  },

  async getTemplate(token: string, templateId: string) {
    const response = await apiClient.get<AdminCultureTemplate>(`/admin/culture-templates/${templateId}`, { token });
    if (!response.data) throw new Error("Template tidak ditemukan");
    return response.data;
  },

  async createTemplate(token: string, payload: { title: string; description?: string }) {
    const response = await apiClient.post<AdminCultureTemplate>("/admin/culture-templates", payload, { token });
    if (!response.data) throw new Error("Gagal membuat template");
    return response.data;
  },

  async updateTemplate(token: string, templateId: string, payload: Partial<AdminCultureTemplate>) {
    const response = await apiClient.put<AdminCultureTemplate>(`/admin/culture-templates/${templateId}`, payload, { token });
    if (!response.data) throw new Error("Gagal menyimpan template");
    return response.data;
  },

  async publishTemplate(token: string, templateId: string) {
    const response = await apiClient.post<AdminCultureTemplate>(`/admin/culture-templates/${templateId}/publish`, {}, { token });
    if (!response.data) throw new Error("Gagal mempublikasikan template");
    return response.data;
  },

  async applyTemplate(token: string, templateId: string, classIds: string[]) {
    const response = await apiClient.post<{ applied: unknown[]; skipped: unknown[]; failed: unknown[] }>(`/admin/culture-templates/${templateId}/apply`, { class_ids: classIds }, { token });
    if (!response.data) throw new Error("Gagal menerapkan template");
    return response.data;
  },

  async deleteTemplate(token: string, templateId: string) {
    await apiClient.delete(`/admin/culture-templates/${templateId}`, { token });
  },

  async createItem(token: string, templateId: string, payload: Partial<AdminCultureTemplateItem>) {
    const response = await apiClient.post<AdminCultureTemplateItem>(`/admin/culture-templates/${templateId}/items`, payload, { token });
    if (!response.data) throw new Error("Gagal membuat item");
    return response.data;
  },

  async updateItem(token: string, itemId: string, payload: Partial<AdminCultureTemplateItem>) {
    const response = await apiClient.put<AdminCultureTemplateItem>(`/admin/culture-template-items/${itemId}`, payload, { token });
    if (!response.data) throw new Error("Gagal menyimpan item");
    return response.data;
  },

  async deleteItem(token: string, itemId: string) {
    await apiClient.delete(`/admin/culture-template-items/${itemId}`, { token });
  },

  async uploadMedia(token: string, file: File) {
    const formData = new FormData();
    formData.append("file", file, file.name);
    formData.append("purpose", "culture_media");
    formData.append("visibility", "public");

    const response = await apiClient.post<MediaFile>("/media", formData, { token, timeoutMs: 60_000 });
    if (!response.data) throw new Error("Upload gagal");
    return response.data;
  }
};
