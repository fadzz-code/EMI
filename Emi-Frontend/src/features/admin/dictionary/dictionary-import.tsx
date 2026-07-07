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
import type { DictionaryImportJob, DictionaryImportType, DuplicateStrategy } from "./types";

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
  const [importType, setImportType] = useState<DictionaryImportType>("vocabulary");
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
        audioZip: importType === "vocabulary" ? audioZip : null,
        duplicateStrategy,
        importType,
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
    mutationFn: (type: DictionaryImportType) => dictionaryService.downloadTemplate(token ?? "", type),
    onSuccess: (blob, type) => {
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = type === "sentence_examples" ? "template-contoh-kalimat-bahasa-mekongga.csv" : "template-kata-bahasa-mekongga.csv";
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
          <h1 className="mt-2 text-3xl font-black text-ink">Impor Kamus</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Buat pratinjau CSV dan ZIP audio terlebih dahulu, lalu konfirmasi hanya
            jika ringkasan baris valid sudah sesuai.
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
              <div className="grid gap-4 md:grid-cols-2">
                {([
                  ["vocabulary", "Import Kosakata", "Untuk data kata utama dan ZIP audio opsional."],
                  ["sentence_examples", "Import Contoh Kalimat", "Untuk menempelkan banyak contoh kalimat ke kode kosakata yang sudah ada."],
                ] as const).map(([type, title, description]) => (
                  <div key={type} className={`flex h-full flex-col rounded-xl border-2 p-4 ${importType === type ? "border-ink bg-yellow-100" : "border-border bg-white"}`}>
                    <button
                      className="block w-full text-left"
                      onClick={() => {
                        setImportType(type);
                        setCsvFile(null);
                        setAudioZip(null);
                      }}
                      type="button"
                    >
                      <p className="text-lg font-black text-ink">{title}</p>
                      <p className="mt-1 text-xs font-bold leading-5 text-slate-600">{description}</p>
                    </button>
                    <Button
                      className="mt-auto w-full"
                      disabled={templateMutation.isPending}
                      onClick={() => {
                        setImportType(type);
                        setCsvFile(null);
                        setAudioZip(null);
                        templateMutation.mutate(type);
                      }}
                      type="button"
                      variant="secondary"
                    >
                      Download Template {type === "vocabulary" ? "Kosakata" : "Contoh Kalimat"}
                    </Button>
                  </div>
                ))}
              </div>
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

              {importType === "vocabulary" ? (
                <>
                  <FormField label="ZIP audio (opsional)">
                    <UploadComponent
                      accept=".zip,application/zip,application/x-zip-compressed"
                      onChange={(event) => setAudioZip(event.target.files?.[0] ?? null)}
                    />
                    <p className="mt-2 text-xs font-bold leading-5 text-slate-600">
                      ZIP audio bersifat opsional untuk Kosakata. Jika tidak diunggah, data kata tetap bisa diimpor tanpa audio. Jika ingin menyertakan audio, pastikan nama file di CSV sama persis dengan nama file di ZIP.
                    </p>
                  </FormField>
                  {audioZip ? (
                    <FilePreview
                      name={audioZip.name}
                      size={formatBytes(audioZip.size)}
                      type="ZIP"
                    />
                  ) : null}
                </>
              ) : (
                <Alert tone="info">Import Contoh Kalimat hanya memakai CSV sesuai template client dan tidak memakai ZIP audio.</Alert>
              )}

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

              <Button disabled={!csvFile || previewMutation.isPending} type="submit">
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
                  <p>Jenis: {selectedJob.import_type === "sentence_examples" ? "Contoh Kalimat" : "Kosakata"}</p>
                  <p>Strategi: {duplicateStrategyLabel(selectedJob.duplicate_strategy)}</p>
                  <p>Dibuat: {formatDateTime(selectedJob.created_at)}</p>
                  <p>Ditambahkan: {numberValue(selectedJob.inserted_rows)}</p>
                  <p>Diperbarui: {numberValue(selectedJob.updated_rows)}</p>
                  <p>Dilewati: {numberValue(selectedJob.skipped_rows)}</p>
                  <p>Audio Tidak Terpakai: {summaryValue(selectedJob, "unused_audio_files")}</p>
                </div>

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
                      className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-100"
                      href="/admin/dictionary"
                    >
                      Lihat Kamus
                    </Link>
                  ) : null}
                </div>
              </div>
            ) : (
              <EmptyState
                description="Unggah CSV untuk membuat pratinjau, atau pilih riwayat impor di bawah."
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
                      <th className="px-4 py-3">Baris</th>
                      <th className="px-4 py-3">Kolom</th>
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
                        <TableCell>
                          <div className="grid gap-1">
                            <p>{error.message}</p>
                            {error.code === "AUDIO_FILE_NOT_FOUND" ? (
                              <p className="text-xs font-bold text-slate-600">
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
