"use client";

import { useRef, useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";

import { Button, MutationAlert } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { useAuth } from "./auth-provider";
import { authService } from "./auth-service";

function getInitials(name?: string | null) {
  return (
    name
      ?.split(" ")
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase())
      .join("") || "?"
  );
}

/**
 * Reusable avatar upload/remove widget shared by Student, Teacher, and
 * Admin profile pages. Uses `/auth/me/avatar` (POST multipart / DELETE),
 * identical contract for every role, so this component never needs to
 * know which role is using it.
 */
export function ProfileAvatarUpload({
  fullName,
  avatarUrl,
  invalidateKey,
}: {
  fullName?: string | null;
  avatarUrl?: string | null;
  invalidateKey: unknown[];
}) {
  const { token, refreshUser } = useAuth();
  const queryClient = useQueryClient();
  const inputRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<string | null>(null);

  const uploadMutation = useMutation({
    mutationFn: (file: File) => authService.uploadAvatar(token ?? "", file),
    onSuccess: async () => {
      setPreview(null);
      await queryClient.invalidateQueries({ queryKey: invalidateKey });
      await refreshUser();
    },
  });

  const removeMutation = useMutation({
    mutationFn: () => authService.deleteAvatar(token ?? ""),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: invalidateKey });
      await refreshUser();
    },
  });

  const error = uploadMutation.error || removeMutation.error;
  const isPending = uploadMutation.isPending || removeMutation.isPending;
  const displayUrl = preview ?? avatarUrl ?? null;

  function pickFile() {
    inputRef.current?.click();
  }

  function onFileSelected(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    setPreview(URL.createObjectURL(file));
    uploadMutation.mutate(file);
    event.target.value = "";
  }

  return (
    <div className="grid gap-3">
      {error ? <MutationAlert eventKey={Math.max(uploadMutation.submittedAt, removeMutation.submittedAt)} tone="error">{getFirstApiError(error)}</MutationAlert> : null}
      <div className="flex items-center gap-4">
        <div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-full border-2 border-border bg-surface text-2xl font-black text-ink shadow-emi">
          {displayUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img alt="Avatar" className="h-full w-full object-cover" src={displayUrl} />
          ) : (
            getInitials(fullName)
          )}
        </div>
        <div className="flex flex-col gap-2">
          <input accept="image/*" className="hidden" onChange={onFileSelected} ref={inputRef} type="file" />
          <Button disabled={isPending} onClick={pickFile} type="button" variant="secondary">
            {uploadMutation.isPending ? "Mengunggah..." : "Ganti Foto"}
          </Button>
          {avatarUrl ? (
            <Button disabled={isPending} onClick={() => removeMutation.mutate()} type="button" variant="ghost">
              {removeMutation.isPending ? "Menghapus..." : "Hapus Foto"}
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
