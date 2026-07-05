"use client";

import { type FormEvent, useState } from "react";

import { Alert, Button, FormField, Input, Select, Textarea } from "@/components/ui";
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
  const [pdfSourceMode, setPdfSourceMode] = useState<"upload" | "url" | "rag">("upload");
  const [selectedPdfFile, setSelectedPdfFile] = useState<File | null>(null);
  const [extractMessage, setExtractMessage] = useState<string | null>(null);
  const [extractError, setExtractError] = useState<string | null>(null);
  const [isPdfSourceImported, setIsPdfSourceImported] = useState(false);
  const isPdfRagCreate = !item && form.source_type === "pdf" && pdfSourceMode === "rag";

  async function extractSource() {
    if (!token || (form.source_type !== "link" && form.source_type !== "pdf") || !form.source_url.trim()) {
      return;
    }

    setIsExtracting(true);
    setExtractMessage(null);
    setExtractError(null);

    try {
      const result = await knowledgeBaseService.extractKnowledgeSource(token, {
        source_type: form.source_type,
        source_url: form.source_url.trim(),
      });

      setForm((current) => ({
        ...current,
        content: result.content,
        title: current.title || result.title || current.title,
        source_url: result.source_url ?? current.source_url,
      }));
      setExtractMessage("Isi sumber berhasil diambil. Periksa kembali konten sebelum menyimpan.");
    } catch (error) {
      const message = getFirstApiError(error);
      setExtractError(message || "Isi sumber tidak dapat diambil. Pastikan URL publik dapat diakses dan format sumber sesuai.");
    } finally {
      setIsExtracting(false);
    }
  }

  async function extractPdfUpload() {
    if (!token || !selectedPdfFile) {
      return;
    }

    setIsExtracting(true);
    setExtractMessage(null);
    setExtractError(null);

    try {
      const result = await knowledgeBaseService.extractPdfUpload(token, selectedPdfFile);

      setForm((current) => ({
        ...current,
        content: result.content,
        source_type: "pdf",
        source_url: result.source_url ?? current.source_url,
        title: current.title || result.title || current.title,
      }));
      setExtractMessage("Isi PDF berhasil diambil. Periksa kembali konten sebelum menyimpan.");
    } catch (error) {
      const message = getFirstApiError(error);
      setExtractError(message || "Isi PDF tidak dapat dibaca. Pastikan PDF berbasis teks dan bukan hasil scan/foto.");
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

    if (!item && form.source_type === "pdf" && pdfSourceMode === "rag") {
      await importPdfSource();
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
      <section className="grid gap-4 rounded-lg border-2 border-ink bg-white p-4">
        <div>
          <h3 className="text-base font-black text-ink">Identitas Pengetahuan</h3>
          <p className="mt-1 text-sm leading-6 text-slate-600">
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
      {!isPdfRagCreate ? (
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
      ) : (
        <div className="rounded-lg border-2 border-ink bg-blue-50 p-4 text-sm font-bold leading-6 text-blue-950">
          Konten Pengetahuan tidak diperlukan untuk Sumber RAG. PDF akan diproses per halaman dan chunk dibuat dari teks PDF.
        </div>
      )}
      <section className="grid gap-4 rounded-lg border-2 border-ink bg-surface-muted p-4">
        <div>
          <h3 className="text-base font-black text-ink">Sumber dan Status</h3>
          <p className="mt-1 text-sm leading-6 text-slate-600">
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
            <option value="published">Terbit</option>
            <option value="archived">Arsip</option>
          </Select>
        </FormField>
      </div>
      </section>
      {form.source_type !== "pdf" ? (
        <FormField label="URL Sumber">
          <Input
            onChange={(event) => setForm((current) => ({ ...current, source_url: event.target.value }))}
            placeholder="https://contoh-sumber-resmi.test"
            required={form.source_type === "link"}
            type="url"
            value={form.source_url}
          />
          {form.source_type === "link" ? (
            <p className="mt-2 text-xs font-bold leading-5 text-slate-600">
              Gunakan link artikel atau halaman publik yang dapat diakses tanpa login.
            </p>
          ) : null}
        </FormField>
      ) : null}
      {form.source_type === "pdf" ? (
        <div className="grid gap-3 rounded-lg border-2 border-ink bg-yellow-50 p-4 text-sm leading-6 text-yellow-950">
          <p className="font-bold">PDF dapat diambil dari upload file lokal atau dari URL PDF publik.</p>
          <p>
            Upload PDF dari perangkat digunakan untuk mengambil isi PDF dari file lokal admin. PDF harus berbasis teks. PDF hasil scan/foto belum dapat dibaca otomatis. Setelah isi PDF diambil, admin tetap dapat mengoreksi Konten Pengetahuan sebelum diterbitkan.
          </p>
          <div className="grid gap-3 sm:grid-cols-3">
            <label className="flex items-center gap-2 font-bold">
              <input
                checked={pdfSourceMode === "upload"}
                onChange={() => setPdfSourceMode("upload")}
                type="radio"
              />
              Ekstrak ke Konten
            </label>
            <label className="flex items-center gap-2 font-bold">
              <input checked={pdfSourceMode === "rag"} onChange={() => setPdfSourceMode("rag")} type="radio" />
              Proses Sumber RAG
            </label>
            <label className="flex items-center gap-2 font-bold">
              <input checked={pdfSourceMode === "url"} onChange={() => setPdfSourceMode("url")} type="radio" />
              Ambil dari URL PDF publik
            </label>
          </div>
          {pdfSourceMode === "upload" || pdfSourceMode === "rag" ? (
            <div className="grid gap-3">
              <Input
                accept="application/pdf,.pdf"
                onChange={(event) => {
                  setSelectedPdfFile(event.target.files?.[0] ?? null);
                  setIsPdfSourceImported(false);
                }}
                type="file"
              />
              <div>
                {pdfSourceMode === "rag" ? (
                  <Button disabled={isExtracting || !selectedPdfFile || !form.title.trim() || isPdfSourceImported} onClick={importPdfSource} type="button" variant="secondary">
                    {isExtracting ? "Memproses PDF..." : isPdfSourceImported ? "PDF Sumber RAG Sudah Diproses" : "Upload PDF Besar sebagai Sumber"}
                  </Button>
                ) : (
                  <Button disabled={isExtracting || !selectedPdfFile} onClick={extractPdfUpload} type="button" variant="secondary">
                    {isExtracting ? "Membaca isi PDF..." : "Ambil Isi PDF"}
                  </Button>
                )}
              </div>
            </div>
          ) : (
            <FormField label="URL PDF Publik">
              <Input
                onChange={(event) => setForm((current) => ({ ...current, source_url: event.target.value }))}
                placeholder="https://contoh-sumber-resmi.test/dokumen.pdf"
                type="url"
                value={form.source_url}
              />
              <div className="mt-3">
                <Button disabled={isExtracting || !form.source_url.trim()} onClick={extractSource} type="button" variant="secondary">
                  {isExtracting ? "Mengambil isi sumber..." : "Ambil Isi Sumber"}
                </Button>
              </div>
            </FormField>
          )}
          {extractMessage ? <Alert tone="success">{extractMessage}</Alert> : null}
          {extractError ? <Alert tone="error">{extractError}</Alert> : null}
        </div>
      ) : null}
      {form.source_type === "link" ? (
        <div className="grid gap-3 rounded-lg border-2 border-ink bg-yellow-50 p-4 text-sm leading-6 text-yellow-950">
          <p className="font-bold">
            Link tidak otomatis digunakan chatbot hanya karena URL disimpan. Gunakan tombol &quot;Ambil Isi Sumber&quot; agar isi sumber masuk ke Konten Pengetahuan. Admin tetap dapat mengoreksi konten sebelum diterbitkan.
          </p>
          <div>
            <Button disabled={isExtracting || !form.source_url.trim()} onClick={extractSource} type="button" variant="secondary">
              {isExtracting ? "Mengambil isi sumber..." : "Ambil Isi Sumber"}
            </Button>
          </div>
          {extractMessage ? <Alert tone="success">{extractMessage}</Alert> : null}
          {extractError ? <Alert tone="error">{extractError}</Alert> : null}
        </div>
      ) : null}
      <div className="rounded-lg border-2 border-dashed border-ink bg-blue-50 p-4 text-sm leading-6 text-blue-950">
        Draft belum digunakan chatbot. Terbit digunakan chatbot siswa. Arsip tetap tersimpan, tetapi tidak digunakan chatbot.
      </div>
      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting || (isPdfRagCreate && isPdfSourceImported)} type="submit">
          {isPdfRagCreate ? "Proses PDF sebagai Sumber RAG" : item ? "Simpan Perubahan" : "Simpan Pengetahuan"}
        </Button>
      </div>
    </form>
  );
}
