"use client";

import { type FormEvent, useMemo, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  EmptyState,
  ErrorState,
  FilePreview,
  FormField,
  LoadingState,
  Pagination,
  Select,
  StatsCard,
  Table,
  TableCell,
  TableHeader,
  UploadComponent,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { dictionaryService } from "./dictionary-service";
import {
  duplicateStrategyLabel,
  formatBytes,
  formatDateTime,
  importStatusLabel,
  statusTone,
} from "./dictionary-utils";
import type { DictionaryImportJob, DictionaryImportSheetSummary, DictionaryImportSummary, DuplicateStrategy } from "./types";

function numberValue(value?: number | null) {
  return String(value ?? 0);
}

function summaryValue(summary: DictionaryImportSheetSummary | null | undefined, key: string) {
  const value = summary?.[key];

  return typeof value === "number" ? String(value) : "-";
}

function simpleErrorLabel(value?: string | null) {
  const labels: Record<string, string> = {
    vocabulary: "Kosakata",
    sentence_examples: "Contoh Kalimat",
    audio: "Audio",
    AUDIO_FILE_NOT_FOUND: "Audio tidak ditemukan",
    AUDIO_FILE_AMBIGUOUS: "Nama audio ganda",
    AUDIO_FILE_DUPLICATE: "Audio duplikat",
    REQUIRED: "Wajib diisi",
    DUPLICATE: "Data duplikat",
    INVALID: "Data tidak valid",
  };

  return value ? labels[value] ?? value.replaceAll("_", " ").toLowerCase() : "-";
}

function audioFilename(rawData?: Record<string, unknown> | null) {
  const value = rawData?.filename ?? rawData?.audio_filename ?? rawData?.audio;
  return typeof value === "string" ? value : "-";
}

const ERROR_CODE_INFO: Record<string, { label: string; hint: string }> = {
  REQUIRED: { label: "Kolom wajib kosong", hint: "Isi kolom Bahasa Indonesia (kolom lain boleh menyusul)." },
  CATEGORY_NOT_FOUND: { label: "Kategori tidak dikenal", hint: "Pilih kategori dari menu Kamus, atau kosongkan kolomnya." },
  DICTIONARY_DUPLICATE: { label: "Kata sudah ada / ganda", hint: "Hapus baris ganda, atau ubah strategi duplikat ke Lewati/Perbarui." },
  SENTENCE_DUPLICATE: { label: "Kalimat sudah ada / ganda", hint: "Hapus baris ganda, atau ubah strategi duplikat ke Lewati/Perbarui." },
  CODE_NOT_FOUND: { label: "Kode tidak ditemukan", hint: "Impor kosakata dulu, atau periksa ejaan kodenya." },
  RELATED_MEKONGGA_NOT_FOUND: { label: "Kata terkait tidak ada", hint: "Impor kata di sheet Kosakata dulu, atau samakan ejaan Mekongga-nya." },
  AMBIGUOUS_RELATED_MEKONGGA: { label: "Kata terkait ganda", hint: "Rapikan entri kamus yang duplikat agar tautannya jelas." },
  UNSAFE_ZIP_ENTRY: { label: "Nama audio tidak aman", hint: "Nama file audio tidak boleh mengandung path (garis miring)." },
};

type BreakdownRow = { code: string; count: number };

function collectBreakdown(summary: DictionaryImportSummary | null | undefined): BreakdownRow[] {
  const totals: Record<string, number> = {};
  const sources = [summary?.error_breakdown, summary?.vocabulary?.error_breakdown, summary?.sentence_examples?.error_breakdown];

  for (const source of sources) {
    if (source && typeof source === "object") {
      for (const [code, count] of Object.entries(source as Record<string, number>)) {
        totals[code] = (totals[code] ?? 0) + (typeof count === "number" ? count : 0);
      }
    }
  }

  return Object.entries(totals)
    .filter(([, count]) => count > 0)
    .map(([code, count]) => ({ code, count }))
    .sort((a, b) => b.count - a.count);
}

function ErrorBreakdown({ summary }: { summary: DictionaryImportSummary | null | undefined }) {
  const rows = collectBreakdown(summary);

  if (rows.length === 0) {
    return null;
  }

  return (
    <div className="grid gap-3 rounded-lg border-2 border-border bg-surface p-4">
      <h3 className="font-black text-ink">Kenapa ada baris tidak valid?</h3>
      <div className="grid gap-2">
        {rows.map(({ code, count }) => {
          const info = ERROR_CODE_INFO[code] ?? { label: simpleErrorLabel(code), hint: "Periksa kembali baris terkait." };
          return (
            <div className="grid gap-1 rounded-md border-2 border-border bg-bg p-3 text-sm" key={code}>
              <div className="flex items-center justify-between gap-2">
                <span className="font-black text-ink">{info.label}</span>
                <Badge tone="yellow">{count} baris</Badge>
              </div>
              <p className="font-bold text-muted">Saran: {info.hint}</p>
            </div>
          );
        })}
      </div>
      <p className="text-xs font-bold text-muted">Rincian per baris ada di tabel Error Impor di bawah.</p>
    </div>
  );
}

function SheetSummary({ label, summary }: { label: string; summary?: DictionaryImportSheetSummary }) {
  return (
    <div className="grid h-full gap-3 rounded-lg border-2 border-border bg-surface p-4">
      <h3 className="font-black text-ink">{label}</h3>
      <div className="grid grid-cols-2 gap-3">
        <StatsCard label="Total Baris" value={summaryValue(summary, "total_rows")} />
        <StatsCard label="Baris Valid" value={summaryValue(summary, "valid_rows")} />
        <StatsCard label="Baris Tidak Valid" value={summaryValue(summary, "invalid_rows")} />
        <StatsCard label="Duplikat" value={summaryValue(summary, "duplicate_rows")} />
      </div>
    </div>
  );
}

export function DictionaryImport() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [excelFile, setExcelFile] = useState<File | null>(null);
  const [audioZip, setAudioZip] = useState<File | null>(null);
  const [duplicateStrategy, setDuplicateStrategy] = useState<DuplicateStrategy>("skip");
  const [page, setPage] = useState(1);
  const [selectedJobId, setSelectedJobId] = useState<string | null>(null);
  const [previewJob, setPreviewJob] = useState<DictionaryImportJob | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [deleteJobId, setDeleteJobId] = useState<string | null>(null);
  const [deleteErrorId, setDeleteErrorId] = useState<string | null>(null);
  const [clearErrorsOpen, setClearErrorsOpen] = useState(false);
  const [confirmImportOpen, setConfirmImportOpen] = useState(false);

  const importsQuery = useQuery({
    queryKey: ["admin", "dictionary", "imports", page],
    queryFn: () => dictionaryService.listImports(token ?? "", { page, per_page: 10 }),
    enabled: Boolean(token),
    refetchInterval: (query) =>
      query.state.data?.items.some((job) => job.status === "queued" || job.status === "processing")
        ? 2_000
        : false,
  });

  const selectedJob = useMemo(
    () => importsQuery.data?.items.find((job) => job.id === selectedJobId) ?? previewJob,
    [importsQuery.data?.items, previewJob, selectedJobId],
  );

  const errorsQuery = useQuery({
    queryKey: ["admin", "dictionary", "imports", selectedJobId, "errors"],
    queryFn: () => dictionaryService.importErrors(token ?? "", selectedJobId ?? ""),
    enabled: Boolean(token && selectedJobId),
  });

  const previewMutation = useMutation({
    mutationFn: () => {
      if (!excelFile) {
        throw new Error("File Excel wajib dipilih.");
      }

      return dictionaryService.previewImport(token ?? "", {
        csvFile: excelFile,
        audioZip,
        duplicateStrategy,
      });
    },
    onSuccess: async (job) => {
      setPreviewJob(job);
      setSelectedJobId(job.id);
      setSuccessMessage("Pratinjau impor berhasil dibuat. Periksa ringkasan sebelum konfirmasi.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "imports"] });
    },
  });

  const confirmMutation = useMutation({
    mutationFn: (jobId: string) => dictionaryService.confirmImport(token ?? "", jobId),
    onSuccess: async (job) => {
      setPreviewJob(job);
      setSelectedJobId(job.id);
      setConfirmImportOpen(false);
      setSuccessMessage("Import sedang diproses. Sistem akan memperbarui hasil secara otomatis.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary"] });
    },
  });

  const deleteJobMutation = useMutation({
    mutationFn: (jobId: string) => dictionaryService.deleteImport(token ?? "", jobId),
    onSuccess: async (_, jobId) => {
      if (selectedJobId === jobId) setSelectedJobId(null);
      setDeleteJobId(null);
      setSuccessMessage("Riwayat impor dihapus. Data yang sudah diimpor tetap tersimpan.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "imports"] });
    },
  });

  const deleteErrorMutation = useMutation({
    mutationFn: (errorId: string) => dictionaryService.deleteImportError(token ?? "", selectedJobId ?? "", errorId),
    onSuccess: async () => {
      setDeleteErrorId(null);
      setSuccessMessage("Error impor dihapus. Data yang sudah diimpor tetap tersimpan.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "imports", selectedJobId, "errors"] });
    },
  });

  const clearErrorsMutation = useMutation({
    mutationFn: () => dictionaryService.clearImportErrors(token ?? "", selectedJobId ?? ""),
    onSuccess: async () => {
      setClearErrorsOpen(false);
      setSuccessMessage("Semua error impor dihapus. Data yang sudah diimpor tetap tersimpan.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "imports", selectedJobId, "errors"] });
    },
  });

  const templateMutation = useMutation({
    mutationFn: () => dictionaryService.downloadTemplate(token ?? ""),
    onSuccess: (blob) => {
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = "template-import-kamus-emi.xlsx";
      link.click();
      URL.revokeObjectURL(url);
    },
  });

  const imports = importsQuery.data?.items ?? [];
  const meta = importsQuery.data?.meta;
  const actionError =
    previewMutation.error ?? confirmMutation.error ?? templateMutation.error ?? deleteJobMutation.error ?? deleteErrorMutation.error ?? clearErrorsMutation.error;

  function submitPreview(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSuccessMessage(null);
    previewMutation.mutate();
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="blue">Admin</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Impor Kamus</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
            Buat pratinjau Excel terlebih dahulu, lalu konfirmasi hanya jika ringkasan
            Kosakata dan Contoh Kalimat sudah sesuai.
          </p>
        </div>

      </header>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      <div className="grid min-w-0 gap-6 xl:grid-cols-[420px_minmax(0,1fr)]">
        <Card className="min-w-0">
          <CardHeader>
            <h2 className="text-xl font-black text-ink">Upload File Excel</h2>
          </CardHeader>
          <CardContent>
            <form className="grid gap-4" onSubmit={submitPreview}>
              <div className="flex h-full min-h-48 flex-col rounded-[var(--radius-card)] border-2 border-primary bg-[var(--color-primary-muted)] p-4">
                <div className="block w-full text-left">
                  <p className="text-lg font-black text-ink">Import Excel</p>
                  <p className="mt-1 text-xs font-bold leading-5 text-muted">Untuk data kata utama, contoh kalimat, dan ZIP audio (tersemat jika pakai ZIP).</p>
                </div>
                <Button
                  className="mt-auto w-full"
                  disabled={templateMutation.isPending}
                  onClick={() => templateMutation.mutate()}
                  type="button"
                  variant="secondary"
                >
                  Download Template
                </Button>
              </div>
              <FormField label="Upload File Excel">
                <UploadComponent
                  accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                  onChange={(event) => setExcelFile(event.target.files?.[0] ?? null)}
                  required
                />
              </FormField>
              {excelFile ? (
                <FilePreview
                  name={excelFile.name}
                  size={formatBytes(excelFile.size)}
                  type="XLSX"
                />
              ) : null}
              <FormField label="Upload ZIP Audio (Opsional)">
                <UploadComponent
                  accept=".zip,application/zip,application/x-zip-compressed"
                  onChange={(event) => setAudioZip(event.target.files?.[0] ?? null)}
                />
              </FormField>
              {audioZip ? <FilePreview name={audioZip.name} size={formatBytes(audioZip.size)} type="ZIP" /> : null}

              <FormField label="Strategi duplikat">
                <Select
                  onChange={(event) => setDuplicateStrategy(event.target.value as DuplicateStrategy)}
                  value={duplicateStrategy}
                >
                  <option value="skip">Lewati duplikat</option>
                  <option value="update">Perbarui duplikat</option>
                  <option value="reject">Tolak jika duplikat</option>
                </Select>
              </FormField>

              <Button disabled={!excelFile || previewMutation.isPending} type="submit">
                Lihat Preview
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card className="min-w-0">
          <CardHeader>
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <h2 className="break-words text-xl font-black text-ink">Ringkasan Pratinjau</h2>
              {selectedJob ? (
                <Badge tone={statusTone(selectedJob.status)}>
                  {importStatusLabel(selectedJob.status)}
                </Badge>
              ) : null}
            </div>
          </CardHeader>
          <CardContent>
            {selectedJob ? (
              <div className="grid gap-4">
                <div className="grid gap-4 sm:grid-cols-2 2xl:grid-cols-4">
                  <StatsCard label="Total Baris" value={numberValue(selectedJob.total_rows)} />
                  <StatsCard label="Baris Valid" value={numberValue(selectedJob.valid_rows)} />
                  <StatsCard label="Baris Tidak Valid" value={numberValue(selectedJob.invalid_rows)} />
                  <StatsCard label="Peringatan" value={numberValue(selectedJob.warning_count)} />
                </div>

                <div className="grid min-w-0 items-stretch gap-4 lg:grid-cols-2">
                  <SheetSummary label="Kosakata" summary={selectedJob.summary?.vocabulary} />
                  <SheetSummary label="Contoh Kalimat" summary={selectedJob.summary?.sentence_examples} />
                </div>

                {(selectedJob.invalid_rows ?? 0) > 0 ? <ErrorBreakdown summary={selectedJob.summary} /> : null}

                <div className="grid gap-3 rounded-lg border-2 border-border bg-surface p-4 sm:grid-cols-2 2xl:grid-cols-3">
                  <StatsCard label="File Ditemukan" value={numberValue(selectedJob.summary?.audio?.files_found)} />
                  <StatsCard label="Cocok" value={numberValue(selectedJob.summary?.audio?.matched)} />
                  <StatsCard label="Tidak Ditemukan" value={numberValue(selectedJob.summary?.audio?.missing)} />
                  <StatsCard label="Nama Ganda" value={numberValue(selectedJob.summary?.audio?.ambiguous)} />
                  <StatsCard label="Tidak Terpakai" value={numberValue(selectedJob.summary?.audio?.unused)} />
                  <StatsCard label="Dipasang" value={numberValue(selectedJob.summary?.audio?.installed)} />
                </div>

                {selectedJob.failure_message ? (
                  <Alert tone="error">{selectedJob.failure_message}</Alert>
                ) : null}

                <div className="grid gap-3 rounded-lg border-2 border-border bg-surface p-4 text-sm font-bold text-ink md:grid-cols-2">
                  <p className="min-w-0 break-words">Excel: {selectedJob.csv_original_name ?? "-"} ({formatBytes(selectedJob.csv_size_bytes)})</p>
                  <p className="min-w-0 break-words">ZIP audio: {selectedJob.audio_zip_original_name ?? "Tidak diunggah"} ({formatBytes(selectedJob.audio_zip_size_bytes)})</p>
                  <p>Format: {selectedJob.source_format?.toUpperCase() ?? "-"}</p>
                  <p>Jenis: {selectedJob.import_type === "combined" ? "Gabungan" : selectedJob.import_type === "sentence_examples" ? "Contoh Kalimat" : "Kosakata"}</p>
                  <p>Strategi: {duplicateStrategyLabel(selectedJob.duplicate_strategy)}</p>
                  <p>Dibuat: {formatDateTime(selectedJob.created_at)}</p>
                  <p>Ditambahkan: {numberValue(selectedJob.inserted_rows)}</p>
                  <p>Diperbarui: {numberValue(selectedJob.updated_rows)}</p>
                  <p>Dilewati: {numberValue(selectedJob.skipped_rows)}</p>
                </div>

                {selectedJob.summary?.vocabulary_result || selectedJob.summary?.sentence_examples_result || selectedJob.summary?.audio_result ? (
                  <div className="grid gap-4 md:grid-cols-3">
                    {([
                      ["Kosakata", selectedJob.summary?.vocabulary_result],
                      ["Contoh Kalimat", selectedJob.summary?.sentence_examples_result],
                      ["Audio", selectedJob.summary?.audio_result],
                    ] as const).map(([label, result]) => (
                      <div key={label} className="rounded-lg border-2 border-border bg-surface p-4 text-sm font-bold text-ink">
                        <h3 className="mb-2 font-black">Hasil {label}</h3>
                        {label === "Audio" ? (
                          <>
                            <p>Dipasang: {numberValue(result?.installed ?? result?.inserted)}</p>
                            <p>Tidak ditemukan: {numberValue(result?.missing)}</p>
                            <p>Duplikat atau nama ganda: {numberValue(result?.ambiguous ?? result?.duplicate)}</p>
                          </>
                        ) : (
                          <>
                            <p>Ditambahkan: {numberValue(result?.inserted)}</p>
                            <p>Diperbarui: {numberValue(result?.updated)}</p>
                            <p>Dilewati: {numberValue(result?.skipped)}</p>
                          </>
                        )}
                      </div>
                    ))}
                  </div>
                ) : null}

                <div className="flex flex-wrap items-center gap-3">
                  <Button
                    disabled={
                      confirmMutation.isPending ||
                      selectedJob.status !== "preview_ready" ||
                      (selectedJob.valid_rows ?? 0) < 1
                    }
                    onClick={() => setConfirmImportOpen(true)}
                    variant="secondary"
                  >
                    Import
                  </Button>
                  {(selectedJob.status === "completed" || selectedJob.status === "completed_with_errors") ? (
                    <Link
                      className="inline-flex min-h-11 items-center justify-center rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-bold text-ink shadow-emi hover:bg-surface-muted"
                      href="/admin/dictionary"
                    >
                      Selesai
                    </Link>
                  ) : null}
                </div>
              </div>
            ) : (
              <EmptyState
                description="Unggah Excel untuk membuat pratinjau, atau pilih riwayat impor di bawah."
                title="Belum ada pratinjau dipilih"
              />
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Riwayat Impor</h2>
        </CardHeader>
        <CardContent>
          {importsQuery.isLoading ? <LoadingState title="Memuat riwayat impor" /> : null}
          {importsQuery.isError ? (
            <ErrorState
              description={getFirstApiError(importsQuery.error)}
              onRetry={() => void importsQuery.refetch()}
              title="Gagal memuat riwayat impor"
            />
          ) : null}
          {!importsQuery.isLoading && !importsQuery.isError ? (
            imports.length === 0 ? (
              <EmptyState
                description="Belum ada riwayat impor kamus yang tersimpan."
                title="Riwayat kosong"
              />
            ) : (
              <div className="grid min-w-0 gap-4">
                <Table className="w-full table-fixed">
                  <TableHeader className="hidden lg:table-header-group">
                    <tr>
                      <th className="px-4 py-3">File</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Strategi</th>
                      <th className="px-4 py-3">Valid/Invalid</th>
                      <th className="px-4 py-3">Dibuat</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody className="grid min-w-0 gap-4 lg:table-row-group">
                    {imports.map((job) => (
                      <tr className="grid min-w-0 gap-3 rounded-xl border-2 border-border p-4 lg:table-row lg:rounded-none lg:border-0 lg:p-0" key={job.id}>
                        <TableCell className="min-w-0 break-words border-0 p-0 lg:border-t lg:px-4 lg:py-3">{job.csv_original_name ?? "-"}</TableCell>
                        <TableCell className="border-0 p-0 lg:border-t lg:px-4 lg:py-3">
                          <span className="mr-2 font-bold lg:hidden">Status:</span>
                          <Badge tone={statusTone(job.status)}>
                            {importStatusLabel(job.status)}
                          </Badge>
                        </TableCell>
                        <TableCell className="border-0 p-0 lg:border-t lg:px-4 lg:py-3"><span className="font-bold lg:hidden">Strategi: </span>{duplicateStrategyLabel(job.duplicate_strategy)}</TableCell>
                        <TableCell className="border-0 p-0 lg:border-t lg:px-4 lg:py-3">
                          <span className="font-bold lg:hidden">Valid/Tidak valid: </span>{numberValue(job.valid_rows)} / {numberValue(job.invalid_rows)}
                        </TableCell>
                        <TableCell className="border-0 p-0 lg:border-t lg:px-4 lg:py-3"><span className="font-bold lg:hidden">Dibuat: </span>{formatDateTime(job.created_at)}</TableCell>
                        <TableCell className="border-0 p-0 lg:border-t lg:px-4 lg:py-3">
                          <div className="flex flex-wrap gap-2">
                            <Button
                              className="min-h-9 px-3 py-1 text-xs"
                              onClick={() => setSelectedJobId(job.id)}
                              variant="ghost"
                            >
                              Lihat Detail
                            </Button>
                            <Button className="min-h-9 px-3 py-1 text-xs" disabled={job.status === "queued" || job.status === "processing"} onClick={() => setDeleteJobId(job.id)} variant="danger">
                              Hapus
                            </Button>
                          </div>
                        </TableCell>
                      </tr>
                    ))}
                  </tbody>
                </Table>
                <Pagination
                  onPageChange={setPage}
                  page={meta?.current_page ?? page}
                  totalPages={meta?.last_page ?? 1}
                />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>

      {selectedJobId ? (
        <Card>
          <CardHeader>
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <h2 className="text-xl font-black text-ink">Error Impor</h2>
              {(errorsQuery.data?.items ?? []).length > 0 ? <Button onClick={() => setClearErrorsOpen(true)} variant="danger">Hapus Semua Error</Button> : null}
            </div>
          </CardHeader>
          <CardContent>
            {errorsQuery.isLoading ? <LoadingState title="Memuat error impor" /> : null}
            {errorsQuery.isError ? (
              <ErrorState
                description={getFirstApiError(errorsQuery.error)}
                onRetry={() => void errorsQuery.refetch()}
                title="Gagal memuat error impor"
              />
            ) : null}
            {!errorsQuery.isLoading && !errorsQuery.isError ? (
              (errorsQuery.data?.items ?? []).length === 0 ? (
                <EmptyState
                  description="Tidak ada error validasi untuk impor ini."
                  title="Tidak ada error"
                />
              ) : (
                <Table className="w-full table-fixed">
                  <TableHeader className="hidden lg:table-header-group">
                    <tr>
                      <th className="px-4 py-3">Bagian</th>
                      <th className="px-4 py-3">Baris</th>
                      <th className="px-4 py-3">Kolom</th>
                      <th className="px-4 py-3">Kode</th>
                      <th className="px-4 py-3">Pesan</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody className="grid min-w-0 gap-4 lg:table-row-group">
                    {(errorsQuery.data?.items ?? []).map((error) => (
                      <tr className="grid min-w-0 gap-2 rounded-xl border-2 border-border p-4 lg:table-row lg:rounded-none lg:border-0 lg:p-0" key={error.id}>
                        <TableCell className="border-0 p-0 lg:border-t lg:px-4 lg:py-3"><span className="font-bold lg:hidden">Bagian: </span>{simpleErrorLabel(error.sheet)}</TableCell>
                        <TableCell className="border-0 p-0 lg:border-t lg:px-4 lg:py-3"><span className="font-bold lg:hidden">Baris: </span>{error.row_number ?? "-"}</TableCell>
                        <TableCell className="min-w-0 break-words border-0 p-0 lg:border-t lg:px-4 lg:py-3"><span className="font-bold lg:hidden">Kolom: </span>{simpleErrorLabel(error.field)}</TableCell>
                        <TableCell className="min-w-0 break-words border-0 p-0 lg:border-t lg:px-4 lg:py-3"><span className="font-bold lg:hidden">Masalah: </span>{simpleErrorLabel(error.code)}</TableCell>
                        <TableCell className="min-w-0 break-words border-0 p-0 lg:border-t lg:px-4 lg:py-3">
                          <div className="grid min-w-0 gap-1">
                            <p>{error.message}</p>
                            {error.code?.startsWith("AUDIO_") ? (
                              <div className="grid gap-1 text-xs font-bold text-muted">
                                <p>File: {audioFilename(error.raw_data)}</p>
                                <p>Status: {simpleErrorLabel(error.code)}</p>
                                <p>Alasan: {error.message}</p>
                              </div>
                            ) : null}
                          </div>
                        </TableCell>
                        <TableCell className="border-0 p-0 lg:border-t lg:px-4 lg:py-3">
                          <Button className="min-h-9 px-3 py-1 text-xs" onClick={() => setDeleteErrorId(error.id)} variant="danger">Hapus</Button>
                        </TableCell>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              )
            ) : null}
          </CardContent>
        </Card>
      ) : null}

      <ConfirmDialog
        confirmLabel="Import"
        confirmVariant="secondary"
        description="Data valid dari preview akan diimpor ke kamus. Lanjutkan?"
        isConfirming={confirmMutation.isPending}
        onCancel={() => setConfirmImportOpen(false)}
        onConfirm={() => selectedJob && confirmMutation.mutate(selectedJob.id)}
        open={confirmImportOpen}
        title="Import data kamus?"
      />
      <ConfirmDialog
        confirmLabel="Hapus Riwayat"
        description="Riwayat impor akan dihapus. Data kamus yang sudah diimpor tetap tersimpan."
        isConfirming={deleteJobMutation.isPending}
        onCancel={() => setDeleteJobId(null)}
        onConfirm={() => deleteJobId && deleteJobMutation.mutate(deleteJobId)}
        open={Boolean(deleteJobId)}
        title="Hapus riwayat impor?"
      />
      <ConfirmDialog
        confirmLabel="Hapus Error"
        description="Error ini akan dihapus. Data yang sudah diimpor tetap tersimpan."
        isConfirming={deleteErrorMutation.isPending}
        onCancel={() => setDeleteErrorId(null)}
        onConfirm={() => deleteErrorId && deleteErrorMutation.mutate(deleteErrorId)}
        open={Boolean(deleteErrorId)}
        title="Hapus error impor?"
      />
      <ConfirmDialog
        confirmLabel="Hapus Semua Error"
        description="Semua error impor ini akan dihapus. Data yang sudah diimpor tetap tersimpan."
        isConfirming={clearErrorsMutation.isPending}
        onCancel={() => setClearErrorsOpen(false)}
        onConfirm={() => clearErrorsMutation.mutate()}
        open={clearErrorsOpen}
        title="Hapus semua error impor?"
      />
    </div>
  );
}
