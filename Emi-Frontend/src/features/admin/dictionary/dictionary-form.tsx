"use client";

import { type FormEvent, useState } from "react";

import {
  Alert,
  Button,
  FormField,
  Input,
  Select,
  Textarea,
  UploadComponent,
} from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { dictionaryService } from "./dictionary-service";
import { normalizeNullable } from "./dictionary-utils";
import type {
  DictionaryCategory,
  DictionaryEntry,
  DictionaryEntryPayload,
  DictionaryStatus,
} from "./types";

type EntryFormState = {
  category_id: string;
  indonesia: string;
  english: string;
  mekongga: string;
  example_mekongga: string;
  example_indonesia: string;
  status: DictionaryStatus;
  audio_media_id: string;
};

function toForm(entry?: DictionaryEntry | null): EntryFormState {
  return {
    category_id: entry?.category_id ?? "",
    indonesia: entry?.indonesia ?? "",
    english: entry?.english ?? "",
    mekongga: entry?.mekongga ?? "",
    example_mekongga: entry?.example_mekongga ?? "",
    example_indonesia: entry?.example_indonesia ?? "",
    status: entry?.status ?? "active",
    audio_media_id: entry?.audio?.id ?? "",
  };
}

function toPayload(form: EntryFormState): DictionaryEntryPayload {
  return {
    category_id: form.category_id,
    indonesia: form.indonesia.trim(),
    english: form.english.trim(),
    mekongga: form.mekongga.trim(),
    example_mekongga: normalizeNullable(form.example_mekongga),
    example_indonesia: normalizeNullable(form.example_indonesia),
    audio_media_id: normalizeNullable(form.audio_media_id),
    status: form.status,
  };
}

export function DictionaryEntryForm({
  categories,
  entry,
  isSubmitting,
  onCancel,
  onSubmit,
  token,
}: {
  categories: DictionaryCategory[];
  entry?: DictionaryEntry | null;
  isSubmitting: boolean;
  onCancel: () => void;
  onSubmit: (payload: DictionaryEntryPayload) => void;
  token: string;
}) {
  const [form, setForm] = useState<EntryFormState>(() => toForm(entry));
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [isUploadingAudio, setIsUploadingAudio] = useState(false);
  const [audioError, setAudioError] = useState<string | null>(null);
  const [audioSuccess, setAudioSuccess] = useState<string | null>(null);

  async function uploadAudio() {
    if (!audioFile) {
      return;
    }

    setAudioError(null);
    setAudioSuccess(null);
    setIsUploadingAudio(true);

    try {
      const media = await dictionaryService.uploadAudio(token, audioFile);
      setForm((current) => ({ ...current, audio_media_id: media.id }));
      setAudioSuccess(`Audio ${media.original_name} berhasil diunggah.`);
    } catch (error) {
      setAudioError(getFirstApiError(error));
    } finally {
      setIsUploadingAudio(false);
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onSubmit(toPayload(form));
  }

  return (
    <form className="grid gap-4" onSubmit={handleSubmit}>
      {audioError ? <Alert tone="error">{audioError}</Alert> : null}
      {audioSuccess ? <Alert tone="success">{audioSuccess}</Alert> : null}

      <FormField label="Kategori">
        <Select
          onChange={(event) => setForm((current) => ({ ...current, category_id: event.target.value }))}
          required
          value={form.category_id}
        >
          <option value="">Pilih kategori</option>
          {categories.map((category) => (
            <option key={category.id} value={category.id}>
              {category.name}
            </option>
          ))}
        </Select>
      </FormField>

      <div className="grid gap-4 md:grid-cols-3">
        <FormField label="Indonesia">
          <Input
            onChange={(event) => setForm((current) => ({ ...current, indonesia: event.target.value }))}
            required
            value={form.indonesia}
          />
        </FormField>
        <FormField label="Inggris">
          <Input
            onChange={(event) => setForm((current) => ({ ...current, english: event.target.value }))}
            required
            value={form.english}
          />
        </FormField>
        <FormField label="Mekongga">
          <Input
            onChange={(event) => setForm((current) => ({ ...current, mekongga: event.target.value }))}
            required
            value={form.mekongga}
          />
        </FormField>
      </div>

      <FormField label="Contoh kalimat Mekongga">
        <Textarea
          onChange={(event) =>
            setForm((current) => ({ ...current, example_mekongga: event.target.value }))
          }
          value={form.example_mekongga}
        />
      </FormField>
      <FormField label="Contoh kalimat Indonesia">
        <Textarea
          onChange={(event) =>
            setForm((current) => ({ ...current, example_indonesia: event.target.value }))
          }
          value={form.example_indonesia}
        />
      </FormField>

      <div className="grid gap-4 md:grid-cols-[1fr_1fr_auto] md:items-end">
        <FormField label="Status">
          <Select
            onChange={(event) =>
              setForm((current) => ({ ...current, status: event.target.value as DictionaryStatus }))
            }
            value={form.status}
          >
            <option value="active">Aktif</option>
            <option value="inactive">Nonaktif</option>
          </Select>
        </FormField>
        <FormField label="Audio media ID">
          <Input
            onChange={(event) =>
              setForm((current) => ({ ...current, audio_media_id: event.target.value }))
            }
            placeholder="Opsional, bisa dari upload audio"
            value={form.audio_media_id}
          />
        </FormField>
        <Button
          disabled={!audioFile || isUploadingAudio}
          onClick={uploadAudio}
          type="button"
          variant="secondary"
        >
          {isUploadingAudio ? "Upload..." : "Upload Audio"}
        </Button>
      </div>

      <UploadComponent
        accept=".mp3,.wav,.m4a,.ogg,.webm,audio/mpeg,audio/wav,audio/x-wav,audio/mp4,audio/ogg,audio/webm,application/octet-stream"
        onChange={(event) => setAudioFile(event.target.files?.[0] ?? null)}
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting} type="submit">
          Simpan Entri
        </Button>
      </div>
    </form>
  );
}
