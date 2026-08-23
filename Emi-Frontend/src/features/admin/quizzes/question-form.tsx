"use client";

import Image from "next/image";
import { type ChangeEvent, type FormEvent, useEffect, useRef, useState } from "react";

import {
  Alert,
  Button,
  FilePreview,
  FormField,
  InfoPopover,
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
  onBusyChange,
  onCancel,
  onSubmit,
  question,
  token,
}: {
  isSubmitting: boolean;
  defaultOrder?: number;
  onBusyChange?: (busy: boolean) => void;
  onCancel: () => void;
  onSubmit: (payload: QuizQuestionPayload, beforeClose: () => void) => Promise<unknown>;
  question?: QuizTemplateQuestion | null;
  token: string;
}) {
  const [form, setForm] = useState<QuestionFormState>(() => toForm(question, defaultOrder));
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imageUrl, setImageUrl] = useState<string | null>(question?.image_media?.url ?? null);
  const [imageName, setImageName] = useState(question?.image_media?.original_name ?? "");
  const [imageSize, setImageSize] = useState<number | null>(question?.image_media?.size_bytes ?? null);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);
  const uploadSequence = useRef(0);
  const ownedMedia = useRef(new Set<string>());
  const keptMedia = useRef<string | null>(null);
  const originalMedia = useRef(question?.image_media ?? null);

  async function deleteOwnedMedia(mediaId: string) {
    if (!ownedMedia.current.delete(mediaId)) return;
    try {
      await quizQuestionService.deleteMedia(token, mediaId);
    } catch {
      ownedMedia.current.add(mediaId);
    }
  }

  useEffect(() => {
    onBusyChange?.(isUploading || isSubmitting);
    return () => onBusyChange?.(false);
  }, [isSubmitting, isUploading, onBusyChange]);

  useEffect(() => () => {
    uploadSequence.current += 1;
    for (const mediaId of ownedMedia.current) {
      if (mediaId !== keptMedia.current) void quizQuestionService.deleteMedia(token, mediaId).catch(() => undefined);
    }
  }, [token]);

  async function uploadImage(file: File) {
    const sequence = ++uploadSequence.current;
    const previousId = form.image_media_id;
    setImageFile(file);
    setImageUrl(URL.createObjectURL(file));
    setImageName(file.name);
    setImageSize(file.size);
    setUploadError(null);
    setIsUploading(true);

    try {
      const media = await quizQuestionService.uploadQuestionImage(token, file);
      if (sequence !== uploadSequence.current) {
        ownedMedia.current.add(media.id);
        void deleteOwnedMedia(media.id);
        return;
      }
      ownedMedia.current.add(media.id);
      setForm((current) => ({ ...current, image_media_id: media.id }));
      setImageUrl(media.url ?? URL.createObjectURL(file));
      setImageName(media.original_name);
      setImageSize(media.size_bytes);
      if (previousId) void deleteOwnedMedia(previousId);
    } catch (error) {
      if (sequence === uploadSequence.current) {
        if (previousId) void deleteOwnedMedia(previousId);
        setForm((current) => ({ ...current, image_media_id: originalMedia.current?.id ?? "" }));
        setImageFile(null);
        setImageUrl(originalMedia.current?.url ?? null);
        setImageName(originalMedia.current?.original_name ?? "");
        setImageSize(originalMedia.current?.size_bytes ?? null);
        setUploadError(getFirstApiError(error));
      }
    } finally {
      if (sequence === uploadSequence.current) setIsUploading(false);
    }
  }

  function handleImageChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (file) void uploadImage(file);
    event.target.value = "";
  }

  function removeImage() {
    uploadSequence.current += 1;
    setIsUploading(false);
    setUploadError(null);
    const mediaId = form.image_media_id;
    setForm((current) => ({ ...current, image_media_id: "" }));
    setImageFile(null);
    setImageUrl(null);
    setImageName("");
    setImageSize(null);
    if (mediaId) void deleteOwnedMedia(mediaId);
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

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSaveError(null);
    try {
      await onSubmit(toPayload(form), () => {
        keptMedia.current = form.image_media_id || null;
      });
      const originalId = originalMedia.current?.id;
      if (originalId && originalId !== form.image_media_id) {
        void quizQuestionService.deleteMedia(token, originalId).catch(() => undefined);
      }
    } catch (error) {
      setSaveError(getFirstApiError(error));
    }
  }

  function handleCancel() {
    uploadSequence.current += 1;
    onCancel();
  }

  const isMultipleChoice = form.question_type === "multiple_choice";

  return (
    <form className="grid min-w-0 max-w-full gap-5 [&>*]:min-w-0" onSubmit={handleSubmit}>
      {uploadError ? <Alert tone="error">{uploadError}</Alert> : null}
      {saveError ? <Alert tone="error">{saveError}</Alert> : null}

      <section className="grid min-w-0 gap-4 rounded-xl border-2 border-border bg-surface-muted p-4">
        <h3 className="text-lg font-black text-ink">Pengaturan Soal</h3>
        <div className="grid min-w-0 gap-4 md:grid-cols-[minmax(0,1fr)_190px_140px]">
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
        </div>
      </section>

      <section className="grid min-w-0 gap-4 rounded-xl border-2 border-border p-4">
        <h3 className="text-lg font-black text-ink">Pertanyaan</h3>
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
      </section>

      <input name="image_media_id" type="hidden" value={form.image_media_id} />
      <section className="grid min-w-0 gap-3 rounded-xl border-2 border-border p-4">
        <h3 className="text-lg font-black text-ink">Media</h3>
        <span className="text-sm font-bold text-ink">Gambar soal (opsional)</span>
        <UploadComponent
          accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp"
          aria-label={imageUrl ? "Ganti gambar soal" : "Pilih gambar soal"}
          disabled={isUploading || isSubmitting}
          onChange={handleImageChange}
        />
        <p aria-live="polite" className="text-sm font-semibold text-muted">
          {isUploading ? "Mengunggah gambar..." : imageUrl ? "Gambar siap disimpan." : "JPG, PNG, atau WebP."}
        </p>
        {imageUrl ? (
          <div className="grid min-w-0 gap-3 rounded-lg border-2 border-border p-3 sm:grid-cols-[8rem_minmax(0,1fr)_auto] sm:items-center">
            <Image alt={`Pratinjau ${imageName}`} className="h-28 w-full rounded-lg object-cover sm:w-32" height={112} src={imageUrl} unoptimized width={128} />
            <FilePreview
              name={imageName}
              size={imageSize === null ? undefined : `${Math.ceil(imageSize / 1024)} KB`}
              type={imageFile?.type || question?.image_media?.mime_type || "Gambar"}
            />
            <Button disabled={isUploading || isSubmitting} onClick={removeImage} type="button" variant="danger">
              Hapus
            </Button>
          </div>
        ) : null}
      </section>

      {isMultipleChoice ? (
        <section className="grid min-w-0 gap-3 rounded-xl border-2 border-border bg-[var(--color-primary-muted)] p-4">
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
            <div className="grid min-w-0 gap-3 sm:grid-cols-[auto_minmax(0,1fr)_auto] sm:items-center" key={index}>
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
        </section>
      ) : (
        <section className="grid min-w-0 gap-4 rounded-xl border-2 border-border bg-surface-muted p-4 md:grid-cols-3">
          <h3 className="text-lg font-black text-ink md:col-span-3">Pilihan Jawaban</h3>
          <FormField label="Jawaban benar">
            <Input
              onChange={(event) =>
                setForm((current) => ({ ...current, correct_answer_text: event.target.value }))
              }
              required
              value={form.correct_answer_text}
            />
          </FormField>
          <FormField
            label={
              <span className="flex items-center gap-1.5">
                Koreksi jawaban mirip
                <InfoPopover label="Info koreksi jawaban mirip">
                  <p className="font-black text-ink">Apa ini?</p>
                  <p className="mt-1">Kalau diaktifkan (Ya), sistem tetap menganggap jawaban siswa benar walau ada typo kecil atau penulisan yang sedikit berbeda dari jawaban baku.</p>
                  <p className="mt-2">Kalau dimatikan (Tidak), jawaban siswa harus sama persis huruf demi huruf dengan jawaban benar.</p>
                </InfoPopover>
              </span>
            }
          >
            <Select
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  use_fuzzy_matching: event.target.value as "true" | "false",
                }))
              }
              value={form.use_fuzzy_matching}
            >
              <option value="false">Tidak, harus persis sama</option>
              <option value="true">Ya, boleh sedikit beda</option>
            </Select>
          </FormField>
          <FormField
            label={
              <span className="flex items-center gap-1.5">
                Tingkat kemiripan
                <InfoPopover label="Info tingkat kemiripan">
                  <p className="font-black text-ink">Semakin besar angkanya, semakin ketat.</p>
                  <p className="mt-1">Nilai tinggi (mendekati 100): jawaban siswa harus sangat mirip dengan jawaban benar, hanya typo kecil yang ditoleransi.</p>
                  <p className="mt-2">Nilai rendah: sistem lebih longgar dan menerima jawaban yang berbeda cukup jauh dari jawaban benar.</p>
                  <p className="mt-2 font-bold">Rekomendasi: 80-90.</p>
                </InfoPopover>
              </span>
            }
          >
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
        </section>
      )}

      <FormField label="Pembahasan">
        <Textarea
          onChange={(event) =>
            setForm((current) => ({ ...current, explanation: event.target.value }))
          }
          value={form.explanation}
        />
      </FormField>

      <div className="sticky -bottom-3 z-10 -mx-3 flex flex-col gap-3 border-t-2 border-border bg-surface p-3 sm:-bottom-5 sm:-mx-5 sm:flex-row sm:justify-end sm:p-5">
        <Button disabled={isSubmitting || isUploading} onClick={handleCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting || isUploading} type="submit">
          Simpan Soal
        </Button>
      </div>
    </form>
  );
}
