import { apiClient } from "@/lib/api-client";

import type { PaginatedResult, QuizAttempt, StudentQuiz, StudentQuizResultsReport } from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const studentQuizService = {
  async quizzes(token: string, filters: { page?: number; per_page?: number } = {}) {
    const response = await apiClient.get<StudentQuiz[]>("/student/quizzes", {
      token,
      query: {
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 12,
      },
    });

    return paginated(response.data, response.meta);
  },

  async attempts(token: string, quizId: string, filters: { page?: number; per_page?: number } = {}) {
    const response = await apiClient.get<QuizAttempt[]>(`/student/quizzes/${quizId}/attempts`, {
      token,
      query: { page: filters.page ?? 1, per_page: filters.per_page ?? 5 },
    });

    return paginated(response.data, response.meta);
  },

  async detail(token: string, quizId: string) {
    const response = await apiClient.get<StudentQuiz>(`/student/quizzes/${quizId}`, {
      token,
    });

    if (!response.data) {
      throw new Error("Detail kuis tidak tersedia.");
    }

    return response.data;
  },

  async startAttempt(token: string, quizId: string) {
    const response = await apiClient.post<QuizAttempt>(`/class-quizzes/${quizId}/attempts`, {}, { token });

    if (!response.data) {
      throw new Error("Gagal memulai attempt kuis.");
    }

    return response.data;
  },

  async attemptDetail(token: string, attemptId: string) {
    const response = await apiClient.get<QuizAttempt>(`/quiz-attempts/${attemptId}`, {
      token,
    });

    if (!response.data) {
      throw new Error("Detail attempt tidak tersedia.");
    }

    return response.data;
  },

  async getStudentQuizResultsReport(token: string, filters: { quiz_id?: string; page?: number; per_page?: number } = {}) {
    const response = await apiClient.get<StudentQuizResultsReport>("/student/reports/quiz-results", {
      token,
      query: {
        quiz_id: filters.quiz_id,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 12,
      },
    });

    return response.data;
  },

  async saveAnswer(token: string, attemptId: string, questionId: string, payload: { selected_option_id?: string; answer_text?: string }) {
    const response = await apiClient.put<unknown>(
      `/quiz-attempts/${attemptId}/answers/${questionId}`,
      payload,
      { token },
    );

    return response.data;
  },

  async submitAttempt(token: string, attemptId: string, idempotencyKey: string) {
    const response = await apiClient.post<QuizAttempt>(
      `/quiz-attempts/${attemptId}/submit`,
      {},
      {
        token,
        headers: {
          "Idempotency-Key": idempotencyKey,
        },
      },
    );

    if (!response.data) {
      throw new Error("Gagal mengumpulkan kuis.");
    }

    return response.data;
  },
};
