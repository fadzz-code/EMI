"use client";

import { type Dispatch, type FormEvent, type SetStateAction, useState } from "react";
import { useMutation } from "@tanstack/react-query";

import { Alert, Button, Card, CardContent, CardHeader, FilePreview, FormField, Input, Select, Textarea, UploadComponent } from "@/components/ui";
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
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);

  const saveMutation = useMutation({
    mutationFn: (payload: Partial<TeacherQuizQuestion>) => editingQuestion ? teacherService.updateQuizQuestion(token, editingQuestion.id, payload) : teacherService.createQuizQuestion(token, classQuizId, payload),
    onSuccess: onSaved,
  });

  async function uploadImage() {
    if (!imageFile) {
      return;
    }
    setUploadError(null);
    setUploadSuccess(null);
    setIsUploading(true);
    try {
      const media = await teacherService.uploadQuestionImage(token, imageFile);
      setForm((current) => ({ ...current, image_media_id: media.id }));
      setUploadSuccess(`Gambar ${media.original_name ?? imageFile.name} berhasil diunggah.`);
    } catch (error) {
      setUploadError(getFirstApiError(error));
    } finally {
      setIsUploading(false);
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
          {uploadSuccess ? <Alert tone="success">{uploadSuccess}</Alert> : null}

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

          <div className="grid gap-4 md:grid-cols-[1fr_auto] md:items-end">
            <FormField label="Image media ID"><Input onChange={(event) => setForm((current) => ({ ...current, image_media_id: event.target.value }))} placeholder="Opsional, terisi otomatis setelah upload" value={form.image_media_id} /></FormField>
            <div className="flex gap-2"><Button disabled={!imageFile || isUploading} onClick={uploadImage} type="button" variant="secondary">{isUploading ? "Upload..." : "Upload Gambar"}</Button>{form.image_media_id ? <Button onClick={() => setForm((current) => ({ ...current, image_media_id: "" }))} type="button" variant="ghost">Lepas</Button> : null}</div>
          </div>
          <UploadComponent accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp" onChange={(event) => setImageFile(event.target.files?.[0] ?? null)} />
          {imageFile ? <FilePreview name={imageFile.name} size={`${Math.ceil(imageFile.size / 1024)} KB`} type={imageFile.type || "Gambar"} /> : null}

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
    <div className="grid gap-3 rounded-lg border-2 border-ink bg-yellow-50 p-4">
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
    <div className="grid gap-4 rounded-lg border-2 border-ink bg-blue-50 p-4 md:grid-cols-3">
      <FormField label="Jawaban benar"><Input onChange={(event) => setForm((current) => ({ ...current, correct_answer_text: event.target.value }))} required value={form.correct_answer_text} /></FormField>
      <FormField label="Fuzzy matching"><Select onChange={(event) => setForm((current) => ({ ...current, use_fuzzy_matching: event.target.value as "true" | "false" }))} value={form.use_fuzzy_matching}><option value="false">Tidak</option><option value="true">Ya</option></Select></FormField>
      <FormField label="Threshold fuzzy"><Input disabled={form.use_fuzzy_matching === "false"} max={100} min={1} onChange={(event) => setForm((current) => ({ ...current, fuzzy_threshold: event.target.value }))} type="number" value={form.fuzzy_threshold} /></FormField>
    </div>
  );
}
