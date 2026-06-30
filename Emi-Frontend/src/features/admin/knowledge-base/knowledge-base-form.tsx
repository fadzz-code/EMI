"use client";

import { type FormEvent, useState } from "react";

import { Alert, Button, FormField, Input, Select, Textarea } from "@/components/ui";

import type { AiKnowledgeItem, AiKnowledgePayload, AiKnowledgeSourceType, AiKnowledgeStatus } from "./types";

const defaultForm = {
  title: "",
  category: "",
  content: "",
  source_type: "manual" as AiKnowledgeSourceType,
  source_url: "",
  status: "draft" as AiKnowledgeStatus,
};

function nullable(value: string) {
  const trimmed = value.trim();

  return trimmed === "" ? null : trimmed;
}

function formFromItem(item?: AiKnowledgeItem | null) {
  return item
    ? {
        title: item.title,
        category: item.category ?? "",
        content: item.content,
        source_type: item.source_type,
        source_url: item.source_url ?? "",
        status: item.status,
      }
    : defaultForm;
}

export function KnowledgeBaseForm({
  item,
  isSubmitting,
  onCancel,
  onSubmit,
}: {
  item?: AiKnowledgeItem | null;
  isSubmitting?: boolean;
  onCancel: () => void;
  onSubmit: (payload: AiKnowledgePayload) => void;
}) {
  const [form, setForm] = useState(() => formFromItem(item));

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onSubmit({
      title: form.title.trim(),
      category: nullable(form.category),
      content: form.content.trim(),
      source_type: form.source_type,
      source_url: nullable(form.source_url),
      status: form.status,
    });
  }

  return (
    <form className="grid gap-4" onSubmit={submit}>
      <FormField label="Judul">
        <Input
          onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))}
          required
          value={form.title}
        />
      </FormField>
      <FormField label="Kategori">
        <Input
          onChange={(event) => setForm((current) => ({ ...current, category: event.target.value }))}
          placeholder="Contoh: Budaya, Bahasa, Sejarah"
          value={form.category}
        />
      </FormField>
      <FormField label="Konten Pengetahuan">
        <Textarea
          className="min-h-40"
          onChange={(event) => setForm((current) => ({ ...current, content: event.target.value }))}
          required
          value={form.content}
        />
        <p className="mt-2 text-xs font-bold leading-5 text-slate-600">
          Agar Chatbot AI menjawab lebih tepat, buat pengetahuan secara spesifik. Contoh: &quot;Asal-usul Mekongga&quot;, &quot;Arti nama Mekongga&quot;, &quot;Kosakata dasar Mekongga&quot;, bukan satu konten terlalu umum.
        </p>
      </FormField>
      <div className="grid gap-4 md:grid-cols-2">
        <FormField label="Jenis Sumber">
          <Select
            onChange={(event) =>
              setForm((current) => ({
                ...current,
                source_type: event.target.value as AiKnowledgeSourceType,
              }))
            }
            required
            value={form.source_type}
          >
            <option value="manual">Teks Manual</option>
            <option value="link">Link</option>
            <option value="pdf">PDF / Dokumen</option>
          </Select>
        </FormField>
        <FormField label="Status">
          <Select
            onChange={(event) =>
              setForm((current) => ({ ...current, status: event.target.value as AiKnowledgeStatus }))
            }
            value={form.status}
          >
            <option value="draft">Draft</option>
            <option value="published">Published</option>
            <option value="archived">Archived</option>
          </Select>
        </FormField>
      </div>
      <FormField label="URL Sumber">
        <Input
          onChange={(event) => setForm((current) => ({ ...current, source_url: event.target.value }))}
          placeholder="https://contoh-sumber-resmi.test"
          required={form.source_type === "link"}
          type="url"
          value={form.source_url}
        />
      </FormField>
      {form.source_type === "pdf" ? (
        <Alert tone="warning">
          Pada versi ini, PDF belum dibaca otomatis oleh chatbot. Masukkan ringkasan/isi penting PDF ke Konten Pengetahuan agar bisa digunakan sebagai jawaban.
        </Alert>
      ) : null}
      <div className="rounded-lg border-2 border-dashed border-ink bg-blue-50 p-4 text-sm leading-6 text-blue-950">
        Draft belum digunakan chatbot. Published digunakan chatbot siswa. Archived disimpan, tetapi tidak digunakan chatbot.
      </div>
      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting} type="submit">
          {item ? "Simpan Perubahan" : "Simpan Pengetahuan"}
        </Button>
      </div>
    </form>
  );
}
