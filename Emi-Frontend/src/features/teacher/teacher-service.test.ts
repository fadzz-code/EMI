import { beforeEach, describe, expect, it, vi } from "vitest";

const { get } = vi.hoisted(() => ({ get: vi.fn() }));
vi.mock("@/lib/api-client", () => ({ apiClient: { get } }));

import { teacherService } from "./teacher-service";

describe("teacher progress service", () => {
  beforeEach(() => get.mockReset());

  it("loads canonical class aggregate with class scope", async () => {
    const data = { class: { id: "class-1", name: "Kelas 1" }, summary: { active_students: 0, average_module_progress_percent: 0, average_best_final_quiz_score_percent: null, last_activity_at: null, completed_students: 0, not_started_students: 0 } };
    get.mockResolvedValue({ data });
    await expect(teacherService.classProgress("token", "class-1")).resolves.toBe(data);
    expect(get).toHaveBeenCalledWith("/teacher/reports/progress/class", { token: "token", query: { class_id: "class-1" } });
  });
});
