"use client";

import { type FormEvent, useState } from "react";
import { SendHorizontal, Sparkles } from "lucide-react";
import { useMutation } from "@tanstack/react-query";

import { Alert, Badge, Button, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { cn } from "@/lib/utils";

import { studentService } from "./student-service";
import type { ChatbotSource, StudentChatbotResponse } from "./types";

const suggestedQuestions = [
  "Apa itu Bahasa Mekongga?",
  "Apa saja budaya Mekongga?",
  "Bagaimana cara belajar kosakata Mekongga?",
  "Apa arti nama Mekongga?",
  "Apa cerita rakyat Mekongga?",
];

const answerPrefix = "Berdasarkan Basis AI EMI, berikut informasi yang ditemukan:";

const fallbackAnswer = "Saya belum menemukan jawaban dari Basis AI yang tersedia.";

type ChatMessage = {
  id: string;
  role: "user" | "assistant";
  content: string;
  source?: ChatbotSource | null;
  matched?: boolean;
  mode?: string;
  provider?: string;
  confidence?: number;
};

function sourceTypeLabel(sourceType?: string) {
  if (sourceType === "pdf") {
    return "PDF / Dokumen";
  }

  if (sourceType === "link") {
    return "Link";
  }

  return "Teks Manual";
}

function sourceLinkLabel(sourceType?: string) {
  return sourceType === "pdf" ? "Buka PDF sumber" : "Buka sumber";
}

function createMessageId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

function displayAnswer(content: string) {
  return content.startsWith(answerPrefix) ? content.slice(answerPrefix.length).trim() : content;
}

export function StudentChatbot() {
  const { token } = useAuth();
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [expandedReferences, setExpandedReferences] = useState<Set<string>>(new Set());
  const [formError, setFormError] = useState<string | null>(null);

  const sendMutation = useMutation({
    mutationFn: (question: string) => studentService.sendChatbotMessage(token ?? "", question),
    onSuccess: (response, question) => {
      appendResponse(question, response);
      setMessage("");
      setFormError(null);
    },
    onError: () => {
      setFormError("Gagal mengirim pertanyaan. Coba lagi.");
    },
  });

  function appendResponse(question: string, response: StudentChatbotResponse) {
    setMessages((current) => [
      ...current,
      {
        id: createMessageId(),
        role: "user",
        content: question,
      },
      {
        id: createMessageId(),
        role: "assistant",
        content: response.answer,
        source: response.source,
        matched: response.matched,
        mode: response.mode,
        provider: response.provider,
        confidence: response.confidence,
      },
    ]);
  }

  function sendQuestion(question: string) {
    const trimmed = question.trim();

    if (!trimmed) {
      setFormError("Masukkan pertanyaan terlebih dahulu.");
      return;
    }

    setFormError(null);
    sendMutation.mutate(trimmed);
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    sendQuestion(message);
  }

  function toggleReference(messageId: string) {
    setExpandedReferences((current) => {
      const next = new Set(current);

      if (next.has(messageId)) {
        next.delete(messageId);
      } else {
        next.add(messageId);
      }

      return next;
    });
  }

  const apiError = sendMutation.error ? getFirstApiError(sendMutation.error) : null;
  const isPending = sendMutation.isPending;

  return (
    <div className="mx-auto flex min-h-[calc(100vh-12rem)] max-w-4xl flex-col overflow-hidden rounded-[var(--radius-card)] border-2 border-border bg-[var(--color-paper)] shadow-emi lg:min-h-[calc(100vh-10rem)]">
      <header className="shrink-0 border-b-2 border-border bg-surface px-4 py-4 sm:px-5">
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <span className="flex size-9 items-center justify-center rounded-full border-2 border-border bg-accent text-accent-foreground shadow-[2px_2px_0_var(--border)]">
                <Sparkles className="size-4" strokeWidth={3} />
              </span>
              <div>
                <p className="text-lg font-black text-ink">Chatbot AI EMI</p>
                <p className="text-xs font-bold uppercase tracking-[0.08em] text-muted">Basis pengetahuan</p>
              </div>
            </div>
            <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-muted">
              Tanyakan materi Bahasa Mekongga. EMI akan menjawab berdasarkan basis pengetahuan yang tersedia dan menampilkan referensi jika cocok.
            </p>
          </div>
          <Badge tone="blue">Aktif</Badge>
        </div>
      </header>

      <div className="flex-1 overflow-y-auto bg-[radial-gradient(circle_at_1px_1px,rgba(29,27,23,0.08)_1px,transparent_0)] [background-size:18px_18px] p-4 sm:p-5">
        <div className="grid gap-4">
          {formError ? <Alert tone="error">{formError}</Alert> : null}
          {apiError ? <Alert tone="error">{apiError}</Alert> : null}

          {messages.length === 0 ? (
            <div className="flex justify-start">
              <div className="max-w-[85%] rounded-[18px] rounded-bl-[4px] border-2 border-border bg-surface p-4 text-sm font-semibold leading-6 text-ink shadow-[2px_2px_0_var(--border)] sm:max-w-[70%]">
                <p className="font-black">Halo! Mau belajar apa hari ini?</p>
                <p className="mt-2 text-muted">
                  Kamu bisa bertanya tentang kosakata, budaya, atau materi Bahasa Mekongga.
                </p>
              </div>
            </div>
          ) : null}

          {messages.map((chat) => {
            const referenceOpen = expandedReferences.has(chat.id);
            const canShowReference = chat.role === "assistant" && chat.matched && chat.source;
            const isFallback = chat.role === "assistant" && !chat.matched && chat.content === fallbackAnswer;
            const isUser = chat.role === "user";

            return (
              <div className={isUser ? "flex justify-end" : "flex justify-start"} key={chat.id}>
                <div
                  className={cn(
                    "max-w-[86%] border-2 border-border p-4 text-sm leading-6 shadow-[2px_2px_0_var(--border)] sm:max-w-[72%]",
                    isUser
                      ? "rounded-[18px] rounded-br-[4px] bg-accent font-bold text-accent-foreground"
                      : "rounded-[18px] rounded-bl-[4px] bg-surface font-semibold text-ink",
                  )}
                >
                  <p className="whitespace-pre-wrap">{displayAnswer(chat.content)}</p>

                  {chat.role === "assistant" ? (
                    <div className="mt-3 grid gap-2">
                      {chat.matched ? (
                        <span className="w-fit rounded-full border border-border bg-paper px-3 py-1 text-[11px] font-black uppercase tracking-[0.06em] text-ink">
                          Referensi tersedia
                        </span>
                      ) : null}

                      {isFallback ? (
                        <p className="rounded-xl border-2 border-dashed border-border bg-orange-50 p-3 text-xs font-bold leading-5 text-orange-950">
                          Coba gunakan kata kunci yang lebih spesifik atau tanyakan topik yang tersedia di Basis AI EMI.
                        </p>
                      ) : null}

                      {canShowReference ? (
                        <div className="grid gap-2">
                          <button
                            className="w-fit rounded-full border border-border bg-paper px-3 py-1 text-xs font-black text-ink underline-offset-2 hover:bg-accent/30"
                            onClick={() => toggleReference(chat.id)}
                            type="button"
                          >
                            {referenceOpen ? "Sembunyikan sumber" : `Sumber: ${chat.source?.title ?? "Basis AI"}`}
                          </button>
                          {referenceOpen ? (
                            <div className="rounded-xl border-2 border-border bg-paper p-3 text-xs leading-5 text-ink">
                              <p className="font-black">{chat.source?.title}</p>
                              <p>Kategori: {chat.source?.category ?? "Umum"}</p>
                              <p>Jenis sumber: {sourceTypeLabel(chat.source?.source_type)}</p>
                              {chat.source?.source_url ? (
                                <a
                                  className="mt-2 inline-flex rounded-lg border-2 border-border bg-surface px-3 py-1 font-black text-ink underline hover:bg-accent/30"
                                  href={chat.source.source_url}
                                  rel="noreferrer noopener"
                                  target="_blank"
                                >
                                  {sourceLinkLabel(chat.source.source_type)}
                                </a>
                              ) : null}
                            </div>
                          ) : null}
                        </div>
                      ) : null}
                    </div>
                  ) : null}
                </div>
              </div>
            );
          })}

          {isPending ? (
            <div className="flex justify-start">
              <div className="rounded-[18px] rounded-bl-[4px] border-2 border-border bg-surface p-4 text-sm font-bold text-muted shadow-[2px_2px_0_var(--border)]">
                EMI sedang mencari jawaban...
              </div>
            </div>
          ) : null}
        </div>
      </div>

      <form className="shrink-0 border-t-2 border-border bg-surface p-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))] sm:p-4" onSubmit={submit}>
        <div className="mb-3 flex gap-2 overflow-x-auto pb-1">
          {suggestedQuestions.map((question) => (
            <button
              className="shrink-0 rounded-full border-2 border-border bg-paper px-4 py-2 text-xs font-black text-ink shadow-[1px_1px_0_var(--border)] hover:bg-accent/30 disabled:cursor-not-allowed disabled:opacity-60"
              disabled={isPending}
              key={question}
              onClick={() => sendQuestion(question)}
              type="button"
            >
              {question}
            </button>
          ))}
        </div>

        <div className="rounded-2xl border-2 border-border bg-paper p-2 shadow-[2px_2px_0_var(--border)]">
          <Textarea
            className="min-h-20 border-0 bg-transparent shadow-none focus-visible:ring-0"
            disabled={isPending}
            onChange={(event) => setMessage(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter" && !event.shiftKey) {
                event.preventDefault();
                sendQuestion(message);
              }
            }}
            placeholder="Tanyakan materi, kosakata, atau budaya Mekongga..."
            value={message}
          />
          <div className="mt-2 flex items-center justify-between gap-3 border-t border-border/20 pt-2">
            <p className="text-[11px] font-bold text-muted">
              Enter kirim, Shift+Enter baris baru.
            </p>
            <Button aria-label="Kirim pertanyaan" className="size-11 rounded-full p-0" disabled={isPending} type="submit">
              <SendHorizontal className="size-5" strokeWidth={3} />
            </Button>
          </div>
        </div>

        <p className="mt-3 text-[11px] font-bold leading-5 text-muted">
          Jawaban berasal dari Basis AI yang dipublish admin. AI bisa keliru; cek referensi saat tersedia.
        </p>
      </form>
    </div>
  );
}
