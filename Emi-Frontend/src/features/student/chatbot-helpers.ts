import type { ChatbotConversationMessage, ChatbotSource } from "./types";

export const CHATBOT_ANSWER_PREFIX = "Berdasarkan Basis AI EMI, berikut informasi yang ditemukan:";

export const CHATBOT_FALLBACK_ANSWER = "Hmm, aku belum menemukan jawaban yang tepat untuk pertanyaan itu.";

export type ChatMessage = {
  id: string;
  role: "user" | "assistant";
  content: string;
  citations?: ChatbotSource[];
  matched?: boolean;
};

export function displayAnswer(content: string) {
  return content.startsWith(CHATBOT_ANSWER_PREFIX) ? content.slice(CHATBOT_ANSWER_PREFIX.length).trim() : content;
}

export function sourceTypeLabel(sourceType?: string) {
  if (sourceType === "pdf") return "PDF / Dokumen";
  if (sourceType === "docx") return "Dokumen Word";
  if (sourceType === "txt") return "Berkas Teks";
  if (sourceType === "link") return "Link";
  return "Teks Manual";
}

export function sourceLinkLabel(sourceType?: string) {
  return sourceType === "pdf" || sourceType === "docx" || sourceType === "txt" ? "Buka dokumen sumber" : "Buka sumber";
}

export function messagesFromHistory(history: ChatbotConversationMessage[]): ChatMessage[] {
  return history.map((message) => ({
    id: message.id,
    role: message.role,
    content: message.content,
    citations: message.citations,
    matched: message.role === "assistant" ? message.citations.length > 0 : undefined,
  }));
}

export function citationsFromResponse(source: ChatbotSource | null, sources?: ChatbotSource[]): ChatbotSource[] {
  if (sources && sources.length > 0) return sources;
  if (source) return [source];
  return [];
}
