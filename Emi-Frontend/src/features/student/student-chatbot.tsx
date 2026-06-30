"use client";

import { type FormEvent, useState } from "react";
import { useMutation } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, PageHeader, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

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
    <div className="grid gap-6">
      <PageHeader
        badge="Basis AI"
        description="Ajukan pertanyaan berdasarkan Basis AI yang sudah dipublish admin."
        title="Chatbot AI"
      />

      <Card>
        <CardHeader>
          <div className="flex items-start justify-between gap-3">
            <div>
              <h2 className="text-xl font-black text-ink">Asisten Belajar EMI</h2>
              <p className="mt-2 text-sm leading-6 text-slate-600">
                Chatbot menjawab berdasarkan referensi Basis AI EMI. Jika referensi belum tersedia, chatbot akan memberi tahu bahwa jawaban belum ditemukan.
              </p>
            </div>
            <Badge tone="blue">Aktif</Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-2xl border-2 border-ink bg-blue-50 p-4 text-sm font-bold leading-6 text-blue-950">
            Jawaban berasal dari pengetahuan yang sudah dipublish admin, bukan dari AI bebas tanpa sumber.
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Contoh pertanyaan</h2>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            {suggestedQuestions.map((question) => (
              <button
                className="rounded-full border-2 border-ink bg-white px-4 py-2 text-sm font-black text-ink hover:bg-yellow-100 disabled:cursor-not-allowed disabled:opacity-60"
                disabled={isPending}
                key={question}
                onClick={() => sendQuestion(question)}
                type="button"
              >
                {question}
              </button>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div>
            <h2 className="text-xl font-black text-ink">Percakapan</h2>
            <p className="mt-1 text-sm text-slate-600">
              Mulai percakapan dengan menanyakan hal yang tersedia di Basis AI EMI.
            </p>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            {formError ? <Alert tone="error">{formError}</Alert> : null}
            {apiError ? <Alert tone="error">{apiError}</Alert> : null}

            <div className="grid min-h-72 gap-4 rounded-2xl border-2 border-ink bg-slate-50 p-4">
              {messages.length === 0 ? (
                <div className="flex min-h-56 items-center justify-center rounded-xl border-2 border-dashed border-ink bg-white p-6 text-center">
                  <div>
                    <p className="text-lg font-black text-ink">Mulai percakapan</p>
                    <p className="mt-2 max-w-md text-sm leading-6 text-slate-600">
                      Mulai percakapan dengan menanyakan hal yang tersedia di Basis AI EMI. Agar jawaban lebih tepat, tuliskan pertanyaan dengan kata kunci yang jelas.
                    </p>
                  </div>
                </div>
              ) : (
                <div className="grid gap-4">
                  {messages.map((chat) => {
                    const referenceOpen = expandedReferences.has(chat.id);
                    const canShowReference = chat.role === "assistant" && chat.matched && chat.source;
                    const isFallback = chat.role === "assistant" && !chat.matched && chat.content === fallbackAnswer;

                    return (
                      <div
                        className={chat.role === "user" ? "flex justify-end" : "flex justify-start"}
                        key={chat.id}
                      >
                        <div
                          className={
                            chat.role === "user"
                              ? "max-w-3xl rounded-2xl border-2 border-ink bg-yellow-200 p-4 text-sm font-bold leading-6 text-ink shadow-brutal"
                              : "max-w-3xl rounded-2xl border-2 border-ink bg-white p-4 text-sm leading-6 text-slate-800 shadow-brutal"
                          }
                        >
                          <p className="whitespace-pre-wrap">{displayAnswer(chat.content)}</p>
                          {chat.role === "assistant" ? (
                            <div className="mt-4 grid gap-2">
                              {chat.matched ? (
                                <p className="text-xs font-bold text-slate-500">
                                  Jawaban berdasarkan Basis AI EMI
                                </p>
                              ) : null}
                              {isFallback ? (
                                <p className="rounded-xl border-2 border-dashed border-ink bg-orange-50 p-3 text-xs font-bold leading-5 text-orange-950">
                                  Coba gunakan kata kunci yang lebih spesifik atau tanyakan topik yang tersedia di Basis AI EMI.
                                </p>
                              ) : null}
                              {canShowReference ? (
                                <div className="grid gap-2">
                                  <button
                                    className="w-fit text-xs font-black text-blue-700 underline hover:text-blue-900"
                                    onClick={() => toggleReference(chat.id)}
                                    type="button"
                                  >
                                    {referenceOpen ? "Sembunyikan referensi" : "Lihat referensi"}
                                  </button>
                                  {referenceOpen ? (
                                    <div className="rounded-xl border-2 border-ink bg-blue-50 p-3 text-xs leading-5 text-blue-950">
                                      <p className="font-black">{chat.source?.title}</p>
                                      <p>Kategori: {chat.source?.category ?? "Umum"}</p>
                                      <p>Jenis sumber: {sourceTypeLabel(chat.source?.source_type)}</p>
                                      {chat.source?.source_url ? (
                                        <a
                                          className="mt-2 inline-flex rounded-lg border-2 border-ink bg-white px-3 py-1 font-black text-blue-800 underline hover:bg-yellow-100"
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
                      <div className="rounded-2xl border-2 border-ink bg-white p-4 text-sm font-bold text-slate-700 shadow-brutal">
                        Mengirim pertanyaan ke Basis AI...
                      </div>
                    </div>
                  ) : null}
                </div>
              )}
            </div>

            <div className="rounded-xl border-2 border-dashed border-ink bg-white p-3 text-xs font-bold leading-5 text-slate-600">
              Jawaban berasal dari Basis AI yang dipublish admin. PDF atau link sumber hanya dapat dijawab jika isi pentingnya sudah dimasukkan ke Konten Pengetahuan.
            </div>

            <form className="grid gap-3" onSubmit={submit}>
              <Textarea
                className="min-h-28"
                disabled={isPending}
                onChange={(event) => setMessage(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter" && !event.shiftKey) {
                    event.preventDefault();
                    sendQuestion(message);
                  }
                }}
                placeholder="Tanyakan sesuatu tentang Bahasa Mekongga, budaya, modul, atau materi yang tersedia..."
                value={message}
              />
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <p className="text-xs font-bold text-slate-500">
                  Tekan Enter untuk kirim, Shift+Enter untuk baris baru.
                </p>
                <Button disabled={isPending} type="submit">
                  {isPending ? "Mengirim..." : "Kirim"}
                </Button>
              </div>
            </form>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
