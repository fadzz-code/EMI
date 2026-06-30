import { apiClient } from "@/lib/api-client";

import type {
  LessonContent,
  LessonProgress,
  PaginatedResult,
  StudentDashboardSummary,
  StudentLesson,
  StudentModule,
  StudentCultureItem,
  StudentProgressReport,
  StudentChatbotResponse,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const studentService = {
  async dashboard(token: string) {
    const response = await apiClient.get<StudentDashboardSummary>("/student/dashboard/summary", {
      token,
    });

    if (!response.data) {
      throw new Error("Ringkasan dashboard siswa tidak tersedia.");
    }

    return response.data;
  },

  async sendChatbotMessage(token: string, message: string) {
    const response = await apiClient.post<StudentChatbotResponse>(
      "/student/chatbot/messages",
      { message },
      { token },
    );

    if (!response.data) {
      throw new Error("Respons Chatbot AI tidak tersedia.");
    }

    return response.data;
  },

  async modules(token: string, filters: { search?: string; status?: string } = {}) {
    const response = await apiClient.get<StudentModule[]>("/student/modules", {
      token,
      query: {
        search: filters.search,
        status: filters.status,
        per_page: 100,
        sort_by: "sort_order",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async moduleDetail(token: string, moduleId: string) {
    const response = await apiClient.get<StudentModule>(`/student/modules/${moduleId}`, {
      token,
    });

    if (!response.data) {
      throw new Error("Detail modul siswa tidak tersedia.");
    }

    return response.data;
  },

  async startModule(token: string, moduleId: string) {
    const response = await apiClient.post<unknown>(`/student/modules/${moduleId}/start`, {}, { token });

    return response.data;
  },

  async lessonDetail(token: string, lessonId: string) {
    const response = await apiClient.get<StudentLesson>(`/class-lessons/${lessonId}`, { token });

    if (!response.data) {
      throw new Error("Detail materi tidak tersedia.");
    }

    return response.data;
  },

  async lessonContent(token: string, lessonId: string) {
    const response = await apiClient.get<LessonContent>(`/class-lessons/${lessonId}/content-url`, {
      token,
    });

    if (!response.data) {
      throw new Error("Konten materi tidak tersedia.");
    }

    return response.data;
  },

  async completeLesson(token: string, lessonId: string) {
    const response = await apiClient.patch<LessonProgress>(
      `/student/lessons/${lessonId}/progress`,
      {
        status: "completed",
        progress_percent: 100,
      },
      { token },
    );

    if (!response.data) {
      throw new Error("Progress materi tidak tersedia.");
    }

    return response.data;
  },

  async culture(token: string, classId?: string) {
    const response = await apiClient.get<StudentCultureItem[]>("/student/culture", {
      token,
      query: { class_id: classId, per_page: 100 },
    });

    return paginated(response.data, response.meta);
  },

  async getStudentProgressReport(token: string) {
    const response = await apiClient.get<StudentProgressReport>("/student/reports/progress", {
      token,
    });

    return response.data;
  },

  async progressReport(token: string) {
    return this.getStudentProgressReport(token);
  },
};
