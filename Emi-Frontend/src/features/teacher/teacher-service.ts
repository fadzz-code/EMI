import { apiClient } from "@/lib/api-client";

import type {
  PaginatedResult,
  TeacherClass,
  TeacherClassLesson,
  TeacherClassModule,
  TeacherClassQuiz,
  TeacherClassStudent,
  TeacherDashboardSummary,
  TeacherProgressStudentRow,
  TeacherQuizAttempt,
  TeacherUserProfile,
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

  async classStudents(token: string, classId: string) {
    const response = await apiClient.get<TeacherClassStudent[]>(`/classes/${classId}/students`, {
      token,
      query: {
        per_page: 100,
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

  async updateClassModule(token: string, moduleId: string, payload: Partial<TeacherClassModule>) {
    const response = await apiClient.put<TeacherClassModule>(`/class-modules/${moduleId}`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal memperbarui modul.");
    }

    return response.data;
  },

  async publishClassModule(token: string, moduleId: string) {
    const response = await apiClient.post<TeacherClassModule>(`/class-modules/${moduleId}/publish`, {}, { token });

    if (!response.data) {
      throw new Error("Gagal mempublikasikan modul.");
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

  async updateClassLesson(token: string, lessonId: string, payload: Partial<TeacherClassLesson>) {
    const response = await apiClient.put<TeacherClassLesson>(`/class-lessons/${lessonId}`, payload, { token });

    if (!response.data) {
      throw new Error("Gagal memperbarui materi.");
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

  async quizDetail(token: string, quizId: string) {
    const response = await apiClient.get<TeacherClassQuiz>(`/class-quizzes/${quizId}`, { token });

    if (!response.data) {
      throw new Error("Detail kuis kelas tidak tersedia.");
    }

    return response.data;
  },

  async quizAttempts(token: string, quizId: string) {
    const response = await apiClient.get<TeacherQuizAttempt[]>(`/class-quizzes/${quizId}/attempts`, {
      token,
      query: {
        per_page: 100,
      },
    });

    return paginated(response.data, response.meta);
  },

  async studentProgress(token: string) {
    const response = await apiClient.get<TeacherProgressStudentRow[]>(
      "/teacher/reports/progress/students",
      {
        token,
        query: {
          per_page: 100,
          sort_by: "full_name",
          sort_direction: "asc",
        },
      },
    );

    return paginated(response.data, response.meta);
  },

  async studentDetail(token: string, studentId: string) {
    const response = await apiClient.get<TeacherProgressStudentRow[]>(
      "/teacher/reports/progress/students",
      {
        token,
        query: {
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

  async uploadMedia(token: string, file: File, purpose: string) {
    const formData = new FormData();
    formData.append("file", file);
    formData.append("purpose", purpose);
    formData.append("visibility", "private");

    const response = await apiClient.post<{ id: string; url: string; mime_type: string }>(
      "/media",
      formData,
      { token }
    );

    if (!response.data) {
      throw new Error("Gagal mengunggah media.");
    }

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
};
