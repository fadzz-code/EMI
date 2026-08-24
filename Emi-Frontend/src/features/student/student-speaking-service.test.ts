import { describe, expect, it, vi } from "vitest";

const { remove } = vi.hoisted(() => ({ remove: vi.fn() }));
vi.mock("@/lib/api-client", () => ({ apiClient: { delete: remove } }));

import { studentService } from "./student-service";

describe("student speaking service", () => {
  it("deletes private history for one exercise", async () => {
    remove.mockResolvedValue({ data: { deleted_count: 3 } });

    await expect(studentService.deletePrivateSpeakingHistory("token", "exercise-1")).resolves.toBe(3);
    expect(remove).toHaveBeenCalledWith("/student/speaking/exercises/exercise-1/attempts/history", { token: "token" });
  });
});
