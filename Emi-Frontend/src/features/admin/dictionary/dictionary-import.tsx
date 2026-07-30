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
import type { DictionaryImportJob, DictionaryImportSheetSummary, DuplicateStrategy } from "./types";

function numberValue(value?: number | null) {
  return String(value ?? 0);
}

function summaryValue(summary: DictionaryImportSheetSummary | null | undefined, key: string) {
  const value = summary?.[key];

  return typeof value === "number" ? String(value) : "-";
}

function SheetSummary({ label, summary }: { label: string; summary?: DictionaryImportSheetSummary }) {
  return (
    <div className="grid gap-3 rounded-lg border-2 border-border bg-surface p-4">
      <h3 className="font-black text-ink">{label}</h3>
      <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
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
  const [duplicateStrategy, setDuplicateStrategy] = useState<DuplicateStrategy>("skip");
  const [page, setPage] = useState(1);
  const [selectedJobId, setSelectedJobId] = useState<string | null>(null);
  const [previewJob, setPreviewJob] = useState<DictionaryImportJob | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

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
      setSuccessMessage("Impor sedang diproses. Sistem akan memperbarui hasil impor secara otomatis.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary"] });
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
    previewMutation.error ?? confirmMutation.error ?? templateMutation.error;

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

      <div className="grid gap-6 xl:grid-cols-[420px_1fr]">
        <Card>
          <CardHeader>
            <h2 className="text-xl font-black text-ink">Upload File</h2>
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
              <FormField label="File Excel">
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
                Buat Pratinjau
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <h2 className="text-xl font-black text-ink">Ringkasan Pratinjau</h2>
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
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                  <StatsCard label="Total Baris" value={numberValue(selectedJob.total_rows)} />
                  <StatsCard label="Baris Valid" value={numberValue(selectedJob.valid_rows)} />
                  <StatsCard label="Baris Tidak Valid" value={numberValue(selectedJob.invalid_rows)} />
                  <StatsCard label="Peringatan" value={numberValue(selectedJob.warning_count)} />
                </div>

                <div className="grid gap-4 xl:grid-cols-2">
                  <SheetSummary label="Kosakata" summary={selectedJob.summary?.vocabulary} />
                  <SheetSummary label="Contoh Kalimat" summary={selectedJob.summary?.sentence_examples} />
                </div>

                {selectedJob.failure_message ? (
                  <Alert tone="error">{selectedJob.failure_message}</Alert>
                ) : null}

                <div className="grid gap-3 rounded-lg border-2 border-border bg-surface p-4 text-sm font-bold text-ink md:grid-cols-2">
                  <p>Excel: {selectedJob.csv_original_name ?? "-"} ({formatBytes(selectedJob.csv_size_bytes)})</p>
                  <p>Format: {selectedJob.source_format?.toUpperCase() ?? "-"}</p>
                  <p>Jenis: {selectedJob.import_type === "combined" ? "Gabungan" : selectedJob.import_type === "sentence_examples" ? "Contoh Kalimat" : "Kosakata"}</p>
                  <p>Strategi: {duplicateStrategyLabel(selectedJob.duplicate_strategy)}</p>
                  <p>Dibuat: {formatDateTime(selectedJob.created_at)}</p>
                  <p>Ditambahkan: {numberValue(selectedJob.inserted_rows)}</p>
                  <p>Diperbarui: {numberValue(selectedJob.updated_rows)}</p>
                  <p>Dilewati: {numberValue(selectedJob.skipped_rows)}</p>
                </div>

                {selectedJob.summary?.vocabulary_result || selectedJob.summary?.sentence_examples_result ? (
                  <div className="grid gap-4 md:grid-cols-2">
                    {([
                      ["Kosakata", selectedJob.summary?.vocabulary_result],
                      ["Contoh Kalimat", selectedJob.summary?.sentence_examples_result],
                    ] as const).map(([label, result]) => (
                      <div key={label} className="rounded-lg border-2 border-border bg-surface p-4 text-sm font-bold text-ink">
                        <h3 className="mb-2 font-black">Hasil {label}</h3>
                        <p>Ditambahkan: {numberValue(result?.inserted)}</p>
                        <p>Diperbarui: {numberValue(result?.updated)}</p>
                        <p>Dilewati: {numberValue(result?.skipped)}</p>
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
                    onClick={() => confirmMutation.mutate(selectedJob.id)}
                    variant="secondary"
                  >
                    Konfirmasi Impor
                  </Button>
                  {(selectedJob.status === "completed" || selectedJob.status === "completed_with_errors") ? (
                    <Link
                      className="inline-flex min-h-11 items-center justify-center rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-bold text-ink shadow-emi hover:bg-surface-muted"
                      href="/admin/dictionary"
                    >
                      Lihat Kamus
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
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">File</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Strategi</th>
                      <th className="px-4 py-3">Valid/Invalid</th>
                      <th className="px-4 py-3">Dibuat</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {imports.map((job) => (
                      <tr key={job.id}>
                        <TableCell>{job.csv_original_name ?? "-"}</TableCell>
                        <TableCell>
                          <Badge tone={statusTone(job.status)}>
                            {importStatusLabel(job.status)}
                          </Badge>
                        </TableCell>
                        <TableCell>{duplicateStrategyLabel(job.duplicate_strategy)}</TableCell>
                        <TableCell>
                          {numberValue(job.valid_rows)} / {numberValue(job.invalid_rows)}
                        </TableCell>
                        <TableCell>{formatDateTime(job.created_at)}</TableCell>
                        <TableCell>
                          <Button
                            className="min-h-9 px-3 py-1 text-xs"
                            onClick={() => setSelectedJobId(job.id)}
                            variant="ghost"
                          >
                            Lihat Detail
                          </Button>
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
            <h2 className="text-xl font-black text-ink">Error Impor</h2>
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
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Sheet</th>
                      <th className="px-4 py-3">Baris</th>
                      <th className="px-4 py-3">Kolom</th>
                      <th className="px-4 py-3">Kode</th>
                      <th className="px-4 py-3">Pesan</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {(errorsQuery.data?.items ?? []).map((error) => (
                      <tr key={error.id}>
                        <TableCell>{error.sheet ?? "-"}</TableCell>
                        <TableCell>{error.row_number ?? "-"}</TableCell>
                        <TableCell>{error.field ?? "-"}</TableCell>
                        <TableCell>{error.code ?? "-"}</TableCell>
                        <TableCell>
                          <div className="grid gap-1">
                            <p>{error.message}</p>
                            {error.code === "AUDIO_FILE_NOT_FOUND" ? (
                              <p className="text-xs font-bold text-muted">
                                Kolom: audio. Masalah: File audio tidak ditemukan atau ZIP audio tidak diunggah. Solusi: Kata tetap bisa diimpor tanpa audio. Untuk menambahkan audio, unggah ZIP berisi file dengan nama yang sama seperti di CSV.
                              </p>
                            ) : null}
                          </div>
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
    </div>
  );
}
