"use client";

import { type FormEvent, useState } from "react";

import {
  Alert,
  Button,
  FilePreview,
  FormField,
  Input,
  Select,
  Textarea,
  UploadComponent,
} from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { quizQuestionService } from "./quiz-service";
import { normalizeNullable } from "./quiz-utils";
import type { QuestionType, QuizQuestionPayload, QuizTemplateQuestion } from "./types";

type OptionForm = {
  option_text: string;
  is_correct: boolean;
};

type QuestionFormState = {
  question_type: QuestionType;
  question_text: string;
  image_media_id: string;
  correct_answer_text: string;
  use_fuzzy_matching: "true" | "false";
  fuzzy_threshold: string;
  points: string;
  order_number: string;
  explanation: string;
  options: OptionForm[];
};

function toForm(question?: QuizTemplateQuestion | null, defaultOrder = 1): QuestionFormState {
  const options = question?.options?.length
    ? question.options.map((option) => ({
        option_text: option.option_text,
        is_correct: Boolean(option.is_correct),
      }))
    : [
        { option_text: "", is_correct: true },
        { option_text: "", is_correct: false },
      ];

  return {
    question_type: question?.question_type ?? "multiple_choice",
    question_text: question?.question_text ?? "",
    image_media_id: question?.image_media_id ?? question?.image_media?.id ?? "",
    correct_answer_text: question?.correct_answer_text ?? "",
    use_fuzzy_matching: question?.use_fuzzy_matching ? "true" : "false",
    fuzzy_threshold: question?.fuzzy_threshold ? String(question.fuzzy_threshold) : "85",
    points: question?.points ? String(question.points) : "10",
    order_number: question?.order_number ? String(question.order_number) : String(defaultOrder),
    explanation: question?.explanation ?? "",
    options,
  };
}

function ensureMultipleChoiceOptions(options: OptionForm[]) {
  const filled = options
    .map((option, index) => ({
      option_text: option.option_text.trim(),
      is_correct: option.is_correct,
      order_number: index + 1,
    }))
    .filter((option) => option.option_text !== "");

  if (!filled.some((option) => option.is_correct) && filled[0]) {
    filled[0].is_correct = true;
  }

  return filled;
}

function toPayload(form: QuestionFormState): QuizQuestionPayload {
  const orderNumber = Number.parseInt(form.order_number, 10);
  const base = {
    question_type: form.question_type,
    question_text: form.question_text.trim(),
    image_media_id: normalizeNullable(form.image_media_id),
    points: Number.parseInt(form.points, 10),
    order_number: Number.isNaN(orderNumber) ? 1 : orderNumber,
    explanation: normalizeNullable(form.explanation),
  };

  if (form.question_type === "multiple_choice") {
    return {
      ...base,
      correct_answer_text: null,
      use_fuzzy_matching: false,
      fuzzy_threshold: null,
      options: ensureMultipleChoiceOptions(form.options),
    };
  }

  return {
    ...base,
    correct_answer_text: form.correct_answer_text.trim(),
    use_fuzzy_matching: form.use_fuzzy_matching === "true",
    fuzzy_threshold:
      form.use_fuzzy_matching === "true"
        ? Number.parseInt(form.fuzzy_threshold, 10)
        : null,
    options: [],
  };
}

