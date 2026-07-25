"use client";

import { type FormEvent, useState } from "react";
import { MessageSquarePlus, RotateCcw, SendHorizontal, Sparkles, Trash2 } from "lucide-react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, ConfirmDialog, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { cn } from "@/lib/utils";

import { CHATBOT_FALLBACK_ANSWER, type ChatMessage, citationsFromResponse, displayAnswer, messagesFromHistory, sourceLinkLabel, sourceTypeLabel } from "./chatbot-helpers";
import { studentService } from "./student-service";
import type { StudentChatbotResponse } from "./types";

const suggestedQuestions = [
  "Apa itu Bahasa Mekongga?",
  "Apa saja budaya Mekongga?",
  "Bagaimana cara belajar kosakata Mekongga?",
  "Apa arti nama Mekongga?",
  "Apa cerita rakyat Mekongga?",
];

function createMessageId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

function formatDateTime(value?: string | null) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(date);
}

export function StudentChatbot() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [message, setMessage] = useState("");
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [loadedConversationId, setLoadedConversationId] = useState<string | null>(null);
  const [expandedReferences, setExpandedReferences] = useState<Set<string>>(new Set());
  const [formError, setFormError] = useState<string | null>(null);
  const [pendingQuestion, setPendingQuestion] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
  const [historyOpenMobile, setHistoryOpenMobile] = useState(false);

  const conversationsQuery = useQuery({
    queryKey: ["chatbot", "conversations"],
    queryFn: () => studentService.chatbotConversations(token ?? ""),
    enabled: Boolean(token),
  });

  const detailQuery = useQuery({
    queryKey: ["chatbot", "conversation", conversationId],
    queryFn: () => studentService.chatbotConversationDetail(token ?? "", conversationId as string),
    enabled: Boolean(token && conversationId),
  });

  // Adjust state when the loaded conversation history changes, following
  // React's "adjusting state during render" pattern instead of an effect
  // (avoids an extra render + synchronous setState-in-effect lint error).
  if (detailQuery.data && detailQuery.data.id !== loadedConversationId) {
    setLoadedConversationId(detailQuery.data.id);
    setMessages(messagesFromHistory(detailQuery.data.messages));
  }

  const sendMutation = useMutation({
    mutationFn: (question: string) => studentService.sendChatbotMessage(token ?? "", question, conversationId),
    onSuccess: (response, question) => {
      appendResponse(question, response);
      setMessage("");
      setPendingQuestion(null);
      setFormError(null);
      // Mark this conversation as already loaded with fresh local state so
      // the render-time sync above does not immediately refetch and
      // overwrite the messages we just optimistically appended.
      setLoadedConversationId(response.conversation_id);
      if (response.conversation_id !== conversationId) {
        setConversationId(response.conversation_id);
      }
      void queryClient.invalidateQueries({ queryKey: ["chatbot", "conversations"] });
    },
    onError: () => {
      setFormError("Gagal mengirim pertanyaan. Coba lagi.");
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => studentService.deleteChatbotConversation(token ?? "", id),
    onSuccess: (_data, id) => {
      if (id === conversationId) {
        startNewSession();
      }
      void queryClient.invalidateQueries({ queryKey: ["chatbot", "conversations"] });
      setDeleteTarget(null);
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
        citations: citationsFromResponse(response.source, response.sources),
        matched: response.matched,
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
    setPendingQuestion(trimmed);
    sendMutation.mutate(trimmed);
  }

  function retryPending() {
    if (pendingQuestion) sendQuestion(pendingQuestion);
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    sendQuestion(message);
  }

  function toggleReference(messageId: string) {
    setExpandedReferences((current) => {
      const next = new Set(current);
      if (next.has(messageId)) next.delete(messageId);
      else next.add(messageId);
      return next;
    });
  }

  function startNewSession() {
    setConversationId(null);
    setLoadedConversationId(null);
    setMessages([]);
    setFormError(null);
    setPendingQuestion(null);
    setMessage("");
    setHistoryOpenMobile(false);
  }

  function openConversation(id: string) {
    setConversationId(id);
    setFormError(null);
    setPendingQuestion(null);
    setHistoryOpenMobile(false);
  }

  const apiError = sendMutation.error ? getFirstApiError(sendMutation.error) : null;
  const isPending = sendMutation.isPending;
  const conversations = conversationsQuery.data?.items ?? [];

  return (
    <div className="mx-auto flex min-h-[760px] max-w-6xl flex-col gap-4 lg:min-h-[820px] lg:flex-row">
      <aside className="hidden w-72 shrink-0 rounded-[var(--radius-card)] border-2 border-border bg-surface shadow-emi lg:flex lg:flex-col">
        <div className="flex items-center justify-between gap-2 border-b-2 border-border p-4">
          <p className="text-sm font-black uppercase tracking-[0.06em] text-muted">Riwayat</p>
          <Button aria-label="Sesi baru" className="size-9 rounded-full p-0" onClick={startNewSession} type="button" variant="secondary">
            <MessageSquarePlus className="size-4" strokeWidth={2.5} />
          </Button>
        </div>
        <div className="flex-1 overflow-y-auto p-3">
          {conversationsQuery.isLoading ? <p className="p-2 text-xs font-bold text-muted">Memuat riwayat...</p> : null}
          {!conversationsQuery.isLoading && conversations.length === 0 ? (
            <p className="p-2 text-xs font-bold text-muted">Belum ada percakapan tersimpan.</p>
          ) : null}
          <div className="grid gap-1">
            {conversations.map((conversation) => (
              <div
                className={cn(
                  "group flex items-center gap-1 rounded-xl border-2 p-2 text-left transition-colors",
                  conversation.id === conversationId
                    ? "border-border bg-accent/20"
                    : "border-transparent hover:border-border hover:bg-surface-muted",
                )}
                key={conversation.id}
              >
                <button
                  className="min-w-0 flex-1 text-left"
                  onClick={() => openConversation(conversation.id)}
                  type="button"
                >
                  <p className="truncate text-xs font-bold text-ink">{conversation.title ?? "Percakapan"}</p>
                  <p className="mt-0.5 text-[10px] font-semibold text-muted">{formatDateTime(conversation.last_message_at ?? conversation.created_at)}</p>
                </button>
                <button
                  aria-label="Hapus percakapan"
                  className="shrink-0 rounded-lg p-1.5 text-muted opacity-0 transition-opacity hover:bg-danger-muted hover:text-danger group-hover:opacity-100"
                  onClick={() => setDeleteTarget(conversation.id)}
                  type="button"
                >
                  <Trash2 className="size-3.5" strokeWidth={2.5} />
                </button>
              </div>
            ))}
          </div>
        </div>
      </aside>

      <div className="flex min-h-[760px] flex-1 flex-col overflow-hidden rounded-[var(--radius-card)] border-2 border-border bg-surface shadow-emi lg:min-h-[820px]">
        <header className="shrink-0 border-b-2 border-border bg-surface px-4 py-5 sm:px-6 sm:py-6">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div className="flex gap-3">
              <span className="flex size-11 shrink-0 items-center justify-center rounded-xl border-2 border-border bg-surface-muted text-ink">
                <Sparkles className="size-5" strokeWidth={2.5} />
              </span>
              <div>
                <p className="text-xl font-black text-ink">Chatbot AI EMI</p>
                <p className="mt-1 text-xs font-black uppercase tracking-[0.08em] text-muted">Basis pengetahuan</p>
                <p className="mt-3 max-w-2xl text-sm font-semibold leading-6 text-muted">
                  Tanyakan materi Bahasa Mekongga. EMI akan menjawab berdasarkan basis pengetahuan yang tersedia dan menampilkan referensi jika cocok.
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Button className="lg:hidden" onClick={() => setHistoryOpenMobile((current) => !current)} type="button" variant="secondary">
                Riwayat
              </Button>
              <Button onClick={startNewSession} type="button" variant="secondary">
                <MessageSquarePlus className="mr-2 size-4" strokeWidth={2.5} />
                Sesi Baru
              </Button>
              <Badge tone="blue">Aktif</Badge>
            </div>
          </div>

          {historyOpenMobile ? (
            <div className="mt-4 grid gap-1 rounded-xl border-2 border-border bg-surface-muted p-2 lg:hidden">
              {conversations.length === 0 ? <p className="p-2 text-xs font-bold text-muted">Belum ada percakapan tersimpan.</p> : null}
              {conversations.map((conversation) => (
                <div className="flex items-center gap-1" key={conversation.id}>
                  <button className="min-w-0 flex-1 rounded-lg p-2 text-left text-xs font-bold text-ink hover:bg-surface" onClick={() => openConversation(conversation.id)} type="button">
                    {conversation.title ?? "Percakapan"}
                  </button>
                  <button aria-label="Hapus percakapan" className="rounded-lg p-2 text-muted hover:bg-danger-muted hover:text-danger" onClick={() => setDeleteTarget(conversation.id)} type="button">
                    <Trash2 className="size-3.5" strokeWidth={2.5} />
                  </button>
                </div>
              ))}
            </div>
          ) : null}
        </header>

        <div className="flex-1 overflow-y-auto bg-surface-muted p-5 sm:p-8">
          <div className="grid gap-6">
            {formError ? <Alert tone="error">{formError}</Alert> : null}
            {apiError ? (
              <Alert tone="error">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <span>{apiError}</span>
                  <Button className="min-h-9 px-3 py-1 text-xs" onClick={retryPending} type="button" variant="secondary">
                    <RotateCcw className="mr-1 size-3.5" strokeWidth={2.5} />
                    Coba lagi
                  </Button>
                </div>
              </Alert>
            ) : null}
            {detailQuery.isError ? <Alert tone="error">Gagal memuat riwayat percakapan.</Alert> : null}

            {messages.length === 0 && !detailQuery.isLoading ? (
              <div className="flex justify-start">
                <div className="max-w-[85%] rounded-[18px] rounded-bl-[4px] border-2 border-border bg-surface p-4 text-sm font-semibold leading-6 text-ink shadow-[2px_2px_0_var(--border)] sm:max-w-[70%]">
                  <p className="font-black">Halo! Mau belajar apa hari ini?</p>
                  <p className="mt-2 text-muted">
                    Kamu bisa bertanya tentang kosakata, budaya, atau materi Bahasa Mekongga.
                  </p>
                </div>
              </div>
            ) : null}

            {detailQuery.isLoading ? (
              <div className="flex justify-start">
                <div className="rounded-[18px] rounded-bl-[4px] border-2 border-border bg-surface p-4 text-sm font-bold text-muted shadow-[2px_2px_0_var(--border)]">
                  Memuat percakapan...
                </div>
              </div>
            ) : null}

            {messages.map((chat) => {
              const referenceOpen = expandedReferences.has(chat.id);
              const citations = chat.citations ?? [];
              const canShowReference = chat.role === "assistant" && chat.matched && citations.length > 0;
              const isFallback = chat.role === "assistant" && !chat.matched && chat.content === CHATBOT_FALLBACK_ANSWER;
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
                          <span className="w-fit rounded-full border border-border bg-surface px-3 py-1 text-[11px] font-black uppercase tracking-[0.06em] text-ink">
                            Referensi tersedia
                          </span>
                        ) : null}

                        {isFallback ? (
                          <p className="rounded-xl border-2 border-dashed border-border bg-surface-muted p-3 text-xs font-bold leading-5 text-muted">
                            Coba gunakan kata kunci yang lebih spesifik atau tanyakan topik yang tersedia di Basis AI EMI.
                          </p>
                        ) : null}

                        {canShowReference ? (
                          <div className="grid gap-2">
                            <button
                              className="w-fit rounded-full border border-border bg-surface px-3 py-1 text-xs font-black text-ink underline-offset-2 hover:bg-accent/30"
                              onClick={() => toggleReference(chat.id)}
                              type="button"
                            >
                              {referenceOpen ? "Sembunyikan sumber" : `Sumber (${citations.length})`}
                            </button>
                            {referenceOpen ? (
                              <div className="grid gap-2">
                                {citations.map((source, index) => (
                                  <div className="rounded-xl border-2 border-border bg-surface p-3 text-xs leading-5 text-ink" key={source.chunk_id ?? `${source.id}-${index}`}>
                                    <p className="font-black">{source.title}</p>
                                    <p>Kategori: {source.category ?? "Umum"}</p>
                                    <p>Jenis sumber: {sourceTypeLabel(source.source_type)}</p>
                                    {source.page_number ? <p>Halaman: {source.page_number}</p> : null}
                                    {source.source_url ? (
                                      <a
                                        className="mt-2 inline-flex rounded-lg border-2 border-border bg-surface px-3 py-1 font-black text-ink underline hover:bg-accent/30"
                                        href={source.source_url}
                                        rel="noreferrer noopener"
                                        target="_blank"
                                      >
                                        {sourceLinkLabel(source.source_type)}
                                      </a>
                                    ) : null}
                                  </div>
                                ))}
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

        <form className="shrink-0 border-t-2 border-border bg-surface p-4 pb-[calc(1rem+env(safe-area-inset-bottom))] sm:p-6" onSubmit={submit}>
          <div className="mb-3 flex gap-2 overflow-x-auto pb-1">
            {suggestedQuestions.map((question) => (
              <button
                className="shrink-0 rounded-full border-2 border-border bg-surface px-4 py-2 text-xs font-black text-ink shadow-[1px_1px_0_var(--border)] hover:bg-accent/30 disabled:cursor-not-allowed disabled:opacity-60"
                disabled={isPending}
                key={question}
                onClick={() => sendQuestion(question)}
                type="button"
              >
                {question}
              </button>
            ))}
          </div>

          <div className="rounded-2xl border-2 border-border bg-surface p-2 shadow-[2px_2px_0_var(--border)]">
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

      <ConfirmDialog
        confirmLabel="Hapus Percakapan"
        description="Riwayat percakapan ini akan dihapus secara permanen dan tidak dapat dikembalikan."
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget)}
        open={Boolean(deleteTarget)}
        title="Hapus percakapan ini?"
      />
    </div>
  );
}
