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

export type TeacherClassLesson = {
  id: string;
  class_module_id: string;
  title: string;
  description?: string | null;
  content_type?: string | null;
  content_body?: string | null;
  external_url?: string | null;
  media?: {
    id: string;
    mime_type: string;
    visibility: string;
  } | null;
  sort_order?: number | null;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  published_at?: string | null;
  created_at?: string | null;
};

export type TeacherClassModule = {
  id: string;
  class_id: string;
  title: string;
  description?: string | null;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  sort_order?: number | null;
  published_at?: string | null;
  archived_at?: string | null;
  created_at?: string | null;
  lessons?: TeacherClassLesson[];
};

export type TeacherQuizOption = {
  id?: string;
  option_text: string;
  is_correct?: boolean;
  order_number: number;
};

export type TeacherQuizQuestion = {
  id: string;
  class_quiz_id?: string;
  question_type: "multiple_choice" | "short_answer" | string;
  question_text: string;
  image_media_id?: string | null;
  correct_answer_text?: string | null;
  use_fuzzy_matching?: boolean | null;
  fuzzy_threshold?: number | null;
  points?: number | null;
  order_number?: number | null;
  explanation?: string | null;
  options?: TeacherQuizOption[];
};

export type TeacherClassQuiz = {
  id: string;
  class_id: string;
  title: string;
  description?: string | null;
  instructions?: string | null;
  duration_minutes?: number | null;
  max_attempts?: number | null;
  show_result?: boolean;
  open_at?: string | null;
  close_at?: string | null;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  class?: {
    id?: string;
    name?: string;
    school?: { id?: string; name?: string } | null;
  } | null;
  questions_count?: number;
  attempts_count?: number;
  published_at?: string | null;
  questions?: TeacherQuizQuestion[];
};

export type TeacherQuizAttempt = {
  id: string;
  status: string;
  score_percent?: number | null;
  started_at?: string | null;
  submitted_at?: string | null;
  student?: {
    id: string;
    full_name: string;
    email: string;
  } | null;
};

export type TeacherUserProfile = {
  id: string;
  full_name: string;
  email: string;
  role: string;
  status: string;
  phone?: string | null;
  avatar?: {
    id: string;
    url?: string | null;
  } | null;
  updated_at?: string | null;
};

export type TeacherProgressStudentRow = {
  student_id?: string;
  full_name?: string;
  school?: {
    id?: string;
    name?: string;
  };
  class?: {
    id?: string;
    name?: string;
  };
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
