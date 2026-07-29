import { apiClient } from "@/lib/api-client";

import type {
  AiKnowledgeFilters,
  AiKnowledgeItem,
  AiKnowledgePayload,
  AiKnowledgePdfImportResult,
  AiKnowledgeSourceExtraction,
  PaginatedResult,
} from "./types";

function paginated<T>(data: T[] | undefined, meta: unknown): PaginatedResult<T> {
  return {
    items: data ?? [],
    meta: meta as PaginatedResult<T>["meta"],
  };
}

export const knowledgeBaseService = {
  async list(token: string, filters: AiKnowledgeFilters = {}) {
    return paginated<AiKnowledgeItem>([], { current_page: 1, last_page: 1, total: 0 });
  },

  async create(token: string, payload: AiKnowledgePayload) {
    return { 
      id: "dummy", 
      ...payload, 
      created_at: new Date().toISOString(), 
      updated_at: new Date().toISOString(),
      source_type: payload.source_type ?? "manual",
      status: payload.status ?? "draft",
    } as AiKnowledgeItem;
  },

  async update(token: string, itemId: string, payload: AiKnowledgePayload) {
    return { 
      id: itemId, 
      ...payload, 
      created_at: new Date().toISOString(), 
      updated_at: new Date().toISOString(),
      source_type: payload.source_type ?? "manual",
      status: payload.status ?? "draft",
    } as AiKnowledgeItem;
  },

  async extractKnowledgeSource(
    token: string,
    payload: { source_type: "link" | "pdf"; source_url: string },
  ) {
    return { content: "Draft konten...", source_url: payload.source_url } as AiKnowledgeSourceExtraction;
  },

  async extractPdfUpload(token: string, file: File) {
    return { content: "Draft konten..." } as AiKnowledgeSourceExtraction;
  },

  async extractDocumentUpload(token: string, file: File) {
    return { content: "Draft konten..." } as AiKnowledgeSourceExtraction;
  },

  async importPdfSource(
    token: string,
    payload: { title: string; category?: string | null; file: File; status?: "draft" | "published" },
  ) {
    return { item: { id: "dummy", title: payload.title, status: payload.status ?? "draft", source_type: "pdf", created_at: new Date().toISOString(), updated_at: new Date().toISOString() } } as unknown as AiKnowledgePdfImportResult;
  },

  async delete(token: string, itemId: string) {
    return;
  },

  async publish(token: string, itemId: string) {
    return { id: itemId, status: "published", created_at: new Date().toISOString(), updated_at: new Date().toISOString(), source_type: "manual" } as AiKnowledgeItem;
  },

  async archive(token: string, itemId: string) {
    return { id: itemId, status: "archived", created_at: new Date().toISOString(), updated_at: new Date().toISOString(), source_type: "manual" } as AiKnowledgeItem;
  },
};
