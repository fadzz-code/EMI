import type { ApiPaginationMeta } from "@/lib/api-client";
import type { TeacherMediaFile } from "@/features/teacher/types";

export type AdminSpeakingExercise = {
  id: string;
  title: string;
  prompt_text?: string | null;
  target_text: string;
  target_translation?: string | null;
  reference_audio_media_id?: string | null;
  reference_audio?: TeacherMediaFile | null;
  language_code?: string | null;
  difficulty?: string | null;
  status: "draft" | "published" | "archived" | string;
  metadata?: Record<string, unknown> | null;
  created_by?: { id?: string; full_name?: string | null } | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type AdminSpeakingExercisePayload = {
  title: string;
  target_text: string;
  target_translation?: string | null;
  prompt_text?: string | null;
  difficulty?: string | null;
  status?: "draft" | "published";
  reference_audio_media_id?: string | null;
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};
