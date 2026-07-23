"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState } from "@/components/ui";
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
  const [remainingSeconds, setRemainingSeconds] = useState<number | null>(null);
  const activeInputRef = useRef<HTMLInputElement | null>(null);
  const allowLeaveRef = useRef(false);

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
      allowLeaveRef.current = true;
      router.replace(`/student/quizzes/${quizId}/result?attemptId=${attempt.id}`);
    },
  });

  useEffect(() => {
    const expiresAt = attemptQuery.data?.expires_at;
    if (!expiresAt || attemptQuery.data?.status !== "in_progress") return;
    const update = () => setRemainingSeconds(Math.max(0, Math.ceil((new Date(expiresAt).getTime() - Date.now()) / 1000)));
    update();
    const interval = window.setInterval(update, 1000);
    return () => window.clearInterval(interval);
  }, [attemptQuery.data?.expires_at, attemptQuery.data?.status]);

  useEffect(() => {
    if (attemptQuery.data?.status !== "in_progress") return;
    const warn = (event: BeforeUnloadEvent) => {
      if (allowLeaveRef.current) return;
      event.preventDefault();
      event.returnValue = "";
    };
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [attemptQuery.data?.status]);

  useEffect(() => {
    if (remainingSeconds === 0 && !submitMutation.isPending) submitMutation.mutate();
  }, [remainingSeconds, submitMutation]);

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

  async function leaveAttempt() {
    if (!window.confirm("Jawaban aktif akan disimpan. Yakin ingin meninggalkan kuis? Waktu tetap berjalan.")) return;
    if (currentQuestion?.question_type !== "multiple_choice") {
      const text = activeInputRef.current?.value ?? shortAnswer;
      await studentQuizService.saveAnswer(token ?? "", attemptId ?? "", currentQuestion.id, { answer_text: text });
    }
    allowLeaveRef.current = true;
    router.push(`/student/quizzes/${quizId}`);
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
              <p className="mt-1 font-black text-red-700">Sisa waktu: {remainingSeconds === null ? "-" : `${Math.floor(remainingSeconds / 60)}:${String(remainingSeconds % 60).padStart(2, "0")}`}</p>
            </div>
            {submitMutation.error ? <Alert tone="error">{getFirstApiError(submitMutation.error)}</Alert> : null}
            <Button onClick={() => void leaveAttempt()} type="button" variant="secondary">Keluar Kuis</Button>
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
                  <input
                    className="min-h-11 w-full rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 py-2 text-sm text-ink outline-none focus:ring-4 focus:ring-accent/40"
                    defaultValue={shortAnswer}
                    ref={activeInputRef}
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
