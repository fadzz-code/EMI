"use client";

import { type ReactNode, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Pencil, Trash2 } from "lucide-react";

import {
  Alert,
  AudioPlayer,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
  ErrorState,
  LoadingState,
  Modal,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { DictionaryEntryForm } from "./dictionary-form";
import { dictionaryService } from "./dictionary-service";
import { formatDateTime, statusLabel, statusTone } from "./dictionary-utils";
import type { DictionaryEntryPayload } from "./types";

function DetailItem({ label, value }: { label: string; value?: ReactNode }) {
  return (
    <div className="flex h-full min-h-24 flex-col rounded-[var(--radius-card)] border-2 border-border bg-surface p-4 shadow-[2px_2px_0_var(--border)]">
      <p className="text-xs font-black uppercase tracking-wide text-muted">{label}</p>
      <div className="mt-2 text-sm font-bold text-ink">{value ?? "-"}</div>
    </div>
  );
}

export function DictionaryDetail({ entryId }: { entryId: string }) {
  const { token } = useAuth();
  const router = useRouter();
  const queryClient = useQueryClient();
  const [editOpen, setEditOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const entryQuery = useQuery({
    queryKey: ["admin", "dictionary", "entries", entryId],
    queryFn: () => dictionaryService.detailEntry(token ?? "", entryId),
    enabled: Boolean(token && entryId),
  });

  const categoriesQuery = useQuery({
    queryKey: ["admin", "dictionary", "categories"],
    queryFn: () => dictionaryService.listCategories(token ?? "", { per_page: 100 }),
    enabled: Boolean(token),
  });

  const updateMutation = useMutation({
    mutationFn: (payload: DictionaryEntryPayload) =>
      dictionaryService.updateEntry(token ?? "", entryId, payload),
    onSuccess: async (entry) => {
      setSuccessMessage(`Entri ${entry.mekongga} berhasil diperbarui.`);
      setEditOpen(false);
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary"] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: () => dictionaryService.deleteEntry(token ?? "", entryId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["admin", "dictionary", "entries"] });
      router.push("/admin/dictionary");
    },
  });

  const entry = entryQuery.data;
  const categories = categoriesQuery.data?.items ?? [];
  const actionError = updateMutation.error ?? deleteMutation.error;

  return (
    <div className="grid gap-6">
      <Link
        className="w-fit rounded-lg border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink hover:bg-surface-muted"
        href="/admin/dictionary"
      >
        <ArrowLeft aria-hidden="true" className="mr-2 inline size-4" />
        Kembali ke Kamus
      </Link>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      {entryQuery.isLoading ? <LoadingState title="Memuat detail kamus" /> : null}
      {entryQuery.isError ? (
        <ErrorState
          description={getFirstApiError(entryQuery.error)}
          onRetry={() => void entryQuery.refetch()}
          title="Gagal memuat detail kamus"
        />
      ) : null}

      {entry ? (
        <>
          <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <div className="flex flex-wrap gap-2">
                <Badge tone="neutral">{entry.category?.name ?? "Tanpa kategori"}</Badge>
                <Badge tone={statusTone(entry.status)}>{statusLabel(entry.status)}</Badge>
              </div>
              <h1 className="mt-2 text-3xl font-black text-ink">{entry.mekongga}</h1>
              <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
                Tinjau terjemahan, contoh kalimat, status, kategori, dan audio yang
                terhubung dengan kata ini.
              </p>
            </div>
            <div className="flex flex-col gap-2 sm:flex-row">
              <Button onClick={() => setEditOpen(true)} variant="secondary">
                <Pencil aria-hidden="true" className="mr-2 size-4" />
                Edit Entri
              </Button>
              <Button onClick={() => setDeleteOpen(true)} variant="danger">
                <Trash2 aria-hidden="true" className="mr-2 size-4" />
                Hapus
              </Button>
            </div>
          </header>

          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <DetailItem label="Mekongga" value={entry.mekongga} />
            <DetailItem label="Indonesia" value={entry.indonesia} />
            <DetailItem label="Inggris" value={entry.english} />
            <DetailItem label="Kategori" value={entry.category?.name} />
            <DetailItem label="Status" value={statusLabel(entry.status)} />
            <DetailItem label="Audio Media ID" value={entry.audio?.id} />
            <DetailItem label="Dibuat" value={formatDateTime(entry.created_at)} />
            <DetailItem label="Terakhir Diubah" value={formatDateTime(entry.updated_at)} />
          </div>

          <div className="grid gap-4 lg:grid-cols-[1fr_380px]">
            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Contoh Kalimat</h2>
              </CardHeader>
              <CardContent className="grid gap-3">
                {entry.example_mekongga || entry.example_indonesia ? (
                  <div className="rounded-lg border-2 border-border bg-surface p-4">
                    <p className="text-xs font-black uppercase text-muted">Contoh Kalimat</p>
                    <p className="mt-2 text-sm font-bold text-ink">Mekongga: {entry.example_mekongga ?? "-"}</p>
                    <p className="mt-1 text-sm font-bold text-muted">Indonesia: {entry.example_indonesia ?? "-"}</p>
                  </div>
                ) : null}
                {(entry.sentence_examples ?? []).map((example, index) => (
                  <div key={example.id} className="rounded-lg border-2 border-border bg-surface p-4">
                    <p className="text-xs font-black uppercase text-muted">Contoh Tambahan {index + 1}</p>
                    <p className="mt-2 text-sm font-bold text-ink">Mekongga: {example.contoh_mekongga}</p>
                    <p className="mt-1 text-sm font-bold text-muted">Indonesia: {example.contoh_indonesia}</p>
                  </div>
                ))}
                {!entry.example_mekongga && !entry.example_indonesia && (entry.sentence_examples ?? []).length === 0 ? (
                  <p className="rounded-lg border-2 border-dashed border-border bg-surface p-4 text-sm font-bold text-muted">Belum ada contoh kalimat.</p>
                ) : null}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Audio</h2>
              </CardHeader>
              <CardContent>
                <AudioPlayer src={entry.audio?.url} title={`Audio ${entry.mekongga}`} />
                <p className="mt-3 text-sm text-muted">
                  Audio muncul jika entri sudah memiliki file media publik yang valid.
                </p>
              </CardContent>
            </Card>
          </div>

          <Modal onClose={() => setEditOpen(false)} open={editOpen} title="Edit Entri Kamus">
            <DictionaryEntryForm
              categories={categories.filter((category) => category.status === "active")}
              entry={entry}
              isSubmitting={updateMutation.isPending}
              onCancel={() => setEditOpen(false)}
              onSubmit={(payload) => updateMutation.mutate(payload)}
              token={token ?? ""}
            />
          </Modal>

          <ConfirmDialog
            confirmLabel="Hapus Entri"
            description="Lanjutkan hanya jika entri memang tidak dipakai lagi di kamus."
            onCancel={() => setDeleteOpen(false)}
            onConfirm={() => deleteMutation.mutate()}
            open={deleteOpen}
            title="Hapus entri kamus?"
          />
        </>
      ) : null}
    </div>
  );
}
