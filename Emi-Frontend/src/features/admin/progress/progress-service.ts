import { apiClient } from "@/lib/api-client";
import { env } from "@/lib/env";

import type {
  ClassProgressFilters,
  ClassProgressRow,
  DashboardSummary,
  PaginatedResult,
  ProgressOverviewReport,
  ProgressScopeFilters,
  ClassProgressDetail,
  StudentProgressDetail,
  QuizResultFilters,
  QuizResultReport,
  QuizResultRow,
  SchoolProgressRow,
  StudentProgressRow,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

function reportQuery(filters: Record<string, string | number | undefined | null>) {
  return {
    ...filters,
    per_page: filters.per_page ?? 15,
  };
}

export const progressReportService = {
  async overview(token: string, filters: ProgressScopeFilters & { student_page?: number; student_per_page?: number; class_page?: number; class_per_page?: number } = {}) {
    const response = await apiClient.get<ProgressOverviewReport>("/admin/reports/progress/overview", { token, query: filters });
    if (!response.data) throw new Error("Overview progress tidak tersedia.");
    return response.data;
  },

  async classDetail(token: string, classId: string, filters: Pick<ProgressScopeFilters, "page" | "per_page"> = {}) {
    const response = await apiClient.get<ClassProgressDetail>(`/admin/reports/progress/classes/${classId}`, { token, query: filters });
    if (!response.data) throw new Error("Detail progress kelas tidak tersedia.");
    return response.data;
  },

  async studentDetail(token: string, studentId: string, filters: { quiz_page?: number; quiz_per_page?: number } = {}) {
    const response = await apiClient.get<StudentProgressDetail>(`/admin/reports/progress/students/${studentId}`, { token, query: filters });
    if (!response.data) throw new Error("Detail progress siswa tidak tersedia.");
    return response.data;
  },

  async downloadPdf(token: string, path: string, filters: ProgressScopeFilters = {}) {
    const url = new URL(`${env.apiBaseUrl}${path}`);
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== "") url.searchParams.set(key, String(value));
    });
    const response = await fetch(url, { headers: { Accept: "application/pdf", Authorization: `Bearer ${token}` } });
    if (!response.ok) throw new Error("PDF laporan gagal diunduh.");
    const blob = await response.blob();
    const disposition = response.headers.get("content-disposition") ?? "";
    const filename = disposition.match(/filename="?([^"]+)"?/i)?.[1] ?? "laporan-progress.pdf";
    const href = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = href;
    link.download = filename;
    link.click();
    URL.revokeObjectURL(href);
  },

  async dashboardSummary(token: string, filters: Pick<ProgressScopeFilters, "school_id" | "class_id"> = {}) {
    const response = await apiClient.get<DashboardSummary>("/admin/dashboard/summary", {
      token,
      query: {
        school_id: filters.school_id,
        class_id: filters.class_id,
      },
    });

    if (!response.data) {
      throw new Error("Ringkasan progress tidak tersedia.");
    }

    return response.data;
  },

  async schools(token: string, filters: { search?: string; page?: number; per_page?: number } = {}) {
    const response = await apiClient.get<SchoolProgressRow[]>("/admin/reports/progress/schools", {
      token,
      query: reportQuery({
        search: filters.search,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "school_name",
        sort_direction: "asc",
      }),
    });

    return paginated(response.data, response.meta);
  },

  async classes(token: string, filters: ClassProgressFilters = {}) {
    const response = await apiClient.get<ClassProgressRow[]>("/admin/reports/progress/classes", {
      token,
      query: reportQuery({
        school_id: filters.school_id,
        search: filters.search,
        status: filters.status,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "class_name",
        sort_direction: "asc",
      }),
    });

    return paginated(response.data, response.meta);
  },

  async students(token: string, filters: ProgressScopeFilters = {}) {
    const response = await apiClient.get<StudentProgressRow[]>("/admin/reports/progress/students", {
      token,
      query: reportQuery({
        school_id: filters.school_id,
        class_id: filters.class_id,
        search: filters.search,
        learning_status: filters.learning_status,
        quiz_status: filters.quiz_status,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "full_name",
        sort_direction: "asc",
      }),
    });

    return paginated(response.data, response.meta);
  },

  async quizResults(token: string, filters: QuizResultFilters = {}): Promise<QuizResultReport> {
    const response = await apiClient.get<{
      summary?: QuizResultReport["summary"];
      rows?: QuizResultRow[];
    }>("/admin/reports/quiz-results", {
      token,
      query: reportQuery({
        school_id: filters.school_id,
        class_id: filters.class_id,
        quiz_id: filters.quiz_id,
        student_id: filters.student_id,
        status: filters.status,
        page: filters.page ?? 1,
        per_page: filters.per_page ?? 15,
        sort_by: "quiz_title",
        sort_direction: "asc",
      }),
    });

    return {
      items: response.data?.rows ?? [],
      summary: response.data?.summary ?? null,
      meta: response.meta as PaginatedResult<QuizResultRow>["meta"],
    };
  },

  async downloadExport(
    token: string,
    report: "schools" | "classes" | "students" | "quiz-results",
    filters: ProgressScopeFilters | QuizResultFilters = {},
  ) {
    const path =
      report === "quiz-results"
        ? "/admin/reports/quiz-results/export"
        : `/admin/reports/progress/${report}/export`;
    const url = new URL(`${env.apiBaseUrl}${path}`);

    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== "") {
        url.searchParams.set(key, String(value));
      }
    });

    const response = await fetch(url.toString(), {
      headers: {
        Accept: "text/csv",
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error("Export laporan gagal diunduh.");
    }

    const blob = await response.blob();
    const disposition = response.headers.get("content-disposition") ?? "";
    const filenameMatch = disposition.match(/filename="?([^"]+)"?/i);

    return {
      blob,
      filename: filenameMatch?.[1] ?? `laporan-${report}.csv`,
    };
  },
};
