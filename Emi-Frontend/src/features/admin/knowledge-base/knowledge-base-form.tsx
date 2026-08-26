"use client";

import { type FormEvent, useState } from "react";

import { Button, FormField, Input, MutationAlert, Select, Textarea } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { knowledgeBaseService } from "./knowledge-base-service";
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
  token,
}: {
  item?: AiKnowledgeItem | null;
  isSubmitting?: boolean;
  onCancel: () => void;
  onSubmit: (payload: AiKnowledgePayload) => void;
  token: string | null;
}) {
  const [form, setForm] = useState(() => formFromItem(item));
  const [isExtracting, setIsExtracting] = useState(false);
  const [selectedPdfFile, setSelectedPdfFile] = useState<File | null>(null);
  const [selectedDocumentFile, setSelectedDocumentFile] = useState<File | null>(null);
  const [extractMessage, setExtractMessage] = useState<string | null>(null);
  const [extractError, setExtractError] = useState<string | null>(null);
  const [resultCounter, setResultCounter] = useState(0);
  const [isPdfSourceImported, setIsPdfSourceImported] = useState(false);
  const [isDocumentExtracted, setIsDocumentExtracted] = useState(false);
  const isPdfRagCreate = !item && form.source_type === "pdf";
  const isDocumentCreate = !item && (form.source_type === "docx" || form.source_type === "txt");

  async function extractDocumentUpload() {
    if (!token || !selectedDocumentFile) {
      return null;
    }

    setIsExtracting(true);
    setExtractMessage(null);
    setExtractError(null);
    setResultCounter((current) => current + 1);

    try {
      const result = await knowledgeBaseService.extractDocumentUpload(token, selectedDocumentFile);

      setForm((current) => ({
        ...current,
        content: result.content,
        source_type: result.source_type,
        source_url: result.source_url ?? current.source_url,
        title: current.title || result.title || current.title,
      }));
      setIsDocumentExtracted(true);
      setExtractMessage("Isi dokumen berhasil diambil.");

      return result;
    } catch (error) {
      const message = getFirstApiError(error);
      setExtractError(message || "Isi dokumen tidak dapat dibaca. Pastikan berkas DOCX/TXT tidak rusak.");

      return null;
    } finally {
      setIsExtracting(false);
    }
  }

  async function importPdfSource() {
    if (!token || !selectedPdfFile || !form.title.trim()) {
      return;
    }

    setIsExtracting(true);
    setExtractMessage(null);
    setExtractError(null);
    setResultCounter((current) => current + 1);

    try {
      const result = await knowledgeBaseService.importPdfSource(token, {
        title: form.title.trim(),
        category: nullable(form.category),
        file: selectedPdfFile,
        status: form.status === "archived" ? "draft" : form.status,
      });

      setForm((current) => ({
        ...current,
        content: "Dokumen PDF telah diproses sebagai sumber Basis AI. Isi lengkap disimpan per halaman dan digunakan untuk pencarian Chatbot AI.",
        source_type: "pdf",
        source_url: result.source_url ?? current.source_url,
      }));
      setIsPdfSourceImported(true);
      setExtractMessage(`PDF berhasil diproses. Halaman terbaca: ${result.page_count}. Halaman dilewati: ${result.skipped_page_count}. Chunk dibuat: ${result.chunk_count}.`);
    } catch (error) {
      const message = getFirstApiError(error);
      setExtractError(message || "PDF tidak dapat diproses sebagai sumber RAG.");
    } finally {
      setIsExtracting(false);
    }
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!item && form.source_type === "pdf") {
      await importPdfSource();
      return;
    }

    if (isDocumentCreate && !isDocumentExtracted) {
      const result = await extractDocumentUpload();

      if (!result) {
        return;
      }

      onSubmit({
        title: form.title.trim() || result.title || "",
        category: nullable(form.category),
        content: result.content.trim(),
        source_type: result.source_type,
        source_url: result.source_url ?? null,
        status: form.status,
      });

      return;
    }

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
    <form className="grid gap-5" onSubmit={submit}>
      <section className="grid gap-4 rounded-2xl border-2 border-border bg-surface p-4">
        <div>
          <h3 className="text-base font-black text-ink">Identitas Pengetahuan</h3>
          <p className="mt-1 text-sm leading-6 text-muted">
            Judul dan kategori membantu admin menemukan sumber saat mengelola Basis AI.
          </p>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
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
        </div>
      </section>
      {!isPdfRagCreate && !isDocumentCreate ? (
        <FormField label="Konten Pengetahuan">
          <Textarea
            className="min-h-40"
            onChange={(event) => setForm((current) => ({ ...current, content: event.target.value }))}
            required
            value={form.content}
          />
          <p className="mt-2 text-xs font-bold leading-5 text-muted">
            Agar Chatbot AI menjawab lebih tepat, buat pengetahuan secara spesifik. Contoh: &quot;Asal-usul Mekongga&quot;, &quot;Arti nama Mekongga&quot;, &quot;Kosakata dasar Mekongga&quot;, bukan satu konten terlalu umum.
          </p>
        </FormField>
      ) : (
        <div className="rounded-2xl border-2 border-border bg-info p-4 text-sm font-bold leading-6 text-info-foreground">
          {isPdfRagCreate
            ? "Konten Pengetahuan tidak diperlukan untuk Sumber RAG. PDF akan diproses per halaman dan chunk dibuat dari teks PDF."
            : "Konten Pengetahuan diambil otomatis dari berkas DOCX/TXT saat disimpan. Admin dapat mengeditnya setelah tersimpan."}
        </div>
      )}
      <section className="grid gap-4 rounded-2xl border-2 border-border bg-surface-muted p-4">
        <div>
          <h3 className="text-base font-black text-ink">Sumber dan Status</h3>
          <p className="mt-1 text-sm leading-6 text-muted">
            Pilih jenis sumber sesuai cara admin memasukkan pengetahuan.
          </p>
        </div>
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
            <option value="pdf">PDF</option>
            <option value="docx">Dokumen (DOCX/TXT)</option>
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
            <option value="published">Terbit</option>
            <option value="archived">Arsip</option>
          </Select>
        </FormField>
      </div>
      </section>
      {form.source_type === "pdf" ? (
        <div className="grid gap-3 rounded-2xl border-2 border-border bg-[var(--color-primary-muted)] p-4 text-sm leading-6 text-ink">
          <p className="font-bold">Upload PDF sebagai Sumber RAG</p>
          <p>
            Upload PDF dari perangkat admin. PDF harus berbasis teks. PDF hasil scan/foto belum dapat dibaca otomatis. PDF akan diproses per halaman dan chunk dibuat dari teks PDF untuk pencarian Chatbot AI.
          </p>
          <Input
            accept="application/pdf,.pdf"
            onChange={(event) => {
              setSelectedPdfFile(event.target.files?.[0] ?? null);
              setIsPdfSourceImported(false);
            }}
            type="file"
          />
          <MutationAlert eventKey={resultCounter} tone="success" visible={Boolean(extractMessage)}>{extractMessage}</MutationAlert>
          <MutationAlert eventKey={resultCounter} tone="error" visible={Boolean(extractError)}>{extractError}</MutationAlert>
        </div>
      ) : null}
      {form.source_type === "docx" || form.source_type === "txt" ? (
        <div className="grid gap-3 rounded-2xl border-2 border-border bg-[var(--color-primary-muted)] p-4 text-sm leading-6 text-ink">
          <p className="font-bold">Upload Dokumen (DOCX/TXT)</p>
          <p>
            Upload berkas DOCX atau TXT dari perangkat untuk mengambil isi teksnya secara otomatis. Setelah isi dokumen diambil, admin tetap dapat mengoreksi Konten Pengetahuan sebelum diterbitkan.
          </p>
          <Input
            accept=".docx,.txt,text/plain,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            onChange={(event) => {
              setSelectedDocumentFile(event.target.files?.[0] ?? null);
              setIsDocumentExtracted(false);
            }}
            type="file"
          />
          <MutationAlert eventKey={resultCounter} tone="success" visible={Boolean(extractMessage)}>{extractMessage}</MutationAlert>
          <MutationAlert eventKey={resultCounter} tone="error" visible={Boolean(extractError)}>{extractError}</MutationAlert>
        </div>
      ) : null}
      <div className="rounded-lg border-2 border-dashed border-border bg-info p-4 text-sm leading-6 text-info-foreground">
        Draft belum digunakan chatbot. Terbit digunakan chatbot siswa. Arsip tetap tersimpan, tetapi tidak digunakan chatbot.
      </div>
      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button
          disabled={
            isSubmitting ||
            isExtracting ||
            (isPdfRagCreate && (!selectedPdfFile || isPdfSourceImported)) ||
            (isDocumentCreate && !selectedDocumentFile)
          }
          type="submit"
        >
          {isPdfRagCreate
            ? isExtracting
              ? "Memproses PDF..."
              : "Proses PDF sebagai Sumber RAG"
            : isDocumentCreate
              ? isExtracting
                ? "Memproses dokumen..."
                : "Proses Dokumen"
              : item
                ? "Simpan Perubahan"
                : "Simpan Pengetahuan"}
        </Button>
      </div>
    </form>
  );
}
