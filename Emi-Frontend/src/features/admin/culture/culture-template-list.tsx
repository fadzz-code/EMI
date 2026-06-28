"use client";

import Link from "next/link";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { adminCultureService } from "./culture-service";

function statusLabel(status: string | null | undefined) {
  if (status === "draft") return "Draft";
  if (status === "published") return "Terbit";
  if (status === "archived") return "Arsip";
  return status ?? "Belum tersedia";
}

export function AdminCultureTemplateList() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [showCreate, setShowCreate] = useState(false);

  const query = useQuery({
    queryKey: ["admin", "culture-templates", search],
    queryFn: () => adminCultureService.getTemplates(token ?? "", search),
    enabled: Boolean(token),
  });

  const createMutation = useMutation({
    mutationFn: (payload: { title: string; description: string }) => adminCultureService.createTemplate(token ?? "", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["admin", "culture-templates"] });
      setShowCreate(false);
    },
  });

  const templates = query.data?.items ?? [];

  return (
    <div className="grid gap-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <PageHeader badge="Admin" description="Kelola template Budaya Mekongga yang dapat diterapkan ke kelas." title="Budaya Mekongga" />
        <Button onClick={() => setShowCreate((v) => !v)} type="button">{showCreate ? "Batal" : "Buat Template"}</Button>
      </div>

      {showCreate ? (
        <Card>
          <CardHeader><h2 className="text-xl font-black text-ink">Buat Template Budaya</h2></CardHeader>
          <CardContent>
            <form className="grid gap-4 sm:max-w-md" onSubmit={(e) => {
              e.preventDefault();
              const formData = new FormData(e.currentTarget);
              createMutation.mutate({ title: String(formData.get("title") ?? ""), description: String(formData.get("description") ?? "") });
            }}>
              {createMutation.error ? <Alert tone="error">{getFirstApiError(createMutation.error)}</Alert> : null}
              <label className="grid gap-2 text-sm font-black text-ink">Judul<Input name="title" required /></label>
              <label className="grid gap-2 text-sm font-black text-ink">Deskripsi (Opsional)<Input name="description" /></label>
              <Button disabled={createMutation.isPending} type="submit">{createMutation.isPending ? "Menyimpan..." : "Buat Template"}</Button>
            </form>
          </CardContent>
        </Card>
      ) : null}

      <div className="mb-2 max-w-sm"><Input onChange={(e) => setSearch(e.target.value)} placeholder="Cari template..." value={search} /></div>

      {query.isLoading ? <LoadingState title="Memuat template" /> : null}
      {query.isError ? <ErrorState description={getFirstApiError(query.error)} onRetry={() => void query.refetch()} title="Gagal memuat template" /> : null}

      {!query.isLoading && !query.isError && templates.length === 0 ? <EmptyState description="Belum ada template budaya." title="Template kosong" /> : null}

      {templates.length > 0 ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {templates.map((template) => (
            <Card key={template.id}>
              <CardHeader>
                <div className="flex items-start justify-between gap-3">
                  <div><Badge tone={template.status === "published" ? "blue" : "neutral"}>{statusLabel(template.status)}</Badge><h3 className="mt-2 font-black text-ink">{template.title}</h3></div>
                </div>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-slate-600 line-clamp-2">{template.description ?? "Tanpa deskripsi"}</p>
                <p className="mt-2 text-sm font-bold text-slate-500">{template.items_count ?? 0} item</p>
                <Link className="mt-4 inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-200" href={`/admin/culture/templates/${template.id}/edit`}>Edit Template</Link>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : null}
    </div>
  );
}
