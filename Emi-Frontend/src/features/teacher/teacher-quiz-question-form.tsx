"use client";

import { type ChangeEvent, type Dispatch, type FormEvent, type SetStateAction, useRef, useState } from "react";
import { useMutation } from "@tanstack/react-query";

import { Alert, Button, Card, CardContent, CardHeader, FormField, InfoPopover, Input, Select, Textarea } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import type { TeacherQuizQuestion } from "./types";

type QuestionType = "multiple_choice" | "short_answer";
type OptionForm = { option_text: string; is_correct: boolean };
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

function toForm(question: TeacherQuizQuestion | null, defaultOrder: number): QuestionFormState {
  return {
    question_type: question?.question_type === "short_answer" ? "short_answer" : "multiple_choice",
    question_text: question?.question_text ?? "",
    image_media_id: question?.image_media_id ?? question?.image_media?.id ?? "",
    correct_answer_text: question?.correct_answer_text ?? "",
    use_fuzzy_matching: question?.use_fuzzy_matching ? "true" : "false",
    fuzzy_threshold: question?.fuzzy_threshold ? String(question.fuzzy_threshold) : "85",
    points: question?.points ? String(question.points) : "10",
    order_number: question?.order_number ? String(question.order_number) : String(defaultOrder),
    explanation: question?.explanation ?? "",
    options: question?.options?.length ? question.options.map((option) => ({ option_text: option.option_text, is_correct: Boolean(option.is_correct) })) : [{ option_text: "", is_correct: true }, { option_text: "", is_correct: false }],
  };
}

function existingImageUrl(question: TeacherQuizQuestion | null) {
  return question?.image_media?.url ?? null;
}

function nullable(value: string) {
  const trimmed = value.trim();
  return trimmed === "" ? null : trimmed;
}

function optionsPayload(options: OptionForm[]) {
  const filled = options.map((option, index) => ({ option_text: option.option_text.trim(), is_correct: option.is_correct, order_number: index + 1 })).filter((option) => option.option_text !== "");
  if (!filled.some((option) => option.is_correct) && filled[0]) {
    filled[0].is_correct = true;
  }
  return filled;
}

