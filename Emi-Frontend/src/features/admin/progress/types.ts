import type { ApiPaginationMeta } from "@/lib/api-client";

export type LearningStatus = "not_started" | "in_progress" | "completed";
export type QuizReportStatus =
  | "not_started"
  | "in_progress"
  | "submitted"
  | "expired"
  | "completed";

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};

export type ProgressScopeFilters = {
  school_id?: string;
  class_id?: string;
  student_id?: string;
  search?: string;
  learning_status?: LearningStatus | "";
  quiz_status?: LearningStatus | "";
  page?: number;
  per_page?: number;
};

export type ClassProgressFilters = {
  school_id?: string;
  search?: string;
  status?: "active" | "inactive" | "";
  page?: number;
  per_page?: number;
};

export type QuizResultFilters = {
  school_id?: string;
  class_id?: string;
  quiz_id?: string;
  student_id?: string;
  status?: QuizReportStatus | "";
  page?: number;
  per_page?: number;
};

export type DashboardSummary = {
  overview: {
    active_schools: number;
    active_classes: number;
    active_teachers: number;
    active_students: number;
    pending_registration_requests: number;
  };
  learning: {
    students_with_learning_activity: number;
    completed_modules: number;
    average_learning_progress_percent: number;
  };
  quizzes: {
    final_attempts: number;
    submitted_attempts: number;
    expired_attempts: number;
    in_progress_attempts: number;
    average_score_percent: number | null;
    participation_rate_percent: number;
  };
  capabilities: {
    speaking_reports: boolean;
  };
  speaking_summary: unknown | null;
  generated_at?: string | null;
};

export type SchoolProgressRow = {
  school_id: string;
  school_name: string;
  active_classes: number;
  active_students: number;
  published_modules: number;
  average_learning_progress_percent: number;
  module_completion_rate_percent: number;
  published_quizzes: number;
  quiz_participation_rate_percent: number;
  average_quiz_score_percent: number | null;
};

export type ClassProgressSummary = {
  active_students: number;
  average_module_progress_percent: number;
  average_best_final_quiz_score_percent: number | null;
  last_activity_at: string | null;
  completed_students: number;
  not_started_students: number;
};

export type ClassProgressDetail = {
  class: {
    id: string;
    name: string;
    academic_year: string;
    status: string;
    school: { id: string; name: string };
    teacher: { id: string; full_name: string; email: string } | null;
  };
  summary: ClassProgressSummary;
  students: PaginatedResult<StudentProgressRow>;
  capabilities: { speaking_reports: boolean };
};

export type ClassProgressRow = {
  class_id: string;
  class_name: string;
  school_id: string;
  school_name: string;
  active_students: number;
  published_modules: number;
  average_learning_progress_percent: number;
  completed_module_count: number;
  published_quizzes: number;
  students_participated_in_quiz: number;
  average_quiz_score_percent: number | null;
};

export type StudentProgressRow = {
  student_id: string;
  full_name: string;
  school: {
    id: string;
    name: string;
  };
  class: {
    id: string;
    name: string;
  };
  published_modules: number;
  started_modules: number;
  completed_modules: number;
  in_progress_modules: number;
  not_started_modules: number;
  overall_learning_progress_percent: number;
  completed_lessons: number;
  total_published_lessons: number;
  published_quizzes: number;
  quizzes_attempted: number;
  quizzes_completed: number;
  average_best_quiz_score_percent: number | null;
  last_learning_activity_at?: string | null;
  last_quiz_activity_at?: string | null;
};

export type QuizResultSummary = {
  eligible_students: number;
  participating_students: number;
  finalized_students: number;
  not_attempted_students: number;
  participation_rate_percent: number;
  completion_rate_percent: number;
  average_best_score_percent: number | null;
  highest_best_score_percent: number | null;
  lowest_best_score_percent: number | null;
  submitted_attempts: number;
  expired_attempts: number;
  in_progress_attempts: number;
};

export type QuizResultRow = {
  quiz: {
    id: string;
    title: string;
    show_result: boolean;
  };
  student: {
    id: string;
    full_name: string;
  };
  school: {
    id: string;
    name: string;
  };
  class: {
    id: string;
    name: string;
  };
  best_attempt_number: number | null;
  attempt_count: number;
  final_attempt_count: number;
  submitted_attempts: number;
  expired_attempts: number;
  in_progress_attempts: number;
  final_attempt: boolean;
  best_score_percent: number | null;
  latest_status?: string | null;
  latest_submitted_at?: string | null;
};

export type QuizResultReport = PaginatedResult<QuizResultRow> & {
  summary: QuizResultSummary | null;
};
