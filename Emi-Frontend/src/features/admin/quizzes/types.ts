import type { ApiPaginationMeta } from "@/lib/api-client";

export type QuizTemplateStatus = "draft" | "published" | "archived";
export type QuestionType = "multiple_choice" | "short_answer";

export type MediaFile = {
  id: string;
  purpose: string;
  original_name: string;
  mime_type: string;
  extension: string;
  size_bytes: number;
  visibility: "public" | "private";
  url?: string | null;
  created_at?: string | null;
};

export type QuizOption = {
  id?: string;
  option_text: string;
  is_correct?: boolean;
  order_number: number;
};

export type QuizTemplateQuestion = {
  id: string;
  quiz_template_id: string;
  question_type: QuestionType;
  question_text: string;
  image_media_id?: string | null;
  image_media?: MediaFile | null;
  correct_answer_text?: string | null;
  use_fuzzy_matching?: boolean | null;
  fuzzy_threshold?: number | null;
  points: number;
  order_number: number;
  explanation?: string | null;
  options?: QuizOption[];
  created_at?: string | null;
  updated_at?: string | null;
};

export type QuizTemplate = {
  id: string;
  title: string;
  description?: string | null;
  instructions?: string | null;
  duration_minutes: number;
  max_attempts: number;
  show_result: boolean;
  status: QuizTemplateStatus;
  created_by?: string | null;
  updated_by?: string | null;
  published_at?: string | null;
  archived_at?: string | null;
  questions_count?: number;
  questions?: QuizTemplateQuestion[];
  created_at?: string | null;
  updated_at?: string | null;
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};

export type QuizTemplateFilters = {
  search?: string;
  status?: QuizTemplateStatus | "";
  page?: number;
  per_page?: number;
};

export type QuizTemplatePayload = {
  title: string;
  description?: string | null;
  instructions?: string | null;
  duration_minutes: number;
  max_attempts: number;
  show_result?: boolean;
  status?: QuizTemplateStatus;
};

export type QuizQuestionPayload = {
  question_type: QuestionType;
  question_text: string;
  image_media_id?: string | null;
  correct_answer_text?: string | null;
  use_fuzzy_matching?: boolean;
  fuzzy_threshold?: number | null;
  points: number;
  order_number: number;
  explanation?: string | null;
  options?: Array<{
    option_text: string;
    is_correct: boolean;
    order_number: number;
  }>;
};

export type QuizTemplateApplyResult = {
  applied: Array<{ class_id: string; class_quiz_id?: string }>;
  synced: Array<{ class_id: string; class_quiz_id?: string }>;
  skipped: Array<{ class_id: string; reason: string }>;
  failed: Array<{ class_id: string; reason: string }>;
};

export type ClassQuiz = {
  id: string;
  class_id: string;
  source_quiz_template_id?: string | null;
  title: string;
  description?: string | null;
  status: QuizTemplateStatus;
  published_at?: string | null;
};
