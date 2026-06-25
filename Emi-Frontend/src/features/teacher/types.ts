import type { ApiPaginationMeta } from "@/lib/api-client";
import type { EntityStatus, SchoolClass, ClassStudent } from "@/features/admin/management/types";

export type TeacherDashboardSummary = {
  class: {
    id: string;
    name: string;
    school?: {
      id?: string | null;
      name?: string | null;
    } | null;
  } | null;
  empty_state: boolean;
  students: {
    active: number;
    with_learning_activity: number;
    completed_all_modules: number;
  };
  learning: {
    published_modules: number;
    published_lessons: number;
    average_progress_percent: number | null;
  };
  quizzes: {
    published_quizzes: number;
    students_participated: number;
    final_attempts: number;
    average_score_percent: number | null;
  };
  recent_activity?: TeacherRecentActivity[];
  capabilities?: {
    speaking_reports?: boolean;
  };
  speaking_summary?: unknown;
  generated_at?: string | null;
};

export type TeacherRecentActivity = {
  type?: string | null;
  student_name?: string | null;
  title?: string | null;
  occurred_at?: string | null;
};

export type TeacherClass = SchoolClass;
export type TeacherClassStudent = ClassStudent;

export type TeacherClassModule = {
  id: string;
  class_id: string;
  title: string;
  description?: string | null;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  sort_order?: number | null;
  published_at?: string | null;
  archived_at?: string | null;
};

export type TeacherClassQuiz = {
  id: string;
  class_id: string;
  title: string;
  description?: string | null;
  duration_minutes?: number | null;
  max_attempts?: number | null;
  show_result?: boolean;
  open_at?: string | null;
  close_at?: string | null;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  questions_count?: number;
  attempts_count?: number;
  published_at?: string | null;
};

export type TeacherProgressStudentRow = {
  student_id?: string;
  student_name?: string;
  student_email?: string;
  published_modules?: number;
  started_modules?: number;
  completed_modules?: number;
  overall_learning_progress_percent?: number | null;
  published_quizzes?: number;
  quizzes_attempted?: number;
  quizzes_completed?: number;
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};
