import { apiClient, apiRequest } from "@/lib/api-client";

import { mediaPurposeForContentType } from "./module-utils";
import type {
  ClassModule,
  LessonContentType,
  LessonTemplate,
  LessonTemplatePayload,
  MediaFile,
  MediaVisibility,
  ModuleTemplate,
  ModuleTemplateFilters,
  ModuleTemplatePayload,
  PaginatedResult,
  TemplateApplyResult,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const moduleTemplateService = {
  async list(token: string, filters: ModuleTemplateFilters = {}) {
    const response = await apiClient.get<ModuleTemplate[]>("/admin/module-templates", {
      token,
      query: {
        search: filters.search,
        status: filters.status,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "updated_at",
        sort_direction: "desc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async detail(token: string, moduleId: string) {
    const response = await apiClient.get<ModuleTemplate>(
      `/admin/module-templates/${moduleId}`,
      { token },
    );

    if (!response.data) {
      throw new Error("Detail modul tidak tersedia.");
    }

    return response.data;
  },

  async create(token: string, payload: ModuleTemplatePayload) {
    const response = await apiClient.post<ModuleTemplate>(
      "/admin/module-templates",
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response modul tidak tersedia.");
    }

    return response.data;
  },

  async update(token: string, moduleId: string, payload: ModuleTemplatePayload) {
    const response = await apiClient.put<ModuleTemplate>(
      `/admin/module-templates/${moduleId}`,
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response modul tidak tersedia.");
    }

    return response.data;
  },

  async delete(token: string, moduleId: string) {
    await apiClient.delete<[]>(`/admin/module-templates/${moduleId}`, { token });
  },

  async publish(token: string, moduleId: string) {
    const response = await apiClient.post<ModuleTemplate>(
      `/admin/module-templates/${moduleId}/publish`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Respons terbit modul tidak tersedia.");
    }

    return response.data;
  },

  async archive(token: string, moduleId: string) {
    const response = await apiClient.post<ModuleTemplate>(
      `/admin/module-templates/${moduleId}/archive`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Response archive modul tidak tersedia.");
    }

    return response.data;
  },

  async applyToClasses(token: string, moduleId: string, classIds: string[]) {
    const response = await apiClient.post<TemplateApplyResult>(
      `/admin/module-templates/${moduleId}/apply`,
      { class_ids: classIds },
      { token },
    );

    if (!response.data) {
      throw new Error("Response penerapan modul tidak tersedia.");
    }

    return response.data;
  },

  async publishClassModule(token: string, classModuleId: string) {
    const response = await apiClient.post<ClassModule>(
      `/class-modules/${classModuleId}/publish`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Response publish modul kelas tidak tersedia.");
    }

    return response.data;
  },
};

export const lessonTemplateService = {
  async list(token: string, moduleId: string) {
    const response = await apiClient.get<LessonTemplate[]>(
      `/admin/module-templates/${moduleId}/lessons`,
      {
        token,
        query: {
          page: 1,
          per_page: 100,
        },
      },
    );

    return paginated(response.data, response.meta);
  },

  async create(token: string, moduleId: string, payload: LessonTemplatePayload) {
    const response = await apiClient.post<LessonTemplate>(
      `/admin/module-templates/${moduleId}/lessons`,
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response materi tidak tersedia.");
    }

    return response.data;
  },

  async update(token: string, lessonId: string, payload: LessonTemplatePayload) {
    const response = await apiClient.put<LessonTemplate>(
      `/admin/lesson-templates/${lessonId}`,
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response materi tidak tersedia.");
    }

    return response.data;
  },

  async delete(token: string, lessonId: string) {
    await apiClient.delete<[]>(`/admin/lesson-templates/${lessonId}`, { token });
  },

  async publish(token: string, lessonId: string) {
    const response = await apiClient.post<LessonTemplate>(
      `/admin/lesson-templates/${lessonId}/publish`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Response publish materi tidak tersedia.");
    }

    return response.data;
  },

  async archive(token: string, lessonId: string) {
    const response = await apiClient.post<LessonTemplate>(
      `/admin/lesson-templates/${lessonId}/archive`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Response archive materi tidak tersedia.");
    }

    return response.data;
  },

  async reorder(token: string, moduleId: string, lessonIds: string[]) {
    await apiClient.patch<[]>(
      `/admin/module-templates/${moduleId}/lessons/reorder`,
      { lesson_ids: lessonIds },
      { token },
    );
  },

  async uploadMedia(
    token: string,
    contentType: LessonContentType,
    file: File,
    visibility: MediaVisibility,
  ) {
    const purpose = mediaPurposeForContentType(contentType);

    if (!purpose) {
      throw new Error("Tipe materi ini tidak memakai upload media.");
    }

    const formData = new FormData();
    formData.append("file", file, file.name);
    formData.append("purpose", purpose);
    formData.append("visibility", visibility);

    const response = await apiRequest<MediaFile>("/media", {
      method: "POST",
      body: formData,
      token,
      timeoutMs: 60_000,
    });

    if (!response.data) {
      throw new Error("Response upload media tidak tersedia.");
    }

    return response.data;
  },
};
