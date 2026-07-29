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

export type StudentCultureContentType = "image" | "audio" | "pdf" | "video" | "youtube" | "article" | "link";

export type StudentCultureItem = {
  id: string;
  class_id: string;
  title: string;
  description?: string | null;
  content_type: StudentCultureContentType;
  media_id?: string | null;
  media?: { id: string; url?: string | null; mime_type?: string | null; visibility?: string | null } | null;
  external_url?: string | null;
  display_order?: number | null;
  status: string;
  school_class?: { id?: string; name?: string; school?: { id?: string; name?: string } | null } | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type StudentProgressSummary = {
  student_id?: string;
  full_name?: string;
  school?: { id?: string; name?: string } | null;
  class?: { id?: string; name?: string } | null;
  published_modules?: number;
  started_modules?: number;
  completed_modules?: number;
  in_progress_modules?: number;
  not_started_modules?: number;
  overall_learning_progress_percent?: number | null;
  completed_lessons?: number;
  total_published_lessons?: number;
  published_quizzes?: number;
  quizzes_attempted?: number;
  quizzes_completed?: number;
  submitted_quiz_count?: number;
  average_best_quiz_score_percent?: number | null;
  average_quiz_score_out_of_100?: number | null;
  last_learning_activity_at?: string | null;
  last_quiz_activity_at?: string | null;
};

export type StudentProgressModuleRow = {
  id?: string;
  class_module_id?: string;
  title?: string;
  sort_order?: number | null;
  status?: LearningStatus;
  progress_percent?: number | null;
  completed_lessons?: number | null;
  total_lessons?: number | null;
  last_calculated_at?: string | null;
};

export type StudentProgressReport = {
  summary?: StudentProgressSummary | null;
  modules?: {
    data?: StudentProgressModuleRow[];
    meta?: ApiPaginationMeta;
  };
};

export type StudentQuizResultReportSummary = {
  eligible_students?: number;
  participating_students?: number;
  finalized_students?: number;
  not_attempted_students?: number;
  participation_rate_percent?: number;
  completion_rate_percent?: number;
  average_best_score_percent?: number | null;
  highest_best_score_percent?: number | null;
  lowest_best_score_percent?: number | null;
  submitted_attempts?: number;
  expired_attempts?: number;
  in_progress_attempts?: number;
};

export type StudentQuizResultReportRow = {
  quiz?: { id?: string; title?: string; show_result?: boolean } | null;
  student?: { id?: string; full_name?: string } | null;
  school?: { id?: string; name?: string } | null;
  class?: { id?: string; name?: string } | null;
  best_attempt_number?: number | null;
  attempt_count?: number;
  final_attempt_count?: number;
  best_score_percent?: number | null;
  latest_status?: string | null;
  latest_submitted_at?: string | null;
};

export type StudentQuizResultsReport = {
  summary?: StudentQuizResultReportSummary;
  rows?: StudentQuizResultReportRow[];
};

export type SpeakingAttemptStatus = "pending" | "processing" | "completed" | "failed" | "reviewed" | string;

export type SpeakingReferenceAudio = {
  id: string;
  url?: string | null;
  content_url?: string | null;
  public_url?: string | null;
  file_url?: string | null;
  mime_type?: string | null;
  original_name?: string | null;
  file_name?: string | null;
  name?: string | null;
  visibility?: string | null;
};

export type SpeakingExercise = {
  id: string;
  title: string;
  prompt_text?: string | null;
  target_text: string;
  target_translation?: string | null;
  reference_audio_media_id?: string | null;
  reference_audio?: SpeakingReferenceAudio | null;
  language_code?: string | null;
  difficulty?: string | null;
  status?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type SpeakingAttempt = {
  id: string;
  exercise_id: string;
  target_text: string;
  status: SpeakingAttemptStatus;
  ai_score?: number | null;
  ai_transcription?: string | null;
  ai_alignment?: Array<{ operation?: string; target?: string | null; transcription?: string | null }> | Record<string, number> | null;
  ai_warnings?: string[];
  ai_error?: string | null;
  ai_error_code?: string | null;
  teacher_score?: number | null;
  teacher_feedback?: string | null;
  reviewed_at?: string | null;
  audio_media_id?: string | null;
  audio_url?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
  exercise?: SpeakingExercise | null;
  student?: { id: string; full_name?: string | null; email?: string | null } | null;
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

export type DictionarySentenceExample = {
  id: string;
  kode?: string | null;
  contoh_mekongga: string;
  contoh_indonesia: string;
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
  sentence_examples?: DictionarySentenceExample[];
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

export type QuizOption = {
  id: string;
  quiz_question_id?: string;
  option_text: string;
  is_correct?: boolean;
  order_number?: number;
};

export type QuizQuestion = {
  id: string;
  class_quiz_id?: string;
  question_type: "multiple_choice" | "short_answer";
  question_text: string;
  image_media_id?: string | null;
  correct_answer_text?: string | null;
  use_fuzzy_matching?: boolean;
  fuzzy_threshold?: number;
  points?: number;
  order_number?: number;
  explanation?: string | null;
  options?: QuizOption[];
  image_media?: {
    id: string;
    url?: string | null;
  } | null;
};

export type StudentQuiz = {
  id: string;
  class_id?: string;
  title: string;
  description?: string | null;
  instructions?: string | null;
  duration_minutes?: number | null;
  max_attempts?: number | null;
  show_result?: boolean;
  open_at?: string | null;
  close_at?: string | null;
  questions_count?: number;
  attempts_count?: number;
  used_attempts?: number;
  submitted_attempts_count?: number;
  remaining_attempts?: number | null;
  attempt_limit_reached?: boolean;
  can_start?: boolean;
  latest_score_points?: number | null;
  latest_max_points?: number | null;
  latest_score_normalized?: number | null;
  latest_score_percent?: number | null;
  best_score_percent?: number | null;
  latest_submitted_at?: string | null;
  questions?: QuizQuestion[];
};

export type QuizAnswer = {
  id: string;
  quiz_attempt_id?: string;
  quiz_question_id?: string;
  selected_option_id?: string | null;
  answer_text?: string | null;
  is_correct?: boolean | null;
  similarity_score?: number | null;
  awarded_points?: number | null;
  max_points?: number | null;
  answered_at?: string | null;
};

export type QuizAttempt = {
  id: string;
  class_quiz_id?: string;
  student_id?: string;
  attempt_number?: number;
  status: "pending" | "in_progress" | "submitted" | "expired";
  started_at?: string | null;
  expires_at?: string | null;
  submitted_at?: string | null;
  score_points?: number | null;
  max_points?: number | null;
  score_percent?: number | null;
  correct_count?: number | null;
  incorrect_count?: number | null;
  unanswered_count?: number | null;
  class_quiz?: StudentQuiz | null;
  answers?: QuizAnswer[];
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};

export type ChatbotSource = {
  id: string;
  title: string;
  category?: string | null;
  source_type?: "manual" | "link" | "pdf" | "docx" | "txt" | string;
  source_url?: string | null;
  chunk_id?: string;
  chunk_index?: number;
  page_number?: number | null;
  page_start?: number | null;
  page_end?: number | null;
  page_type?: string | null;
  retrieval_mode?: "vector" | "keyword" | string | null;
  similarity_score?: number | null;
  distance?: number | null;
};

export type StudentChatbotResponse = {
  answer: string;
  source: ChatbotSource | null;
  sources?: ChatbotSource[];
  matched: boolean;
  mode: "default_extractive" | string;
  provider: "default" | string;
  confidence?: number;
  fallback_reason?: string | null;
  conversation_id: string;
};

export type ChatbotConversationMessage = {
  id: string;
  role: "user" | "assistant";
  content: string;
  citations: ChatbotSource[];
  retrieval_mode?: string | null;
  provider?: string | null;
  confidence?: number | null;
  fallback_reason?: string | null;
  created_at?: string | null;
};

export type ChatbotConversationSummary = {
  id: string;
  title: string | null;
  status: "active" | "archived" | string;
  last_message_at?: string | null;
  created_at?: string | null;
};

export type ChatbotConversationDetail = ChatbotConversationSummary & {
  messages: ChatbotConversationMessage[];
};
