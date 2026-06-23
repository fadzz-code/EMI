"use client";

import { type FormEvent, useMemo, useState } from "react";
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
import type { DictionaryImportJob, DuplicateStrategy } from "./types";

function numberValue(value?: number | null) {
  return String(value ?? 0);
}

function summaryValue(job: DictionaryImportJob | null, key: string) {
  const value = job?.summary?.[key];

  return typeof value === "number" ? String(value) : "-";
}

export function DictionaryImport() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [audioZip, setAudioZip] = useState<File | null>(null);
  const [duplicateStrategy, setDuplicateStrategy] = useState<DuplicateStrategy>("skip");
  const [page, setPage] = useState(1);
  const [selectedJobId, setSelectedJobId] = useState<string | null>(null);
  const [previewJob, setPreviewJob] = useState<DictionaryImportJob | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const importsQuery = useQuery({
    queryKey: ["admin", "dictionary", "imports", page],
    queryFn: () => dictionaryService.listImports(token ?? "", { page, per_page: 10 }),
    enabled: Boolean(token),
  });

  const selectedJob = useMemo(() => {
    if (previewJob && previewJob.id === selectedJobId) {
      return previewJob;
    }

    return importsQuery.data?.items.find((job) => job.id === selectedJobId) ?? previewJob;
  }, [importsQuery.data?.items, previewJob, selectedJobId]);

  const errorsQuery = useQuery({
    queryKey: ["admin", "dictionary", "imports", selectedJobId, "errors"],
    queryFn: () => dictionaryService.importErrors(token ?? "", selectedJobId ?? ""),
    enabled: Boolean(token && selectedJobId),
  });

  const previewMutation = useMutation({
    mutationFn: () => {
      if (!csvFile) {
        throw new Error("CSV wajib dipilih.");
      }

      return dictionaryService.previewImport(token ?? "", {
        csvFile,
        audioZip,
        duplicateStrategy,
      });
    },
    onSuccess: async (job) => {
      setPreviewJob(job);
      setSelectedJobId(job.id);
      setSuccessMessage("Preview import berhasil dibuat. Periksa ringkasan sebelum confirm.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "imports"] });
    },
  });

  const confirmMutation = useMutation({
    mutationFn: (jobId: string) => dictionaryService.confirmImport(token ?? "", jobId),
    onSuccess: async (job) => {
      setPreviewJob(job);
      setSelectedJobId(job.id);
      setSuccessMessage("Import sudah dikonfirmasi. Status terbaru mengikuti backend.");
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary"] });
    },
  });

  const templateMutation = useMutation({
    mutationFn: () => dictionaryService.downloadTemplate(token ?? ""),
    onSuccess: (blob) => {
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = "emi-dictionary-template.csv";
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
          <Badge tone="yellow">Admin</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Import Kamus</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Preview CSV dan ZIP audio memakai endpoint import backend sebelum data
            benar-benar dimasukkan ke kamus.
          </p>
        </div>
        <Button
          disabled={templateMutation.isPending}
          onClick={() => templateMutation.mutate()}
          variant="secondary"
        >
          Download Template CSV
        </Button>
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
              <FormField label="File CSV">
                <UploadComponent
                  accept=".csv,text/csv"
                  onChange={(event) => setCsvFile(event.target.files?.[0] ?? null)}
                  required
                />
              </FormField>
              {csvFile ? (
                <FilePreview
                  name={csvFile.name}
                  size={formatBytes(csvFile.size)}
                  type="CSV"
                />
              ) : null}

              <FormField label="ZIP audio (opsional)">
                <UploadComponent
                  accept=".zip,application/zip,application/x-zip-compressed"
                  onChange={(event) => setAudioZip(event.target.files?.[0] ?? null)}
                />
              </FormField>
              {audioZip ? (
                <FilePreview
                  name={audioZip.name}
                  size={formatBytes(audioZip.size)}
                  type="ZIP"
                />
              ) : null}

              <FormField label="Strategi duplikat">
                <Select
                  onChange={(event) => setDuplicateStrategy(event.target.value as DuplicateStrategy)}
                  value={duplicateStrategy}
                >
                  <option value="skip">Skip duplikat</option>
                  <option value="update">Update duplikat</option>
                  <option value="reject">Tolak jika duplikat</option>
                </Select>
              </FormField>

              <Button disabled={!csvFile || previewMutation.isPending} type="submit">
                Buat Preview Import
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <h2 className="text-xl font-black text-ink">Ringkasan Preview</h2>
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
                  <StatsCard label="Total Row" value={numberValue(selectedJob.total_rows)} />
                  <StatsCard label="Valid Row" value={numberValue(selectedJob.valid_rows)} />
                  <StatsCard label="Invalid Row" value={numberValue(selectedJob.invalid_rows)} />
                  <StatsCard label="Warning" value={numberValue(selectedJob.warning_count)} />
                  <StatsCard label="Baru" value={summaryValue(selectedJob, "new_rows")} />
                  <StatsCard label="Duplikat" value={summaryValue(selectedJob, "duplicate_rows")} />
                  <StatsCard label="Audio Dirujuk" value={summaryValue(selectedJob, "audio_referenced")} />
                  <StatsCard label="Audio Hilang" value={summaryValue(selectedJob, "audio_missing")} />
                </div>

                {selectedJob.failure_message ? (
                  <Alert tone="error">{selectedJob.failure_message}</Alert>
                ) : null}

                <div className="grid gap-3 rounded-lg border-2 border-ink bg-white p-4 text-sm font-bold text-ink md:grid-cols-2">
                  <p>CSV: {selectedJob.csv_original_name ?? "-"} ({formatBytes(selectedJob.csv_size_bytes)})</p>
                  <p>ZIP: {selectedJob.audio_zip_original_name ?? "-"} ({formatBytes(selectedJob.audio_zip_size_bytes)})</p>
                  <p>Strategi: {duplicateStrategyLabel(selectedJob.duplicate_strategy)}</p>
                  <p>Dibuat: {formatDateTime(selectedJob.created_at)}</p>
                  <p>Inserted: {numberValue(selectedJob.inserted_rows)}</p>
                  <p>Updated: {numberValue(selectedJob.updated_rows)}</p>
                  <p>Skipped: {numberValue(selectedJob.skipped_rows)}</p>
                  <p>Unused audio: {summaryValue(selectedJob, "unused_audio_files")}</p>
                </div>

                <Button
                  disabled={
                    confirmMutation.isPending ||
                    selectedJob.status !== "preview_ready" ||
                    (selectedJob.valid_rows ?? 0) < 1
                  }
                  onClick={() => confirmMutation.mutate(selectedJob.id)}
                  variant="secondary"
                >
                  Confirm Import
                </Button>
              </div>
            ) : (
              <EmptyState
                description="Upload CSV untuk membuat preview, atau pilih riwayat import di bawah."
                title="Belum ada preview dipilih"
              />
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Riwayat Import</h2>
        </CardHeader>
        <CardContent>
          {importsQuery.isLoading ? <LoadingState title="Memuat riwayat import" /> : null}
          {importsQuery.isError ? (
            <ErrorState
              description={getFirstApiError(importsQuery.error)}
              onRetry={() => void importsQuery.refetch()}
              title="Gagal memuat riwayat import"
            />
          ) : null}
          {!importsQuery.isLoading && !importsQuery.isError ? (
            imports.length === 0 ? (
              <EmptyState
                description="Belum ada import kamus yang tersimpan."
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
            <h2 className="text-xl font-black text-ink">Error Import</h2>
          </CardHeader>
          <CardContent>
            {errorsQuery.isLoading ? <LoadingState title="Memuat error import" /> : null}
            {errorsQuery.isError ? (
              <ErrorState
                description={getFirstApiError(errorsQuery.error)}
                onRetry={() => void errorsQuery.refetch()}
                title="Gagal memuat error import"
              />
            ) : null}
            {!errorsQuery.isLoading && !errorsQuery.isError ? (
              (errorsQuery.data?.items ?? []).length === 0 ? (
                <EmptyState
                  description="Backend tidak mengembalikan error untuk import ini."
                  title="Tidak ada error"
                />
              ) : (
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Row</th>
                      <th className="px-4 py-3">Field</th>
                      <th className="px-4 py-3">Kode</th>
                      <th className="px-4 py-3">Pesan</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {(errorsQuery.data?.items ?? []).map((error) => (
                      <tr key={error.id}>
                        <TableCell>{error.row_number ?? "-"}</TableCell>
                        <TableCell>{error.field ?? "-"}</TableCell>
                        <TableCell>{error.code ?? "-"}</TableCell>
                        <TableCell>{error.message}</TableCell>
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
