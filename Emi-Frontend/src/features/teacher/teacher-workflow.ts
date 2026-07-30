import type { TeacherClassQuiz } from "./types";

export type TeacherProgressQuery = { class_id: string; page?: number; per_page?: number; search?: string };
export type TeacherProgressKeyFilters = Omit<TeacherProgressQuery, "class_id"> & { student_id?: string; view?: "report" };

export function teacherProgressKey(classId: string, filters: TeacherProgressKeyFilters = {}) {
  return ["teacher", "progress", "students", classId, filters] as const;
}

export function teacherProgressRequestQuery(query: TeacherProgressQuery) {
  return {
    class_id: query.class_id,
    page: query.page,
    per_page: query.per_page ?? 12,
    search: query.search,
    sort_by: "full_name",
    sort_direction: "asc",
  };
}

export function progressStudentIdentity(student: { student_id?: string; full_name?: string }): string | null {
  return student.student_id ?? null;
}

export function quizLifecycle(quiz: Pick<TeacherClassQuiz, "status" | "attempts_count">): "delete" | "archive" {
  return quiz.status !== "published" && (quiz.attempts_count ?? 0) === 0 ? "delete" : "archive";
}

export function moduleLifecycle(module: { status: string }): "delete" | "archive" {
  return module.status === "draft" || module.status === "archived" ? "delete" : "archive";
}

export function lessonLifecycle(lesson: { status: string }): "delete" | "archive" {
  return lesson.status === "draft" || lesson.status === "archived" ? "delete" : "archive";
}

export function speakingExerciseLifecycle(exercise: { attempts_count?: number }): "delete" | "archive" {
  return (exercise.attempts_count ?? 0) === 0 ? "delete" : "archive";
}
