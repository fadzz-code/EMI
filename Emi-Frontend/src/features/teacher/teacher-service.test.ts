import { beforeEach, describe, expect, it, vi } from "vitest";

const { get, remove } = vi.hoisted(() => ({ get: vi.fn(), remove: vi.fn() }));
vi.mock("@/lib/api-client", () => ({ apiClient: { get, delete: remove } }));

import { teacherService } from "./teacher-service";

describe("teacher progress service", () => {
  beforeEach(() => { get.mockReset(); remove.mockReset(); });

  it("loads canonical class aggregate with class scope", async () => {
    const data = { class: { id: "class-1", name: "Kelas 1" }, summary: { active_students: 0, average_module_progress_percent: 0, average_best_final_quiz_score_percent: null, last_activity_at: null, completed_students: 0, not_started_students: 0 } };
    get.mockResolvedValue({ data });
    await expect(teacherService.classProgress("token", "class-1")).resolves.toBe(data);
    expect(get).toHaveBeenCalledWith("/teacher/reports/progress/class", { token: "token", query: { class_id: "class-1" } });
  });

  it("requests visible speaking attempt page and preserves pagination metadata", async () => {
    const meta = { current_page: 2, last_page: 3, total: 201, counts: { total: 201, pending: 120, reviewed: 78, failed: 3 } };
    get.mockResolvedValue({ data: [{ id: "attempt-101" }], meta });
    await expect(teacherService.speakingAttempts("token", 2, { search: "Nina", review_status: "pending" })).resolves.toEqual({ items: [{ id: "attempt-101" }], meta });
    expect(get).toHaveBeenCalledWith("/teacher/speaking/attempts", {
      token: "token",
      query: { page: 2, per_page: 100, search: "Nina", review_status: "pending" },
    });
  });

  it("deletes pending submitted speaking attempt", async () => {
    remove.mockResolvedValue({});
    await teacherService.deleteSpeakingAttempt("token", "attempt-1");
    expect(remove).toHaveBeenCalledWith("/teacher/speaking/attempts/attempt-1", { token: "token" });
  });
});
