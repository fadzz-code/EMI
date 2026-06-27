import type { ApiPaginationMeta } from "@/lib/api-client";

export type ModuleTemplateStatus = "draft" | "published" | "archived";
export type LessonContentType = "text" | "image" | "audio" | "pdf" | "video" | "link";
export type MediaVisibility = "public" | "private";
export type MediaPurpose = "lesson_image" | "audio" | "document";

export type MediaFile = {
  id: string;
  purpose: string;
  original_name: string;
  mime_type: string;
  extension: string;
  size_bytes: number;
  visibility: MediaVisibility;
  url?: string | null;
  created_at?: string | null;
};

export type LessonTemplate = {
  id: string;
  module_template_id: string;
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
  sort_order: number;
  status: ModuleTemplateStatus;
  published_at?: string | null;
  archived_at?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type ModuleTemplate = {
  id: string;
  title: string;
  description?: string | null;
  status: ModuleTemplateStatus;
  created_by?: string | null;
  updated_by?: string | null;
  published_at?: string | null;
  archived_at?: string | null;
  lessons?: LessonTemplate[];
  created_at?: string | null;
  updated_at?: string | null;
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};

export type ModuleTemplateFilters = {
  search?: string;
  status?: ModuleTemplateStatus | "";
  page?: number;
  per_page?: number;
};

export type ModuleTemplatePayload = {
  title: string;
  description?: string | null;
  status?: ModuleTemplateStatus;
};

export type LessonTemplatePayload = {
  title: string;
  description?: string | null;
  content_type: LessonContentType;
  content_body?: string | null;
  media_id?: string | null;
  external_url?: string | null;
  sort_order?: number;
  status?: ModuleTemplateStatus;
};

export type TemplateApplyResult = {
  applied: Array<{ class_id: string; class_module_id?: string }>;
  skipped: Array<{ class_id: string; reason: string }>;
  failed: Array<{ class_id: string; reason: string }>;
};

export type ClassModule = {
  id: string;
  class_id: string;
  source_module_template_id?: string | null;
  title: string;
  description?: string | null;
  status: ModuleTemplateStatus;
  published_at?: string | null;
};
