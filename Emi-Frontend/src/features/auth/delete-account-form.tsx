"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation } from "@tanstack/react-query";

import { Alert, Button, Input, Modal } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { useAuth } from "./auth-provider";
import { authService } from "./auth-service";

/**
 * Reusable "delete/deactivate account" action shared by Student, Teacher,
 * and Admin profile pages. Backend `DELETE /auth/account` deactivates the
 * account (not a hard delete); requires current password confirmation.
 */
export function DeleteAccountForm() {
  const { token, logout } = useAuth();
  const router = useRouter();
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [password, setPassword] = useState("");

  const mutation = useMutation({
    mutationFn: () => authService.deleteAccount(token ?? "", { current_password: password }),
    onSuccess: async () => {
      setConfirmOpen(false);
      await logout();
      router.replace("/login");
    },
  });

  return (
    <div className="grid gap-3">
      {mutation.error ? <Alert tone="error">{getFirstApiError(mutation.error)}</Alert> : null}
      <p className="text-sm text-muted">
        Akun akan dinonaktifkan dan Anda tidak dapat login kembali sampai diaktifkan ulang oleh Admin.
      </p>
      <Button
        onClick={() => {
          setPassword("");
          setConfirmOpen(true);
        }}
        type="button"
        variant="danger"
      >
        Hapus Akun
      </Button>

      <Modal onClose={() => setConfirmOpen(false)} open={confirmOpen} title="Hapus akun ini?">
        <p className="text-sm text-slate-700">Masukkan password Anda untuk mengonfirmasi penghapusan akun.</p>
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
            {mutation.isPending ? "Memproses..." : "Ya, Hapus Akun"}
          </Button>
        </div>
      </Modal>
    </div>
  );
}
