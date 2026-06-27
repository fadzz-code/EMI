import type { ApiPaginationMeta } from "@/lib/api-client";
import type { LessonContentType, MediaVisibility } from "@/features/admin/modules/types";

export type LearningStatus = "not_started" | "in_progress" | "completed";

export type StudentDashboardSummary = {
  class: {
    id: string;
    name: string;
    school?: {
      id?: string | null;
      name?: string | null;
    } | null;
  } | null;
  empty_state: boolean;
  learning: {
    published_modules: number;
    not_started_modules: number;
    in_progress_modules: number;
    completed_modules: number;
    overall_progress_percent: number | null;
    completed_lessons: number;
    total_lessons: number;
  };
  quizzes: {
    available: number;
    upcoming: number;
    in_progress_attempts: number;
    completed: number;
    visible_result_count: number;
    hidden_result_count: number;
    visible_average_score: number | null;
  };
  upcoming_deadlines?: Array<{
    id: string;
    title: string;
    close_at?: string | null;
  }>;
  recent_activity?: unknown[];
  capabilities?: {
    speaking_reports?: boolean;
  };
  speaking_summary?: unknown;
  generated_at?: string | null;
};

export type ModuleProgress = {
  id?: string;
  class_module_id?: string;
  status: LearningStatus;
  progress_percent: number;
  completed_lessons: number;
  total_lessons: number;
  started_at?: string | null;
  completed_at?: string | null;
  last_calculated_at?: string | null;
};

export type StudentModule = {
  id: string;
  title: string;
  description?: string | null;
  status: string;
  sort_order?: number | null;
  progress: ModuleProgress;
  lessons?: StudentLesson[];
};

export type StudentLesson = {
  id: string;
  class_module_id: string;
  source_lesson_template_id?: string | null;
  title: string;
  description?: string | null;
  content_type: LessonContentType;
  content_body?: string | null;
  external_url?: string | null;
  media?: {
    id: string;
    mime_type: string;
    visibility: MediaVisibility;
  } | null;
  sort_order?: number | null;
  status: string;
  published_at?: string | null;
  archived_at?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type LessonContent = {
  type: LessonContentType;
  content_body?: string | null;
  url?: string | null;
  media?: {
    id: string;
    mime_type: string;
    visibility: MediaVisibility;
  } | null;
};

export type LessonProgress = {
  id: string;
  class_lesson_id: string;
  status: LearningStatus;
  progress_percent: number;
  started_at?: string | null;
  completed_at?: string | null;
  last_accessed_at?: string | null;
};

export type StudentProgressReport = {
  summary?: {
    published_modules?: number;
    completed_modules?: number;
    overall_learning_progress_percent?: number | null;
    total_published_lessons?: number;
    completed_lessons?: number;
  };
  modules?: {
    data?: Array<{
      class_module_id?: string;
      title?: string;
      status?: LearningStatus;
      progress_percent?: number | null;
    }>;
  };
};

export type DictionaryCategory = {
  id: string;
  name: string;
  slug?: string;
  description?: string | null;
  status?: string;
};

export type DictionaryAudio = {
  id: string;
  url: string;
  mime_type: string;
};

export type DictionaryEntry = {
  id: string;
  category_id?: string | null;
  category?: DictionaryCategory | null;
  indonesia: string;
  english: string;
  mekongga: string;
  example_mekongga?: string | null;
  example_indonesia?: string | null;
  audio?: DictionaryAudio | null;
  status?: string;
  created_at?: string | null;
  updated_at?: string | null;
};

export type DictionaryEntryFilters = {
  search?: string;
  language?: "all" | "indonesia" | "english" | "mekongga";
  category_id?: string;
  page?: number;
  per_page?: number;
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};