export function TeacherQuizQuestionForm({ classQuizId, defaultOrder, editingQuestion, onCancelEdit, onSaved, token }: { classQuizId: string; defaultOrder: number; editingQuestion: TeacherQuizQuestion | null; onCancelEdit: () => void; onSaved: () => void; token: string }) {
  const [form, setForm] = useState<QuestionFormState>(() => toForm(editingQuestion, defaultOrder));
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreviewUrl, setImagePreviewUrl] = useState<string | null>(() => existingImageUrl(editingQuestion));
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const uploadSequence = useRef(0);

  const saveMutation = useMutation({
    mutationFn: (payload: Partial<TeacherQuizQuestion>) => editingQuestion ? teacherService.updateQuizQuestion(token, editingQuestion.id, payload) : teacherService.createQuizQuestion(token, classQuizId, payload),
    onSuccess: onSaved,
  });

  async function chooseImage(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null;
    const sequence = uploadSequence.current + 1;
    uploadSequence.current = sequence;
    setUploadError(null);

    if (!file) {
      return;
    }

    setImageFile(file);
    setImagePreviewUrl(URL.createObjectURL(file));
    setIsUploading(true);

    try {
      const media = await teacherService.uploadQuestionImage(token, file);
      if (sequence !== uploadSequence.current) {
        return;
      }
      setForm((current) => ({ ...current, image_media_id: media.id }));
    } catch (error) {
      if (sequence !== uploadSequence.current) {
        return;
      }
      setUploadError(getFirstApiError(error));
      setImageFile(null);
      setImagePreviewUrl(existingImageUrl(editingQuestion));
    } finally {
      if (sequence === uploadSequence.current) {
        setIsUploading(false);
      }
    }
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const orderNumber = Number.parseInt(form.order_number, 10);
    const base = {
      question_type: form.question_type,
      question_text: form.question_text.trim(),
      image_media_id: nullable(form.image_media_id),
      points: Number.parseInt(form.points, 10),
      order_number: Number.isNaN(orderNumber) ? defaultOrder : orderNumber,
      explanation: nullable(form.explanation),
    };

    saveMutation.mutate(form.question_type === "multiple_choice" ? {
      ...base,
      correct_answer_text: null,
      use_fuzzy_matching: false,
      fuzzy_threshold: null,
      options: optionsPayload(form.options),
    } : {
      ...base,
      correct_answer_text: form.correct_answer_text.trim(),
      use_fuzzy_matching: form.use_fuzzy_matching === "true",
      fuzzy_threshold: form.use_fuzzy_matching === "true" ? Number.parseInt(form.fuzzy_threshold, 10) : null,
      options: [],
    });
  }

  const isMultipleChoice = form.question_type === "multiple_choice";

  return (
    <Card className="lg:col-span-2">
      <CardHeader><h2 className="text-xl font-black text-ink">{editingQuestion ? "Edit Soal" : "Tambah Soal"}</h2></CardHeader>
      <CardContent>
        <form className="grid gap-4" onSubmit={submit}>
          {saveMutation.error ? <Alert tone="error">{getFirstApiError(saveMutation.error)}</Alert> : null}
          {uploadError ? <Alert tone="error">{uploadError}</Alert> : null}

          <div className="grid gap-4 md:grid-cols-[1fr_160px_140px]">
            <FormField label="Tipe soal">
              <Select onChange={(event) => setForm((current) => ({ ...current, question_type: event.target.value as QuestionType }))} value={form.question_type}>
                <option value="multiple_choice">Pilihan ganda</option>
                <option value="short_answer">Isian</option>
              </Select>
            </FormField>
            <FormField label="Poin"><Input min={1} onChange={(event) => setForm((current) => ({ ...current, points: event.target.value }))} required type="number" value={form.points} /></FormField>
            <FormField label="Urutan"><Input min={1} onChange={(event) => setForm((current) => ({ ...current, order_number: event.target.value }))} required type="number" value={form.order_number} /></FormField>
          </div>

          <FormField label="Teks soal"><Textarea className="min-h-32" onChange={(event) => setForm((current) => ({ ...current, question_text: event.target.value }))} required value={form.question_text} /></FormField>

          <FormField label="Gambar soal (opsional)">
            <label className="grid cursor-pointer gap-2 rounded-lg border-2 border-dashed border-ink bg-white p-5 text-sm font-bold text-ink transition hover:bg-yellow-50">
              <span>{isUploading ? "Mengunggah gambar..." : "Pilih file gambar"}</span>
              <input accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp" className="text-sm" disabled={isUploading} onChange={chooseImage} type="file" />
            </label>
          </FormField>
          {imagePreviewUrl ? (
            <div className="flex flex-col gap-2 rounded-lg border-2 border-ink bg-white p-3 sm:flex-row sm:items-center">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img alt="Pratinjau gambar soal" className="max-h-40 w-fit rounded-lg border-2 border-border object-contain" src={imagePreviewUrl} />
              <div className="text-sm">
                <p className="font-black text-ink">{imageFile ? imageFile.name : "Gambar tersimpan"}</p>
                {imageFile ? <p className="text-xs text-slate-500">{Math.ceil(imageFile.size / 1024)} KB · {imageFile.type || "image"}</p> : null}
              </div>
            </div>
          ) : null}

          {isMultipleChoice ? <MultipleChoiceFields form={form} setForm={setForm} /> : <ShortAnswerFields form={form} setForm={setForm} />}

          <FormField label="Pembahasan"><Textarea onChange={(event) => setForm((current) => ({ ...current, explanation: event.target.value }))} value={form.explanation} /></FormField>

          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            {editingQuestion ? <Button onClick={onCancelEdit} type="button" variant="ghost">Batal Edit</Button> : null}
            <Button disabled={saveMutation.isPending || isUploading} type="submit">{saveMutation.isPending ? "Menyimpan..." : "Simpan Soal"}</Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}

