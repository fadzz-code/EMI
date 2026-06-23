"use client";

import { type ReactNode, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

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
    <div className="rounded-lg border-2 border-ink bg-white p-4">
      <p className="text-xs font-black uppercase text-slate-500">{label}</p>
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
        className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100"
        href="/admin/dictionary"
      >
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
                <Badge tone="yellow">{entry.category?.name ?? "Tanpa kategori"}</Badge>
                <Badge tone={statusTone(entry.status)}>{statusLabel(entry.status)}</Badge>
              </div>
              <h1 className="mt-2 text-3xl font-black text-ink">{entry.mekongga}</h1>
              <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
                Detail kata kamus dari endpoint admin dictionary. Perubahan tetap
                mengikuti validasi dan policy backend.
              </p>
            </div>
            <div className="flex flex-col gap-2 sm:flex-row">
              <Button onClick={() => setEditOpen(true)} variant="secondary">
                Edit Entri
              </Button>
              <Button onClick={() => setDeleteOpen(true)} variant="danger">
                Delete
              </Button>
            </div>
          </header>

          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <DetailItem label="Mekongga" value={entry.mekongga} />
            <DetailItem label="Indonesia" value={entry.indonesia} />
            <DetailItem label="English" value={entry.english} />
            <DetailItem label="Kategori" value={entry.category?.name} />
            <DetailItem label="Status" value={statusLabel(entry.status)} />
            <DetailItem label="Audio Media ID" value={entry.audio?.id} />
            <DetailItem label="Dibuat" value={formatDateTime(entry.created_at)} />
            <DetailItem label="Terakhir Update" value={formatDateTime(entry.updated_at)} />
          </div>

          <div className="grid gap-4 lg:grid-cols-[1fr_380px]">
            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Contoh Kalimat</h2>
              </CardHeader>
              <CardContent className="grid gap-4">
                <DetailItem label="Mekongga" value={entry.example_mekongga} />
                <DetailItem label="Indonesia" value={entry.example_indonesia} />
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <h2 className="text-xl font-black text-ink">Audio</h2>
              </CardHeader>
              <CardContent>
                <AudioPlayer src={entry.audio?.url} title={`Audio ${entry.mekongga}`} />
                <p className="mt-3 text-sm text-slate-600">
                  Audio memakai file media publik yang terhubung melalui `audio_media_id`.
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
            confirmLabel="Delete Entri"
            description="Aksi ini memakai endpoint DELETE admin dictionary. Lanjutkan hanya jika entri memang tidak dipakai."
            onCancel={() => setDeleteOpen(false)}
            onConfirm={() => deleteMutation.mutate()}
            open={deleteOpen}
            title="Delete entri kamus?"
          />
        </>
      ) : null}
    </div>
  );
}
