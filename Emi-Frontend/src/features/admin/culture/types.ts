import type { EntityStatus } from "@/features/admin/management/types";

export type AdminCultureTemplate = {
  id: string;
  title: string;
  description?: string | null;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  items_count?: number;
  published_at?: string | null;
  archived_at?: string | null;
  created_at?: string | null;
  items?: AdminCultureTemplateItem[];
};

export type AdminGlobalCultureItem = {
  id: string;
  admin_group_id: string;
  title: string;
  description?: string | null;
  content_type: "image" | "audio" | "pdf" | "video" | "youtube" | "article" | "link" | string;
  media_id?: string | null;
  external_url?: string | null;
  display_order: number;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  created_scope?: string | null;
  classes_count?: number;
  published_classes_count?: number;
  created_at?: string | null;
  updated_at?: string | null;
  media?: {
    id: string;
    original_name?: string | null;
    mime_type?: string | null;
    url?: string | null;
  } | null;
};

export type AdminCultureTemplateItem = {
  id: string;
  culture_template_id: string;
  title: string;
  description?: string | null;
  content_type: "image" | "audio" | "pdf" | "video" | "youtube" | "article" | "link" | string;
  media_id?: string | null;
  external_url?: string | null;
  display_order: number;
  status: EntityStatus | "draft" | "published" | "archived" | string;
  published_at?: string | null;
  archived_at?: string | null;
  created_at?: string | null;
  media?: {
    id: string;
    original_name?: string | null;
    mime_type?: string | null;
    url?: string | null;
  } | null;
};
