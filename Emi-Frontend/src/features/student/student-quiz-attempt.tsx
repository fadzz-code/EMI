"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { studentQuizService } from "./student-quiz-service";

export function StudentQuizAttempt({ quizId }: { quizId: string }) {
  const { token } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const attemptId = searchParams.get("attemptId");
  const queryClient = useQueryClient();

  const [idempotencyKey] = useState(() => crypto.randomUUID());
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [selectedOptions, setSelectedOptions] = useState<Record<string, string>>({});
  const [shortAnswers, setShortAnswers] = useState<Record<string, string>>({});

  const quizQuery = useQuery({
    queryKey: ["student", "quizzes", quizId],
    queryFn: () => studentQuizService.detail(token ?? "", quizId),
    enabled: Boolean(token && quizId),
  });

  const attemptQuery = useQuery({
    queryKey: ["student", "quiz-attempts", attemptId],
    queryFn: () => studentQuizService.attemptDetail(token ?? "", attemptId ?? ""),
    enabled: Boolean(token && attemptId),
  });

  const saveAnswerMutation = useMutation({
    mutationFn: ({ questionId, answerText, optionId }: { questionId: string; answerText?: string; optionId?: string }) =>
      studentQuizService.saveAnswer(token ?? "", attemptId ?? "", questionId, {
        answer_text: answerText,
        selected_option_id: optionId,
      }),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["student", "quiz-attempts", attemptId] });
    },
  });

  const submitMutation = useMutation({
    mutationFn: () => studentQuizService.submitAttempt(token ?? "", attemptId ?? "", idempotencyKey),
    onSuccess: (attempt) => {
      router.replace(`/student/quizzes/${quizId}/result?attemptId=${attempt.id}`);
    },
  });

  if (!attemptId) {
    return <ErrorState description="ID Attempt tidak ditemukan di URL." title="Data tidak lengkap" />;
  }

  const isLoading = quizQuery.isLoading || attemptQuery.isLoading;
  const isError = quizQuery.isError || attemptQuery.isError;
  const error = quizQuery.error || attemptQuery.error;

  const quiz = quizQuery.data;
  const attempt = attemptQuery.data;
  const questions = quiz?.questions ?? [];
  const currentQuestion = questions[currentQuestionIndex];
  const existingAnswer = attempt?.answers?.find((answer) => answer.quiz_question_id === currentQuestion?.id);
  const selectedOptionId = currentQuestion ? selectedOptions[currentQuestion.id] ?? existingAnswer?.selected_option_id : undefined;
  const shortAnswer = currentQuestion ? shortAnswers[currentQuestion.id] ?? existingAnswer?.answer_text ?? "" : "";

  function handleOptionSelect(optionId: string) {
    if (!currentQuestion || attempt?.status !== "in_progress") return;
    setSelectedOptions((current) => ({ ...current, [currentQuestion.id]: optionId }));
    saveAnswerMutation.mutate({ questionId: currentQuestion.id, optionId });
  }

  function handleShortAnswerBlur(text: string) {
    if (!currentQuestion || attempt?.status !== "in_progress") return;
    setShortAnswers((current) => ({ ...current, [currentQuestion.id]: text }));
    saveAnswerMutation.mutate({ questionId: currentQuestion.id, answerText: text });
  }

  function handleNext() {
    if (currentQuestionIndex < questions.length - 1) {
      setCurrentQuestionIndex((prev) => prev + 1);
    }
  }

  function handlePrev() {
    if (currentQuestionIndex > 0) {
      setCurrentQuestionIndex((prev) => prev - 1);
    }
  }

  return (
    <div className="grid gap-6">
      {isLoading ? <LoadingState title="Memuat soal kuis" /> : null}
      {isError ? <ErrorState description={getFirstApiError(error)} onRetry={() => { quizQuery.refetch(); attemptQuery.refetch(); }} title="Gagal memuat soal" /> : null}

      {!isLoading && !isError && attempt && attempt.status !== "in_progress" ? (
        <ErrorState
          description="Attempt ini sudah selesai atau kedaluwarsa. Buka halaman hasil untuk melihat status terbaru."
          onRetry={() => router.replace(`/student/quizzes/${quizId}/result?attemptId=${attempt.id}`)}
          title="Attempt tidak aktif"
        />
      ) : null}

      {!isLoading && !isError && quiz && attempt?.status === "in_progress" && currentQuestion ? (
        <>
          <header className="flex flex-wrap items-center justify-between gap-4 rounded-3xl border-2 border-ink bg-white p-5 shadow-brutal">
            <div>
              <h1 className="text-xl font-black text-ink">{quiz.title}</h1>
              <p className="text-sm text-slate-600">Soal {currentQuestionIndex + 1} dari {questions.length}</p>
            </div>
            {submitMutation.error ? <Alert tone="error">{getFirstApiError(submitMutation.error)}</Alert> : null}
            <Button
              className="bg-green-600 hover:bg-green-700"
              disabled={submitMutation.isPending}
              onClick={() => {
                if (window.confirm("Apakah Anda yakin ingin mengumpulkan kuis ini sekarang?")) {
                  submitMutation.mutate();
                }
              }}
            >
              Kumpulkan Kuis
            </Button>
          </header>

          <Card>
            <CardHeader>
              <h2 className="text-lg font-black text-ink">{currentQuestion.question_text}</h2>
              {currentQuestion.image_media?.url ? (
                <img alt="Soal" className="mt-4 max-h-64 rounded-xl border-2 border-ink object-cover" src={currentQuestion.image_media.url} />
              ) : null}
            </CardHeader>
            <CardContent>
              {saveAnswerMutation.isError ? <Alert className="mb-4" tone="error">{getFirstApiError(saveAnswerMutation.error)}</Alert> : null}
              {saveAnswerMutation.isPending ? <p className="mb-4 text-sm font-bold text-yellow-600">Menyimpan jawaban...</p> : null}
              
              {currentQuestion.question_type === "multiple_choice" ? (
                <div className="grid gap-3">
                  {currentQuestion.options?.map((option) => {
                    const isSelected = selectedOptionId === option.id;
                    return (
                      <button
                        className={`flex min-h-12 w-full items-center rounded-xl border-2 px-4 py-2 text-left font-bold transition-colors ${
                          isSelected ? "border-blue-600 bg-blue-50 text-blue-900 shadow-[4px_4px_0_#2563eb]" : "border-ink bg-white text-ink hover:bg-slate-50"
                        }`}
                        key={option.id}
                        onClick={() => handleOptionSelect(option.id)}
                        type="button"
                      >
                        {option.option_text}
                      </button>
                    );
                  })}
                </div>
              ) : (
                <div className="grid gap-2">
                  <label className="text-sm font-bold text-ink">Jawaban Singkat</label>
                  <Input
                    defaultValue={shortAnswer}
                    onBlur={(e) => handleShortAnswerBlur(e.target.value)}
                    placeholder="Ketik jawaban Anda lalu klik di luar kotak untuk menyimpan"
                  />
                </div>
              )}
            </CardContent>
          </Card>

          <div className="flex justify-between">
            <Button disabled={currentQuestionIndex === 0} onClick={handlePrev} variant="secondary">
              Soal Sebelumnya
            </Button>
            <Button disabled={currentQuestionIndex === questions.length - 1} onClick={handleNext} variant="secondary">
              Soal Berikutnya
            </Button>
          </div>
        </>
      ) : !isLoading && !isError && (!attempt || attempt.status === "in_progress") ? (
        <EmptyState description="Soal tidak ditemukan untuk kuis ini." title="Data kuis tidak lengkap" />
      ) : null}
    </div>
  );
}
