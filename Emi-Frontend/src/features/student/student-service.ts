import { apiClient } from "@/lib/api-client";

import type {
  ChatbotConversationDetail,
  ChatbotConversationSummary,
  LessonContent,
  LessonProgress,
  PaginatedResult,
  StudentDashboardSummary,
  StudentLesson,
  StudentModule,
  StudentCultureItem,
  StudentProgressReport,
  StudentChatbotResponse,
  SpeakingAttempt,
  SpeakingExercise,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export function speakingAttemptForm(file: File, captureSource: "web_microphone" | "web_esp32_serial", duration?: number) {
  const formData = new FormData();
  formData.append("file", file, file.name);
  formData.append("capture_source", captureSource);
  if (duration !== undefined && duration >= 1) formData.append("audio_duration_seconds", String(Math.floor(duration)));
  return formData;
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

  async sendChatbotMessage(token: string, message: string, conversationId?: string | null) {
    const response = await apiClient.post<StudentChatbotResponse>(
      "/student/chatbot/messages",
      { message, conversation_id: conversationId ?? undefined },
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

  async speakingExercises(token: string) {
    const response = await apiClient.get<SpeakingExercise[]>("/student/speaking/exercises", { token });
    return response.data ?? [];
  },

  async speakingAttempts(token: string, page = 1) {
    const response = await apiClient.get<SpeakingAttempt[]>("/student/speaking/attempts", { token, query: { page, per_page: 100 } });
    return paginated(response.data, response.meta);
  },

  async speakingAttemptDetail(token: string, attemptId: string) {
    const response = await apiClient.get<SpeakingAttempt>(`/student/speaking/attempts/${attemptId}`, { token });
    if (!response.data) throw new Error("Detail percobaan speaking tidak tersedia.");
    return response.data;
  },

  async submitSpeakingAttempt(token: string, exerciseId: string, file: File, captureSource: "web_microphone" | "web_esp32_serial" = "web_microphone", duration?: number) {
    const formData = speakingAttemptForm(file, captureSource, duration);

    const response = await apiClient.post<SpeakingAttempt>(
      `/student/speaking/exercises/${exerciseId}/attempts`,
      formData,
      { token, timeoutMs: 60_000 },
    );

    if (!response.data) throw new Error("Percobaan speaking tidak tersedia.");
    return response.data;
  },

  async temporaryMediaUrl(token: string, mediaId: string) {
    const response = await apiClient.post<{ url: string; expires_at: string }>(
      `/media/${mediaId}/temporary-url`,
      { expires_in_minutes: 15, disposition: "inline" },
      { token },
    );

    if (!response.data) {
      throw new Error("URL audio tidak tersedia.");
    }

    return response.data.url;
  },

  async chatbotConversations(token: string, status?: "active" | "archived") {
    const response = await apiClient.get<ChatbotConversationSummary[]>("/student/chatbot/conversations", {
      token,
      query: { status, per_page: 30 },
    });

    return paginated(response.data, response.meta);
  },

  async chatbotConversationDetail(token: string, conversationId: string) {
    const response = await apiClient.get<ChatbotConversationDetail>(`/student/chatbot/conversations/${conversationId}`, { token });

    if (!response.data) {
      throw new Error("Detail percakapan tidak tersedia.");
    }

    return response.data;
  },

  async deleteChatbotConversation(token: string, conversationId: string) {
    await apiClient.delete(`/student/chatbot/conversations/${conversationId}`, { token });
  },
};