function MultipleChoiceFields({ form, setForm }: { form: QuestionFormState; setForm: Dispatch<SetStateAction<QuestionFormState>> }) {
  return (
    <div className="grid gap-3 rounded-xl border-2 border-border bg-surface-muted p-4">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between"><h3 className="font-black text-ink">Pilihan Jawaban</h3><Button onClick={() => setForm((current) => ({ ...current, options: [...current.options, { option_text: "", is_correct: false }] }))} type="button" variant="ghost">Tambah Pilihan</Button></div>
      {form.options.map((option, index) => (
        <div className="grid gap-3 md:grid-cols-[auto_1fr_auto]" key={index}>
          <label className="flex items-center gap-2 text-sm font-bold text-ink"><input checked={option.is_correct} onChange={() => setForm((current) => ({ ...current, options: current.options.map((item, optionIndex) => ({ ...item, is_correct: optionIndex === index })) }))} type="radio" />Benar</label>
          <Input onChange={(event) => setForm((current) => ({ ...current, options: current.options.map((item, optionIndex) => optionIndex === index ? { ...item, option_text: event.target.value } : item) }))} placeholder={`Pilihan ${index + 1}`} required={index < 2} value={option.option_text} />
          <Button disabled={form.options.length <= 2} onClick={() => setForm((current) => ({ ...current, options: current.options.filter((_, optionIndex) => optionIndex !== index) }))} type="button" variant="danger">Hapus</Button>
        </div>
      ))}
    </div>
  );
}

function ShortAnswerFields({ form, setForm }: { form: QuestionFormState; setForm: Dispatch<SetStateAction<QuestionFormState>> }) {
  return (
    <div className="grid gap-4 rounded-xl border-2 border-border bg-[var(--color-primary-muted)] p-4 md:grid-cols-3">
      <FormField label="Jawaban benar"><Input onChange={(event) => setForm((current) => ({ ...current, correct_answer_text: event.target.value }))} required value={form.correct_answer_text} /></FormField>
      <FormField label={<span className="flex items-center gap-1.5">Koreksi jawaban mirip<InfoPopover label="Info koreksi jawaban mirip"><p className="font-black text-ink">Apa ini?</p><p className="mt-1">Kalau diaktifkan (Ya), sistem tetap menganggap jawaban siswa benar walau ada typo kecil atau penulisan yang sedikit berbeda dari jawaban baku.</p><p className="mt-2">Kalau dimatikan (Tidak), jawaban siswa harus sama persis huruf demi huruf dengan jawaban benar.</p></InfoPopover></span>}>
        <Select onChange={(event) => setForm((current) => ({ ...current, use_fuzzy_matching: event.target.value as "true" | "false" }))} value={form.use_fuzzy_matching}><option value="false">Tidak, harus persis sama</option><option value="true">Ya, boleh sedikit beda</option></Select>
      </FormField>
      <FormField label={<span className="flex items-center gap-1.5">Tingkat kemiripan<InfoPopover label="Info tingkat kemiripan"><p className="font-black text-ink">Semakin besar angkanya, semakin ketat.</p><p className="mt-1">Nilai tinggi (mendekati 100): jawaban siswa harus sangat mirip dengan jawaban benar, hanya typo kecil yang ditoleransi.</p><p className="mt-2">Nilai rendah: sistem lebih longgar dan menerima jawaban yang berbeda cukup jauh dari jawaban benar.</p><p className="mt-2 font-bold">Rekomendasi: 80-90.</p></InfoPopover></span>}>
        <Input disabled={form.use_fuzzy_matching === "false"} max={100} min={1} onChange={(event) => setForm((current) => ({ ...current, fuzzy_threshold: event.target.value }))} type="number" value={form.fuzzy_threshold} />
      </FormField>
    </div>
  );
}
