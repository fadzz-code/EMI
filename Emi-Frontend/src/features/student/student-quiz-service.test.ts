import { beforeEach, describe, expect, it, vi } from "vitest";

const { get } = vi.hoisted(() => ({ get: vi.fn() }));

vi.mock("@/lib/api-client", () => ({ apiClient: { get } }));

import { studentQuizService } from "./student-quiz-service";

describe("student quiz history service", () => {
  beforeEach(() => get.mockReset());

  it("uses canonical paginated attempt endpoint", async () => {
    const attempt = { id: "attempt-1", status: "submitted", attempt_number: 2, started_at: "2026-07-24T00:00:00Z", submitted_at: "2026-07-24T00:10:00Z", score_points: 8, max_points: 10, score_percent: 80 };
    get.mockResolvedValue({ data: [attempt], meta: { current_page: 2, last_page: 3, per_page: 5, total: 11 } });
    await expect(studentQuizService.attempts("token", "quiz-1", { page: 2, per_page: 5 })).resolves.toEqual({ items: [attempt], meta: { current_page: 2, last_page: 3, per_page: 5, total: 11 } });
    expect(get).toHaveBeenCalledWith("/student/quizzes/quiz-1/attempts", { token: "token", query: { page: 2, per_page: 5 } });
  });
});
