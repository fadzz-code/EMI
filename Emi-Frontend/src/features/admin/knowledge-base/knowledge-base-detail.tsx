"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, LoadingState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { knowledgeBaseService } from "./knowledge-base-service";

const sourceTypeLabel = { manual: "Teks Manual", link: "Link", pdf: "PDF / Dokumen" } as const;
const statusLabel = { draft: "Draft", published: "Terbit", archived: "Arsip" } as const;

function formatDate(value?: string | null) {
  return value ? new Intl.DateTimeFormat("id-ID", { dateStyle: "long", timeStyle: "short" }).format(new Date(value)) : "-";
}

export function KnowledgeBaseDetail({ knowledgeId }: { knowledgeId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const detailQuery = useQuery({
    queryKey: ["admin", "knowledge-base", knowledgeId],
    queryFn: () => knowledgeBaseService.detail(token ?? "", knowledgeId),
    enabled: Boolean(token),
  });
  const retryMutation = useMutation({
    mutationFn: () => knowledgeBaseService.retryProcessing(token ?? "", knowledgeId),
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ["admin", "knowledge-base", knowledgeId] }),
        queryClient.invalidateQueries({ queryKey: ["admin", "knowledge-base"] }),
      ]);
    },
  });
  const item = detailQuery.data;
  const canRetry = item && item.source_type !== "manual" && item.processing_status !== "ready";

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div><Badge tone="yellow">ADMIN-12</Badge><h1 className="mt-2 text-3xl font-black text-ink">Detail Pengetahuan AI</h1><p className="mt-2 text-sm text-slate-600">Data langsung dari Basis AI.</p></div>
        <div className="flex gap-2"><Link className="inline-flex min-h-11 items-center rounded-lg border-2 border-ink bg-white px-4 font-bold" href="/admin/knowledge-base">Kembali</Link>{canRetry ? <Button disabled={retryMutation.isPending} onClick={() => retryMutation.mutate()}>{retryMutation.isPending ? "Memproses..." : "Proses Ulang"}</Button> : null}</div>
      </header>
      {retryMutation.isSuccess ? <Alert tone="success">Proses ulang Basis AI berhasil dijalankan.</Alert> : null}
      {retryMutation.isError ? <Alert tone="error">{getFirstApiError(retryMutation.error)}</Alert> : null}
      {detailQuery.isLoading ? <LoadingState title="Memuat detail Basis AI" /> : null}
      {detailQuery.isError ? <ErrorState description={getFirstApiError(detailQuery.error)} onRetry={() => void detailQuery.refetch()} title="Gagal memuat detail Basis AI" /> : null}
      {!detailQuery.isLoading && !detailQuery.isError && !item ? <EmptyState description="Data tidak ditemukan." title="Basis AI tidak tersedia" /> : null}
      {item ? <>
        <Card><CardHeader><h2 className="text-xl font-black text-ink">{item.title}</h2></CardHeader><CardContent><dl className="grid gap-4 md:grid-cols-2"><div><dt className="text-xs font-black uppercase text-slate-500">Status</dt><dd className="mt-1 font-bold">{statusLabel[item.status]}</dd></div><div><dt className="text-xs font-black uppercase text-slate-500">Pemrosesan</dt><dd className="mt-1 font-bold">{item.processing_status ?? "-"}</dd></div><div><dt className="text-xs font-black uppercase text-slate-500">Kategori</dt><dd className="mt-1">{item.category ?? "-"}</dd></div><div><dt className="text-xs font-black uppercase text-slate-500">Jenis sumber</dt><dd className="mt-1">{sourceTypeLabel[item.source_type]}</dd></div><div><dt className="text-xs font-black uppercase text-slate-500">Dibuat</dt><dd className="mt-1">{formatDate(item.created_at)}</dd></div><div><dt className="text-xs font-black uppercase text-slate-500">Diubah</dt><dd className="mt-1">{formatDate(item.updated_at)}</dd></div></dl>{item.source_url ? <a className="mt-4 block break-all font-bold text-blue-700 underline" href={item.source_url} rel="noreferrer noopener" target="_blank">{item.source_url}</a> : null}</CardContent></Card>
        <Card><CardHeader><h2 className="text-xl font-black text-ink">Konten Pengetahuan</h2></CardHeader><CardContent><div className="whitespace-pre-wrap rounded-lg border-2 border-ink bg-slate-50 p-4 text-sm leading-6">{item.content}</div></CardContent></Card>
      </> : null}
    </div>
  );
}
