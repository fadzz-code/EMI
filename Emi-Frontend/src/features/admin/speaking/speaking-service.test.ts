import { beforeEach, describe, expect, it, vi } from "vitest";

const { get } = vi.hoisted(() => ({ get: vi.fn() }));
vi.mock("@/lib/api-client", () => ({ apiClient: { get } }));

import { adminSpeakingService } from "./speaking-service";

describe("admin speaking report service", () => {
  beforeEach(() => get.mockReset());

  it("parses student envelope and sends filters/page", async () => {
    const row = { student_id: "student-1", full_name: "Siswa", attempt_count: 2, analyzed_attempts: 1, reviewed_attempts: 0, average_ai_score: 80, average_teacher_score: null };
    get.mockResolvedValue({ data: { students: { data: [row], meta: { current_page: 2, total: 1 } }, capabilities: { speaking_reports: true } } });
    await expect(adminSpeakingService.studentReports("token", { school_id: "school-1", class_id: "class-1", analysis_status: "completed", review_status: "pending", page: 2, per_page: 5 })).resolves.toEqual({ items: [row], meta: { current_page: 2, total: 1 } });
    expect(get).toHaveBeenCalledWith("/admin/reports/speaking/students", { token: "token", query: { school_id: "school-1", class_id: "class-1", analysis_status: "completed", review_status: "pending", page: 2, per_page: 5 } });
  });

  it("parses class envelope with default pagination", async () => {
    get.mockResolvedValue({ data: { classes: { data: [], meta: { current_page: 1 } } } });
    await expect(adminSpeakingService.classReports("token", { class_id: "class-1" })).resolves.toEqual({ items: [], meta: { current_page: 1 } });
    expect(get).toHaveBeenCalledWith("/admin/reports/speaking/classes", { token: "token", query: { class_id: "class-1", page: 1, per_page: 10 } });
  });
});
