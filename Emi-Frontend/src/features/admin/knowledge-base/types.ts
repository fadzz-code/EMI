export type AiKnowledgeStatus = "draft" | "published" | "archived";
export type AiKnowledgeSourceType = "manual" | "link" | "pdf";

export type AiKnowledgeItem = {
  id: string;
  title: string;
  category?: string | null;
  content: string;
  source_type: AiKnowledgeSourceType;
  source_url?: string | null;
  status: AiKnowledgeStatus;
  processing_status?: "pending" | "processing" | "ready" | "failed";
  created_by?: string | null;
  updated_by?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type AiKnowledgePayload = {
  title: string;
  category?: string | null;
  content: string;
  source_type: AiKnowledgeSourceType;
  source_url?: string | null;
  status?: AiKnowledgeStatus;
};

export type AiKnowledgeSourceExtraction = {
  title?: string | null;
  content: string;
  source_type: Extract<AiKnowledgeSourceType, "link" | "pdf">;
  source_url?: string | null;
  original_filename?: string | null;
  character_count: number;
  warnings: string[];
};

export type AiKnowledgePdfImportResult = {
  item_id: string;
  page_count: number;
  chunk_count: number;
  skipped_page_count: number;
  source_url?: string | null;
};

export type AiKnowledgeFilters = {
  search?: string;
  category?: string;
  status?: AiKnowledgeStatus | "";
  page?: number;
  per_page?: number;
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: {
    current_page?: number;
    per_page?: number;
    total?: number;
    last_page?: number;
  };
};

export type KnowledgeFeature = {
  label: string;
  description: string;
};

export type KnowledgePlaceholderRow = {
  label: string;
  value: string;
};
