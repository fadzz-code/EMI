import { beforeEach, describe, expect, it, vi } from "vitest";

const { get } = vi.hoisted(() => ({ get: vi.fn() }));
vi.mock("@/lib/api-client", () => ({ apiClient: { get } }));

import { progressReportService } from "./progress-service";

describe("admin progress service", () => {
  beforeEach(() => get.mockReset());

  it("loads canonical class detail with independent student page", async () => {
    const data = { class: { id: "class-1" }, summary: { active_students: 20, last_activity_at: null }, students: { data: [], meta: { current_page: 3 } } };
    get.mockResolvedValue({ data });
    await expect(progressReportService.classDetail("token", "class-1", { page: 3, per_page: 12 })).resolves.toEqual({ ...data, students: { items: [], meta: { current_page: 3 } } });
    expect(get).toHaveBeenCalledWith("/admin/reports/progress/classes/class-1", { token: "token", query: { page: 3, per_page: 12 } });
  });
});
