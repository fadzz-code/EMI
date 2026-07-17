"use client";

import Link from "next/link";
import { type FormEvent, useState } from "react";
import { useMutation } from "@tanstack/react-query";

import { Alert, Badge, Button, Card, CardContent, CardHeader, FilePreview, FormField, Input, PageHeader, Select, UploadComponent } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import { teacherRoutes } from "@/lib/routes";

import { teacherService } from "./teacher-service";
import type { TeacherMediaFile } from "./types";

function formatBytes(value: number | null | undefined) {
  if (typeof value !== "number") {
    return "Belum tersedia";
  }
  if (value < 1024) {
    return `${value} B`;
  }
  return `${Math.ceil(value / 1024)} KB`;
}

export function TeacherMediaPage() {
  const { token } = useAuth();
  const [file, setFile] = useState<File | null>(null);
  const [uploaded, setUploaded] = useState<TeacherMediaFile | null>(null);

  const uploadMutation = useMutation({
    mutationFn: ({ selectedFile, purpose, visibility }: { selectedFile: File; purpose: string; visibility: "public" | "private" }) => teacherService.uploadMedia(token ?? "", selectedFile, purpose, visibility),
    onSuccess: (media) => setUploaded(media),
  });

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!file) {
      return;
    }
    const formData = new FormData(event.currentTarget);
    uploadMutation.mutate({
      selectedFile: file,
      purpose: String(formData.get("purpose") ?? "lesson_image"),
      visibility: String(formData.get("visibility") ?? "public") as "public" | "private",
    });
  }

  return (
    <div className="grid gap-6">
      <PageHeader badge="Media Kelas" description="Unggah media untuk dipakai pada materi, soal kuis, atau konten budaya. Galeri umum belum tersedia." title="Media" />

      <Card>
        <CardHeader>
          <div className="flex flex-wrap gap-2"><Badge tone="yellow">Galeri ditunda</Badge><Badge tone="blue">Upload aktif</Badge></div>
          <h2 className="mt-3 text-xl font-black text-ink">Media dipakai dari editor materi dan kuis</h2>
        </CardHeader>
        <CardContent>
          <p className="text-sm leading-6 text-slate-700">
            Saat ini media guru dipakai dari editor materi, builder kuis, dan konten budaya. Halaman ini tetap menyediakan upload nyata, tetapi belum menampilkan galeri media umum agar tidak membuat daftar palsu.
          </p>
          <div className="mt-5 flex flex-wrap gap-3">
            <Link className="rounded-lg border-2 border-ink bg-yellow-300 px-4 py-2 text-sm font-black text-ink shadow-brutal hover:bg-yellow-200" href={teacherRoutes.modules}>Buka Modul</Link>
            <Link className="rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-black text-ink hover:bg-yellow-100" href={teacherRoutes.quizzes}>Buka Kuis</Link>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader><h2 className="text-xl font-black text-ink">Upload Media</h2></CardHeader>
        <CardContent>
          <form className="grid gap-4" onSubmit={submit}>
            {uploadMutation.error ? <Alert tone="error">{getFirstApiError(uploadMutation.error)}</Alert> : null}
            {uploaded ? <Alert tone="success">Media berhasil diunggah. Simpan media ID jika ingin dipakai pada editor yang mendukung attachment.</Alert> : null}
            <div className="grid gap-4 md:grid-cols-2">
              <FormField label="Kegunaan media">
                <Select name="purpose">
                  <option value="lesson_image">Gambar materi</option>
                  <option value="question_image">Gambar soal</option>
                  <option value="document">Dokumen PDF</option>
                  <option value="audio">Audio</option>
                </Select>
              </FormField>
              <FormField label="Akses file">
                <Select name="visibility">
                  <option value="public">Public</option>
                  <option value="private">Private</option>
                </Select>
              </FormField>
            </div>
            <UploadComponent accept=".jpg,.jpeg,.png,.webp,.pdf,.mp3,.wav,.m4a,.ogg,.webm,image/jpeg,image/png,image/webp,application/pdf,audio/*" onChange={(event) => setFile(event.target.files?.[0] ?? null)} />
            {file ? <FilePreview name={file.name} size={`${Math.ceil(file.size / 1024)} KB`} type={file.type || "File"} /> : null}
            <Button disabled={!file || uploadMutation.isPending} type="submit">{uploadMutation.isPending ? "Mengunggah..." : "Upload Media"}</Button>
          </form>

          {uploaded ? (
            <div className="mt-6 grid gap-3 rounded-xl border-2 border-ink bg-slate-50 p-4 text-sm">
              <h3 className="font-black text-ink">Metadata dari Backend</h3>
              <label className="grid gap-2 font-black text-ink">Media ID<Input readOnly value={uploaded.id} /></label>
              <dl className="grid gap-3 sm:grid-cols-2">
                <div><dt className="font-black text-slate-500">Nama file</dt><dd>{uploaded.original_name ?? "Belum tersedia"}</dd></div>
                <div><dt className="font-black text-slate-500">Kegunaan</dt><dd>{uploaded.purpose ?? "Belum tersedia"}</dd></div>
                <div><dt className="font-black text-slate-500">Tipe file</dt><dd>{uploaded.mime_type ?? "Belum tersedia"}</dd></div>
                <div><dt className="font-black text-slate-500">Ukuran</dt><dd>{formatBytes(uploaded.size_bytes)}</dd></div>
                <div><dt className="font-black text-slate-500">Akses</dt><dd>{uploaded.visibility ?? "Belum tersedia"}</dd></div>
                <div><dt className="font-black text-slate-500">URL public</dt><dd>{uploaded.url ? <a className="font-black text-blue-700 underline" href={uploaded.url} rel="noreferrer" target="_blank">Buka file</a> : "Tidak tersedia untuk media private"}</dd></div>
              </dl>
            </div>
          ) : null}
        </CardContent>
      </Card>
    </div>
  );
}
