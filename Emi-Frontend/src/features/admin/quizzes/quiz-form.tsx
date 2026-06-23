"use client";

import { type FormEvent, useState } from "react";

import { Button, FormField, Input, Select, Textarea } from "@/components/ui";

import { normalizeNullable } from "./quiz-utils";
import type { QuizTemplate, QuizTemplatePayload, QuizTemplateStatus } from "./types";

type QuizFormState = {
  title: string;
  description: string;
  instructions: string;
  duration_minutes: string;
  max_attempts: string;
  show_result: "true" | "false";
  status: QuizTemplateStatus;
};

function toForm(quiz?: QuizTemplate | null): QuizFormState {
  return {
    title: quiz?.title ?? "",
    description: quiz?.description ?? "",
    instructions: quiz?.instructions ?? "",
    duration_minutes: quiz?.duration_minutes ? String(quiz.duration_minutes) : "30",
    max_attempts: quiz?.max_attempts ? String(quiz.max_attempts) : "1",
    show_result: quiz?.show_result === false ? "false" : "true",
    status: quiz?.status ?? "draft",
  };
}

function toPayload(form: QuizFormState): QuizTemplatePayload {
  return {
    title: form.title.trim(),
    description: normalizeNullable(form.description),
    instructions: normalizeNullable(form.instructions),
    duration_minutes: Number.parseInt(form.duration_minutes, 10),
    max_attempts: Number.parseInt(form.max_attempts, 10),
    show_result: form.show_result === "true",
    status: form.status,
  };
}

export function QuizTemplateForm({
  isSubmitting,
  onCancel,
  onSubmit,
  quiz,
}: {
  isSubmitting: boolean;
  onCancel: () => void;
  onSubmit: (payload: QuizTemplatePayload) => void;
  quiz?: QuizTemplate | null;
}) {
  const [form, setForm] = useState<QuizFormState>(() => toForm(quiz));

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onSubmit(toPayload(form));
  }

  return (
    <form className="grid gap-4" onSubmit={handleSubmit}>
      <FormField label="Judul kuis">
        <Input
          maxLength={255}
          onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))}
          required
          value={form.title}
        />
      </FormField>
      <FormField label="Deskripsi">
        <Textarea
          onChange={(event) =>
            setForm((current) => ({ ...current, description: event.target.value }))
          }
          value={form.description}
        />
      </FormField>
      <FormField label="Instruksi pengerjaan">
        <Textarea
          onChange={(event) =>
            setForm((current) => ({ ...current, instructions: event.target.value }))
          }
          value={form.instructions}
        />
      </FormField>
      <div className="grid gap-4 md:grid-cols-2">
        <FormField label="Durasi menit">
          <Input
            max={240}
            min={1}
            onChange={(event) =>
              setForm((current) => ({ ...current, duration_minutes: event.target.value }))
            }
            required
            type="number"
            value={form.duration_minutes}
          />
        </FormField>
        <FormField label="Maksimal percobaan">
          <Input
            max={10}
            min={1}
            onChange={(event) =>
              setForm((current) => ({ ...current, max_attempts: event.target.value }))
            }
            required
            type="number"
            value={form.max_attempts}
          />
        </FormField>
      </div>
      <div className="grid gap-4 md:grid-cols-2">
        <FormField label="Tampilkan hasil ke siswa">
          <Select
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                show_result: event.target.value as "true" | "false",
              }))
            }
            value={form.show_result}
          >
            <option value="true">Ya</option>
            <option value="false">Tidak</option>
          </Select>
        </FormField>
        <FormField label="Status">
          <Select
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                status: event.target.value as QuizTemplateStatus,
              }))
            }
            value={form.status}
          >
            <option value="draft">Draft</option>
            <option value="published">Published</option>
            <option value="archived">Diarsipkan</option>
          </Select>
        </FormField>
      </div>
      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting} type="submit">
          Simpan Kuis
        </Button>
      </div>
    </form>
  );
}
