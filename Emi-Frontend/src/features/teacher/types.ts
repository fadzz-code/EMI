import type { ApiPaginationMeta } from "@/lib/api-client";
import type { EntityStatus, SchoolClass, ClassStudent } from "@/features/admin/management/types";
import type { SpeakingAttempt, SpeakingExercise } from "@/features/student/types";

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

export type TeacherLessonContentType = "text" | "image" | "audio" | "pdf" | "video" | "link";
export type TeacherMediaPurpose = "lesson_image" | "audio" | "document" | "culture_media" | "question_image" | "speaking_reference_audio";
export type TeacherMediaVisibility = "public" | "private";

export type TeacherLessonPayload = {
  title: string;
  description: string | null;
  content_type: TeacherLessonContentType;
  content_body: string | null;
  media_id: string | null;
  external_url: string | null;
  sort_order?: number;
};

export type TeacherLessonForm = {
  title: string;
  description: string;
  content_type: TeacherLessonContentType;
  content_body: string;
  media_id: string;
  external_url: string;
  sort_order: string;
};

export type TeacherLessonContent = {
  type: TeacherLessonContentType;
  content_body?: string | null;
  url?: string | null;
  media?: {
    id: string;
    mime_type: string;
    visibility: TeacherMediaVisibility;
  } | null;
};

export type TeacherClassLesson = {
  id: string;
  class_module_id: string;
  title: string;
  description?: string | null;
  content_type: TeacherLessonContentType;
  content_body?: string | null;
  external_url?: string | null;
  media?: TeacherMediaFile | null;
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

export type TeacherMediaFile = {
  id: string;
  purpose?: string | null;
  original_name?: string | null;
  url?: string | null;
  mime_type?: string | null;
  extension?: string | null;
  size_bytes?: number | null;
  visibility?: string | null;
  created_at?: string | null;
};

export type TeacherQuizQuestion = {
  id: string;
  class_quiz_id?: string;
  question_type: "multiple_choice" | "short_answer" | string;
  question_text: string;
  image_media_id?: string | null;
  image_media?: TeacherMediaFile | null;
  correct_answer_text?: string | null;
  use_fuzzy_matching?: boolean | null;
  fuzzy_threshold?: number | null;
  points?: number | null;
  order_number?: number | null;
  explanation?: string | null;
  options?: TeacherQuizOption[];
};

export type TeacherCultureContentType = "image" | "audio" | "pdf" | "video" | "youtube" | "article" | "link";

export type TeacherCultureItem = {
  id: string;
  class_id: string;
  source_template_id?: string | null;
  source_template_item_id?: string | null;
  admin_group_id?: string | null;
  created_scope?: string | null;
  title: string;
  description?: string | null;
  content_type: TeacherCultureContentType;
  media_id?: string | null;
  media?: TeacherMediaFile | null;
  external_url?: string | null;
  thumbnail_media_id?: string | null;
  display_order?: number | null;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  created_by?: string | null;
  updated_by?: string | null;
  school_class?: {
    id?: string;
    name?: string;
    school?: { id?: string; name?: string } | null;
  } | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type TeacherCulturePayload = {
  title: string;
  description?: string | null;
  content_type: TeacherCultureContentType;
  media_id?: string | null;
  external_url?: string | null;
  display_order?: number | null;
  status?: string;
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

export type TeacherQuizAnswer = {
  id: string;
  quiz_attempt_id: string;
  quiz_question_id: string;
  selected_option_id?: string | null;
  answer_text?: string | null;
  is_correct?: boolean | null;
  similarity_score?: number | null;
  awarded_points?: number | null;
  max_points?: number | null;
  answered_at?: string | null;
};

export type TeacherQuizAttempt = {
  id: string;
  class_quiz_id?: string;
  student_id?: string;
  attempt_number?: number | null;
  status: string;
  score_points?: number | null;
  max_points?: number | null;
  score_percent?: number | null;
  correct_count?: number | null;
  incorrect_count?: number | null;
  unanswered_count?: number | null;
  started_at?: string | null;
  expires_at?: string | null;
  submitted_at?: string | null;
  answers?: TeacherQuizAnswer[];
  student?: {
    id: string;
    full_name?: string;
    name?: string;
    email?: string;
  } | null;
};

export type TeacherQuizReport = {
  class_quiz_id: string;
  student_count?: number | null;
  attempts_count?: number | null;
  submitted_count?: number | null;
  in_progress_count?: number | null;
  average_score_percent?: number | null;
  highest_score_percent?: number | null;
  lowest_score_percent?: number | null;
  questions?: Array<{
    id: string;
    question_type?: string;
    order_number?: number | null;
    points?: number | null;
    answered_count?: number | null;
    correct_count?: number | null;
    incorrect_count?: number | null;
    average_awarded_points?: number | null;
  }>;
};

export type TeacherSpeakingTemplate = SpeakingExercise & {
  classroom_id?: null;
  created_by_id?: string | null;
  metadata?: Record<string, unknown> | null;
  created_by?: { id?: string; full_name?: string | null } | null;
};

export type TeacherSpeakingExercise = SpeakingExercise & {
  classroom_id?: string | null;
  created_by_id?: string | null;
  metadata?: Record<string, unknown> | null;
  classroom?: {
    id?: string;
    name?: string;
    school?: { id?: string; name?: string } | null;
  } | null;
  created_by?: { id?: string; full_name?: string | null } | null;
  attempts_count?: number;
};

export type TeacherSpeakingExercisePayload = {
  template_exercise_id?: string | null;
  classroom_id: string;
  title: string;
  target_text: string;
  prompt_text?: string | null;
  target_translation?: string | null;
  reference_audio_media_id?: string | null;
  language_code?: string | null;
  difficulty?: string | null;
  status?: "draft" | "published";
};

export type TeacherSpeakingAttempt = SpeakingAttempt & {
  exercise?: SpeakingExercise | null;
  student?: { id: string; full_name?: string | null; email?: string | null } | null;
};

export type SpeakingFeedbackRequest = {
  teacher_score: number;
  teacher_feedback?: string | null;
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

export type TeacherProgressClassSummary = {
  active_students: number;
  average_module_progress_percent: number;
  average_best_final_quiz_score_percent: number | null;
  last_activity_at: string | null;
  completed_students: number;
  not_started_students: number;
};

export type TeacherProgressStudentRow = {
  student_id?: string;
  full_name?: string;
  email?: string;
  student_status?: string;
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
  average_best_quiz_score_percent?: number | null;
};

export type TeacherQuizResultRow = {
  quiz: { id: string; title: string; show_result: boolean };
  student: { id: string; full_name: string };
  school: { id: string; name: string };
  class: { id: string; name: string };
  best_attempt_number: number | null;
  attempt_count: number;
  final_attempt_count: number;
  best_score_percent: number | null;
  latest_status?: string | null;
  latest_submitted_at?: string | null;
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};