export function QuestionForm({
  isSubmitting,
  defaultOrder,
  onCancel,
  onSubmit,
  question,
  token,
}: {
  isSubmitting: boolean;
  defaultOrder?: number;
  onCancel: () => void;
  onSubmit: (payload: QuizQuestionPayload) => void;
  question?: QuizTemplateQuestion | null;
  token: string;
}) {
  const [form, setForm] = useState<QuestionFormState>(() => toForm(question, defaultOrder));
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);

  async function uploadImage() {
    if (!imageFile) {
      return;
    }

    setUploadError(null);
    setUploadSuccess(null);
    setIsUploading(true);

    try {
      const media = await quizQuestionService.uploadQuestionImage(token, imageFile);
      setForm((current) => ({ ...current, image_media_id: media.id }));
      setUploadSuccess(`Gambar ${media.original_name} berhasil diunggah.`);
    } catch (error) {
      setUploadError(getFirstApiError(error));
    } finally {
      setIsUploading(false);
    }
  }

  function updateOption(index: number, patch: Partial<OptionForm>) {
    setForm((current) => ({
      ...current,
      options: current.options.map((option, optionIndex) =>
        optionIndex === index ? { ...option, ...patch } : option,
      ),
    }));
  }

  function setCorrectOption(index: number) {
    setForm((current) => ({
      ...current,
      options: current.options.map((option, optionIndex) => ({
        ...option,
        is_correct: optionIndex === index,
      })),
    }));
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onSubmit(toPayload(form));
  }

  const isMultipleChoice = form.question_type === "multiple_choice";

  return (
    <form className="grid gap-4" onSubmit={handleSubmit}>
      {uploadError ? <Alert tone="error">{uploadError}</Alert> : null}
      {uploadSuccess ? <Alert tone="success">{uploadSuccess}</Alert> : null}

      <div className="grid gap-4 md:grid-cols-[1fr_190px_140px_130px]">
        <FormField label="Tipe soal">
          <Select
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                question_type: event.target.value as QuestionType,
              }))
            }
            value={form.question_type}
          >
            <option value="multiple_choice">Pilihan Ganda</option>
            <option value="short_answer">Isian Singkat</option>
          </Select>
        </FormField>
        <FormField label="Poin">
          <Input
            min={1}
            onChange={(event) => setForm((current) => ({ ...current, points: event.target.value }))}
            required
            type="number"
            value={form.points}
          />
        </FormField>
        <FormField label="Urutan">
          <Input
            min={1}
            onChange={(event) =>
              setForm((current) => ({ ...current, order_number: event.target.value }))
            }
            placeholder="1"
            required
            type="number"
            value={form.order_number}
          />
        </FormField>
        <div />
      </div>

      <FormField label="Teks soal">
        <Textarea
          className="min-h-32"
          onChange={(event) =>
            setForm((current) => ({ ...current, question_text: event.target.value }))
          }
          required
          value={form.question_text}
        />
      </FormField>

      <div className="grid gap-4 md:grid-cols-[1fr_auto] md:items-end">
        <FormField label="ID media gambar">
          <Input
            onChange={(event) =>
              setForm((current) => ({ ...current, image_media_id: event.target.value }))
            }
            placeholder="Opsional, terisi otomatis setelah upload"
            value={form.image_media_id}
          />
        </FormField>
        <Button
          disabled={!imageFile || isUploading}
          onClick={uploadImage}
          type="button"
          variant="secondary"
        >
          {isUploading ? "Upload..." : "Upload Gambar"}
        </Button>
      </div>
      <UploadComponent
        accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp"
        onChange={(event) => setImageFile(event.target.files?.[0] ?? null)}
      />
      {imageFile ? (
        <FilePreview
          name={imageFile.name}
          size={`${Math.ceil(imageFile.size / 1024)} KB`}
          type={imageFile.type || "Gambar"}
        />
      ) : null}

      {isMultipleChoice ? (
        <div className="grid gap-3 rounded-lg border-2 border-border bg-[var(--color-primary-muted)] p-4">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <h3 className="font-black text-ink">Pilihan Jawaban</h3>
            <Button
              onClick={() =>
                setForm((current) => ({
                  ...current,
                  options: [...current.options, { option_text: "", is_correct: false }],
                }))
              }
              type="button"
              variant="ghost"
            >
              Tambah Pilihan
            </Button>
          </div>
          {form.options.map((option, index) => (
            <div className="grid gap-3 md:grid-cols-[auto_1fr_auto]" key={index}>
              <label className="flex items-center gap-2 text-sm font-bold text-ink">
                <input
                  checked={option.is_correct}
                  onChange={() => setCorrectOption(index)}
                  type="radio"
                />
                Benar
              </label>
              <Input
                onChange={(event) => updateOption(index, { option_text: event.target.value })}
                placeholder={`Pilihan ${index + 1}`}
                required={index < 2}
                value={option.option_text}
              />
              <Button
                disabled={form.options.length <= 2}
                onClick={() =>
                  setForm((current) => ({
                    ...current,
                    options: current.options.filter((_, optionIndex) => optionIndex !== index),
                  }))
                }
                type="button"
                variant="danger"
              >
                Hapus
              </Button>
            </div>
          ))}
        </div>
      ) : (
        <div className="grid gap-4 rounded-lg border-2 border-border bg-surface-muted p-4 md:grid-cols-3">
          <FormField label="Jawaban benar">
            <Input
              onChange={(event) =>
                setForm((current) => ({ ...current, correct_answer_text: event.target.value }))
              }
              required
              value={form.correct_answer_text}
            />
          </FormField>
          <FormField label="Fuzzy matching">
            <Select
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  use_fuzzy_matching: event.target.value as "true" | "false",
                }))
              }
              value={form.use_fuzzy_matching}
            >
              <option value="false">Tidak</option>
              <option value="true">Ya</option>
            </Select>
          </FormField>
          <FormField label="Threshold fuzzy">
            <Input
              disabled={form.use_fuzzy_matching === "false"}
              max={100}
              min={1}
              onChange={(event) =>
                setForm((current) => ({ ...current, fuzzy_threshold: event.target.value }))
              }
              type="number"
              value={form.fuzzy_threshold}
            />
          </FormField>
        </div>
      )}

      <FormField label="Pembahasan">
        <Textarea
          onChange={(event) =>
            setForm((current) => ({ ...current, explanation: event.target.value }))
          }
          value={form.explanation}
        />
      </FormField>

      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting} type="submit">
          Simpan Soal
        </Button>
      </div>
    </form>
  );
}
