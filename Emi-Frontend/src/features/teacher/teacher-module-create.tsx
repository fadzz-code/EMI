"use client";

import { type FormEvent, useState } from "react";

import { Button, FormField, Input, MutationAlert, Textarea } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

export function TeacherModuleCreateForm({
  isSubmitting,
  error,
  submittedAt,
  onCancel,
  onSubmit,
}: {
  isSubmitting: boolean;
  error?: unknown;
  submittedAt: number;
  onCancel: () => void;
  onSubmit: (payload: { title: string; description?: string | null; sort_order?: number }) => void;
}) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onSubmit({ title: title.trim(), description: description.trim() || null });
  }

  return (
    <form className="grid gap-4" onSubmit={handleSubmit}>
      <MutationAlert eventKey={submittedAt} tone="error" visible={Boolean(error)}>{getFirstApiError(error)}</MutationAlert>
      <FormField label="Judul Modul">
        <Input autoFocus maxLength={255} onChange={(event) => setTitle(event.target.value)} required value={title} />
      </FormField>
      <FormField label="Deskripsi Singkat">
        <Textarea onChange={(event) => setDescription(event.target.value)} rows={3} value={description} />
      </FormField>
      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button disabled={isSubmitting} onClick={onCancel} type="button" variant="ghost">Batal</Button>
        <Button disabled={isSubmitting || !title.trim()} type="submit">{isSubmitting ? "Menyimpan..." : "Simpan Modul"}</Button>
      </div>
    </form>
  );
}
