"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Pencil } from "lucide-react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import { statusLabel } from "./teacher-utils";
import { useState } from "react";

export function TeacherModuleEdit({ moduleId }: { moduleId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const moduleQuery = useQuery({
    queryKey: ["teacher", "class-modules", moduleId],
    queryFn: () => teacherService.classModuleDetail(token ?? "", moduleId),
    enabled: Boolean(token && moduleId),
  });

  const updateMutation = useMutation({
    mutationFn: (payload: { title: string; description?: string; sort_order?: number }) =>
      teacherService.updateClassModule(token ?? "", moduleId, payload),
    onSuccess: () => {
      setSuccessMsg("Modul berhasil disimpan.");
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-modules", moduleId] });
      queryClient.invalidateQueries({ queryKey: ["teacher", "classes"] });
    },
  });

  const publishMutation = useMutation({
    mutationFn: () => teacherService.publishClassModule(token ?? "", moduleId),
    onSuccess: () => {
      setSuccessMsg("Modul berhasil dipublikasikan.");
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-modules", moduleId] });
      queryClient.invalidateQueries({ queryKey: ["teacher", "classes"] });
    },
  });

  const moduleData = moduleQuery.data;

  return (
    <div className="grid gap-8">
      <Link className="inline-flex min-h-11 w-fit items-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-sm font-black text-primary transition hover:-translate-y-0.5 hover:bg-[var(--color-primary-muted)] hover:shadow-emi" href={teacherRoutes.modules}>
        <ArrowLeft className="size-5" strokeWidth={2.5} /> Kembali ke Daftar Modul
      </Link>
      <PageHeader badge="Guru" description="Ubah judul, deskripsi, atau urutan modul kelas Anda." title="Edit Modul" />

      {moduleQuery.isLoading ? <LoadingState title="Memuat detail modul" /> : null}
      {moduleQuery.isError ? <ErrorState description={getFirstApiError(moduleQuery.error)} onRetry={() => void moduleQuery.refetch()} title="Gagal memuat modul" /> : null}

      {moduleData ? (
        <div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-black text-primary">Form Edit Modul</h2>
                <Badge tone={moduleData.status === "published" ? "blue" : "neutral"}>{statusLabel(moduleData.status)}</Badge>
              </div>
            </CardHeader>
            <CardContent>
              <form
                className="grid gap-4"
                key={moduleData.id}
                onSubmit={(e) => {
                  e.preventDefault();
                  setSuccessMsg(null);
                  const formData = new FormData(e.currentTarget);
                  updateMutation.mutate({
                    title: String(formData.get("title") ?? ""),
                    description: String(formData.get("description") ?? ""),
                    sort_order: Number(formData.get("sort_order") ?? 1),
                  });
                }}
              >
                {successMsg ? <Alert tone="success">{successMsg}</Alert> : null}
                {updateMutation.error ? <Alert tone="error">{getFirstApiError(updateMutation.error)}</Alert> : null}
                
                <label className="grid gap-2 text-sm font-black text-primary">
                  Judul Modul
                  <Input defaultValue={moduleData.title} name="title" required />
                </label>
                <label className="grid gap-2 text-sm font-black text-primary">
                  Deskripsi Modul
                  <Textarea defaultValue={moduleData.description ?? ""} name="description" rows={4} />
                </label>
                <label className="grid gap-2 text-sm font-black text-primary">
                  Urutan Tampil (Sort Order)
                  <Input defaultValue={moduleData.sort_order ?? 1} min={1} name="sort_order" type="number" required />
                </label>
                
                <div className="mt-2 flex flex-col gap-3 sm:flex-row">
                  <Button disabled={updateMutation.isPending || publishMutation.isPending} type="submit">
                    {updateMutation.isPending ? "Menyimpan..." : "Simpan Perubahan"}
                  </Button>
                  {moduleData.status !== "published" ? (
                    <Button
                      disabled={publishMutation.isPending || updateMutation.isPending}
                      onClick={() => {
                        if (confirm("Apakah Anda yakin ingin menerbitkan modul ini agar bisa diakses siswa?")) {
                          setSuccessMsg(null);
                          publishMutation.mutate();
                        }
                      }}
                      type="button"
                      variant="secondary"
                    >
                      {publishMutation.isPending ? "Menerbitkan..." : "Terbitkan Modul"}
                    </Button>
                  ) : null}
                </div>
                {publishMutation.error ? <Alert tone="error">{getFirstApiError(publishMutation.error)}</Alert> : null}
              </form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-primary">Daftar Materi (Lessons)</h2></CardHeader>
            <CardContent>
              {moduleData.lessons && moduleData.lessons.length > 0 ? (
                <div className="grid gap-3">
                  {moduleData.lessons.map((lesson) => (
                    <div className="flex flex-col gap-2 rounded-xl border border-border bg-surface-muted p-3" key={lesson.id}>
                      <div className="flex items-start justify-between gap-3">
                        <div className="font-bold text-primary">{lesson.title}</div>
                        <Badge tone={lesson.status === "published" ? "blue" : "neutral"}>{statusLabel(lesson.status)}</Badge>
                      </div>
                      <div className="text-xs text-muted">Tipe: {lesson.content_type || "-"} | Urutan: {lesson.sort_order}</div>
                      <Link
                        className="mt-2 inline-flex min-h-10 items-center justify-center gap-2 rounded-[var(--radius-control)] border-2 border-border bg-surface px-3 text-xs font-black text-primary transition hover:-translate-y-0.5 hover:bg-primary hover:text-primary-foreground hover:shadow-emi"
                        href={teacherRoutes.lessonEdit(moduleId, lesson.id)}
                      >
                        <Pencil className="size-4" strokeWidth={2.5} /> Edit Materi
                      </Link>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState description="Modul ini tidak memiliki materi (lessons)." title="Materi kosong" />
              )}
            </CardContent>
          </Card>
        </div>
      ) : null}
    </div>
  );
}
