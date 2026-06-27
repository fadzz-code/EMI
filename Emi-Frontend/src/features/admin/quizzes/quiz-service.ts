import { apiClient, apiRequest } from "@/lib/api-client";

import type {
  ClassQuiz,
  MediaFile,
  PaginatedResult,
  QuizQuestionPayload,
  QuizTemplate,
  QuizTemplateApplyResult,
  QuizTemplateFilters,
  QuizTemplatePayload,
  QuizTemplateQuestion,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const quizTemplateService = {
  async list(token: string, filters: QuizTemplateFilters = {}) {
    const response = await apiClient.get<QuizTemplate[]>("/admin/quiz-templates", {
      token,
      query: {
        search: filters.search,
        status: filters.status,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "created_at",
        sort_direction: "desc",
      },
    });

    return paginated(response.data, response.meta);
  },

  async detail(token: string, quizId: string) {
    const response = await apiClient.get<QuizTemplate>(`/admin/quiz-templates/${quizId}`, {
      token,
    });

    if (!response.data) {
      throw new Error("Detail kuis tidak tersedia.");
    }

    return response.data;
  },

  async create(token: string, payload: QuizTemplatePayload) {
    const response = await apiClient.post<QuizTemplate>(
      "/admin/quiz-templates",
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response kuis tidak tersedia.");
    }

    return response.data;
  },

  async update(token: string, quizId: string, payload: QuizTemplatePayload) {
    const response = await apiClient.put<QuizTemplate>(
      `/admin/quiz-templates/${quizId}`,
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response kuis tidak tersedia.");
    }

    return response.data;
  },

  async delete(token: string, quizId: string) {
    await apiClient.delete<[]>(`/admin/quiz-templates/${quizId}`, { token });
  },

  async publish(token: string, quizId: string) {
    const response = await apiClient.post<QuizTemplate>(
      `/admin/quiz-templates/${quizId}/publish`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Respons terbit kuis tidak tersedia.");
    }

    return response.data;
  },

  async archive(token: string, quizId: string) {
    const response = await apiClient.post<QuizTemplate>(
      `/admin/quiz-templates/${quizId}/archive`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Response archive kuis tidak tersedia.");
    }

    return response.data;
  },

  async applyToClasses(token: string, quizId: string, classIds: string[]) {
    const response = await apiClient.post<QuizTemplateApplyResult>(
      `/admin/quiz-templates/${quizId}/apply`,
      { class_ids: classIds },
      { token },
    );

    if (!response.data) {
      throw new Error("Response penerapan kuis tidak tersedia.");
    }

    return response.data;
  },

  async publishClassQuiz(token: string, classQuizId: string) {
    const response = await apiClient.post<ClassQuiz>(
      `/class-quizzes/${classQuizId}/publish`,
      {},
      { token },
    );

    if (!response.data) {
      throw new Error("Response publish kuis kelas tidak tersedia.");
    }

    return response.data;
  },
};

export const quizQuestionService = {
  async list(token: string, quizId: string) {
    const response = await apiClient.get<QuizTemplateQuestion[]>(
      `/admin/quiz-templates/${quizId}/questions`,
      { token },
    );

    return response.data ?? [];
  },

  async create(token: string, quizId: string, payload: QuizQuestionPayload) {
    const response = await apiClient.post<QuizTemplateQuestion>(
      `/admin/quiz-templates/${quizId}/questions`,
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response soal tidak tersedia.");
    }

    return response.data;
  },

  async update(token: string, questionId: string, payload: QuizQuestionPayload) {
    const response = await apiClient.put<QuizTemplateQuestion>(
      `/admin/quiz-template-questions/${questionId}`,
      payload,
      { token },
    );

    if (!response.data) {
      throw new Error("Response soal tidak tersedia.");
    }

    return response.data;
  },

  async delete(token: string, questionId: string) {
    await apiClient.delete<[]>(`/admin/quiz-template-questions/${questionId}`, { token });
  },

  async reorder(token: string, quizId: string, questionIds: string[]) {
    await apiClient.patch<[]>(
      `/admin/quiz-templates/${quizId}/questions/reorder`,
      { question_ids: questionIds },
      { token },
    );
  },

  async uploadQuestionImage(token: string, file: File) {
    const formData = new FormData();
    formData.append("file", file, file.name);
    formData.append("purpose", "question_image");
    formData.append("visibility", "public");

    const response = await apiRequest<MediaFile>("/media", {
      method: "POST",
      body: formData,
      token,
      timeoutMs: 60_000,
    });

    if (!response.data) {
      throw new Error("Response upload gambar tidak tersedia.");
    }

    return response.data;
  },
};
