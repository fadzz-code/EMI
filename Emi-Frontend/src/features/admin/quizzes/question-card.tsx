import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
} from "@/components/ui";

import { questionTypeLabel } from "./quiz-utils";
import type { QuizTemplateQuestion } from "./types";

export function QuestionCard({
  canMoveDown,
  canMoveUp,
  disabledActions,
  isReordering,
  onDelete,
  onEdit,
  onMoveDown,
  onMoveUp,
  question,
}: {
  canMoveDown: boolean;
  canMoveUp: boolean;
  disabledActions?: boolean;
  isReordering?: boolean;
  onDelete: () => void;
  onEdit: () => void;
  onMoveDown: () => void;
  onMoveUp: () => void;
  question: QuizTemplateQuestion;
}) {
  return (
    <Card className="h-full">
      <CardHeader>
        <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <Badge tone="neutral">#{question.order_number}</Badge>
              <Badge tone="blue">{questionTypeLabel(question.question_type)}</Badge>
              <Badge tone="neutral">{question.points} poin</Badge>
            </div>
            <h3 className="mt-3 text-lg font-black text-ink">{question.question_text}</h3>
          </div>
          <div className="flex flex-wrap gap-2">
            <Button
              className="min-h-9 px-3 py-1 text-xs"
              disabled={!canMoveUp || disabledActions || isReordering}
              onClick={onMoveUp}
              variant="ghost"
            >
              Naik
            </Button>
            <Button
              className="min-h-9 px-3 py-1 text-xs"
              disabled={!canMoveDown || disabledActions || isReordering}
              onClick={onMoveDown}
              variant="ghost"
            >
              Turun
            </Button>
            <Button
              className="min-h-9 px-3 py-1 text-xs"
              disabled={disabledActions}
              onClick={onEdit}
              variant="secondary"
            >
              Edit
            </Button>
            <Button
              className="min-h-9 px-3 py-1 text-xs"
              disabled={disabledActions}
              onClick={onDelete}
              variant="danger"
            >
              Hapus
            </Button>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid gap-4">
          {question.image_media?.url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              alt="Gambar soal"
              className="max-h-64 w-fit rounded-lg border-2 border-border bg-surface object-contain"
              src={question.image_media.url}
            />
          ) : question.image_media_id ? (
            <p className="rounded-lg border border-border bg-surface p-3 text-xs font-semibold text-muted">
              Gambar terhubung: {question.image_media_id}
            </p>
          ) : null}

          {question.question_type === "multiple_choice" ? (
            <div className="grid gap-2">
              {(question.options ?? []).map((option) => (
                <div
                  className="flex items-start justify-between gap-3 rounded-lg border-2 border-border bg-surface p-3 text-sm"
                  key={option.id ?? `${question.id}-${option.order_number}`}
                >
                  <span>
                    {option.order_number}. {option.option_text}
                  </span>
                  {option.is_correct ? <Badge tone="blue">Jawaban benar</Badge> : null}
                </div>
              ))}
            </div>
          ) : (
            <div className="rounded-lg border-2 border-border bg-surface p-4 text-sm">
              <p>
                <span className="font-black">Jawaban benar:</span>{" "}
                {question.correct_answer_text ?? "-"}
              </p>
              <p className="mt-2 font-semibold text-muted">
                Fuzzy matching: {question.use_fuzzy_matching ? "Ya" : "Tidak"}
                {question.use_fuzzy_matching ? ` (${question.fuzzy_threshold ?? 85})` : ""}
              </p>
            </div>
          )}

          {question.explanation ? (
            <p className="rounded-lg border-2 border-border bg-[var(--color-primary-muted)] p-3 text-sm leading-6 text-muted">
              <span className="font-black text-ink">Pembahasan:</span> {question.explanation}
            </p>
          ) : null}
        </div>
      </CardContent>
    </Card>
  );
}
