import type { ApiPaginationMeta } from "@/lib/api-client";

export type DictionaryStatus = "active" | "inactive";
export type DuplicateStrategy = "skip" | "update" | "reject";
export type DictionaryImportStatus =
  | "previewing"
  | "preview_ready"
  | "queued"
  | "processing"
  | "completed"
  | "completed_with_errors"
  | "failed"
  | "cancelled";

export type DictionaryCategory = {
  id: string;
  name: string;
  slug: string;
  description?: string | null;
  status: DictionaryStatus;
  entries_count?: number;
  created_at?: string | null;
  updated_at?: string | null;
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
  audio?: DictionaryAudio | null;
};

export type DictionaryEntry = {
  id: string;
  category_id: string;
  category?: DictionaryCategory | null;
  indonesia: string;
  english: string;
  mekongga: string;
  example_mekongga?: string | null;
  example_indonesia?: string | null;
  sentence_examples?: DictionarySentenceExample[];
  audio?: DictionaryAudio | null;
  status: DictionaryStatus;
  created_at?: string | null;
  updated_at?: string | null;
};

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

export type DictionaryImportType = "vocabulary" | "sentence_examples" | "combined";

export type DictionaryImportSourceFormat = "csv" | "xlsx";

export type DictionaryImportResultSummary = {
  inserted?: number;
  updated?: number;
  skipped?: number;
  installed?: number;
  missing?: number;
  duplicate?: number;
  ambiguous?: number;
};

export type DictionaryImportAudioSummary = {
  files_found?: number;
  matched?: number;
  missing?: number;
  ambiguous?: number;
  unused?: number;
  installed?: number;
};

export type DictionaryImportSheetSummary = {
  total_rows?: number;
  valid_rows?: number;
  invalid_rows?: number;
  warning_count?: number;
  new_rows?: number;
  duplicate_rows?: number;
  error_breakdown?: Record<string, number>;
  [key: string]: unknown;
};

export type DictionaryImportSummary = DictionaryImportSheetSummary & {
  audio_referenced?: number;
  audio_missing?: number;
  unused_audio_files?: number;
  audio?: DictionaryImportAudioSummary;
  vocabulary?: DictionaryImportSheetSummary;
  sentence_examples?: DictionaryImportSheetSummary;
  vocabulary_result?: DictionaryImportResultSummary;
  sentence_examples_result?: DictionaryImportResultSummary;
  audio_result?: DictionaryImportResultSummary;
};

export type DictionaryImportJob = {
  id: string;
  status: DictionaryImportStatus;
  duplicate_strategy: DuplicateStrategy;
  import_type?: DictionaryImportType;
  source_format?: DictionaryImportSourceFormat;
  csv_original_name?: string | null;
  csv_size_bytes?: number | null;
  audio_zip_original_name?: string | null;
  audio_zip_size_bytes?: number | null;
  total_rows?: number | null;
  valid_rows?: number | null;
  invalid_rows?: number | null;
  inserted_rows?: number | null;
  updated_rows?: number | null;
  skipped_rows?: number | null;
  warning_count?: number | null;
  summary?: DictionaryImportSummary | null;
  failure_code?: string | null;
  failure_message?: string | null;
  started_at?: string | null;
  completed_at?: string | null;
  failed_at?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

export type DictionaryImportError = {
  id: string;
  row_number?: number | null;
  sheet?: string | null;
  field?: string | null;
  code?: string | null;
  message: string;
  raw_data?: Record<string, unknown> | null;
  created_at?: string | null;
};

export type PaginatedResult<T> = {
  items: T[];
  meta?: ApiPaginationMeta;
};

export type DictionaryEntryFilters = {
  search?: string;
  category_id?: string;
  status?: DictionaryStatus | "";
  has_audio?: boolean | "";
  page?: number;
  per_page?: number;
};

export type DictionaryCategoryFilters = {
  search?: string;
  status?: DictionaryStatus | "";
  page?: number;
  per_page?: number;
};

export type DictionaryImportFilters = {
  status?: DictionaryImportStatus | "";
  duplicate_strategy?: DuplicateStrategy | "";
  page?: number;
  per_page?: number;
};

export type DictionaryEntryPayload = {
  category_id: string;
  indonesia: string;
  english: string;
  mekongga: string;
  example_mekongga?: string | null;
  example_indonesia?: string | null;
  audio_media_id?: string | null;
  status?: DictionaryStatus;
};

export type DictionaryCategoryPayload = {
  name: string;
  description?: string | null;
  status?: DictionaryStatus;
};
