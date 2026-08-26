import { describe, expect, it } from "vitest";

import { progressStudentIdentity, quizHasAttempts, quizLifecycle, quizPublished, teacherProgressKey, teacherProgressRequestQuery } from "./teacher-workflow";

describe("teacher workflow", () => {
  it("isolates progress cache by class and server filters", () => {
    expect(teacherProgressKey("class-1", { page: 2, search: "Budi" })).toEqual(["teacher", "progress", "students", "class-1", { page: 2, search: "Budi" }]);
    expect(teacherProgressKey("class-1")).not.toEqual(teacherProgressKey("class-2"));
    expect(teacherProgressKey("class-1", { page: 1 })).not.toEqual(teacherProgressKey("class-1", { page: 2 }));
    expect(teacherProgressKey("class-1", { search: "Budi" })).not.toEqual(teacherProgressKey("class-1", { search: "Siti" }));
  });

  it("builds exact canonical progress query", () => {
    expect(teacherProgressRequestQuery({ class_id: "class-1", page: 3, search: "Budi" })).toEqual({ class_id: "class-1", page: 3, per_page: 12, search: "Budi", sort_by: "full_name", sort_direction: "asc" });
  });

  it("never falls back to student name identity", () => {
    expect(progressStudentIdentity({ student_id: "student-1", full_name: "Nama Sama" })).toBe("student-1");
    expect(progressStudentIdentity({ full_name: "Nama Sama" })).toBeNull();
  });

  it("keeps lifecycle, published lock, and attempts independent", () => {
    const matrix = [
      { status: "draft", attempts_count: 0, lifecycle: "delete", published: false, attempts: false },
      { status: "draft", attempts_count: 1, lifecycle: "archive", published: false, attempts: true },
      { status: "archived", attempts_count: 0, lifecycle: "delete", published: false, attempts: false },
      { status: "archived", attempts_count: 1, lifecycle: "archive", published: false, attempts: true },
      { status: "published", attempts_count: 0, lifecycle: "archive", published: true, attempts: false },
      { status: "published", attempts_count: 1, lifecycle: "archive", published: true, attempts: true },
    ] as const;
    for (const row of matrix) {
      expect(quizLifecycle(row)).toBe(row.lifecycle);
      expect(quizPublished(row)).toBe(row.published);
      expect(quizHasAttempts(row)).toBe(row.attempts);
    }
  });
});
