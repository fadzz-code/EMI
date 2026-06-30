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
  "Apa materi yang tersedia?",
];

type ChatMessage = {
  id: string;
  role: "user" | "assistant";
  content: string;
  source?: ChatbotSource | null;
  matched?: boolean;
  mode?: string;
  provider?: string;
};

function modeLabel(mode?: string, provider?: string) {
  if (mode === "default_extractive" && provider === "default") {
    return "Mode: Basis AI default";
  }

  return "Mode: Basis AI";
}

function createMessageId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

export function StudentChatbot() {
  const { token } = useAuth();
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>([]);
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
          <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 className="text-xl font-black text-ink">Percakapan</h2>
              <p className="mt-1 text-sm text-slate-600">
                Mulai percakapan dengan menanyakan hal yang tersedia di Basis AI EMI.
              </p>
            </div>
            <Badge tone="neutral">{modeLabel("default_extractive", "default")}</Badge>
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
                      Mulai percakapan dengan menanyakan hal yang tersedia di Basis AI EMI.
                    </p>
                  </div>
                </div>
              ) : (
                <div className="grid gap-4">
                  {messages.map((chat) => (
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
                        <p className="whitespace-pre-wrap">{chat.content}</p>
                        {chat.role === "assistant" ? (
                          <div className="mt-4 grid gap-2">
                            {chat.matched && chat.source ? (
                              <div className="rounded-xl border-2 border-ink bg-blue-50 p-3 text-xs leading-5 text-blue-950">
                                <p className="font-black">Sumber: {chat.source.title}</p>
                                <p>Kategori: {chat.source.category ?? "Umum"}</p>
                              </div>
                            ) : (
                              <div className="rounded-xl border-2 border-dashed border-ink bg-orange-50 p-3 text-xs font-bold leading-5 text-orange-950">
                                Belum ada referensi Basis AI yang cocok untuk pertanyaan ini.
                              </div>
                            )}
                            <p className="text-xs font-bold text-slate-500">
                              {modeLabel(chat.mode, chat.provider)}
                            </p>
                          </div>
                        ) : null}
                      </div>
                    </div>
                  ))}
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
