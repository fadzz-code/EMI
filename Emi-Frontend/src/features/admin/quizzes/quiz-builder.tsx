"use client";

import Link from "next/link";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  EmptyState,
  ErrorState,
  LoadingState,
  Modal,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { QuestionCard } from "./question-card";
import { QuestionForm } from "./question-form";
import { QuizTemplateForm } from "./quiz-form";
import { quizQuestionService, quizTemplateService } from "./quiz-service";
import { formatDate, statusLabel, statusTone } from "./quiz-utils";
import type { QuizQuestionPayload, QuizTemplatePayload, QuizTemplateQuestion } from "./types";

export function QuizBuilder({ quizId }: { quizId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [createQuestionOpen, setCreateQuestionOpen] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState<QuizTemplateQuestion | null>(null);
  const [deleteQuestionTarget, setDeleteQuestionTarget] =
    useState<QuizTemplateQuestion | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const quizQuery = useQuery({
    queryKey: ["admin", "quiz-templates", quizId],
    queryFn: () => quizTemplateService.detail(token ?? "", quizId),
    enabled: Boolean(token),
  });

  const questionsQuery = useQuery({
    queryKey: ["admin", "quiz-templates", quizId, "questions"],
    queryFn: () => quizQuestionService.list(token ?? "", quizId),
    enabled: Boolean(token),
  });

  async function invalidateQuiz() {
    await queryClient.invalidateQueries({ queryKey: ["admin", "quiz-templates"] });
  }

  const updateQuizMutation = useMutation({
    mutationFn: (payload: QuizTemplatePayload) =>
      quizTemplateService.update(token ?? "", quizId, payload),
    onSuccess: async (quiz) => {
      setSuccessMessage(`Metadata kuis ${quiz.title} berhasil disimpan.`);
      await invalidateQuiz();
    },
  });

  const publishQuizMutation = useMutation({
    mutationFn: () => quizTemplateService.publish(token ?? "", quizId),
    onSuccess: async (quiz) => {
      setSuccessMessage(`Kuis ${quiz.title} berhasil diterbitkan.`);
      await invalidateQuiz();
    },
  });

  const archiveQuizMutation = useMutation({
    mutationFn: () => quizTemplateService.archive(token ?? "", quizId),
    onSuccess: async (quiz) => {
      setSuccessMessage(`Kuis ${quiz.title} berhasil diarsipkan.`);
      await invalidateQuiz();
    },
  });

  const createQuestionMutation = useMutation({
    mutationFn: (payload: QuizQuestionPayload) =>
      quizQuestionService.create(token ?? "", quizId, payload),
    onSuccess: async (question) => {
      setSuccessMessage(`Soal #${question.order_number} berhasil dibuat.`);
      setCreateQuestionOpen(false);
      await invalidateQuiz();
    },
  });

  const updateQuestionMutation = useMutation({
    mutationFn: ({
      payload,
      questionId,
    }: {
      payload: QuizQuestionPayload;
      questionId: string;
    }) => quizQuestionService.update(token ?? "", questionId, payload),
    onSuccess: async (question) => {
      setSuccessMessage(`Soal #${question.order_number} berhasil diperbarui.`);
      setEditingQuestion(null);
      await invalidateQuiz();
    },
  });

  const deleteQuestionMutation = useMutation({
    mutationFn: (questionId: string) => quizQuestionService.delete(token ?? "", questionId),
    onSuccess: async () => {
      setSuccessMessage("Soal berhasil dihapus dari daftar aktif.");
      setDeleteQuestionTarget(null);
      await invalidateQuiz();
    },
  });

  const reorderQuestionMutation = useMutation({
    mutationFn: (questionIds: string[]) =>
      quizQuestionService.reorder(token ?? "", quizId, questionIds),
    onSuccess: async () => {
      setSuccessMessage("Urutan soal berhasil diperbarui.");
      await invalidateQuiz();
    },
  });

  const quiz = quizQuery.data;
  const questions = questionsQuery.data ?? [];
  const isPublished = quiz?.status === "published";
  const actionError =
    updateQuizMutation.error ??
    publishQuizMutation.error ??
    archiveQuizMutation.error ??
    createQuestionMutation.error ??
    updateQuestionMutation.error ??
    deleteQuestionMutation.error ??
    reorderQuestionMutation.error;

  function moveQuestion(index: number, direction: -1 | 1) {
    const targetIndex = index + direction;

    if (targetIndex < 0 || targetIndex >= questions.length) {
      return;
    }

    const ids = questions.map((question) => question.id);
    const current = ids[index];
    ids[index] = ids[targetIndex] ?? ids[index];
    ids[targetIndex] = current;
    reorderQuestionMutation.mutate(ids);
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="blue">ADMIN-16</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">
            {quiz?.title ?? "Builder Soal Kuis"}
          </h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 font-semibold text-muted">
            Bangun soal template kuis default, atur urutan, poin, gambar soal,
            dan pembahasan sebelum kuis diterbitkan.
          </p>
        </div>
        <Link
          className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-border bg-surface px-4 py-2 text-sm font-bold text-ink hover:bg-surface-muted"
          href="/admin/quizzes"
        >
          Kembali ke Daftar
        </Link>
      </header>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}
      {isPublished ? (
        <Alert tone="warning">
          Kuis yang sudah terbit dikunci agar konten soal tetap stabil. Arsipkan atau
          buat kuis baru jika perlu mengubah isi soal.
        </Alert>
      ) : null}

      {quizQuery.isLoading ? <LoadingState title="Memuat kuis" /> : null}
      {quizQuery.isError ? (
        <ErrorState
          description={getFirstApiError(quizQuery.error)}
          onRetry={() => void quizQuery.refetch()}
          title="Gagal memuat kuis"
        />
      ) : null}

      {quiz ? (
        <div className="grid items-start gap-6 xl:grid-cols-[minmax(320px,380px)_1fr]">
          <Card>
            <CardHeader>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <h2 className="text-xl font-black text-ink">Metadata Kuis</h2>
                <Badge tone={statusTone(quiz.status)}>{statusLabel(quiz.status)}</Badge>
              </div>
              <p className="text-xs font-semibold text-muted">
                Dibuat: {formatDate(quiz.created_at)} | Diubah: {formatDate(quiz.updated_at)}
              </p>
              <p className="mt-2 text-sm leading-6 font-semibold text-muted">
                Simpan metadata kuis terpisah dari daftar soal agar perubahan mudah diperiksa.
              </p>
            </CardHeader>
            <CardContent>
              <QuizTemplateForm
                isSubmitting={updateQuizMutation.isPending}
                onCancel={() => void quizQuery.refetch()}
                onSubmit={(payload) => updateQuizMutation.mutate(payload)}
                quiz={quiz}
              />
              <div className="mt-5 flex flex-col gap-2 border-t-2 border-border pt-4 sm:flex-row">
                <Button
                  disabled={publishQuizMutation.isPending || quiz.status === "published"}
                  onClick={() => publishQuizMutation.mutate()}
                  variant="secondary"
                >
                  Terbitkan Kuis
                </Button>
                <Button
                  disabled={archiveQuizMutation.isPending || quiz.status === "archived"}
                  onClick={() => archiveQuizMutation.mutate()}
                  variant="ghost"
                >
                  Arsipkan Kuis
                </Button>
              </div>
            </CardContent>
          </Card>

          <div className="grid gap-4">
            <Card>
              <CardHeader>
                <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                  <div>
                    <h2 className="text-xl font-black text-ink">Daftar Soal</h2>
                    <p className="mt-1 text-sm font-semibold text-muted">
                      Total soal aktif: {questions.length}
                    </p>
                  </div>
                  <Button
                    disabled={isPublished}
                    onClick={() => setCreateQuestionOpen(true)}
                  >
                    Tambah Soal
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                {questionsQuery.isLoading ? <LoadingState title="Memuat soal" /> : null}
                {questionsQuery.isError ? (
                  <ErrorState
                    description={getFirstApiError(questionsQuery.error)}
                    onRetry={() => void questionsQuery.refetch()}
                    title="Gagal memuat soal"
                  />
                ) : null}
                {!questionsQuery.isLoading && !questionsQuery.isError ? (
                  questions.length === 0 ? (
                    <EmptyState
                      description="Belum ada soal. Tambahkan minimal satu soal valid sebelum menerbitkan kuis."
                      title="Soal kosong"
                    />
                  ) : (
                    <div className="grid gap-4">
                      {questions.map((question, index) => (
                        <QuestionCard
                          canMoveDown={index < questions.length - 1}
                          canMoveUp={index > 0}
                          disabledActions={isPublished}
                          isReordering={reorderQuestionMutation.isPending}
                          key={question.id}
                          onDelete={() => setDeleteQuestionTarget(question)}
                          onEdit={() => setEditingQuestion(question)}
                          onMoveDown={() => moveQuestion(index, 1)}
                          onMoveUp={() => moveQuestion(index, -1)}
                          question={question}
                        />
                      ))}
                    </div>
                  )
                ) : null}
              </CardContent>
            </Card>
          </div>
        </div>
      ) : null}

      <Modal
        onClose={() => setCreateQuestionOpen(false)}
        open={createQuestionOpen}
        title="Tambah Soal Kuis"
      >
        <QuestionForm
          defaultOrder={questions.length + 1}
          isSubmitting={createQuestionMutation.isPending}
          onCancel={() => setCreateQuestionOpen(false)}
          onSubmit={(payload) => createQuestionMutation.mutate(payload)}
          token={token ?? ""}
        />
      </Modal>

      <Modal
        onClose={() => setEditingQuestion(null)}
        open={Boolean(editingQuestion)}
        title="Edit Soal Kuis"
      >
        {editingQuestion ? (
          <QuestionForm
            isSubmitting={updateQuestionMutation.isPending}
            onCancel={() => setEditingQuestion(null)}
            onSubmit={(payload) =>
              updateQuestionMutation.mutate({ payload, questionId: editingQuestion.id })
            }
            question={editingQuestion}
            token={token ?? ""}
          />
        ) : null}
      </Modal>

      <ConfirmDialog
        confirmLabel={deleteQuestionMutation.isPending ? "Menghapus..." : "Hapus Soal"}
        description={
          deleteQuestionTarget
            ? `Soal #${deleteQuestionTarget.order_number} akan dihapus dari daftar aktif.`
            : ""
        }
        onCancel={() => setDeleteQuestionTarget(null)}
        onConfirm={() => {
          if (deleteQuestionTarget) {
            deleteQuestionMutation.mutate(deleteQuestionTarget.id);
          }
        }}
        open={Boolean(deleteQuestionTarget)}
        title="Hapus soal?"
      />
    </div>
  );
}
