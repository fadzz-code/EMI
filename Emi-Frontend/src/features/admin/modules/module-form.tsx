"use client";

import { type FormEvent, useState } from "react";

import { Button, FormField, Input, Select, Textarea } from "@/components/ui";

import { normalizeNullable } from "./module-utils";
import type { ModuleTemplate, ModuleTemplatePayload, ModuleTemplateStatus } from "./types";

type ModuleFormState = {
  title: string;
  description: string;
  status: ModuleTemplateStatus;
};

function toForm(module?: ModuleTemplate | null): ModuleFormState {
  return {
    title: module?.title ?? "",
    description: module?.description ?? "",
    status: module?.status ?? "draft",
  };
}

function toPayload(form: ModuleFormState): ModuleTemplatePayload {
  return {
    title: form.title.trim(),
    description: normalizeNullable(form.description),
    status: form.status,
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
      <FormField label="Status">
        <Select
          onChange={(event) =>
            setForm((current) => ({
              ...current,
              status: event.target.value as ModuleTemplateStatus,
            }))
          }
          value={form.status}
        >
          <option value="draft">Draft</option>
          <option value="published">Terbit</option>
          <option value="archived">Diarsipkan</option>
        </Select>
      </FormField>
      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button onClick={onCancel} type="button" variant="ghost">
          Batal
        </Button>
        <Button disabled={isSubmitting} type="submit">
          Simpan Modul
        </Button>
      </div>
    </form>
  );
}
