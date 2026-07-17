"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";

import { Alert, Badge, Button, Card, CardContent, CardHeader, EmptyState, ErrorState, Input, LoadingState, PageHeader, Textarea } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { friendlyLessonMediaError, lessonMediaConfig, validateLessonMedia } from "./teacher-lesson-workflow";
import { teacherService } from "./teacher-service";
import { statusLabel } from "./teacher-utils";

export function TeacherLessonEdit({ moduleId, lessonId }: { moduleId: string; lessonId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [mediaError, setMediaError] = useState<string | null>(null);

  const lessonQuery = useQuery({
    queryKey: ["teacher", "class-lessons", lessonId],
    queryFn: () => teacherService.classLessonDetail(token ?? "", lessonId),
    enabled: Boolean(token && lessonId),
  });

  const updateMutation = useMutation({
    mutationFn: (payload: Record<string, unknown>) => teacherService.updateClassLesson(token ?? "", lessonId, payload),
    onSuccess: () => {
      setSuccessMsg("Materi berhasil disimpan.");
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-lessons", lessonId] });
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-modules", moduleId] });
    },
  });

  const publishMutation = useMutation({
    mutationFn: () => teacherService.publishClassLesson(token ?? "", lessonId),
    onSuccess: () => {
      setSuccessMsg("Materi berhasil dipublikasikan.");
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-lessons", lessonId] });
      queryClient.invalidateQueries({ queryKey: ["teacher", "class-modules", moduleId] });
    },
  });

  const uploadMediaMutation = useMutation({
    mutationFn: ({ file, purpose }: { file: File; purpose: "document" | "lesson_image" | "audio" }) => teacherService.uploadMedia(token ?? "", file, purpose),
  });

  const lessonData = lessonQuery.data;
  const mediaConfig = lessonData?.content_type ? lessonMediaConfig(lessonData.content_type) : null;
  const isMediaOperationPending = uploadMediaMutation.isPending || updateMutation.isPending;

  const handleUploadFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !lessonData?.content_type || !mediaConfig) return;
    const validationError = validateLessonMedia(file, lessonData.content_type);
    setSuccessMsg(null);
    setMediaError(validationError);
    if (validationError) {
      e.target.value = "";
      return;
    }

    try {
      const media = await uploadMediaMutation.mutateAsync({ file, purpose: mediaConfig.purpose });
      await updateMutation.mutateAsync({ media_id: media.id });
      setSuccessMsg("Media berhasil diunggah dan disimpan ke materi.");
    } catch (error) {
      setSuccessMsg(null);
      setMediaError(friendlyLessonMediaError(error));
    } finally {
      e.target.value = "";
    }
  };

  return (
    <div className="grid gap-6">
      <Link className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={teacherRoutes.moduleEdit(moduleId)}>
        Kembali ke Modul
      </Link>
      <PageHeader badge="Guru" description="Ubah konten materi kelas Anda." title="Edit Materi (Lesson)" />

      {lessonQuery.isLoading ? <LoadingState title="Memuat detail materi" /> : null}
      {lessonQuery.isError ? <ErrorState description={getFirstApiError(lessonQuery.error)} onRetry={() => void lessonQuery.refetch()} title="Gagal memuat materi" /> : null}

      {lessonData ? (
        <div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-black text-ink">Form Edit Materi</h2>
                <Badge tone={lessonData.status === "published" ? "blue" : "neutral"}>{statusLabel(lessonData.status)}</Badge>
              </div>
            </CardHeader>
            <CardContent>
              <form
                className="grid gap-4"
                key={lessonData.id}
                onSubmit={(e) => {
                  e.preventDefault();
                  setSuccessMsg(null);
                  const formData = new FormData(e.currentTarget);
                   updateMutation.mutate({
                     title: String(formData.get("title") ?? ""),
                     description: String(formData.get("description") ?? "") || null,
                     content_body: lessonData.content_type === "text" ? String(formData.get("content_body") ?? "") || null : null,
                     external_url: lessonData.content_type === "video" || lessonData.content_type === "link" ? String(formData.get("external_url") ?? "") || null : null,
                     sort_order: Number(formData.get("sort_order") ?? 1),
                   });
                }}
              >
                {successMsg ? <Alert tone="success">{successMsg}</Alert> : null}
                {updateMutation.error ? <Alert tone="error">{getFirstApiError(updateMutation.error)}</Alert> : null}

                <label className="grid gap-2 text-sm font-black text-ink">
                  Judul Materi
                  <Input defaultValue={lessonData.title} name="title" required />
                </label>
                <label className="grid gap-2 text-sm font-black text-ink">
                  Deskripsi Singkat
                  <Textarea defaultValue={lessonData.description ?? ""} name="description" rows={2} />
                </label>
                {lessonData.content_type === "text" && (
                  <label className="grid gap-2 text-sm font-black text-ink">
                    Isi Materi (Teks)
                    <Textarea defaultValue={lessonData.content_body ?? ""} name="content_body" rows={6} />
                  </label>
                )}
                {(lessonData.content_type === "video" || lessonData.content_type === "link") && (
                  <label className="grid gap-2 text-sm font-black text-ink">
                    URL Eksternal (contoh: link YouTube)
                    <Input defaultValue={lessonData.external_url ?? ""} name="external_url" type="url" />
                  </label>
                )}
                <label className="grid gap-2 text-sm font-black text-ink">
                  Urutan Tampil
                  <Input defaultValue={lessonData.sort_order ?? 1} min={1} name="sort_order" type="number" required />
                </label>

                <div className="mt-2 flex flex-col gap-3 sm:flex-row">
                  <Button disabled={isMediaOperationPending || publishMutation.isPending} type="submit">
                    {updateMutation.isPending ? "Menyimpan..." : "Simpan Perubahan"}
                  </Button>
                  {lessonData.status !== "published" ? (
                    <Button
                      disabled={publishMutation.isPending || updateMutation.isPending}
                      onClick={() => {
                        if (confirm("Apakah Anda yakin ingin menerbitkan materi ini?")) {
                          setSuccessMsg(null);
                          publishMutation.mutate();
                        }
                      }}
                      type="button"
                      variant="secondary"
                    >
                      {publishMutation.isPending ? "Menerbitkan..." : "Terbitkan Materi"}
                    </Button>
                  ) : null}
                </div>
                {publishMutation.error ? <Alert tone="error">{getFirstApiError(publishMutation.error)}</Alert> : null}
              </form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader><h2 className="text-xl font-black text-ink">Media Lampiran</h2></CardHeader>
            <CardContent>
              <div className="grid gap-4">
                {lessonData.media ? (
                  <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
                    <p className="font-bold text-ink">Media Terlampir</p>
                     <p className="text-sm text-slate-600">Tipe: {lessonData.media.mime_type}</p>
                    <div className="mt-2">
                      <Button
                        disabled={isMediaOperationPending || publishMutation.isPending}
                        onClick={() => {
                          if (confirm("Hapus lampiran media?")) updateMutation.mutate({ media_id: null });
                        }}
                        type="button"
                        variant="danger"
                      >
                        Hapus Lampiran
                      </Button>
                    </div>
                  </div>
                ) : (
                  <EmptyState description="Materi ini belum memiliki media lampiran (gambar/audio/PDF)." title="Tidak ada lampiran" />
                )}

                <div className="rounded-xl border-2 border-dashed border-slate-300 p-4 text-center">
                  <p className="mb-2 text-sm font-bold text-slate-600">Unggah Media Baru</p>
                   {mediaError ? <Alert className="mb-2" tone="error">{mediaError}</Alert> : null}
                   {isMediaOperationPending ? <p className="text-sm text-slate-500">Mengunggah dan menyimpan...</p> : null}
                   {mediaConfig ? (
                     <input
                       accept={mediaConfig.accept}
                       className="block w-full text-sm text-slate-500 file:mr-4 file:rounded-lg file:border-2 file:border-ink file:bg-yellow-300 file:px-4 file:py-2 file:text-sm file:font-bold file:text-ink hover:file:bg-yellow-200"
                       disabled={isMediaOperationPending || publishMutation.isPending}
                       onChange={handleUploadFile}
                       type="file"
                     />
                   ) : <p className="text-sm text-slate-500">Tipe materi ini tidak menggunakan lampiran file.</p>}
                </div>
                <Alert tone="warning">Mengunggah file baru akan langsung mengganti lampiran lama pada materi ini.</Alert>
              </div>
            </CardContent>
          </Card>
        </div>
      ) : null}
    </div>
  );
}
