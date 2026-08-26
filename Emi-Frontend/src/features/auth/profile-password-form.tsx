"use client";

import { type FormEvent, useState } from "react";
import { useMutation } from "@tanstack/react-query";

import { Button, Input, MutationAlert } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { useAuth } from "./auth-provider";
import { authService } from "./auth-service";

/**
 * Reusable "change password" form shared by Student, Teacher, and Admin
 * profile pages. Uses `PUT /auth/password`, identical contract for every
 * role.
 */
export function ProfilePasswordForm() {
  const { token } = useAuth();
  const [success, setSuccess] = useState(false);

  const mutation = useMutation({
    mutationFn: (payload: { current_password: string; password: string; password_confirmation: string }) =>
      authService.updatePassword(token ?? "", payload),
    onSuccess: () => setSuccess(true),
  });

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSuccess(false);
    const data = new FormData(event.currentTarget);
    mutation.mutate({
      current_password: String(data.get("current_password") ?? ""),
      password: String(data.get("password") ?? ""),
      password_confirmation: String(data.get("password_confirmation") ?? ""),
    });
    event.currentTarget.reset();
  }

  return (
    <form className="grid gap-3" onSubmit={submit}>
      {success ? <MutationAlert eventKey={mutation.submittedAt} tone="success">Password berhasil diperbarui.</MutationAlert> : null}
      {mutation.error ? <MutationAlert eventKey={mutation.submittedAt} tone="error">{getFirstApiError(mutation.error)}</MutationAlert> : null}
      <Input name="current_password" placeholder="Password lama" required type="password" />
      <Input name="password" placeholder="Password baru" required type="password" />
      <Input name="password_confirmation" placeholder="Konfirmasi password baru" required type="password" />
      <Button disabled={mutation.isPending} type="submit">
        {mutation.isPending ? "Menyimpan..." : "Ubah Password"}
      </Button>
    </form>
  );
}
