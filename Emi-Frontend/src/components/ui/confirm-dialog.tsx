"use client";

import { Button } from "./button";
import { Modal } from "./modal";

type ConfirmDialogVariant = "primary" | "secondary" | "danger";

export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel = "Ya, lanjutkan",
  confirmVariant = "danger",
  isConfirming = false,
  onCancel,
  onConfirm,
}: {
  open: boolean;
  title: string;
  description: string;
  confirmLabel?: string;
  confirmVariant?: ConfirmDialogVariant;
  isConfirming?: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <Modal onClose={onCancel} open={open} title={title}>
      <p className="text-sm text-slate-700">{description}</p>
      <div className="mt-5 flex flex-col gap-3 sm:flex-row sm:justify-end">
        <Button disabled={isConfirming} onClick={onCancel} variant="ghost">
          Batal
        </Button>
        <Button disabled={isConfirming} onClick={onConfirm} variant={confirmVariant}>
          {confirmLabel}
        </Button>
      </div>
    </Modal>
  );
}
