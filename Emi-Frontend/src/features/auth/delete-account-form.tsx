"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation } from "@tanstack/react-query";

import { Button, Input, Modal, MutationAlert } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { useAuth } from "./auth-provider";
import { authService } from "./auth-service";

export function DeleteAccountForm() {
  const { token, clearSession } = useAuth();
  const router = useRouter();
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [password, setPassword] = useState("");

  const mutation = useMutation({
    mutationFn: () => authService.deleteAccount(token ?? "", { current_password: password }),
    onSuccess: () => {
      setConfirmOpen(false);
      clearSession();
      router.replace("/login");
    },
  });

  return (
    <div className="grid gap-3">
      {mutation.error ? <MutationAlert eventKey={mutation.submittedAt} tone="error">{getFirstApiError(mutation.error)}</MutationAlert> : null}
      <p className="text-sm text-muted">
        Akun dan data pribadi Anda akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.
      </p>
      <Button
        disabled={mutation.isPending}
        onClick={() => {
          if (confirmOpen || mutation.isPending) return;
          setPassword("");
          setConfirmOpen(true);
        }}
        type="button"
        variant="danger"
      >
        Hapus Akun
      </Button>

      <Modal onClose={() => setConfirmOpen(false)} open={confirmOpen} title="Hapus akun secara permanen?">
        <p className="text-sm text-slate-700">Masukkan password Anda untuk mengonfirmasi penghapusan permanen akun.</p>
        <Input
          className="mt-3"
          onChange={(event) => setPassword(event.target.value)}
          placeholder="Password"
          type="password"
          value={password}
        />
        <div className="mt-5 flex flex-col gap-3 sm:flex-row sm:justify-end">
          <Button disabled={mutation.isPending} onClick={() => setConfirmOpen(false)} variant="ghost">
            Batal
          </Button>
          <Button disabled={mutation.isPending || !password} onClick={() => mutation.mutate()} variant="danger">
            {mutation.isPending ? "Menghapus..." : "Ya, Hapus Permanen"}
          </Button>
        </div>
      </Modal>
    </div>
  );
}
