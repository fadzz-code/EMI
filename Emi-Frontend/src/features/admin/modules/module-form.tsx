"use client";

import { type FormEvent, useState } from "react";

import { Button, FormField, Input, Textarea } from "@/components/ui";

import { normalizeNullable } from "./module-utils";
import type { ModuleTemplate, ModuleTemplatePayload } from "./types";

type ModuleFormState = {
  title: string;
  description: string;
};

function toForm(module?: ModuleTemplate | null): ModuleFormState {
  return {
    title: module?.title ?? "",
    description: module?.description ?? "",
  };
}

function toPayload(form: ModuleFormState): ModuleTemplatePayload {
  return {
    title: form.title.trim(),
    description: normalizeNullable(form.description),
  };
}

export function ModuleTemplateForm({
  module,
  isSubmitting,
  onCancel,
  onSubmit,
}: {
  module?: ModuleTemplate | null;
  isSubmitting: boolean;
  onCancel: () => void;
  onSubmit: (payload: ModuleTemplatePayload) => void;
}) {
  const [form, setForm] = useState<ModuleFormState>(() => toForm(module));

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    onSubmit(toPayload(form));
  }

  return (
    <form className="grid gap-4" onSubmit={handleSubmit}>
      <FormField label="Judul modul">
        <Input
          autoFocus
          maxLength={255}
          onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))}
          required
          value={form.title}
        />
      </FormField>
      <FormField label="Deskripsi singkat">
        <Textarea
          onChange={(event) =>
            setForm((current) => ({ ...current, description: event.target.value }))
          }
          value={form.description}
        />
      </FormField>
      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting} type="submit">
          Simpan Metadata
        </Button>
      </div>
    </form>
  );
}
