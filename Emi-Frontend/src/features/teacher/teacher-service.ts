import { apiClient } from "@/lib/api-client";
import type { ChatbotConversationDetail, ChatbotConversationSummary, DictionaryEntry, DictionaryEntryFilters, StudentChatbotResponse } from "@/features/student/types";

import { teacherProgressRequestQuery } from "./teacher-workflow";
import type {
  PaginatedResult,
  TeacherClass,
  TeacherClassLesson,
  TeacherClassModule,
  TeacherClassQuiz,
  TeacherCultureItem,
  TeacherCulturePayload,
  TeacherClassStudent,
  TeacherDashboardSummary,
  TeacherProgressClassSummary,
  TeacherProgressStudentRow,
  TeacherMediaFile,
  TeacherLessonContent,
  TeacherLessonPayload,
  TeacherMediaPurpose,
  TeacherMediaVisibility,
  TeacherQuizAttempt,
  TeacherQuizQuestion,
  TeacherQuizReport,
  TeacherQuizResultRow,
  TeacherUserProfile,
  TeacherSpeakingAttempt,
  TeacherSpeakingExercise,
  TeacherSpeakingExercisePayload,
  TeacherSpeakingTemplate,
  SpeakingFeedbackRequest,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const teacherService = {
  async dashboard(token: string) {
    const response = await apiClient.get<TeacherDashboardSummary>("/teacher/dashboard/summary", {
      token,
    });

    if (!response.data) {
      throw new Error("Ringkasan dashboard guru tidak tersedia.");
    }

    return response.data;
  },

  async classes(token: string) {
    const response = await apiClient.get<TeacherClass[]>("/classes", {
      token,
      query: {
        per_page: 10,
        sort_by: "name",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async classDetail(token: string, classId: string) {
    const response = await apiClient.get<TeacherClass>(`/classes/${classId}`, { token });

    if (!response.data) {
      throw new Error("Detail kelas tidak tersedia.");
    }

    return response.data;
  },

  async classStudents(token: string, classId: string, query: { page?: number; per_page?: number; search?: string } = {}) {
    const response = await apiClient.get<TeacherClassStudent[]>(`/classes/${classId}/students`, {
      token,
      query: {
        page: query.page,
        per_page: query.per_page ?? 12,
        search: query.search,
        sort_by: "full_name",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async classModules(token: string, classId: string) {
    const response = await apiClient.get<TeacherClassModule[]>(`/classes/${classId}/modules`, {
      token,
      query: {
        per_page: 100,
        sort_by: "sort_order",
        sort_direction: "asc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async classModuleDetail(token: string, moduleId: string) {
    const response = await apiClient.get<TeacherClassModule>(`/class-modules/${moduleId}`, { token });

    if (!response.data) {
      throw new Error("Detail modul kelas tidak tersedia.");
    }

    return response.data;
  },

  async createClassModule(token: string, classId: string, payload: { title: string; description?: string | null; sort_order?: number }) {
    const response = await apiClient.post<TeacherClassModule>(`/classes/${classId}/modules`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal membuat modul.");
    }

    return response.data;
  },

  async updateClassModule(token: string, moduleId: string, payload: Partial<TeacherClassModule>) {
    const response = await apiClient.put<TeacherClassModule>(`/class-modules/${moduleId}`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal memperbarui modul.");
    }

    return response.data;
  },

  async deleteClassModule(token: string, moduleId: string) {
    await apiClient.delete(`/class-modules/${moduleId}`, { token });
  },

  async publishClassModule(token: string, moduleId: string) {
    const response = await apiClient.post<TeacherClassModule>(`/class-modules/${moduleId}/publish`, {}, { token });

    if (!response.data) {
      throw new Error("Gagal mempublikasikan modul.");
    }

    return response.data;
  },

  async archiveClassModule(token: string, moduleId: string) {
    const response = await apiClient.post<TeacherClassModule>(`/class-modules/${moduleId}/archive`, {}, { token });

    if (!response.data) {
      throw new Error("Gagal mengarsipkan modul.");
    }

    return response.data;
  },

  async createClassLesson(token: string, moduleId: string, payload: TeacherLessonPayload) {
    const response = await apiClient.post<TeacherClassLesson>(`/class-modules/${moduleId}/lessons`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal membuat materi.");
    }

    return response.data;
  },

  async classLessonDetail(token: string, lessonId: string) {
    const response = await apiClient.get<TeacherClassLesson>(`/class-lessons/${lessonId}`, { token });

    if (!response.data) {
      throw new Error("Detail materi tidak tersedia.");
    }

    return response.data;
  },

  async updateClassLesson(token: string, lessonId: string, payload: TeacherLessonPayload) {
    const response = await apiClient.put<TeacherClassLesson>(`/class-lessons/${lessonId}`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal memperbarui materi.");
    }

    return response.data;
  },

  async deleteClassLesson(token: string, lessonId: string) {
    await apiClient.delete(`/class-lessons/${lessonId}`, { token });
  },

  async archiveClassLesson(token: string, lessonId: string) {
    const response = await apiClient.post<TeacherClassLesson>(`/class-lessons/${lessonId}/archive`, {}, { token });

    if (!response.data) {
      throw new Error("Gagal mengarsipkan materi.");
    }

    return response.data;
  },

  async classLessonContent(token: string, lessonId: string) {
    const response = await apiClient.get<TeacherLessonContent>(`/class-lessons/${lessonId}/content-url`, { token });

    if (!response.data) {
      throw new Error("Konten materi tidak tersedia.");
    }

    return response.data;
  },

  async publishClassLesson(token: string, lessonId: string) {
    const response = await apiClient.post<TeacherClassLesson>(`/class-lessons/${lessonId}/publish`, {}, { token });

    if (!response.data) {
      throw new Error("Gagal mempublikasikan materi.");
    }

    return response.data;
  },

  async classQuizzes(token: string, classId: string) {
    const response = await apiClient.get<TeacherClassQuiz[]>("/class-quizzes", {
      token,
      query: {
        class_id: classId,
        per_page: 100,
      },
    });

    return paginated(response.data, response.meta);
  },

  async classCulture(token: string, classId: string) {
    const response = await apiClient.get<TeacherCultureItem[]>(`/classes/${classId}/culture`, {
      token,
      query: { per_page: 100, sort_by: "display_order", sort_direction: "asc" },
    });

    return paginated(response.data, response.meta);
  },

  async createClassCulture(token: string, classId: string, payload: TeacherCulturePayload) {
    const response = await apiClient.post<TeacherCultureItem>(`/classes/${classId}/culture`, payload, { token });
    if (!response.data) throw new Error("Gagal membuat Budaya Mekongga.");
    return response.data;
  },

  async updateClassCulture(token: string, itemId: string, payload: TeacherCulturePayload) {
    const response = await apiClient.put<TeacherCultureItem>(`/class-culture-items/${itemId}`, payload, { token });
    if (!response.data) throw new Error("Gagal memperbarui Budaya Mekongga.");
    return response.data;
  },

  async deleteClassCulture(token: string, itemId: string) {
    await apiClient.delete(`/class-culture-items/${itemId}`, { token });
  },

  async publishClassCulture(token: string, itemId: string) {
    const response = await apiClient.post<TeacherCultureItem>(`/class-culture-items/${itemId}/publish`, {}, { token });
    if (!response.data) throw new Error("Gagal mempublikasikan Budaya Mekongga.");
    return response.data;
  },

  async archiveClassCulture(token: string, itemId: string) {
    const response = await apiClient.post<TeacherCultureItem>(`/class-culture-items/${itemId}/archive`, {}, { token });
    if (!response.data) throw new Error("Gagal mengarsipkan Budaya Mekongga.");
    return response.data;
  },

  async uploadCultureMedia(token: string, file: File) {
    return this.uploadMedia(token, file, "culture_media", "public");
  },

  async quizzes(token: string) {
    const response = await apiClient.get<TeacherClassQuiz[]>("/class-quizzes", {
      token,
      query: {
        per_page: 100,
        sort_by: "created_at",
        sort_direction: "desc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async quizDetail(token: string, quizId: string) {
    const response = await apiClient.get<TeacherClassQuiz>(`/class-quizzes/${quizId}`, { token });

    if (!response.data) {
      throw new Error("Detail kuis kelas tidak tersedia.");
    }

    return response.data;
  },

  async createQuiz(token: string, payload: Partial<TeacherClassQuiz>) {
    const response = await apiClient.post<TeacherClassQuiz>("/class-quizzes", payload, { token });

    if (!response.data) {
      throw new Error("Gagal membuat kuis.");
    }

    return response.data;
  },

  async updateQuiz(token: string, quizId: string, payload: Partial<TeacherClassQuiz>) {
    const response = await apiClient.put<TeacherClassQuiz>(`/class-quizzes/${quizId}`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal memperbarui kuis.");
    }

    return response.data;
  },

  async deleteQuiz(token: string, quizId: string) {
    await apiClient.delete(`/class-quizzes/${quizId}`, { token });
  },

  async archiveQuiz(token: string, quizId: string) {
    const response = await apiClient.post<TeacherClassQuiz>(`/class-quizzes/${quizId}/archive`, {}, { token });
    if (!response.data) throw new Error("Gagal mengarsipkan kuis.");
    return response.data;
  },

  async publishQuiz(token: string, quizId: string) {
    const response = await apiClient.post<TeacherClassQuiz>(`/class-quizzes/${quizId}/publish`, {}, { token });

    if (!response.data) {
      throw new Error("Gagal mempublikasikan kuis.");
    }

    return response.data;
  },

  async createQuizQuestion(token: string, quizId: string, payload: Partial<TeacherQuizQuestion>) {
    const response = await apiClient.post<TeacherQuizQuestion>(`/class-quizzes/${quizId}/questions`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal menambah soal.");
    }

    return response.data;
  },

  async updateQuizQuestion(token: string, questionId: string, payload: Partial<TeacherQuizQuestion>) {
    const response = await apiClient.put<TeacherQuizQuestion>(`/quiz-questions/${questionId}`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal memperbarui soal.");
    }

    return response.data;
  },

  async deleteQuizQuestion(token: string, questionId: string) {
    await apiClient.delete(`/quiz-questions/${questionId}`, { token });
  },

  async quizAttempts(token: string, quizId: string, query?: { status?: string; page?: number; per_page?: number }) {
    const response = await apiClient.get<TeacherQuizAttempt[]>(`/class-quizzes/${quizId}/attempts`, {
      token,
      query: {
        per_page: query?.per_page ?? 100,
        page: query?.page,
        status: query?.status,
      },
    });

    return paginated(response.data, response.meta);
  },

  async quizAttemptDetail(token: string, attemptId: string) {
    const response = await apiClient.get<TeacherQuizAttempt>(`/quiz-attempts/${attemptId}`, { token });

    if (!response.data) {
      throw new Error("Detail attempt tidak tersedia.");
    }

    return response.data;
  },

  async quizReport(token: string, quizId: string) {
    const response = await apiClient.get<TeacherQuizReport>(`/class-quizzes/${quizId}/report`, { token });

    if (!response.data) {
      throw new Error("Laporan kuis tidak tersedia.");
    }

    return response.data;
  },

  async classProgress(token: string, classId: string) {
    const response = await apiClient.get<{ class: { id: string; name: string }; summary: TeacherProgressClassSummary }>(
      "/teacher/reports/progress/class",
      { token, query: { class_id: classId } },
    );
    if (!response.data) throw new Error("Ringkasan progress kelas tidak tersedia.");
    return response.data;
  },

  async studentProgress(token: string, query: { class_id: string; page?: number; per_page?: number; search?: string } ) {
    const response = await apiClient.get<TeacherProgressStudentRow[]>(
      "/teacher/reports/progress/students",
      {
        token,
        query: teacherProgressRequestQuery(query),
      },
    );

    return paginated(response.data, response.meta);
  },

  async studentDetail(token: string, studentId: string, classId: string) {
    const response = await apiClient.get<TeacherProgressStudentRow[]>(
      "/teacher/reports/progress/students",
      {
        token,
        query: {
          class_id: classId,
          per_page: 1,
          student_id: studentId,
        },
      },
    );

    const student = response.data?.[0];
    if (!student) {
      throw new Error("Detail siswa tidak tersedia atau bukan berada di kelas Anda.");
    }

    return student;
  },

  async studentQuizHistory(token: string, studentId: string) {
    const response = await apiClient.get<{ rows?: TeacherQuizResultRow[] }>(
      "/teacher/reports/quiz-results",
      {
        token,
        query: { student_id: studentId, per_page: 100 },
      },
    );

    return response.data?.rows ?? [];
  },

  async uploadMedia(token: string, file: File, purpose: TeacherMediaPurpose, visibility: TeacherMediaVisibility = "private") {
    const formData = new FormData();
    formData.append("file", file, file.name);
    formData.append("purpose", purpose);
    formData.append("visibility", visibility);

    const response = await apiClient.post<TeacherMediaFile>(
      "/media",
      formData,
      { token, timeoutMs: 60_000 }
    );

    if (!response.data) {
      throw new Error("Gagal mengunggah media.");
    }

    return response.data;
  },

  async uploadQuestionImage(token: string, file: File) {
    return this.uploadMedia(token, file, "question_image", "public");
  },

  async uploadSpeakingReferenceAudio(token: string, file: File) {
    return this.uploadMedia(token, file, "speaking_reference_audio", "public");
  },

  async mediaDetail(token: string, mediaId: string) {
    const response = await apiClient.get<TeacherMediaFile>(`/media/${mediaId}`, { token });

    if (!response.data) {
      throw new Error("Detail media tidak tersedia.");
    }

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

  async speakingTemplates(token: string) {
    const response = await apiClient.get<TeacherSpeakingTemplate[]>("/teacher/speaking/templates", {
      token,
      query: { per_page: 100 },
    });

    return paginated(response.data, response.meta);
  },

  async speakingExercises(token: string, filters: { classroom_id?: string; status?: string } = {}) {
    const response = await apiClient.get<TeacherSpeakingExercise[]>("/teacher/speaking/exercises", {
      token,
      query: {
        per_page: 100,
        classroom_id: filters.classroom_id,
        status: filters.status,
      },
    });

    return paginated(response.data, response.meta);
  },

  async createSpeakingExercise(token: string, payload: TeacherSpeakingExercisePayload) {
    const response = await apiClient.post<TeacherSpeakingExercise>("/teacher/speaking/exercises", payload, { token });
    if (!response.data) throw new Error("Target speaking tidak tersedia.");
    return response.data;
  },

  async updateSpeakingExercise(token: string, exerciseId: string, payload: TeacherSpeakingExercisePayload) {
    const response = await apiClient.patch<TeacherSpeakingExercise>(`/teacher/speaking/exercises/${exerciseId}`, payload, { token });
    if (!response.data) throw new Error("Target speaking tidak tersedia.");
    return response.data;
  },

  async archiveSpeakingExercise(token: string, exerciseId: string) {
    const response = await apiClient.patch<TeacherSpeakingExercise>(`/teacher/speaking/exercises/${exerciseId}/archive`, {}, { token });
    if (!response.data) throw new Error("Target speaking tidak tersedia.");
    return response.data;
  },

  async speakingExerciseDetail(token: string, exerciseId: string) {
    const response = await apiClient.get<TeacherSpeakingExercise>(`/teacher/speaking/exercises/${exerciseId}`, { token });
    if (!response.data) throw new Error("Target speaking tidak tersedia.");
    return response.data;
  },

  async deleteSpeakingExercise(token: string, exerciseId: string) {
    await apiClient.delete(`/teacher/speaking/exercises/${exerciseId}`, { token });
  },

  async speakingAttempts(token: string) {
    const response = await apiClient.get<TeacherSpeakingAttempt[]>("/teacher/speaking/attempts", { token });
    return response.data ?? [];
  },

  async speakingAttemptDetail(token: string, attemptId: string) {
    const response = await apiClient.get<TeacherSpeakingAttempt>(`/teacher/speaking/attempts/${attemptId}`, { token });
    if (!response.data) throw new Error("Detail hasil speaking tidak tersedia.");
    return response.data;
  },

  async submitSpeakingFeedback(token: string, attemptId: string, payload: SpeakingFeedbackRequest) {
    const response = await apiClient.patch<TeacherSpeakingAttempt>(
      `/teacher/speaking/attempts/${attemptId}/feedback`,
      payload,
      { token },
    );
    if (!response.data) throw new Error("Feedback speaking tidak tersedia.");
    return response.data;
  },

  async profile(token: string) {
    const response = await apiClient.get<TeacherUserProfile>("/auth/me", { token });

    if (!response.data) {
      throw new Error("Profil guru tidak tersedia.");
    }

    return response.data;
  },

  async updateProfile(token: string, payload: { full_name: string; phone?: string | null }) {
    const response = await apiClient.patch<TeacherUserProfile>("/auth/me", payload, { token });

    if (!response.data) {
      throw new Error("Profil guru tidak tersedia.");
    }

    return response.data;
  },

  async sendChatbotMessage(token: string, message: string, conversationId?: string | null) {
    const response = await apiClient.post<StudentChatbotResponse>(
      "/teacher/chatbot/messages",
      { message, conversation_id: conversationId ?? undefined },
      { token },
    );

    if (!response.data) {
      throw new Error("Respons Chatbot AI tidak tersedia.");
    }

    return response.data;
  },

  async chatbotConversations(token: string, status?: "active" | "archived") {
    const response = await apiClient.get<ChatbotConversationSummary[]>("/teacher/chatbot/conversations", {
      token,
      query: { status, per_page: 30 },
    });

    return paginated(response.data, response.meta);
  },

  async chatbotConversationDetail(token: string, conversationId: string) {
    const response = await apiClient.get<ChatbotConversationDetail>(`/teacher/chatbot/conversations/${conversationId}`, { token });

    if (!response.data) {
      throw new Error("Detail percakapan tidak tersedia.");
    }

    return response.data;
  },

  async deleteChatbotConversation(token: string, conversationId: string) {
    await apiClient.delete(`/teacher/chatbot/conversations/${conversationId}`, { token });
  },

  async dictionaryEntries(token: string, filters: DictionaryEntryFilters = {}) {
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

  async dictionaryEntryDetail(token: string, entryId: string) {
    const response = await apiClient.get<DictionaryEntry>(`/dictionary/${entryId}`, { token });

    if (!response.data) {
      throw new Error("Detail kamus tidak tersedia.");
    }

    return response.data;
  },
};
